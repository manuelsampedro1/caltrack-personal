import Foundation

enum PlanGoalMode: String, CaseIterable, Sendable {
    case notSet
    case lose
    case maintain
    case gain

    var title: String {
        switch self {
        case .notSet: "Sin configurar"
        case .lose: "Perder peso"
        case .maintain: "Mantener peso"
        case .gain: "Ganar peso"
        }
    }

    func signedRate(_ magnitude: Double) -> Double {
        switch self {
        case .notSet, .maintain: 0
        case .lose: -abs(magnitude)
        case .gain: abs(magnitude)
        }
    }
}

struct AdaptivePlanDay: Equatable, Sendable {
    let date: Date
    let calories: Double
    let isComplete: Bool
}

struct AdaptiveWeightPoint: Equatable, Sendable {
    let date: Date
    let weight: Double
}

enum AdaptivePlanState: Equatable, Sendable {
    case needsConfiguration
    case collecting
    case followCurrentPlan
    case stable
    case recentlyAdjusted
    case adjustment
    case safetyLimit
}

struct AdaptivePlanReview: Equatable, Sendable {
    let state: AdaptivePlanState
    let title: String
    let message: String
    let completeDays: Int
    let weightDays: Int
    let rangeAdherence: Double?
    let actualWeeklyRate: Double?
    let targetWeeklyRate: Double
    let calorieDelta: Double?
    let proposedRange: ClosedRange<Double>?
}

enum AdaptivePlanEngine {
    static let windowDays = 14
    static let minimumCompleteDays = 7
    static let minimumWeightDays = 3
    static let minimumWeightSpanDays = 7.0
    static let minimumAdherence = 0.7
    static let rateTolerance = 0.15
    static let adjustmentStep = 100.0
    static let calorieBounds = 1_000.0...6_000.0

