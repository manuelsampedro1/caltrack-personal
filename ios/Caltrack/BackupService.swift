import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct CaltrackBackup: Codable, Sendable {
    struct Meal: Codable, Sendable {
        let id: UUID
        let date: Date
        let name: String
        let calories: Double
        let protein: Double
        let carbohydrates: Double
        let fat: Double
        let fiber: Double?
        let photoData: Data?
        let components: [MealComponent]?
        let source: String
        let confidence: Double
        let assumption: String

        init(
            id: UUID,
            date: Date,
            name: String,
            calories: Double,
            protein: Double,
            carbohydrates: Double,
            fat: Double,
            fiber: Double? = nil,
            photoData: Data?,
            components: [MealComponent]? = nil,
            source: String,
            confidence: Double,
            assumption: String
        ) {
            self.id = id
            self.date = date
            self.name = name
            self.calories = calories
            self.protein = protein
            self.carbohydrates = carbohydrates
            self.fat = fat
            self.fiber = fiber
            self.photoData = photoData
            self.components = components
            self.source = source
            self.confidence = confidence
            self.assumption = assumption
        }
    }

    struct Body: Codable, Sendable {
        let id: UUID
        let date: Date
        let weight: Double?
        let bodyFat: Double?
        let waist: Double?
        let photoData: Data?
        let source: String

        init(id: UUID, date: Date, weight: Double?, bodyFat: Double?, waist: Double?, photoData: Data? = nil, source: String) {
            self.id = id
            self.date = date
            self.weight = weight
            self.bodyFat = bodyFat
            self.waist = waist
            self.photoData = photoData
            self.source = source
        }

        private enum CodingKeys: String, CodingKey {
            case id, date, weight, bodyFat, waist, photoData, source
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(UUID.self, forKey: .id)
            date = try container.decode(Date.self, forKey: .date)
            weight = try container.decodeIfPresent(Double.self, forKey: .weight)
            bodyFat = try container.decodeIfPresent(Double.self, forKey: .bodyFat)
            waist = try container.decodeIfPresent(Double.self, forKey: .waist)
            photoData = try container.decodeIfPresent(Data.self, forKey: .photoData)
            source = try container.decode(String.self, forKey: .source)
        }
    }

    struct Exercise: Codable, Sendable {
        let name: String
        let setCount: Int
        let bestWeight: Double?
        let bestReps: Int?
        let volumeKg: Double
        let rpe: Double?
    }

    struct Activity: Codable, Sendable {
        let id: UUID
        let externalID: String
        let date: Date
        let activeEnergy: Double
        let restingEnergy: Double
        let steps: Double
        let source: String
    }

    struct Recovery: Codable, Sendable {
        let id: UUID
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

    struct DailyCheckIn: Codable, Sendable {
        let id: UUID
        let externalID: String
        let date: Date
        let nutritionComplete: Bool
        let hunger: Int
        let energy: Int
    }

    struct PlanSettings: Codable, Sendable, Equatable {
        let goalMode: String
        let weeklyRate: Double
        let targetWeight: Double?
        let lastAdjustmentTimestamp: Double?
        let calorieMin: Double
        let calorieMax: Double
        let proteinMin: Double
        let proteinMax: Double
        let fiberTarget: Double?
    }

    struct Workout: Codable, Sendable {
        let id: UUID
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
        let exercises: [Exercise]
    }

    struct Message: Codable, Sendable {
        let id: UUID
        let date: Date
        let role: String
        let content: String
    }

    let version: Int
    let exportedAt: Date
    let meals: [Meal]
    let measurements: [Body]
    let activities: [Activity]
    let recovery: [Recovery]
    let checkIns: [DailyCheckIn]
    let planSettings: PlanSettings?
    let workouts: [Workout]
    let messages: [Message]

    init(version: Int, exportedAt: Date, meals: [Meal], measurements: [Body], activities: [Activity] = [], recovery: [Recovery] = [], checkIns: [DailyCheckIn] = [], planSettings: PlanSettings? = nil, workouts: [Workout], messages: [Message]) {
        self.version = version
        self.exportedAt = exportedAt
        self.meals = meals
        self.measurements = measurements
        self.activities = activities
        self.recovery = recovery
        self.checkIns = checkIns
        self.planSettings = planSettings
        self.workouts = workouts
        self.messages = messages
    }

    private enum CodingKeys: String, CodingKey {
        case version, exportedAt, meals, measurements, activities, recovery, checkIns, planSettings, workouts, messages
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(Int.self, forKey: .version)
        exportedAt = try container.decode(Date.self, forKey: .exportedAt)
        meals = try container.decode([Meal].self, forKey: .meals)
        measurements = try container.decode([Body].self, forKey: .measurements)
        activities = try container.decodeIfPresent([Activity].self, forKey: .activities) ?? []
        recovery = try container.decodeIfPresent([Recovery].self, forKey: .recovery) ?? []
        checkIns = try container.decodeIfPresent([DailyCheckIn].self, forKey: .checkIns) ?? []
        planSettings = try container.decodeIfPresent(PlanSettings.self, forKey: .planSettings)
        workouts = try container.decode([Workout].self, forKey: .workouts)
        messages = try container.decode([Message].self, forKey: .messages)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version, forKey: .version)
        try container.encode(exportedAt, forKey: .exportedAt)
        try container.encode(meals, forKey: .meals)
        try container.encode(measurements, forKey: .measurements)
        try container.encode(activities, forKey: .activities)
        try container.encode(recovery, forKey: .recovery)
        try container.encode(checkIns, forKey: .checkIns)
        try container.encodeIfPresent(planSettings, forKey: .planSettings)
        try container.encode(workouts, forKey: .workouts)
        try container.encode(messages, forKey: .messages)
    }
}

