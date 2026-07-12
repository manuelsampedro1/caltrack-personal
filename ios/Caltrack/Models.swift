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

private extension ClosedRange where Bound == Double {
    func clamped(_ value: Double) -> Double {
        Swift.min(Swift.max(value, lowerBound), upperBound)
    }
}
