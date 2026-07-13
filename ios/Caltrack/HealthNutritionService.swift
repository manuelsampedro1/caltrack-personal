import Foundation
import HealthKit

struct HealthNutritionService {
    private let store: HKHealthStore
    private static let mealNameKey = "com.manuelsampedro.caltrack.mealName"

    init(store: HKHealthStore = HKHealthStore()) {
        self.store = store
    }

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAuthorization() async throws {
        guard isAvailable else { throw HealthNutritionError.unavailable }
        let types = try Self.shareTypes()
        try await store.requestAuthorization(toShare: types, read: [])
        guard try Self.coreShareTypes().allSatisfy({ store.authorizationStatus(for: $0) == .sharingAuthorized }) else {
            throw HealthNutritionError.permissionDenied
        }
    }

    func upsert(_ meal: MealEntry) async throws {
        guard isAvailable else { throw HealthNutritionError.unavailable }
        let types = try Self.shareTypes()
        if types.contains(where: { store.authorizationStatus(for: $0) == .notDetermined }) {
            try await requestAuthorization()
        }
        guard try Self.coreShareTypes().allSatisfy({ store.authorizationStatus(for: $0) == .sharingAuthorized }) else {
            throw HealthNutritionError.permissionDenied
        }
        try await delete(mealID: meal.id)
        let fiberType = HKQuantityType(.dietaryFiber)
        let correlation = try Self.makeCorrelation(
            for: meal,
            includeFiber: store.authorizationStatus(for: fiberType) == .sharingAuthorized
        )
        try await save(correlation)
    }

    func delete(mealID: UUID) async throws {
        guard isAvailable else { throw HealthNutritionError.unavailable }
        let type = try Self.correlationType()
        let predicate = HKQuery.predicateForObjects(withMetadataKey: HKMetadataKeyExternalUUID, allowedValues: [mealID.uuidString])
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            store.deleteObjects(of: type, predicate: predicate) { success, _, error in
                if let error { continuation.resume(throwing: error) }
                else if success { continuation.resume(returning: ()) }
                else { continuation.resume(throwing: HealthNutritionError.writeFailed) }
            }
        }
    }

    func syncAll(_ meals: [MealEntry]) async throws -> Int {
        for meal in meals.sorted(by: { $0.date < $1.date }) {
            try await upsert(meal)
        }
        return meals.count
    }

    static func makeCorrelation(for meal: MealEntry, includeFiber: Bool = true) throws -> HKCorrelation {
        let foodType = try correlationType()
        let energyType = HKQuantityType(.dietaryEnergyConsumed)
        let proteinType = HKQuantityType(.dietaryProtein)
        let carbohydrateType = HKQuantityType(.dietaryCarbohydrates)
        let fatType = HKQuantityType(.dietaryFatTotal)
        let fiberType = HKQuantityType(.dietaryFiber)
        let date = meal.date
        var objects: Set<HKSample> = [
            HKQuantitySample(type: energyType, quantity: HKQuantity(unit: .kilocalorie(), doubleValue: max(0, meal.calories)), start: date, end: date),
            HKQuantitySample(type: proteinType, quantity: HKQuantity(unit: .gram(), doubleValue: max(0, meal.protein)), start: date, end: date),
            HKQuantitySample(type: carbohydrateType, quantity: HKQuantity(unit: .gram(), doubleValue: max(0, meal.carbohydrates)), start: date, end: date),
            HKQuantitySample(type: fatType, quantity: HKQuantity(unit: .gram(), doubleValue: max(0, meal.fat)), start: date, end: date)
        ]
        if includeFiber, let fiber = meal.fiber {
            objects.insert(HKQuantitySample(type: fiberType, quantity: HKQuantity(unit: .gram(), doubleValue: max(0, fiber)), start: date, end: date))
        }
        return HKCorrelation(
            type: foodType,
            start: date,
            end: date,
            objects: objects,
            metadata: [
                HKMetadataKeyExternalUUID: meal.id.uuidString,
                HKMetadataKeyWasUserEntered: true,
                mealNameKey: meal.name
            ]
        )
    }

    private static func shareTypes() throws -> Set<HKSampleType> {
        try coreShareTypes().union([
            HKQuantityType(.dietaryFiber)
        ])
    }

    private static func coreShareTypes() throws -> Set<HKSampleType> {
        [
            try correlationType(),
            HKQuantityType(.dietaryEnergyConsumed),
            HKQuantityType(.dietaryProtein),
            HKQuantityType(.dietaryCarbohydrates),
            HKQuantityType(.dietaryFatTotal)
        ]
    }

    private static func correlationType() throws -> HKCorrelationType {
        guard let type = HKObjectType.correlationType(forIdentifier: .food) else {
            throw HealthNutritionError.typeUnavailable
        }
        return type
    }

    private func save(_ correlation: HKCorrelation) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            store.save(correlation) { success, error in
                if let error { continuation.resume(throwing: error) }
                else if success { continuation.resume(returning: ()) }
                else { continuation.resume(throwing: HealthNutritionError.writeFailed) }
            }
        }
    }
}

enum HealthNutritionError: LocalizedError {
    case unavailable
    case permissionDenied
    case typeUnavailable
    case writeFailed

    var errorDescription: String? {
        switch self {
        case .unavailable: "Apple Salud no está disponible en este dispositivo."
        case .permissionDenied: "Caltrack no tiene permiso para guardar nutrición en Salud."
        case .typeUnavailable: "El tipo de nutrición de Salud no está disponible."
        case .writeFailed: "Salud no confirmó el guardado de la comida."
        }
    }
}
