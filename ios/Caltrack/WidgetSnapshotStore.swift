import Foundation

struct WidgetSnapshot: Codable, Sendable, Hashable {
    let day: Date
    let generatedAt: Date
    let calories: Double
    let protein: Double
    let calorieMin: Double
    let calorieMax: Double
    let proteinMin: Double
    let mealCount: Int
    let nutritionComplete: Bool
    let planTitle: String

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.day == rhs.day
            && lhs.calories == rhs.calories
            && lhs.protein == rhs.protein
            && lhs.calorieMin == rhs.calorieMin
            && lhs.calorieMax == rhs.calorieMax
            && lhs.proteinMin == rhs.proteinMin
            && lhs.mealCount == rhs.mealCount
            && lhs.nutritionComplete == rhs.nutritionComplete
            && lhs.planTitle == rhs.planTitle
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(day)
        hasher.combine(calories)
        hasher.combine(protein)
        hasher.combine(calorieMin)
        hasher.combine(calorieMax)
        hasher.combine(proteinMin)
        hasher.combine(mealCount)
        hasher.combine(nutritionComplete)
        hasher.combine(planTitle)
    }

    func forDay(containing date: Date, calendar: Calendar = .current) -> WidgetSnapshot {
        guard !calendar.isDate(day, inSameDayAs: date) else { return self }
        return WidgetSnapshot(
            day: calendar.startOfDay(for: date),
            generatedAt: date,
            calories: 0,
            protein: 0,
            calorieMin: calorieMin,
            calorieMax: calorieMax,
            proteinMin: proteinMin,
            mealCount: 0,
            nutritionComplete: false,
            planTitle: "Empieza el día"
        )
    }

    static func empty(date: Date = .now, calendar: Calendar = .current) -> WidgetSnapshot {
        WidgetSnapshot(
            day: calendar.startOfDay(for: date),
            generatedAt: date,
            calories: 0,
            protein: 0,
            calorieMin: 1_800,
            calorieMax: 2_000,
            proteinMin: 160,
            mealCount: 0,
            nutritionComplete: false,
            planTitle: "Abre Caltrack"
        )
    }

    static var preview: WidgetSnapshot {
        WidgetSnapshot(
            day: Calendar.current.startOfDay(for: .now),
            generatedAt: .now,
            calories: 1_760,
            protein: 159,
            calorieMin: 1_800,
            calorieMax: 2_000,
            proteinMin: 160,
            mealCount: 3,
            nutritionComplete: false,
            planTitle: "Mantén el rango"
        )
    }
}

enum WidgetSnapshotStore {
    static let appGroupIdentifier = "group.com.manuelsampedro.caltrack"
    private static let snapshotKey = "caltrack.widget.snapshot.v1"

    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }

    @discardableResult
    static func save(_ snapshot: WidgetSnapshot, defaults: UserDefaults? = nil) -> Bool {
        let defaults = defaults ?? sharedDefaults
        if let current = decode(defaults.data(forKey: snapshotKey)), current == snapshot {
            return false
        }
        guard let data = try? JSONEncoder().encode(snapshot) else { return false }
        defaults.set(data, forKey: snapshotKey)
        return true
    }

    static func load(defaults: UserDefaults? = nil, now: Date = .now, calendar: Calendar = .current) -> WidgetSnapshot {
        let defaults = defaults ?? sharedDefaults
        return (decode(defaults.data(forKey: snapshotKey)) ?? .empty(date: now, calendar: calendar))
            .forDay(containing: now, calendar: calendar)
    }

    private static func decode(_ data: Data?) -> WidgetSnapshot? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }
}