    static func review(
        days: [AdaptivePlanDay],
        weights: [AdaptiveWeightPoint],
        mode: PlanGoalMode,
        weeklyRate: Double,
        calorieRange: ClosedRange<Double>,
        lastAdjustmentDate: Date? = nil,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> AdaptivePlanReview {
        let target = mode.signedRate(weeklyRate)
        guard mode != .notSet else {
            return result(
                state: .needsConfiguration,
                title: "Define tu rumbo",
                message: "Elige si quieres perder, mantener o ganar peso. Tus rangos actuales no cambiarán hasta que aceptes una propuesta.",
                target: target
            )
        }

        let startOfToday = calendar.startOfDay(for: now)
        let start = calendar.date(byAdding: .day, value: -(windowDays - 1), to: startOfToday) ?? .distantPast
        let recentDays = uniqueDays(days, since: start, calendar: calendar).filter(\.isComplete)
        let recentWeights = uniqueWeights(weights, since: start, calendar: calendar)
        let slope = weeklySlope(recentWeights)
        let weightSpan = recentWeights.last.map { last in
            recentWeights.first.map { last.date.timeIntervalSince($0.date) / 86_400 } ?? 0
        } ?? 0

        guard recentDays.count >= minimumCompleteDays,
              recentWeights.count >= minimumWeightDays,
              weightSpan >= minimumWeightSpanDays,
              let slope else {
            let missingDays = max(0, minimumCompleteDays - recentDays.count)
            let missingWeights = max(0, minimumWeightDays - recentWeights.count)
            var needs: [String] = []
            if missingDays > 0 { needs.append("\(missingDays) días completos") }
            if missingWeights > 0 { needs.append("\(missingWeights) pesos") }
            if recentWeights.count >= minimumWeightDays && weightSpan < minimumWeightSpanDays {
                needs.append("pesos separados por al menos 7 días")
            }
            let detail = needs.isEmpty ? "más días entre tus mediciones" : needs.joined(separator: " y ")
            return result(
                state: .collecting,
                title: "Aprendiendo de tus datos",
                message: "Faltan \(detail). Hasta entonces mantén el rango actual.",
                completeDays: recentDays.count,
                weightDays: recentWeights.count,
                actual: slope,
                target: target
            )
        }

        if let lastAdjustmentDate,
           now.timeIntervalSince(lastAdjustmentDate) < 6 * 86_400 {
            return result(
                state: .recentlyAdjusted,
                title: "Deja actuar el último cambio",
                message: "La revisión ya se aplicó esta semana. Reúne nuevos cierres y pesos antes de volver a ajustar.",
                completeDays: recentDays.count,
                weightDays: recentWeights.count,
                actual: slope,
                target: target
            )
        }

        let adherence = Double(recentDays.filter { calorieRange.contains($0.calories) }.count) / Double(recentDays.count)
        guard adherence >= minimumAdherence else {
            return result(
                state: .followCurrentPlan,
                title: "Prueba primero el plan actual",
                message: "Estuviste dentro del rango el \(Int((adherence * 100).rounded()))% de los días completos. Todavía no hay base para cambiar calorías.",
                completeDays: recentDays.count,
                weightDays: recentWeights.count,
                adherence: adherence,
                actual: slope,
                target: target
            )
        }

        let difference = slope - target
        guard abs(difference) > rateTolerance else {
            return result(
                state: .stable,
                title: "Mantén el rango",
                message: "Tu tendencia está cerca del ritmo elegido. No hace falta corregir calorías esta semana.",
                completeDays: recentDays.count,
                weightDays: recentWeights.count,
                adherence: adherence,
                actual: slope,
                target: target
            )
        }

        let delta = difference > 0 ? -adjustmentStep : adjustmentStep
        let proposed = (calorieRange.lowerBound + delta)...(calorieRange.upperBound + delta)
        guard calorieBounds.contains(proposed.lowerBound), calorieBounds.contains(proposed.upperBound) else {
            return result(
                state: .safetyLimit,
                title: "Revisión manual necesaria",
                message: "El siguiente paso saldría de los límites de seguridad de Caltrack. No se aplicará automáticamente.",
                completeDays: recentDays.count,
                weightDays: recentWeights.count,
                adherence: adherence,
                actual: slope,
                target: target
            )
        }

        let direction = delta > 0 ? "subir" : "bajar"
        return result(
            state: .adjustment,
            title: "Propuesta para esta semana",
            message: "Tu tendencia se aleja del ritmo elegido pese a seguir el plan. Puedes \(direction) el rango 100 kcal y revisar de nuevo en una semana.",
            completeDays: recentDays.count,
            weightDays: recentWeights.count,
            adherence: adherence,
            actual: slope,
            target: target,
            delta: delta,
            proposed: proposed
        )
    }

    static func weeklySlope(_ weights: [AdaptiveWeightPoint]) -> Double? {
        guard weights.count >= 2 else { return nil }
        let sorted = weights.sorted { $0.date < $1.date }
        guard let first = sorted.first else { return nil }
        let samples = sorted.map { point in
            (x: point.date.timeIntervalSince(first.date) / 86_400, y: point.weight)
        }
        let meanX = samples.reduce(0) { $0 + $1.x } / Double(samples.count)
        let meanY = samples.reduce(0) { $0 + $1.y } / Double(samples.count)
        let denominator = samples.reduce(0) { $0 + pow($1.x - meanX, 2) }
        guard denominator > 0 else { return nil }
        let numerator = samples.reduce(0) { $0 + (($1.x - meanX) * ($1.y - meanY)) }
        return numerator / denominator * 7
    }

    private static func uniqueDays(_ days: [AdaptivePlanDay], since start: Date, calendar: Calendar) -> [AdaptivePlanDay] {
        Dictionary(grouping: days.filter { $0.date >= start }) { calendar.startOfDay(for: $0.date) }
            .compactMap { date, entries in
                let complete = entries.contains(where: \.isComplete)
                let calories = entries.max(by: { $0.calories < $1.calories })?.calories ?? 0
                return AdaptivePlanDay(date: date, calories: calories, isComplete: complete)
            }
            .sorted { $0.date < $1.date }
    }

    private static func uniqueWeights(_ weights: [AdaptiveWeightPoint], since start: Date, calendar: Calendar) -> [AdaptiveWeightPoint] {
        Dictionary(grouping: weights.filter { $0.date >= start && $0.weight > 0 }) { calendar.startOfDay(for: $0.date) }
            .map { date, entries in
                AdaptiveWeightPoint(date: date, weight: entries.reduce(0) { $0 + $1.weight } / Double(entries.count))
            }
            .sorted { $0.date < $1.date }
    }

    private static func result(
        state: AdaptivePlanState,
        title: String,
        message: String,
        completeDays: Int = 0,
        weightDays: Int = 0,
        adherence: Double? = nil,
        actual: Double? = nil,
        target: Double,
        delta: Double? = nil,
        proposed: ClosedRange<Double>? = nil
    ) -> AdaptivePlanReview {
        AdaptivePlanReview(
            state: state,
            title: title,
            message: message,
            completeDays: completeDays,
            weightDays: weightDays,
            rangeAdherence: adherence,
            actualWeeklyRate: actual,
            targetWeeklyRate: target,
            calorieDelta: delta,
            proposedRange: proposed
        )
    }
}
