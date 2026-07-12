import Foundation
import HealthKit
import Observation

struct HealthSnapshot: Equatable {
    let date: Date
    let weight: Double?
    let bodyFat: Double?
    let waist: Double?
}

struct HealthWorkoutSnapshot: Equatable {
    let externalID: String
    let startDate: Date
    let endDate: Date
    let title: String
    let activityType: String
    let durationMinutes: Double
    let calories: Double?
    let distanceKm: Double?
    let source: String
    let sourceBundle: String
}

struct DailyActivitySnapshot: Equatable {
    let externalID: String
    let date: Date
    let activeEnergy: Double
    let restingEnergy: Double
    let steps: Double
}

struct RecoverySnapshot: Equatable {
    let externalID: String
    let date: Date
    let sleepMinutes: Double
    let coreMinutes: Double
    let deepMinutes: Double
    let remMinutes: Double
    let restingHeartRate: Double?
    let hrvSDNN: Double?
    let source: String
}

private struct DatedHealthQuantity {
    let date: Date
    let value: Double
}

private struct BodyDayAccumulator {
    var date: Date
    var weight: Double?
    var bodyFat: Double?
    var waist: Double?
}

@MainActor
@Observable
final class HealthKitService {
    enum State: Equatable {
        case idle
        case loading
        case ready
        case unavailable
        case failed(String)

        var isFailure: Bool {
            switch self {
            case .unavailable, .failed: true
            default: false
            }
        }
    }

