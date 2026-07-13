import Foundation

struct HevyService {
    static let apiKeyAccount = "hevy-api-key"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchRecentWorkouts(apiKey: String, pageSize: Int = 10) async throws -> [HevyWorkoutDTO] {
        try await fetchWorkoutBatch(apiKey: apiKey, pageSize: pageSize, maxPages: 1).workouts
    }

    func fetchWorkoutBatch(apiKey: String, pageSize: Int = 10, maxPages: Int = 10) async throws -> HevyWorkoutBatch {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw HevyError.missingAPIKey
        }
        let safePageSize = min(max(pageSize, 1), 10)
        let safeMaxPages = min(max(maxPages, 1), 25)
        var workouts = [HevyWorkoutDTO]()
        var identifiers = Set<String>()
        var totalPages: Int?
        var pagesFetched = 0

        for page in 1...safeMaxPages {
            let response = try await fetchWorkoutPage(apiKey: apiKey, page: page, pageSize: safePageSize)
            pagesFetched += 1
            totalPages = response.pageCount ?? totalPages
            for workout in response.workouts where identifiers.insert(workout.id).inserted {
                workouts.append(workout)
            }
            if response.workouts.isEmpty { break }
            if let pageCount = response.pageCount, page >= pageCount { break }
            if response.pageCount == nil, response.workouts.count < safePageSize { break }
        }

        return HevyWorkoutBatch(
            workouts: workouts,
            pagesFetched: pagesFetched,
            totalPages: totalPages,
            isTruncated: totalPages.map { pagesFetched < $0 } ?? (pagesFetched == safeMaxPages && workouts.count == safePageSize * safeMaxPages)
        )
    }

    private func fetchWorkoutPage(apiKey: String, page: Int, pageSize: Int) async throws -> HevyWorkoutsResponse {
        var components = URLComponents(string: "https://api.hevyapp.com/v1/workouts")!
        components.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "pageSize", value: String(pageSize))
        ]
        var request = URLRequest(url: components.url!)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(apiKey, forHTTPHeaderField: "api-key")
        request.timeoutInterval = 45

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw HevyError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            if http.statusCode == 401 { throw HevyError.invalidAPIKey }
            if http.statusCode == 403 { throw HevyError.proRequired }
            throw HevyError.api("Hevy devolvió el código \(http.statusCode).")
        }
        return try Self.decodeWorkoutPage(data)
    }

    static func decodeWorkouts(_ data: Data) throws -> [HevyWorkoutDTO] {
        try decodeWorkoutPage(data).workouts
    }

    static func decodeWorkoutPage(_ data: Data) throws -> HevyWorkoutsResponse {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let value = try decoder.singleValueContainer().decode(String.self)
            let fractional = ISO8601DateFormatter()
            fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = fractional.date(from: value) { return date }
            let standard = ISO8601DateFormatter()
            if let date = standard.date(from: value) { return date }
            throw DecodingError.dataCorruptedError(in: try decoder.singleValueContainer(), debugDescription: "Fecha de Hevy no válida")
        }
        return try decoder.decode(HevyWorkoutsResponse.self, from: data)
    }
}

struct HevyWorkoutBatch: Equatable {
    let workouts: [HevyWorkoutDTO]
    let pagesFetched: Int
    let totalPages: Int?
    let isTruncated: Bool
}

struct HevyWorkoutsResponse: Decodable {
    let page: Int?
    let pageCount: Int?
    let workouts: [HevyWorkoutDTO]

    enum CodingKeys: String, CodingKey {
        case page, workouts
        case pageCount = "page_count"
    }
}

struct HevyWorkoutDTO: Decodable, Equatable {
    struct Exercise: Decodable, Equatable {
        struct Set: Decodable, Equatable {
            let index: Int?
            let setType: String?
            let weightKg: Double?
            let reps: Int?
            let distanceMeters: Double?
            let durationSeconds: Double?
            let rpe: Double?

            enum CodingKeys: String, CodingKey {
                case index, reps, rpe
                case setType = "set_type"
                case weightKg = "weight_kg"
                case distanceMeters = "distance_meters"
                case durationSeconds = "duration_seconds"
            }
        }

        let title: String
        let notes: String?
        let sets: [Set]
    }

    let id: String
    let title: String
    let description: String?
    let startTime: Date
    let endTime: Date
    let exercises: [Exercise]

    enum CodingKeys: String, CodingKey {
        case id, title, description, exercises
        case startTime = "start_time"
        case endTime = "end_time"
    }

    var exerciseSummaries: [WorkoutExerciseSummary] {
        exercises.map { exercise in
            let workingSets = exercise.sets.filter { ($0.setType ?? "normal") != "warmup" }
            let best = workingSets.max { lhs, rhs in
                estimatedOneRepMax(lhs) < estimatedOneRepMax(rhs)
            }
            let volume = workingSets.reduce(0.0) { total, set in
                total + (set.weightKg ?? 0) * Double(set.reps ?? 0)
            }
            return WorkoutExerciseSummary(
                name: exercise.title,
                setCount: workingSets.count,
                bestWeight: best?.weightKg,
                bestReps: best?.reps,
                volumeKg: volume,
                rpe: best?.rpe
            )
        }
    }

    func makeEntry() -> WorkoutEntry {
        let summaries = exerciseSummaries
        return WorkoutEntry(
            externalID: "hevy:\(id)",
            startDate: startTime,
            endDate: endTime,
            title: title,
            activityType: "Fuerza",
            durationMinutes: max(0, endTime.timeIntervalSince(startTime) / 60),
            source: "Hevy",
            sourceBundle: "com.hevyapp.hevy",
            exerciseCount: summaries.count,
            setCount: summaries.reduce(0) { $0 + $1.setCount },
            totalVolumeKg: summaries.reduce(0) { $0 + $1.volumeKg },
            exercises: summaries
        )
    }

    private func estimatedOneRepMax(_ set: Exercise.Set) -> Double {
        let weight = set.weightKg ?? 0
        let reps = Double(set.reps ?? 0)
        return weight * (1 + reps / 30)
    }
}

enum HevyError: LocalizedError {
    case missingAPIKey
    case invalidAPIKey
    case proRequired
    case invalidResponse
    case api(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: "Añade tu clave de Hevy en Ajustes."
        case .invalidAPIKey: "La clave de Hevy no es válida."
        case .proRequired: "La API oficial de Hevy está disponible únicamente para usuarios Pro."
        case .invalidResponse: "Hevy respondió con un formato no válido."
        case .api(let message): message
        }
    }
}
