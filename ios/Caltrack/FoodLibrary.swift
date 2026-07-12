import Foundation

struct FrequentMeal: Identifiable, Equatable {
    let key: String
    let name: String
    let calories: Double
    let protein: Double
    let carbohydrates: Double
    let fat: Double
    let components: [MealComponent]
    let count: Int
    let lastUsed: Date

    var id: String { key }
}

enum FoodLibrary {
    static func frequentMeals(meals: [MealEntry], now: Date = .now, limit: Int = 6, calendar: Calendar = .current) -> [FrequentMeal] {
        let cutoff = calendar.date(byAdding: .day, value: -90, to: now) ?? .distantPast
        let recent = meals.filter { $0.date >= cutoff }
        let groups = Dictionary(grouping: recent) { normalizedName($0.name) }
        return groups.compactMap { key, entries -> FrequentMeal? in
            guard !key.isEmpty, let latest = entries.max(by: { $0.date < $1.date }) else { return nil }
            return FrequentMeal(
                key: key,
                name: latest.name,
                calories: latest.calories,
                protein: latest.protein,
                carbohydrates: latest.carbohydrates,
                fat: latest.fat,
                components: latest.components,
                count: entries.count,
                lastUsed: latest.date
            )
        }
        .sorted {
            if $0.count == $1.count { return $0.lastUsed > $1.lastUsed }
            return $0.count > $1.count
        }
        .prefix(limit)
        .map { $0 }
    }

    static func normalizedName(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "es_ES"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
            .lowercased()
    }
}
