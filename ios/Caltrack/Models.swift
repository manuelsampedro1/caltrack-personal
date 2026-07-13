import Foundation
import SwiftData

struct MealComponent: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let name: String
    let portion: String
    let calories: Double
    let protein: Double
    let carbohydrates: Double
    let fat: Double
    let fiber: Double?

    init(
        id: UUID = UUID(),
        name: String,
        portion: String,
        calories: Double,
        protein: Double,
        carbohydrates: Double,
        fat: Double,
        fiber: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.portion = portion
        self.calories = calories
        self.protein = protein
        self.carbohydrates = carbohydrates
        self.fat = fat
        self.fiber = fiber
    }
}

@Model
final class MealEntry {
    var id: UUID
    var date: Date
    var name: String
    var calories: Double
    var protein: Double
    var carbohydrates: Double
    var fat: Double
    var fiber: Double?
    @Attribute(.externalStorage) var photoData: Data?
    @Attribute(.externalStorage) var componentData: Data?
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
        fiber: Double? = nil,
        photoData: Data? = nil,
        components: [MealComponent] = [],
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
        self.fiber = fiber
        self.photoData = photoData
        self.componentData = components.isEmpty ? nil : try? JSONEncoder().encode(components)
        self.source = source
        self.confidence = confidence
        self.assumption = assumption
    }

    var components: [MealComponent] {
        guard let componentData else { return [] }
        return (try? JSONDecoder().decode([MealComponent].self, from: componentData)) ?? []
    }

    func updateComponents(_ components: [MealComponent]) {
        componentData = components.isEmpty ? nil : try? JSONEncoder().encode(components)
    }
}

@Model
final class BodyMeasurement {
    var id: UUID
    var date: Date
    var weight: Double?
    var bodyFat: Double?
    var waist: Double?
    @Attribute(.externalStorage) var photoData: Data?
    var source: String

    init(
        id: UUID = UUID(),
        date: Date = .now,
        weight: Double? = nil,
        bodyFat: Double? = nil,
        waist: Double? = nil,
        photoData: Data? = nil,
        source: String = "manual"
    ) {
        self.id = id
        self.date = date
        self.weight = weight
        self.bodyFat = bodyFat
        self.waist = waist
        self.photoData = photoData
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

@Model
final class RecoveryDay {
    var id: UUID
    @Attribute(.unique) var externalID: String
    var date: Date
    var sleepMinutes: Double
    var coreMinutes: Double
    var deepMinutes: Double
    var remMinutes: Double
    var restingHeartRate: Double?
    var hrvSDNN: Double?
    var source: String

    init(
        id: UUID = UUID(),
        externalID: String,
        date: Date,
        sleepMinutes: Double = 0,
        coreMinutes: Double = 0,
        deepMinutes: Double = 0,
        remMinutes: Double = 0,
        restingHeartRate: Double? = nil,
        hrvSDNN: Double? = nil,
        source: String = "HealthKit"
    ) {
        self.id = id
        self.externalID = externalID
        self.date = date
        self.sleepMinutes = sleepMinutes
        self.coreMinutes = coreMinutes
        self.deepMinutes = deepMinutes
        self.remMinutes = remMinutes
        self.restingHeartRate = restingHeartRate
        self.hrvSDNN = hrvSDNN
        self.source = source
    }
}

@Model
final class DailyPlanCheckIn {
    var id: UUID
    @Attribute(.unique) var externalID: String
    var date: Date
    var nutritionComplete: Bool
    var hunger: Int
    var energy: Int

    init(
        id: UUID = UUID(),
        externalID: String,
        date: Date,
        nutritionComplete: Bool = true,
        hunger: Int = 3,
        energy: Int = 3
    ) {
        self.id = id
        self.externalID = externalID
        self.date = date
        self.nutritionComplete = nutritionComplete
        self.hunger = hunger
        self.energy = energy
    }
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
        var fiberG: Double? = nil

        enum CodingKeys: String, CodingKey {
            case name, portion, calories
            case proteinG = "protein_g"
            case carbsG = "carbs_g"
            case fatG = "fat_g"
            case fiberG = "fiber_g"
        }
    }

    let title: String
    let items: [Item]
    let calories: Double
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
    var fiberG: Double? = nil
    let confidence: Double
    let assumptions: [String]
    let warning: String

    enum CodingKeys: String, CodingKey {
        case title, items, calories, confidence, assumptions, warning
        case proteinG = "protein_g"
        case carbsG = "carbs_g"
        case fatG = "fat_g"
        case fiberG = "fiber_g"
    }
}

struct EditableMealComponent: Identifiable, Equatable {
    var id = UUID()
    var name = ""
    var portion = ""
    var calories = ""
    var protein = ""
    var carbohydrates = ""
    var fat = ""
    var fiber = ""

    init() {}

