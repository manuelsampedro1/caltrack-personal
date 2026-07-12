import XCTest
import SwiftData
import HealthKit
@testable import Caltrack

final class GrokServiceTests: XCTestCase {
    func testDecodesStructuredFoodAnalysis() throws {
        let analysis = #"{"title":"Pollo con arroz","items":[{"name":"Pechuga de pollo","portion":"180 g","calories":297,"protein_g":55.8,"carbs_g":0,"fat_g":6.5}],"calories":510,"protein_g":60,"carbs_g":45,"fat_g":10,"confidence":0.82,"assumptions":["Una cucharadita de aceite"],"warning":"La salsa puede cambiar el total."}"#
        let escaped = analysis
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let envelope = "{\"output\":[{\"content\":[{\"type\":\"output_text\",\"text\":\"\(escaped)\"}]}]}"
        let result = try GrokService.decodeResponse(Data(envelope.utf8))

        XCTAssertEqual(result.title, "Pollo con arroz")
        XCTAssertEqual(result.calories, 510)
        XCTAssertEqual(result.proteinG, 60)
        XCTAssertEqual(result.items.first?.portion, "180 g")
    }

    func testAdherenceRewardsConfiguredRanges() {
        XCTAssertEqual(CaltrackMath.adherence(calories: 1_900, protein: 170, calorieRange: 1_800...2_000, proteinRange: 160...190), 100)
        XCTAssertLessThan(CaltrackMath.adherence(calories: 2_800, protein: 80, calorieRange: 1_800...2_000, proteinRange: 160...190), 100)
    }

    func testDecodesHevyAndCalculatesStrengthDetails() throws {
        let fixture = #"{"workouts":[{"id":"workout-1","title":"Torso","description":"","start_time":"2026-07-12T08:00:00Z","end_time":"2026-07-12T09:10:00Z","exercises":[{"title":"Press banca","notes":"","sets":[{"index":0,"set_type":"warmup","weight_kg":20,"reps":10,"distance_meters":null,"duration_seconds":null,"rpe":null},{"index":1,"set_type":"normal","weight_kg":55,"reps":8,"distance_meters":null,"duration_seconds":null,"rpe":8},{"index":2,"set_type":"normal","weight_kg":60,"reps":4,"distance_meters":null,"duration_seconds":null,"rpe":9}]}]}]}"#
        let workout = try XCTUnwrap(HevyService.decodeWorkouts(Data(fixture.utf8)).first)
        let summary = try XCTUnwrap(workout.exerciseSummaries.first)
        let entry = workout.makeEntry()

        XCTAssertEqual(workout.title, "Torso")
        XCTAssertEqual(summary.setCount, 2)
        XCTAssertEqual(summary.bestWeight, 55)
        XCTAssertEqual(summary.bestReps, 8)
        XCTAssertEqual(summary.volumeKg, 680)
        XCTAssertEqual(entry.durationMinutes, 70)
        XCTAssertEqual(entry.externalID, "hevy:workout-1")
    }

