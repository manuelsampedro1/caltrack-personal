import Foundation
import SwiftData

@Model
final class MealEntry {
    var id: UUID
    var date: Date
    var name: String
    var calories: Double
    var protein: Double
    var carbohydrates: Double
    var fat: Double
    @Attribute(.externalStorage) var photoData: Data?
    var source: String
    var confidence: Double
    var assumption: String

    init(
        id: UUID = UUID(),
        date: Date = .now,
        name: String,
        calories: Double,
        protein: Double,
        carbohydrates: Double = 0,
        fat: Double = 0,
        photoData: Data? = nil,
        source: String = "manual",
        confidence: Double = 1,
        assumption: String = ""
    ) {
        self.id = id
        self.date = date
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbohydrates = carbohydrates
        self.fat = fat
        self.photoData = photoData
        self.source = source
        self.confidence = confidence
        self.assumption = assumption
    }
}

@Model
final class BodyMeasurement {
    var id: UUID
    var date: Date
    var weight: Double?
    var bodyFat: Double?
    var waist: Double?
    var source: String

    init(id: UUID = UUID(), date: Date = .now, weight: Double? = nil, bodyFat: Double? = nil, waist: Double? = nil, source: String = "manual") {
        self.id = id
        self.date = date
        self.weight = weight
        self.bodyFat = bodyFat
        self.waist = waist
        self.source = source
    }
}

@Model
final class ActivityDay {
    var id: UUID
    @Attribute(.unique) var externalID: String
    var date: Date
    var activeEnergy: Double
    var restingEnergy: Double
    var steps: Double
    var source: String

    init(
        id: UUID = UUID(),
        externalID: String,
        date: Date,
        activeEnergy: Double = 0,
        restingEnergy: Double = 0,
        steps: Double = 0,
        source: String = "HealthKit"
    ) {
        self.id = id
        self.externalID = externalID
        self.date = date
        self.activeEnergy = activeEnergy
        self.restingEnergy = restingEnergy
        self.steps = steps
        self.source = source
    }

    var totalEnergy: Double { activeEnergy + restingEnergy }
}

struct WorkoutExerciseSummary: Codable, Equatable, Identifiable {
    var id: String { name }
    let name: String
    let setCount: Int
    let bestWeight: Double?
    let bestReps: Int?
    let volumeKg: Double
    let rpe: Double?
}

@Model
final class WorkoutEntry {
    var id: UUID
    @Attribute(.unique) var externalID: String
    var startDate: Date
    var endDate: Date
    var title: String
    var activityType: String
    var durationMinutes: Double
    var calories: Double?
    var distanceKm: Double?
    var source: String
    var sourceBundle: String
    var exerciseCount: Int
    var setCount: Int
    var totalVolumeKg: Double
    @Attribute(.externalStorage) var exerciseData: Data?

    init(
        id: UUID = UUID(),
        externalID: String,
        startDate: Date,
        endDate: Date,
        title: String,
        activityType: String,
        durationMinutes: Double,
        calories: Double? = nil,
        distanceKm: Double? = nil,
        source: String,
        sourceBundle: String = "",
        exerciseCount: Int = 0,
        setCount: Int = 0,
        totalVolumeKg: Double = 0,
        exercises: [WorkoutExerciseSummary] = []
    ) {
        self.id = id
        self.externalID = externalID
        self.startDate = startDate
        self.endDate = endDate
        self.title = title
        self.activityType = activityType
        self.durationMinutes = durationMinutes
        self.calories = calories
        self.distanceKm = distanceKm
        self.source = source
        self.sourceBundle = sourceBundle
        self.exerciseCount = exerciseCount == 0 && !exercises.isEmpty ? exercises.count : exerciseCount
        self.setCount = setCount == 0 && !exercises.isEmpty ? exercises.reduce(0) { $0 + $1.setCount } : setCount
        self.totalVolumeKg = totalVolumeKg == 0 && !exercises.isEmpty ? exercises.reduce(0) { $0 + $1.volumeKg } : totalVolumeKg
        self.exerciseData = try? JSONEncoder().encode(exercises)
    }