struct CaltrackBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    let backup: CaltrackBackup

    init(backup: CaltrackBackup) {
        self.backup = backup
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        backup = try JSONDecoder.caltrack.decode(CaltrackBackup.self, from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try JSONEncoder.caltrack.encode(backup)
        return FileWrapper(regularFileWithContents: data)
    }
}

enum BackupService {
    @MainActor
    static func make(
        meals: [MealEntry],
        measurements: [BodyMeasurement],
        activities: [ActivityDay],
        recovery: [RecoveryDay] = [],
        checkIns: [DailyPlanCheckIn] = [],
        planSettings: CaltrackBackup.PlanSettings? = nil,
        workouts: [WorkoutEntry],
        messages: [CoachMessage]
    ) -> CaltrackBackup {
        CaltrackBackup(
            version: 1,
            exportedAt: .now,
            meals: meals.map {
                .init(
                    id: $0.id,
                    date: $0.date,
                    name: $0.name,
                    calories: $0.calories,
                    protein: $0.protein,
                    carbohydrates: $0.carbohydrates,
                    fat: $0.fat,
                    fiber: $0.fiber,
                    photoData: $0.photoData,
                    components: $0.components.isEmpty ? nil : $0.components,
                    source: $0.source,
                    confidence: $0.confidence,
                    assumption: $0.assumption
                )
            },
            measurements: measurements.map {
                .init(id: $0.id, date: $0.date, weight: $0.weight, bodyFat: $0.bodyFat, waist: $0.waist, photoData: $0.photoData, source: $0.source)
            },
            activities: activities.map {
                .init(id: $0.id, externalID: $0.externalID, date: $0.date, activeEnergy: $0.activeEnergy, restingEnergy: $0.restingEnergy, steps: $0.steps, source: $0.source)
            },
            recovery: recovery.map {
                .init(
                    id: $0.id,
                    externalID: $0.externalID,
                    date: $0.date,
                    sleepMinutes: $0.sleepMinutes,
                    coreMinutes: $0.coreMinutes,
                    deepMinutes: $0.deepMinutes,
                    remMinutes: $0.remMinutes,
                    restingHeartRate: $0.restingHeartRate,
                    hrvSDNN: $0.hrvSDNN,
                    source: $0.source
                )
            },
            checkIns: checkIns.map {
                .init(
                    id: $0.id,
                    externalID: $0.externalID,
                    date: $0.date,
                    nutritionComplete: $0.nutritionComplete,
                    hunger: $0.hunger,
                    energy: $0.energy
                )
            },
            planSettings: planSettings,
            workouts: workouts.map { workout in
                .init(
                    id: workout.id,
                    externalID: workout.externalID,
                    startDate: workout.startDate,
                    endDate: workout.endDate,
                    title: workout.title,
                    activityType: workout.activityType,
                    durationMinutes: workout.durationMinutes,
                    calories: workout.calories,
                    distanceKm: workout.distanceKm,
                    source: workout.source,
                    sourceBundle: workout.sourceBundle,
                    exercises: workout.exercises.map {
                        .init(name: $0.name, setCount: $0.setCount, bestWeight: $0.bestWeight, bestReps: $0.bestReps, volumeKg: $0.volumeKg, rpe: $0.rpe)
                    }
                )
            },
            messages: messages.map { .init(id: $0.id, date: $0.date, role: $0.role, content: $0.content) }
        )
    }

    static func decode(_ data: Data) throws -> CaltrackBackup {
        let backup = try JSONDecoder.caltrack.decode(CaltrackBackup.self, from: data)
        guard backup.version == 1 else { throw BackupError.unsupportedVersion }
        return backup
    }

