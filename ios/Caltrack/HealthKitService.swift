import Foundation
import HealthKit
import Observation

struct HealthSnapshot: Equatable {
    let date: Date
    let weight: Double?
    let bodyFat: Double?
    let waist: Double?
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
    }

    private let store = HKHealthStore()
    var state: State = .idle
    var snapshot: HealthSnapshot?

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func connectAndRead() async {
        guard isAvailable else {
            state = .unavailable
            return
        }
        state = .loading
        do {
            let types = Set([HKQuantityType(.bodyMass), HKQuantityType(.bodyFatPercentage), HKQuantityType(.waistCircumference)])
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
        let values = try await (weight, bodyFat, waist)
        let dates = [values.0?.date, values.1?.date, values.2?.date].compactMap { $0 }
        snapshot = HealthSnapshot(
            date: dates.max() ?? .now,
            weight: values.0?.value,
            bodyFat: values.1?.value,
            waist: values.2?.value
        )
        state = .ready
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