    var exercises: [WorkoutExerciseSummary] {
        guard let exerciseData else { return [] }
        return (try? JSONDecoder().decode([WorkoutExerciseSummary].self, from: exerciseData)) ?? []
    }

    func updateExercises(_ exercises: [WorkoutExerciseSummary]) {
        exerciseData = try? JSONEncoder().encode(exercises)
        exerciseCount = exercises.count
        setCount = exercises.reduce(0) { $0 + $1.setCount }
        totalVolumeKg = exercises.reduce(0) { $0 + $1.volumeKg }
    }
}

@Model
final class CoachMessage {
    var id: UUID
    var date: Date
    var role: String
    var content: String

    init(id: UUID = UUID(), date: Date = .now, role: String, content: String) {
        self.id = id
        self.date = date
        self.role = role
        self.content = content
    }
}

struct FoodAnalysis: Codable, Equatable {
    struct Item: Codable, Equatable, Identifiable {
        var id: String { "\(name)-\(portion)" }
        let name: String
        let portion: String
        let calories: Double
        let proteinG: Double
        let carbsG: Double
        let fatG: Double

        enum CodingKeys: String, CodingKey {
            case name, portion, calories
            case proteinG = "protein_g"
            case carbsG = "carbs_g"
            case fatG = "fat_g"
        }
    }

    let title: String
    let items: [Item]
    let calories: Double
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
    let confidence: Double
    let assumptions: [String]
    let warning: String

    enum CodingKeys: String, CodingKey {
        case title, items, calories, confidence, assumptions, warning
        case proteinG = "protein_g"
        case carbsG = "carbs_g"
        case fatG = "fat_g"
    }
}

struct EditableMeal {
    var name = ""
    var calories = ""
    var protein = ""
    var carbohydrates = ""
    var fat = ""
    var confidence = 0.0
    var assumption = ""

    init() {}

    init(analysis: FoodAnalysis) {
        name = analysis.title
        calories = Self.format(analysis.calories)
        protein = Self.format(analysis.proteinG)
        carbohydrates = Self.format(analysis.carbsG)
        fat = Self.format(analysis.fatG)
        confidence = analysis.confidence
        assumption = analysis.assumptions.joined(separator: " · ")
    }

    init(meal: MealEntry) {
        name = meal.name
        calories = Self.format(meal.calories)
        protein = Self.format(meal.protein)
        carbohydrates = Self.format(meal.carbohydrates)
        fat = Self.format(meal.fat)
        confidence = meal.confidence
        assumption = meal.assumption
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && number(calories) >= 0 && number(protein) >= 0
    }

    func number(_ value: String) -> Double {
        Double(value.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private static func format(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }
}

enum CaltrackMath {
    static func totals(for meals: [MealEntry]) -> (calories: Double, protein: Double) {
        meals.reduce((0, 0)) { ($0.0 + $1.calories, $0.1 + $1.protein) }
    }

    static func adherence(calories: Double, protein: Double, calorieRange: ClosedRange<Double>, proteinRange: ClosedRange<Double>) -> Int {
        let calorieScore = calorieRange.contains(calories) ? 1.0 : max(0, 1 - abs(calories - calorieRange.clamped(calories)) / max(calorieRange.upperBound, 1))
        let proteinScore = min(1, protein / max(proteinRange.lowerBound, 1))
        return Int(((calorieScore + proteinScore) * 50).rounded())
    }
}

enum WorkoutMatch {
    static func isHevySource(name: String, bundle: String) -> Bool {
        "\(name) \(bundle)".localizedCaseInsensitiveContains("hevy")
    }

    static func representsSameSession(sourceName: String, sourceBundle: String, startDate: Date, hevyStartDate: Date) -> Bool {
        isHevySource(name: sourceName, bundle: sourceBundle) && abs(startDate.timeIntervalSince(hevyStartDate)) < 600
    }
}

private extension ClosedRange where Bound == Double {
    func clamped(_ value: Double) -> Double {
        Swift.min(Swift.max(value, lowerBound), upperBound)
    }
}