    @MainActor
    static func restore(_ backup: CaltrackBackup, into context: ModelContext) throws -> Int {
        guard backup.version == 1 else { throw BackupError.unsupportedVersion }
        let existingMeals = try context.fetch(FetchDescriptor<MealEntry>())
        let existingBodies = try context.fetch(FetchDescriptor<BodyMeasurement>())
        let existingActivities = try context.fetch(FetchDescriptor<ActivityDay>())
        let existingRecovery = try context.fetch(FetchDescriptor<RecoveryDay>())
        let existingCheckIns = try context.fetch(FetchDescriptor<DailyPlanCheckIn>())
        let existingWorkouts = try context.fetch(FetchDescriptor<WorkoutEntry>())
        let existingMessages = try context.fetch(FetchDescriptor<CoachMessage>())
        var mealIDs = Set(existingMeals.map(\.id))
        var bodyIDs = Set(existingBodies.map(\.id))
        var activityIDs = Set(existingActivities.map(\.externalID))
        var recoveryIDs = Set(existingRecovery.map(\.externalID))
        var checkInIDs = Set(existingCheckIns.map(\.externalID))
        var workoutIDs = Set(existingWorkouts.map(\.externalID))
        var messageIDs = Set(existingMessages.map(\.id))
        var inserted = 0

        for item in backup.meals where mealIDs.insert(item.id).inserted {
            context.insert(MealEntry(
                id: item.id,
                date: item.date,
                name: item.name,
                calories: item.calories,
                protein: item.protein,
                carbohydrates: item.carbohydrates,
                fat: item.fat,
                fiber: item.fiber,
                photoData: item.photoData,
                components: item.components ?? [],
                source: item.source,
                confidence: item.confidence,
                assumption: item.assumption
            ))
            inserted += 1
        }
        for item in backup.measurements where bodyIDs.insert(item.id).inserted {
            context.insert(BodyMeasurement(id: item.id, date: item.date, weight: item.weight, bodyFat: item.bodyFat, waist: item.waist, photoData: item.photoData, source: item.source))
            inserted += 1
        }
        for item in backup.activities where activityIDs.insert(item.externalID).inserted {
            context.insert(ActivityDay(
                id: item.id,
                externalID: item.externalID,
                date: item.date,
                activeEnergy: item.activeEnergy,
                restingEnergy: item.restingEnergy,
                steps: item.steps,
                source: item.source
            ))
            inserted += 1
        }
        for item in backup.recovery where recoveryIDs.insert(item.externalID).inserted {
            context.insert(RecoveryDay(
                id: item.id,
                externalID: item.externalID,
                date: item.date,
                sleepMinutes: item.sleepMinutes,
                coreMinutes: item.coreMinutes,
                deepMinutes: item.deepMinutes,
                remMinutes: item.remMinutes,
                restingHeartRate: item.restingHeartRate,
                hrvSDNN: item.hrvSDNN,
                source: item.source
            ))
            inserted += 1
        }
        for item in backup.checkIns where checkInIDs.insert(item.externalID).inserted {
            context.insert(DailyPlanCheckIn(
                id: item.id,
                externalID: item.externalID,
                date: item.date,
                nutritionComplete: item.nutritionComplete,
                hunger: item.hunger,
                energy: item.energy
            ))
            inserted += 1
        }
        for item in backup.workouts where workoutIDs.insert(item.externalID).inserted {
            let exercises = item.exercises.map {
                WorkoutExerciseSummary(name: $0.name, setCount: $0.setCount, bestWeight: $0.bestWeight, bestReps: $0.bestReps, volumeKg: $0.volumeKg, rpe: $0.rpe)
            }
            context.insert(WorkoutEntry(
                id: item.id,
                externalID: item.externalID,
                startDate: item.startDate,
                endDate: item.endDate,
                title: item.title,
                activityType: item.activityType,
                durationMinutes: item.durationMinutes,
                calories: item.calories,
                distanceKm: item.distanceKm,
                source: item.source,
                sourceBundle: item.sourceBundle,
                exerciseCount: exercises.count,
                setCount: exercises.reduce(0) { $0 + $1.setCount },
                totalVolumeKg: exercises.reduce(0) { $0 + $1.volumeKg },
                exercises: exercises
            ))
            inserted += 1
        }
        for item in backup.messages where messageIDs.insert(item.id).inserted {
            context.insert(CoachMessage(id: item.id, date: item.date, role: item.role, content: item.content))
            inserted += 1
        }
        if let settings = backup.planSettings {
            let defaults = UserDefaults.standard
            defaults.set(settings.goalMode, forKey: "planGoalMode")
            defaults.set(settings.weeklyRate, forKey: "planWeeklyRate")
            defaults.set(settings.targetWeight ?? 0, forKey: "planTargetWeight")
            defaults.set(settings.lastAdjustmentTimestamp ?? 0, forKey: "planLastAdjustmentTimestamp")
            defaults.set(settings.calorieMin, forKey: "calorieMin")
            defaults.set(settings.calorieMax, forKey: "calorieMax")
            defaults.set(settings.proteinMin, forKey: "proteinMin")
            defaults.set(settings.proteinMax, forKey: "proteinMax")
            if let fiberTarget = settings.fiberTarget {
                defaults.set(fiberTarget, forKey: "fiberTarget")
            }
        }
        try context.save()
        return inserted
    }
}

enum BackupError: LocalizedError {
    case unsupportedVersion

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion: "Esta copia pertenece a una versión de Caltrack que no se puede restaurar."
        }
    }
}

private extension JSONEncoder {
    static var caltrack: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var caltrack: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