    private let store = HKHealthStore()
    var state: State = .idle
    var snapshot: HealthSnapshot?
    var measurementHistory: [HealthSnapshot] = []
    var activityHistory: [DailyActivitySnapshot] = []
    var recoveryHistory: [RecoverySnapshot] = []
    var workouts: [HealthWorkoutSnapshot] = []

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func connectAndRead() async {
        guard isAvailable else {
            state = .unavailable
            return
        }
        state = .loading
        do {
            let types: Set<HKObjectType> = [
                HKQuantityType(.bodyMass),
                HKQuantityType(.bodyFatPercentage),
                HKQuantityType(.waistCircumference),
                HKObjectType.workoutType(),
                HKQuantityType(.activeEnergyBurned),
                HKQuantityType(.basalEnergyBurned),
                HKQuantityType(.stepCount),
                HKCategoryType(.sleepAnalysis),
                HKQuantityType(.restingHeartRate),
                HKQuantityType(.heartRateVariabilitySDNN),
                HKQuantityType(.distanceWalkingRunning),
                HKQuantityType(.distanceCycling),
                HKQuantityType(.distanceSwimming)
            ]
            try await store.requestAuthorization(toShare: [], read: types)
            try await refresh()
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func refresh() async throws {
        guard isAvailable else {
            state = .unavailable
            return
        }
        state = .loading
        async let weight = latest(.bodyMass, unit: .gramUnit(with: .kilo), multiplier: 1)
        async let bodyFat = latest(.bodyFatPercentage, unit: .percent(), multiplier: 100)
        async let waist = latest(.waistCircumference, unit: .meterUnit(with: .centi), multiplier: 1)
        async let recentWorkouts = loadRecentWorkouts()
        async let recentMeasurements = loadMeasurementHistory()
        async let recentActivity = loadActivityHistory()
        async let recentRecovery = loadRecoveryHistory()
        let values = try await (weight, bodyFat, waist, recentWorkouts, recentMeasurements, recentActivity, recentRecovery)
        let dates = [values.0?.date, values.1?.date, values.2?.date].compactMap { $0 }
        snapshot = HealthSnapshot(
            date: dates.max() ?? .now,
            weight: values.0?.value,
            bodyFat: values.1?.value,
            waist: values.2?.value
        )
        workouts = values.3
        measurementHistory = values.4
        activityHistory = values.5
        recoveryHistory = values.6
        state = .ready
    }

    private func loadRecoveryHistory() async throws -> [RecoverySnapshot] {
        async let sleepSegments = loadSleepSegments()
        async let restingHeartRate = dailyAverages(
            .restingHeartRate,
            unit: HKUnit.count().unitDivided(by: .minute()),
            days: 30
        )
        async let hrv = dailyAverages(
            .heartRateVariabilitySDNN,
            unit: .secondUnit(with: .milli),
            days: 30
        )
        let values = try await (sleepSegments, restingHeartRate, hrv)
        let sleepDays = RecoveryMath.sleepDays(from: values.0)
        let sleepByDay = Dictionary(uniqueKeysWithValues: sleepDays.map { (Calendar.current.startOfDay(for: $0.date), $0) })
        let dates = Set(sleepByDay.keys).union(values.1.keys).union(values.2.keys)

        return dates.sorted(by: >).map { date in
            let sleep = sleepByDay[date]
            return RecoverySnapshot(
                externalID: "health-recovery:\(Int(date.timeIntervalSince1970))",
                date: date,
                sleepMinutes: sleep?.sleepMinutes ?? 0,
                coreMinutes: sleep?.coreMinutes ?? 0,
                deepMinutes: sleep?.deepMinutes ?? 0,
                remMinutes: sleep?.remMinutes ?? 0,
                restingHeartRate: values.1[date],
                hrvSDNN: values.2[date],
                source: sleep?.source ?? "HealthKit"
            )
        }
    }

    private func loadSleepSegments() async throws -> [RecoverySleepSegment] {
        let type = HKCategoryType(.sleepAnalysis)
        let start = Calendar.current.date(byAdding: .day, value: -31, to: .now)
        let predicate = start.map { HKQuery.predicateForSamples(withStart: $0, end: nil, options: .strictEndDate) }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let samples: [HKCategorySample] = try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 1_000, sortDescriptors: [sort]) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: samples?.compactMap { $0 as? HKCategorySample } ?? [])
            }
            store.execute(query)
        }
        return samples.compactMap { sample in
            guard let value = HKCategoryValueSleepAnalysis(rawValue: sample.value),
                  HKCategoryValueSleepAnalysis.allAsleepValues.contains(value) else { return nil }
            let stage: RecoverySleepStage = switch value {
            case .asleepCore: .core
            case .asleepDeep: .deep
            case .asleepREM: .rem
            default: .unspecified
            }
            return RecoverySleepSegment(
                startDate: sample.startDate,
                endDate: sample.endDate,
                stage: stage,
                source: sample.sourceRevision.source.name
            )
        }
    }

    private func loadActivityHistory() async throws -> [DailyActivitySnapshot] {
        async let active = dailySums(.activeEnergyBurned, unit: .kilocalorie(), days: 30)
        async let resting = dailySums(.basalEnergyBurned, unit: .kilocalorie(), days: 30)
        async let steps = dailySums(.stepCount, unit: .count(), days: 30)
        let values = try await (active, resting, steps)
        let dates = Set(values.0.keys).union(values.1.keys).union(values.2.keys)
        return dates.sorted(by: >).map { date in
            DailyActivitySnapshot(
                externalID: "health-activity:\(Int(date.timeIntervalSince1970))",
                date: date,
                activeEnergy: values.0[date] ?? 0,
                restingEnergy: values.1[date] ?? 0,
                steps: values.2[date] ?? 0
            )
        }
    }

    private func loadMeasurementHistory() async throws -> [HealthSnapshot] {
        async let weights = recent(.bodyMass, unit: .gramUnit(with: .kilo), multiplier: 1)
        async let bodyFat = recent(.bodyFatPercentage, unit: .percent(), multiplier: 100)
        async let waists = recent(.waistCircumference, unit: .meterUnit(with: .centi), multiplier: 1)
        let values = try await (weights, bodyFat, waists)
        let calendar = Calendar.current
        var days = [Date: BodyDayAccumulator]()

        func insert(_ item: DatedHealthQuantity, keyPath: WritableKeyPath<BodyDayAccumulator, Double?>) {
            let day = calendar.startOfDay(for: item.date)
            var value = days[day] ?? BodyDayAccumulator(date: item.date)
            value.date = max(value.date, item.date)
            if value[keyPath: keyPath] == nil { value[keyPath: keyPath] = item.value }
            days[day] = value
        }

        values.0.forEach { insert($0, keyPath: \.weight) }
        values.1.forEach { insert($0, keyPath: \.bodyFat) }
        values.2.forEach { insert($0, keyPath: \.waist) }
        return days.values
            .sorted { $0.date > $1.date }
            .map { HealthSnapshot(date: $0.date, weight: $0.weight, bodyFat: $0.bodyFat, waist: $0.waist) }
    }

    private func loadRecentWorkouts() async throws -> [HealthWorkoutSnapshot] {
        let workoutType = HKObjectType.workoutType()
        let start = Calendar.current.date(byAdding: .day, value: -30, to: .now)
        let predicate = start.map { HKQuery.predicateForSamples(withStart: $0, end: nil, options: .strictStartDate) }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let samples: [HKWorkout] = try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: 100, sortDescriptors: [sort]) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: samples?.compactMap { $0 as? HKWorkout } ?? [])
            }
            store.execute(query)
        }
        let energyType = HKQuantityType(.activeEnergyBurned)
        let distanceTypes = [HKQuantityType(.distanceWalkingRunning), HKQuantityType(.distanceCycling), HKQuantityType(.distanceSwimming)]
        return samples.map { workout in
            let calories = workout.statistics(for: energyType)?.sumQuantity()?.doubleValue(for: .kilocalorie())
            let distanceMeters = distanceTypes.compactMap { workout.statistics(for: $0)?.sumQuantity()?.doubleValue(for: .meter()) }.max()
            let type = Self.activityName(workout.workoutActivityType)
            let source = workout.sourceRevision.source
            return HealthWorkoutSnapshot(
                externalID: "health:\(workout.uuid.uuidString)",
                startDate: workout.startDate,
                endDate: workout.endDate,
                title: type,
                activityType: type,
                durationMinutes: workout.duration / 60,
                calories: calories,
                distanceKm: distanceMeters.map { $0 / 1_000 },
                source: source.name,
                sourceBundle: source.bundleIdentifier
            )
        }
    }

    static func activityName(_ type: HKWorkoutActivityType) -> String {
        switch type {
        case .traditionalStrengthTraining: "Fuerza"
        case .functionalStrengthTraining: "Fuerza funcional"
        case .running: "Running"
        case .cycling: "Ciclismo"
        case .walking: "Caminar"
        case .hiking: "Senderismo"
        case .swimming: "Natación"
        case .highIntensityIntervalTraining: "HIIT"
        case .coreTraining: "Core"
        case .flexibility: "Movilidad"
        case .yoga: "Yoga"
        case .rowing: "Remo"
        case .elliptical: "Elíptica"
        case .stairClimbing: "Escaleras"
        default: "Entrenamiento"
        }
    }

    private func latest(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit, multiplier: Double) async throws -> (value: Double, date: Date)? {
        let type = HKQuantityType(identifier)
        return try await withCheckedThrowingContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: (sample.quantity.doubleValue(for: unit) * multiplier, sample.endDate))
            }
            store.execute(query)
        }
    }

    private func recent(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit, multiplier: Double) async throws -> [DatedHealthQuantity] {
        let type = HKQuantityType(identifier)
        let start = Calendar.current.date(byAdding: .day, value: -180, to: .now)
        let predicate = start.map { HKQuery.predicateForSamples(withStart: $0, end: nil, options: .strictStartDate) }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 200, sortDescriptors: [sort]) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let values = samples?.compactMap { sample -> DatedHealthQuantity? in
                    guard let sample = sample as? HKQuantitySample else { return nil }
                    return DatedHealthQuantity(date: sample.endDate, value: sample.quantity.doubleValue(for: unit) * multiplier)
                } ?? []
                continuation.resume(returning: values)
            }
            store.execute(query)
        }
    }

    private func dailySums(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit, days: Int) async throws -> [Date: Double] {
        let type = HKQuantityType(identifier)
        let calendar = Calendar.current
        let end = Date.now
        let start = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -(days - 1), to: end) ?? end)
        var interval = DateComponents()
        interval.day = 1
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: HKQuery.predicateForSamples(withStart: start, end: end),
                options: .cumulativeSum,
                anchorDate: start,
                intervalComponents: interval
            )
            query.initialResultsHandler = { _, collection, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                var result = [Date: Double]()
                collection?.enumerateStatistics(from: start, to: end) { statistics, _ in
                    if let sum = statistics.sumQuantity() {
                        result[calendar.startOfDay(for: statistics.startDate)] = sum.doubleValue(for: unit)
                    }
                }
                continuation.resume(returning: result)
            }
            store.execute(query)
        }
    }

    private func dailyAverages(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit, days: Int) async throws -> [Date: Double] {
        let type = HKQuantityType(identifier)
        let calendar = Calendar.current
        let end = Date.now
        let start = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -(days - 1), to: end) ?? end)
        var interval = DateComponents()
        interval.day = 1
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: HKQuery.predicateForSamples(withStart: start, end: end),
                options: .discreteAverage,
                anchorDate: start,
                intervalComponents: interval
            )
            query.initialResultsHandler = { _, collection, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                var result = [Date: Double]()
                collection?.enumerateStatistics(from: start, to: end) { statistics, _ in
                    if let average = statistics.averageQuantity()?.doubleValue(for: unit), average > 0 {
                        result[calendar.startOfDay(for: statistics.startDate)] = average
                    }
                }
                continuation.resume(returning: result)
            }
            store.execute(query)
        }
    }
}