    func testHevyDeduplicationNeedsSourceAndCloseStartTime() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        XCTAssertTrue(WorkoutMatch.representsSameSession(sourceName: "Hevy", sourceBundle: "com.hevyapp.hevy", startDate: start, hevyStartDate: start.addingTimeInterval(300)))
        XCTAssertFalse(WorkoutMatch.representsSameSession(sourceName: "Strava", sourceBundle: "com.strava", startDate: start, hevyStartDate: start.addingTimeInterval(300)))
        XCTAssertFalse(WorkoutMatch.representsSameSession(sourceName: "Hevy", sourceBundle: "com.hevyapp.hevy", startDate: start, hevyStartDate: start.addingTimeInterval(900)))
    }

    func testHealthStateOnlyMarksUnavailableAndFailureAsFailure() {
        XCTAssertFalse(HealthKitService.State.idle.isFailure)
        XCTAssertFalse(HealthKitService.State.ready.isFailure)
        XCTAssertTrue(HealthKitService.State.unavailable.isFailure)
        XCTAssertTrue(HealthKitService.State.failed("Sin permiso").isFailure)
    }

    func testInsightReportUsesOnlyDaysWithLoggedFood() {
        let calendar = Calendar(identifier: .gregorian)
        let now = Date(timeIntervalSince1970: 1_788_739_200)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let meals = [
            MealEntry(date: now, name: "Día uno", calories: 1_900, protein: 170),
            MealEntry(date: yesterday, name: "Día dos", calories: 1_850, protein: 165)
        ]
        let report = InsightEngine.report(
            meals: meals,
            measurements: [],
            workouts: [],
            calorieRange: 1_800...2_000,
            proteinRange: 160...190,
            now: now,
            calendar: calendar
        )

        XCTAssertGreaterThan(report.score, 80)
        XCTAssertTrue(report.summary.contains("2 días"))
        XCTAssertTrue(report.observations.contains { $0.contains("dentro del rango") })
    }

    func testCoachContextContainsAggregatesWithoutPhotosOrHealthIdentifiers() {
        let meal = MealEntry(name: "Pollo", calories: 500, protein: 55, photoData: Data("private-photo".utf8))
        let workout = WorkoutEntry(
            externalID: "health:secret-identifier",
            startDate: .now.addingTimeInterval(-3_600),
            endDate: .now,
            title: "Torso",
            activityType: "Fuerza",
            durationMinutes: 60,
            source: "HealthKit",
            sourceBundle: "private.bundle"
        )
        let context = CoachContextBuilder.build(
            meals: [meal],
            measurements: [],
            workouts: [workout],
            calorieRange: 1_800...2_000,
            proteinRange: 160...190
        )

        XCTAssertTrue(context.contains("500 kcal"))
        XCTAssertTrue(context.contains("Torso"))
        XCTAssertFalse(context.contains("private-photo"))
        XCTAssertFalse(context.contains("secret-identifier"))
        XCTAssertFalse(context.contains("private.bundle"))
    }

    func testCoachDecodesTextResponse() throws {
        let payload = #"{"output":[{"content":[{"type":"output_text","text":"Mantén la proteína y planifica la cena."}]}]}"#
        XCTAssertEqual(try CoachService.decodeText(Data(payload.utf8)), "Mantén la proteína y planifica la cena.")
    }

    func testWorkoutDerivesTotalsFromExerciseSummaries() {
        let workout = WorkoutEntry(
            externalID: "test:derived",
            startDate: .now.addingTimeInterval(-3_600),
            endDate: .now,
            title: "Torso",
            activityType: "Fuerza",
            durationMinutes: 60,
            source: "Test",
            exercises: [
                WorkoutExerciseSummary(name: "Press", setCount: 3, bestWeight: 70, bestReps: 8, volumeKg: 1_400, rpe: 8),
                WorkoutExerciseSummary(name: "Remo", setCount: 4, bestWeight: 60, bestReps: 10, volumeKg: 1_800, rpe: 8)
            ]
        )

        XCTAssertEqual(workout.exerciseCount, 2)
        XCTAssertEqual(workout.setCount, 7)
        XCTAssertEqual(workout.totalVolumeKg, 3_200)
    }

    func testBackupDecoderAcceptsCurrentVersionAndRejectsFutureVersion() throws {
        let current = CaltrackBackup(version: 1, exportedAt: .now, meals: [], measurements: [], workouts: [], messages: [])
        let future = CaltrackBackup(version: 2, exportedAt: .now, meals: [], measurements: [], workouts: [], messages: [])
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        XCTAssertEqual(try BackupService.decode(encoder.encode(current)).version, 1)
        XCTAssertThrowsError(try BackupService.decode(encoder.encode(future)))
    }

    @MainActor
    func testBackupRestoreMergesWithoutDuplicates() throws {
        let schema = Schema([MealEntry.self, BodyMeasurement.self, ActivityDay.self, WorkoutEntry.self, CoachMessage.self])
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        let mealID = UUID()
        let backup = CaltrackBackup(
            version: 1,
            exportedAt: .now,
            meals: [
                .init(id: mealID, date: .now, name: "Comida restaurada", calories: 600, protein: 50, carbohydrates: 60, fat: 18, photoData: nil, source: "manual", confidence: 1, assumption: "")
            ],
            measurements: [],
            activities: [],
            workouts: [],
            messages: []
        )

        XCTAssertEqual(try BackupService.restore(backup, into: container.mainContext), 1)
        XCTAssertEqual(try BackupService.restore(backup, into: container.mainContext), 0)
        XCTAssertEqual(try container.mainContext.fetch(FetchDescriptor<MealEntry>()).map(\.id), [mealID])
    }

    func testActivityTotalEnergyCombinesActiveAndResting() {
        let activity = ActivityDay(externalID: "test:activity", date: .now, activeEnergy: 650, restingEnergy: 1_850, steps: 10_000)
        XCTAssertEqual(activity.totalEnergy, 2_500)
    }

    func testFrequentMealsNormalizesNamesAndUsesLatestValues() throws {
        let now = Date(timeIntervalSince1970: 1_788_739_200)
        let meals = [
            MealEntry(date: now.addingTimeInterval(-300), name: "  Pollo   con arroz ", calories: 700, protein: 60, carbohydrates: 70, fat: 18),
            MealEntry(date: now.addingTimeInterval(-100), name: "POLLO CON ARROZ", calories: 740, protein: 64, carbohydrates: 74, fat: 19),
            MealEntry(date: now.addingTimeInterval(-200), name: "Salmón", calories: 610, protein: 55)
        ]

        let frequent = FoodLibrary.frequentMeals(meals: meals, now: now)
        let first = try XCTUnwrap(frequent.first)

        XCTAssertEqual(first.key, "pollo con arroz")
        XCTAssertEqual(first.count, 2)
        XCTAssertEqual(first.calories, 740)
        XCTAssertEqual(FoodLibrary.normalizedName("  SALMÓN  "), "salmon")
    }

    func testHealthNutritionCorrelationContainsConfirmedMacrosAndStableIdentifier() throws {
        let id = UUID()
        let date = Date(timeIntervalSince1970: 1_788_739_200)
        let meal = MealEntry(id: id, date: date, name: "Bowl", calories: 640, protein: 52, carbohydrates: 68, fat: 18)
        let correlation = try HealthNutritionService.makeCorrelation(for: meal)

        XCTAssertEqual(correlation.startDate, date)
        XCTAssertEqual(correlation.metadata?[HKMetadataKeyExternalUUID] as? String, id.uuidString)
        XCTAssertEqual(correlation.objects.count, 4)

        let samples = correlation.objects.compactMap { $0 as? HKQuantitySample }
        let energy = try XCTUnwrap(samples.first { $0.quantityType.identifier == HKQuantityTypeIdentifier.dietaryEnergyConsumed.rawValue })
        let protein = try XCTUnwrap(samples.first { $0.quantityType.identifier == HKQuantityTypeIdentifier.dietaryProtein.rawValue })
        XCTAssertEqual(energy.quantity.doubleValue(for: .kilocalorie()), 640)
        XCTAssertEqual(protein.quantity.doubleValue(for: .gram()), 52)
    }
}
