import Foundation

enum RecoverySleepStage: String, Sendable {
    case core
    case deep
    case rem
    case unspecified
}

struct RecoverySleepSegment: Equatable, Sendable {
    let startDate: Date
    let endDate: Date
    let stage: RecoverySleepStage
    let source: String
}

struct RecoverySleepSummary: Equatable, Sendable {
    let date: Date
    let sleepMinutes: Double
    let coreMinutes: Double
    let deepMinutes: Double
    let remMinutes: Double
    let source: String
}

enum RecoveryMath {
    static func sleepDays(
        from segments: [RecoverySleepSegment],
        calendar: Calendar = .current
    ) -> [RecoverySleepSummary] {
        let valid = segments.filter { $0.endDate > $0.startDate }
        let grouped = Dictionary(grouping: valid) { segment in
            WakeSourceKey(
                day: wakeDay(for: segment, calendar: calendar),
                source: segment.source
            )
        }
        let byDay = Dictionary(grouping: grouped.keys, by: \.day)

        return byDay.keys.sorted().compactMap { day in
            let candidates = byDay[day, default: []].compactMap { key -> RecoverySleepSummary? in
                guard let sourceSegments = grouped[key] else { return nil }
                let total = mergedMinutes(sourceSegments.map { ($0.startDate, $0.endDate) })
                guard total > 0 else { return nil }
                return RecoverySleepSummary(
                    date: day,
                    sleepMinutes: total,
                    coreMinutes: stageMinutes(.core, in: sourceSegments),
                    deepMinutes: stageMinutes(.deep, in: sourceSegments),
                    remMinutes: stageMinutes(.rem, in: sourceSegments),
                    source: key.source
                )
            }
            return candidates.max {
                if $0.sleepMinutes == $1.sleepMinutes { return $0.source > $1.source }
                return $0.sleepMinutes < $1.sleepMinutes
            }
        }
    }

    static func personalComparison(latest: Double, history: [Double], unit: String) -> String? {
        let previous = history.filter { $0 > 0 }
        guard previous.count >= 3 else { return nil }
        let average = previous.reduce(0, +) / Double(previous.count)
        let delta = latest - average
        guard abs(delta) >= 0.05 else { return "Muy cerca de tu media reciente." }
        let sign = delta > 0 ? "+" : ""
        return "\(sign)\(delta.formatted(.number.precision(.fractionLength(0...1)))) \(unit) frente a tu media reciente."
    }

    private static func stageMinutes(_ stage: RecoverySleepStage, in segments: [RecoverySleepSegment]) -> Double {
        mergedMinutes(
            segments
                .filter { $0.stage == stage }
                .map { ($0.startDate, $0.endDate) }
        )
    }

    private static func mergedMinutes(_ intervals: [(Date, Date)]) -> Double {
        let sorted = intervals.filter { $0.1 > $0.0 }.sorted { $0.0 < $1.0 }
        guard var current = sorted.first else { return 0 }
        var duration: TimeInterval = 0
        for interval in sorted.dropFirst() {
            if interval.0 <= current.1 {
                current.1 = max(current.1, interval.1)
            } else {
                duration += current.1.timeIntervalSince(current.0)
                current = interval
            }
        }
        duration += current.1.timeIntervalSince(current.0)
        return duration / 60
    }

    private static func wakeDay(for segment: RecoverySleepSegment, calendar: Calendar) -> Date {
        let midpoint = segment.startDate.addingTimeInterval(segment.endDate.timeIntervalSince(segment.startDate) / 2)
        let day = calendar.startOfDay(for: midpoint)
        guard calendar.component(.hour, from: midpoint) >= 18 else { return day }
        return calendar.date(byAdding: .day, value: 1, to: day) ?? day
    }

    private struct WakeSourceKey: Hashable {
        let day: Date
        let source: String
    }
}