    init(item: FoodAnalysis.Item) {
        name = item.name
        portion = item.portion
        calories = EditableMeal.format(item.calories)
        protein = EditableMeal.format(item.proteinG)
        carbohydrates = EditableMeal.format(item.carbsG)
        fat = EditableMeal.format(item.fatG)
        fiber = item.fiberG.map(EditableMeal.format) ?? ""
    }

    init(component: MealComponent) {
        id = component.id
        name = component.name
        portion = component.portion
        calories = EditableMeal.format(component.calories)
        protein = EditableMeal.format(component.protein)
        carbohydrates = EditableMeal.format(component.carbohydrates)
        fat = EditableMeal.format(component.fat)
        fiber = component.fiber.map(EditableMeal.format) ?? ""
    }

    var persisted: MealComponent? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return nil }
        return MealComponent(
            id: id,
            name: trimmedName,
            portion: portion.trimmingCharacters(in: .whitespacesAndNewlines),
            calories: EditableMeal.number(calories),
            protein: EditableMeal.number(protein),
            carbohydrates: EditableMeal.number(carbohydrates),
            fat: EditableMeal.number(fat),
            fiber: EditableMeal.optionalNumber(fiber)
        )
    }

    var hasValidFiber: Bool {
        let trimmed = fiber.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || (EditableMeal.optionalNumber(trimmed) ?? -1) >= 0
    }
}

struct EditableMeal {
    var name = ""
    var calories = ""
    var protein = ""
    var carbohydrates = ""
    var fat = ""
    var fiber = ""
    var confidence = 0.0
    var assumption = ""
    var components = [EditableMealComponent]()

    init() {}

    init(analysis: FoodAnalysis) {
        name = analysis.title
        calories = Self.format(analysis.calories)
        protein = Self.format(analysis.proteinG)
        carbohydrates = Self.format(analysis.carbsG)
        fat = Self.format(analysis.fatG)
        fiber = analysis.fiberG.map(Self.format) ?? ""
        confidence = analysis.confidence
        assumption = analysis.assumptions.joined(separator: " · ")
        components = analysis.items.map(EditableMealComponent.init)
    }

    init(meal: MealEntry) {
        name = meal.name
        calories = Self.format(meal.calories)
        protein = Self.format(meal.protein)
        carbohydrates = Self.format(meal.carbohydrates)
        fat = Self.format(meal.fat)
        fiber = meal.fiber.map(Self.format) ?? ""
        confidence = meal.confidence
        assumption = meal.assumption
        components = meal.components.map(EditableMealComponent.init)
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && Self.number(calories) >= 0
            && Self.number(protein) >= 0
            && components.allSatisfy { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            && components.allSatisfy(\.hasValidFiber)
            && hasValidFiber
    }

    func number(_ value: String) -> Double {
        Self.number(value)
    }

    var persistedComponents: [MealComponent] {
        components.compactMap(\.persisted)
    }

    var fiberValue: Double? {
        Self.optionalNumber(fiber)
    }

    mutating func recalculateFromComponents() {
        guard !components.isEmpty else {
            calories = "0"
            protein = "0"
            carbohydrates = "0"
            fat = "0"
            fiber = ""
            return
        }
        calories = Self.format(components.reduce(0) { $0 + Self.number($1.calories) })
        protein = Self.format(components.reduce(0) { $0 + Self.number($1.protein) })
        carbohydrates = Self.format(components.reduce(0) { $0 + Self.number($1.carbohydrates) })
        fat = Self.format(components.reduce(0) { $0 + Self.number($1.fat) })
        let componentFiber = components.compactMap { Self.optionalNumber($0.fiber) }
        fiber = componentFiber.count == components.count ? Self.format(componentFiber.reduce(0, +)) : ""
    }

    static func number(_ value: String) -> Double {
        Double(value.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    static func optionalNumber(_ value: String) -> Double? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return Double(trimmed.replacingOccurrences(of: ",", with: "."))
    }

    static func format(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }

    private var hasValidFiber: Bool {
        let trimmed = fiber.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || (Self.optionalNumber(trimmed) ?? -1) >= 0
    }
}

struct FiberSummary: Equatable {
    let value: Double
    let knownMeals: Int
    let totalMeals: Int

    var hasData: Bool { knownMeals > 0 }
    var isComplete: Bool { totalMeals > 0 && knownMeals == totalMeals }
}

enum CaltrackMath {
    static func orderedRange(_ first: Double, _ second: Double) -> ClosedRange<Double> {
        Swift.min(first, second)...Swift.max(first, second)
    }

    static func totals(for meals: [MealEntry]) -> (calories: Double, protein: Double) {
        meals.reduce((0, 0)) { ($0.0 + $1.calories, $0.1 + $1.protein) }
    }

    static func fiberSummary(for meals: [MealEntry]) -> FiberSummary {
        let known = meals.compactMap(\.fiber)
        return FiberSummary(value: known.reduce(0, +), knownMeals: known.count, totalMeals: meals.count)
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
