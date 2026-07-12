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
        let values = try await (weight, bodyFat, waist, recentWorkouts)
        let dates = [values.0?.date, values.1?.date, values.2?.date].compactMap { $0 }
        snapshot = HealthSnapshot(
            date: dates.max() ?? .now,
            weight: values.0?.value,
            bodyFat: values.1?.value,
            waist: values.2?.value
        )
        workouts = values.3
        state = .ready
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
}
