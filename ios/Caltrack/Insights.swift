import Foundation

struct NutritionDay: Identifiable, Equatable {
    let date: Date
    let calories: Double
    let protein: Double
    let carbohydrates: Double
    let fat: Double

    var id: Date { date }
}

struct InsightReport: Equatable {
    let score: Int
    let title: String
    let summary: String
    let observations: [String]
}

enum InsightEngine {
    static func nutritionDays(meals: [MealEntry], count: Int, now: Date = .now, calendar: Calendar = .current) -> [NutritionDay] {
        let today = calendar.startOfDay(for: now)
        return (0..<count).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let entries = meals.filter { calendar.isDate($0.date, inSameDayAs: date) }
            return NutritionDay(
                date: date,
                calories: entries.reduce(0) { $0 + $1.calories },
                protein: entries.reduce(0) { $0 + $1.protein },
                carbohydrates: entries.reduce(0) { $0 + $1.carbohydrates },
                fat: entries.reduce(0) { $0 + $1.fat }
            )
        }
    }

    static func report(
        meals: [MealEntry],
        measurements: [BodyMeasurement],
        workouts: [WorkoutEntry],
        calorieRange: ClosedRange<Double>,
        proteinRange: ClosedRange<Double>,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> InsightReport {
        let days = nutritionDays(meals: meals, count: 14, now: now, calendar: calendar)
        let logged = days.filter { $0.calories > 0 || $0.protein > 0 }
        guard !logged.isEmpty else {
            return InsightReport(
                score: 0,
                title: "Necesito algunos días",
                summary: "Registra comidas para detectar tendencias reales, no impresiones de un solo día.",
                observations: ["Empieza con una foto o una entrada manual.", "Tres días completos ya permiten una primera lectura útil."]
            )
        }

        let averageCalories = logged.reduce(0) { $0 + $1.calories } / Double(logged.count)
        let averageProtein = logged.reduce(0) { $0 + $1.protein } / Double(logged.count)
        let adherence = logged.reduce(0) {
            $0 + CaltrackMath.adherence(calories: $1.calories, protein: $1.protein, calorieRange: calorieRange, proteinRange: proteinRange)
        } / logged.count
        let proteinThreshold = proteinRange.lowerBound * 0.95
        let proteinDays = logged.filter { $0.protein >= proteinThreshold }.count
        let recentWorkouts = workouts.filter {
            $0.startDate >= calendar.date(byAdding: .day, value: -7, to: now) ?? .distantPast
        }

        var observations = [String]()
        if averageCalories < calorieRange.lowerBound {
            observations.append("Promedias \(Int(averageCalories)) kcal en los días registrados, por debajo de tu rango.")
        } else if averageCalories > calorieRange.upperBound {
            observations.append("Promedias \(Int(averageCalories)) kcal, por encima de tu máximo configurado.")
        } else {
            observations.append("Tu media de \(Int(averageCalories)) kcal está dentro del rango configurado.")
        }
        observations.append("Cubres al menos el 95% del objetivo de proteína en \(proteinDays) de \(logged.count) días registrados.")

        let weightedMeasurements = measurements
            .filter { $0.weight != nil }
            .sorted { $0.date < $1.date }
        if let first = weightedMeasurements.first?.weight, let last = weightedMeasurements.last?.weight, weightedMeasurements.count > 1 {
            let change = last - first
            let direction = abs(change) < 0.2 ? "estable" : change < 0 ? "bajando" : "subiendo"
            observations.append("El peso está \(direction), con un cambio registrado de \(abs(change).formatted(.number.precision(.fractionLength(1)))) kg.")
        }
        observations.append("Has registrado \(recentWorkouts.count) entrenamientos en los últimos 7 días.")

        let completeness = min(100, Int(Double(logged.count) / 7 * 100))
        let score = min(100, max(0, Int(Double(adherence) * 0.8 + Double(completeness) * 0.2)))
        let title = score >= 85 ? "Vas muy consistente" : score >= 65 ? "Buena base, hay margen" : "Hay una palanca clara"
        let summary = "Lectura basada en \(logged.count) días con comida, una media de \(Int(averageProtein)) g de proteína y \(recentWorkouts.count) entrenamientos recientes."
        return InsightReport(score: score, title: title, summary: summary, observations: observations)
    }
}
