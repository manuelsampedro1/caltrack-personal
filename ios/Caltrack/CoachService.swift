import Foundation

struct CoachService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func ask(question: String, context: String, apiKey: String) async throws -> String {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw GrokError.missingAPIKey
        }
        var request = URLRequest(url: URL(string: "https://api.x.ai/v1/responses")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 90
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": "grok-4.5",
            "store": false,
            "input": [
                [
                    "role": "system",
                    "content": [["type": "input_text", "text": Self.systemPrompt]]
                ],
                [
                    "role": "user",
                    "content": [["type": "input_text", "text": "DATOS\n\(context)\n\nPREGUNTA\n\(question)"]]
                ]
            ]
        ])

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw CoachError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            if http.statusCode == 401 { throw GrokError.invalidAPIKey }
            throw CoachError.api(Self.errorMessage(from: data) ?? "xAI devolvió el código \(http.statusCode).")
        }
        return try Self.decodeText(data)
    }

    static func decodeText(_ data: Data) throws -> String {
        let envelope = try JSONDecoder().decode(CoachResponseEnvelope.self, from: data)
        guard let rawText = envelope.output
            .flatMap({ $0.content ?? [] })
            .first(where: { $0.type == "output_text" })?.text else {
            throw CoachError.invalidResponse
        }
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw CoachError.invalidResponse }
        return text
    }

    private static func errorMessage(from data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let error = object["error"] as? [String: Any] else { return nil }
        return error["message"] as? String
    }

    private static let systemPrompt = """
    Eres el entrenador nutricional de una aplicación personal. Responde en español, de forma directa, concreta y humana. Basa cada afirmación en los datos incluidos. Diferencia registros completos de días sin datos. No diagnostiques, no prescribas fármacos y no recomiendes déficits extremos. Cuando los datos sean insuficientes, dilo. Prioriza adherencia, proteína, tendencia corporal, energía y recuperación. Termina con una única acción práctica para los próximos siete días. No uses tablas ni más de 220 palabras.
    """
}

enum CoachContextBuilder {
    static func build(
        meals: [MealEntry],
        measurements: [BodyMeasurement],
        workouts: [WorkoutEntry],
        activities: [ActivityDay] = [],
        checkIns: [DailyPlanCheckIn] = [],
        planMode: PlanGoalMode = .notSet,
        planWeeklyRate: Double = 0,
        calorieRange: ClosedRange<Double>,
        proteinRange: ClosedRange<Double>,
        now: Date = .now
    ) -> String {
        let days = InsightEngine.nutritionDays(meals: meals, count: 30, now: now)
            .filter { $0.calories > 0 || $0.protein > 0 }
        var lines = [
            "Objetivo de calorías: \(Int(calorieRange.lowerBound)) a \(Int(calorieRange.upperBound)) kcal.",
            "Objetivo de proteína: \(Int(proteinRange.lowerBound)) a \(Int(proteinRange.upperBound)) g.",
            "Días con comida registrada: \(days.count) de 30."
        ]
        if planMode != .notSet {
            lines.append("Plan personal: \(planMode.title), ritmo objetivo \(planMode.signedRate(planWeeklyRate).formatted(.number.precision(.fractionLength(2)))) kg por semana.")
        }
        let recentCheckIns = checkIns.filter {
            $0.nutritionComplete && $0.date >= (Calendar.current.date(byAdding: .day, value: -30, to: now) ?? .distantPast)
        }
        if !recentCheckIns.isEmpty {
            let hunger = Double(recentCheckIns.reduce(0) { $0 + $1.hunger }) / Double(recentCheckIns.count)
            let energy = Double(recentCheckIns.reduce(0) { $0 + $1.energy }) / Double(recentCheckIns.count)
            lines.append("Cierres completos: \(recentCheckIns.count) de 30. Hambre media \(hunger.formatted(.number.precision(.fractionLength(1)))) de 5 y energía media \(energy.formatted(.number.precision(.fractionLength(1)))) de 5.")
        }
        lines += days.suffix(20).map {
            "\($0.date.formatted(.iso8601.year().month().day())): \(Int($0.calories)) kcal, \(Int($0.protein)) g proteína, \(Int($0.carbohydrates)) g carbohidratos, \(Int($0.fat)) g grasa."
        }

        let body = measurements.sorted { $0.date > $1.date }.prefix(12)
        if !body.isEmpty {
            lines.append("Mediciones recientes:")
            lines += body.map {
                let weight = $0.weight.map { "\($0.formatted(.number.precision(.fractionLength(1)))) kg" } ?? "sin peso"
                let fat = $0.bodyFat.map { "\($0.formatted(.number.precision(.fractionLength(1))))% grasa" } ?? "sin grasa"
                let waist = $0.waist.map { "\($0.formatted(.number.precision(.fractionLength(1)))) cm cintura" } ?? "sin cintura"
                return "\($0.date.formatted(.iso8601.year().month().day())): \(weight), \(fat), \(waist)."
            }
        }

        let recentWorkouts = workouts
            .filter { $0.startDate >= Calendar.current.date(byAdding: .day, value: -30, to: now) ?? .distantPast }
            .sorted { $0.startDate > $1.startDate }
            .prefix(20)
        lines.append("Entrenamientos en 30 días: \(recentWorkouts.count).")
        lines += recentWorkouts.map {
            "\($0.startDate.formatted(.iso8601.year().month().day())): \($0.title), \(Int($0.durationMinutes)) min, \($0.setCount) series, \(Int($0.totalVolumeKg)) kg de volumen."
        }
        let recentActivity = activities.sorted { $0.date > $1.date }.prefix(20)
        if !recentActivity.isEmpty {
            lines.append("Actividad diaria reciente:")
            lines += recentActivity.map {
                "\($0.date.formatted(.iso8601.year().month().day())): \(Int($0.activeEnergy)) kcal activas, \(Int($0.restingEnergy)) kcal basales, \(Int($0.steps)) pasos."
            }
        }
        return lines.joined(separator: "\n")
    }
}

private struct CoachResponseEnvelope: Decodable {
    struct Output: Decodable {
        struct Content: Decodable {
            let type: String
            let text: String?
        }
        let content: [Content]?
    }
    let output: [Output]
}

enum CoachError: LocalizedError {
    case invalidResponse
    case api(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: "Grok respondió con un formato que Caltrack no reconoce."
        case .api(let message): message
        }
    }
}
