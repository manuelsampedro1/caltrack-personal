import XCTest
import SwiftData
import HealthKit
import UIKit
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
        XCTAssertEqual(EditableMeal(analysis: result).components.first?.name, "Pechuga de pollo")
    }

    func testEditableMealComponentsRecalculateAndPersist() throws {
        var meal = EditableMeal()
        meal.name = "Pollo con arroz"
        var chicken = EditableMealComponent()
        chicken.name = "Pechuga de pollo"
        chicken.portion = "220 g"
        chicken.calories = "330"
        chicken.protein = "55"
        chicken.fat = "8"
        var rice = EditableMealComponent()
        rice.name = "Arroz cocido"
        rice.portion = "250 g"
        rice.calories = "330"
        rice.protein = "7"
        rice.carbohydrates = "74"
        rice.fat = "2"
        meal.components = [chicken, rice]
        meal.recalculateFromComponents()

        XCTAssertEqual(meal.number(meal.calories), 660)
        XCTAssertEqual(meal.number(meal.protein), 62)
        XCTAssertEqual(meal.number(meal.carbohydrates), 74)
        XCTAssertEqual(meal.number(meal.fat), 10)
        XCTAssertTrue(meal.isValid)

        let entry = MealEntry(
            name: meal.name,
            calories: meal.number(meal.calories),
            protein: meal.number(meal.protein),
            carbohydrates: meal.number(meal.carbohydrates),
            fat: meal.number(meal.fat),
            components: meal.persistedComponents
        )
        XCTAssertEqual(entry.components.map(\.name), ["Pechuga de pollo", "Arroz cocido"])
        XCTAssertEqual(EditableMeal(meal: entry).components.count, 2)
    }

    func testAdherenceRewardsConfiguredRanges() {
        XCTAssertEqual(CaltrackMath.adherence(calories: 1_900, protein: 170, calorieRange: 1_800...2_000, proteinRange: 160...190), 100)
        XCTAssertLessThan(CaltrackMath.adherence(calories: 2_800, protein: 80, calorieRange: 1_800...2_000, proteinRange: 160...190), 100)
        XCTAssertEqual(CaltrackMath.orderedRange(2_000, 1_800), 1_800...2_000)
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
            checkIns: [DailyPlanCheckIn(externalID: "private-check-in-id", date: .now, hunger: 4, energy: 2)],
            planMode: .lose,
            planWeeklyRate: 0.5,
            calorieRange: 1_800...2_000,
            proteinRange: 160...190
        )

        XCTAssertTrue(context.contains("500 kcal"))
        XCTAssertTrue(context.contains("Torso"))
        XCTAssertTrue(context.contains("Hambre media 4"))
        XCTAssertTrue(context.contains("Perder peso"))
        XCTAssertFalse(context.contains("private-photo"))
        XCTAssertFalse(context.contains("secret-identifier"))
        XCTAssertFalse(context.contains("private.bundle"))
        XCTAssertFalse(context.contains("private-check-in-id"))
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

    func testLegacyMealBackupWithoutComponentsDecodes() throws {
        let meal = CaltrackBackup.Meal(
            id: UUID(),
            date: .now,
            name: "Comida antigua",
            calories: 500,
            protein: 40,
            carbohydrates: 45,
            fat: 15,
            photoData: nil,
            source: "manual",
            confidence: 1,
            assumption: ""
        )
        let backup = CaltrackBackup(version: 1, exportedAt: .now, meals: [meal], measurements: [], workouts: [], messages: [])
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(backup)

        XCTAssertFalse(String(decoding: data, as: UTF8.self).contains("components"))
        XCTAssertNil(try BackupService.decode(data).meals.first?.components)
    }

    @MainActor
    func testBackupRestoreMergesWithoutDuplicates() throws {
        let schema = Schema([MealEntry.self, BodyMeasurement.self, ActivityDay.self, RecoveryDay.self, DailyPlanCheckIn.self, WorkoutEntry.self, CoachMessage.self])
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        let mealID = UUID()
        let component = MealComponent(name: "Arroz cocido", portion: "250 g", calories: 330, protein: 7, carbohydrates: 74, fat: 2)
        let backup = CaltrackBackup(
            version: 1,
            exportedAt: .now,
            meals: [
                .init(id: mealID, date: .now, name: "Comida restaurada", calories: 600, protein: 50, carbohydrates: 60, fat: 18, photoData: nil, components: [component], source: "manual", confidence: 1, assumption: "")
            ],
            measurements: [],
            activities: [],
            workouts: [],
            messages: []
        )

        XCTAssertEqual(try BackupService.restore(backup, into: container.mainContext), 1)
        XCTAssertEqual(try BackupService.restore(backup, into: container.mainContext), 0)
        let restored = try container.mainContext.fetch(FetchDescriptor<MealEntry>())
        XCTAssertEqual(restored.map(\.id), [mealID])
        XCTAssertEqual(restored.first?.components, [component])
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

    func testOpenFoodFactsDecodesV3ProductAndScalesServing() throws {
        let fixture = #"{"status":"success","code":"3017620422003","product":{"code":"3017620422003","product_name":"Nutella","product_name_es":"Nutella","brands":"Ferrero","serving_size":"15 g","nutriscore_grade":"e","nutriments":{"energy-kcal_100g":539,"proteins_100g":6.3,"carbohydrates_100g":57.5,"fat_100g":30.9}}}"#
        let product = try OpenFoodFactsService.decodeProduct(Data(fixture.utf8))
        let meal = product.editableMeal(amount: 30)

        XCTAssertEqual(product.name, "Nutella")
        XCTAssertEqual(product.servingSize, "15 g")
        XCTAssertEqual(meal.number(meal.calories), 161.7, accuracy: 0.01)
        XCTAssertEqual(meal.number(meal.protein), 1.9, accuracy: 0.01)
        XCTAssertTrue(meal.assumption.contains("3017620422003"))
    }

    func testOpenFoodFactsRejectsInvalidBarcodeAndIncompleteNutrition() throws {
        XCTAssertThrowsError(try OpenFoodFactsService.normalizedBarcode("ABC-123"))
        let fixture = #"{"status":"success","code":"12345678","product":{"product_name":"Producto","nutriments":{"energy-kcal_100g":100}}}"#
        XCTAssertThrowsError(try OpenFoodFactsService.decodeProduct(Data(fixture.utf8))) { error in
            XCTAssertEqual(error as? OpenFoodFactsError, .incompleteNutrition)
        }
    }

    func testBodyCheckInValidationAcceptsPartialDataAndRejectsUnsafeValues() {
        var draft = BodyCheckInDraft()
        XCTAssertFalse(draft.isValid)

        draft.weight = "78,9"
        XCTAssertTrue(draft.isValid)
        XCTAssertEqual(draft.weightValue, 78.9)

        draft.bodyFat = "90"
        XCTAssertFalse(draft.isValid)
        XCTAssertEqual(draft.validationMessage, "La grasa debe estar entre 1 y 75 %.")
    }

    func testProgressPhotoCompressionLimitsDimensions() throws {
        let source = UIGraphicsImageRenderer(size: CGSize(width: 2_400, height: 1_200)).image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 2_400, height: 1_200))
        }
        let png = try XCTUnwrap(source.pngData())
        let compressed = try XCTUnwrap(ProgressPhotoProcessor.compressedJPEG(from: png))
        let result = try XCTUnwrap(UIImage(data: compressed))

        XCTAssertEqual(max(result.size.width, result.size.height), 1_600, accuracy: 1)
        XCTAssertLessThan(compressed.count, png.count)
    }

    @MainActor
    func testBodyPhotoBackupRestoresAndOldBackupWithoutPhotoDecodes() throws {
        let schema = Schema([MealEntry.self, BodyMeasurement.self, ActivityDay.self, RecoveryDay.self, DailyPlanCheckIn.self, WorkoutEntry.self, CoachMessage.self])
        let source = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        let photo = Data([1, 2, 3, 4])
        source.mainContext.insert(BodyMeasurement(weight: 78.9, waist: 80.5, photoData: photo, source: "manual"))
        try source.mainContext.save()
        let backup = BackupService.make(meals: [], measurements: try source.mainContext.fetch(FetchDescriptor<BodyMeasurement>()), activities: [], workouts: [], messages: [])

        let destination = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        XCTAssertEqual(try BackupService.restore(backup, into: destination.mainContext), 1)
        XCTAssertEqual(try destination.mainContext.fetch(FetchDescriptor<BodyMeasurement>()).first?.photoData, photo)

        let id = UUID()
        let legacy = #"{"version":1,"exportedAt":"2026-07-12T12:00:00Z","meals":[],"measurements":[{"id":"\#(id.uuidString)","date":"2026-07-12T12:00:00Z","weight":80,"bodyFat":null,"waist":82,"source":"manual"}],"activities":[],"workouts":[],"messages":[]}"#
        let decoded = try BackupService.decode(Data(legacy.utf8))
        XCTAssertEqual(decoded.measurements.first?.id, id)
        XCTAssertNil(decoded.measurements.first?.photoData)
    }

    func testQuickActionStoreConsumesOnceAndParsesLaunchArguments() throws {
        let suiteName = "CaltrackTests.QuickActionStore.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

        QuickActionStore.set(.barcode, defaults: defaults)
        XCTAssertEqual(QuickActionStore.consume(defaults: defaults), .barcode)
        XCTAssertNil(QuickActionStore.consume(defaults: defaults))
        XCTAssertEqual(
            QuickActionStore.fromLaunchArguments(["Caltrack", "-quick-action", "bodyCheckIn"]),
            .bodyCheckIn
        )
        XCTAssertNil(QuickActionStore.fromLaunchArguments(["Caltrack", "-quick-action", "unknown"]))
    }

    func testWidgetSnapshotPersistsContentAndExpiresAtMidnight() throws {
        let suiteName = "CaltrackTests.WidgetSnapshot.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let formatter = ISO8601DateFormatter()
        let day = try XCTUnwrap(formatter.date(from: "2026-07-13T12:00:00Z"))
        let tomorrow = try XCTUnwrap(formatter.date(from: "2026-07-14T00:01:00Z"))
        let snapshot = WidgetSnapshot(
            day: calendar.startOfDay(for: day),
            generatedAt: day,
            calories: 1_760,
            protein: 159,
            calorieMin: 1_800,
            calorieMax: 2_000,
            proteinMin: 160,
            mealCount: 3,
            nutritionComplete: true,
            planTitle: "Mantén el rango"
        )

        XCTAssertTrue(WidgetSnapshotStore.save(snapshot, defaults: defaults))
        XCTAssertFalse(WidgetSnapshotStore.save(snapshot, defaults: defaults))
        XCTAssertEqual(WidgetSnapshotStore.load(defaults: defaults, now: day, calendar: calendar), snapshot)

        let expired = WidgetSnapshotStore.load(defaults: defaults, now: tomorrow, calendar: calendar)
        XCTAssertEqual(expired.calories, 0)
        XCTAssertEqual(expired.protein, 0)
        XCTAssertEqual(expired.mealCount, 0)
        XCTAssertFalse(expired.nutritionComplete)
        XCTAssertEqual(expired.calorieMax, 2_000)
        XCTAssertEqual(expired.proteinMin, 160)
        XCTAssertEqual(expired.planTitle, "Empieza el día")
    }

    func testAppIntentsExposeExpectedRoutesAndFourShortcuts() {
        XCTAssertEqual(CaptureMealIntent.targetAction, .camera)
        XCTAssertEqual(ScanProductIntent.targetAction, .barcode)
        XCTAssertEqual(NewBodyCheckInIntent.targetAction, .bodyCheckIn)
        XCTAssertEqual(OpenProgressIntent.targetAction, .progress)
        XCTAssertEqual(CaltrackShortcuts.appShortcuts.count, 4)
    }

    func testRecoverySleepAggregationMergesDuplicatesAndChoosesBestSource() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let formatter = ISO8601DateFormatter()
        func date(_ value: String) -> Date { formatter.date(from: value)! }
        let segments = [
            RecoverySleepSegment(startDate: date("2026-07-11T22:00:00Z"), endDate: date("2026-07-12T00:00:00Z"), stage: .core, source: "Apple Watch"),
            RecoverySleepSegment(startDate: date("2026-07-11T22:00:00Z"), endDate: date("2026-07-12T00:00:00Z"), stage: .core, source: "Apple Watch"),
            RecoverySleepSegment(startDate: date("2026-07-12T00:00:00Z"), endDate: date("2026-07-12T01:00:00Z"), stage: .deep, source: "Apple Watch"),
            RecoverySleepSegment(startDate: date("2026-07-11T23:00:00Z"), endDate: date("2026-07-12T00:00:00Z"), stage: .unspecified, source: "iPhone")
        ]

        let day = try XCTUnwrap(RecoveryMath.sleepDays(from: segments, calendar: calendar).first)
        XCTAssertEqual(day.date, date("2026-07-12T00:00:00Z"))
        XCTAssertEqual(day.sleepMinutes, 180)
        XCTAssertEqual(day.coreMinutes, 120)
        XCTAssertEqual(day.deepMinutes, 60)
        XCTAssertEqual(day.source, "Apple Watch")
    }

    func testRecoveryComparisonNeedsPersonalHistory() {
        XCTAssertNil(RecoveryMath.personalComparison(latest: 7.5, history: [7, 8], unit: "h"))
        XCTAssertEqual(
            RecoveryMath.personalComparison(latest: 8, history: [7, 7, 7], unit: "h"),
            "+1 h frente a tu media reciente."
        )
    }

    @MainActor
    func testRecoveryBackupRoundTripAndLegacyBackupDefault() throws {
        let schema = Schema([MealEntry.self, BodyMeasurement.self, ActivityDay.self, RecoveryDay.self, DailyPlanCheckIn.self, WorkoutEntry.self, CoachMessage.self])
        let source = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        source.mainContext.insert(RecoveryDay(
            externalID: "health-recovery:test",
            date: .now,
            sleepMinutes: 452,
            coreMinutes: 260,
            deepMinutes: 72,
            remMinutes: 102,
            restingHeartRate: 54,
            hrvSDNN: 48,
            source: "Apple Watch"
        ))
        try source.mainContext.save()
        let recovery = try source.mainContext.fetch(FetchDescriptor<RecoveryDay>())
        let backup = BackupService.make(meals: [], measurements: [], activities: [], recovery: recovery, workouts: [], messages: [])

        let destination = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        XCTAssertEqual(try BackupService.restore(backup, into: destination.mainContext), 1)
        let restored = try XCTUnwrap(destination.mainContext.fetch(FetchDescriptor<RecoveryDay>()).first)
        XCTAssertEqual(restored.sleepMinutes, 452)
        XCTAssertEqual(restored.hrvSDNN, 48)

        let legacy = #"{"version":1,"exportedAt":"2026-07-12T12:00:00Z","meals":[],"measurements":[],"activities":[],"workouts":[],"messages":[]}"#
        XCTAssertTrue(try BackupService.decode(Data(legacy.utf8)).recovery.isEmpty)
    }

    func testAdaptivePlanCollectsEvidenceBeforeReviewing() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let now = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-07-12T12:00:00Z"))
        let configured = AdaptivePlanEngine.review(
            days: [],
            weights: [],
            mode: .lose,
            weeklyRate: 0.5,
            calorieRange: 1_800...2_000,
            now: now,
            calendar: calendar
        )
        XCTAssertEqual(configured.state, .collecting)
        XCTAssertTrue(configured.message.contains("7 días completos"))
        XCTAssertTrue(configured.message.contains("3 pesos"))

        let unconfigured = AdaptivePlanEngine.review(
            days: [],
            weights: [],
            mode: .notSet,
            weeklyRate: 0.5,
            calorieRange: 1_800...2_000,
            now: now,
            calendar: calendar
        )
        XCTAssertEqual(unconfigured.state, .needsConfiguration)
        XCTAssertNil(unconfigured.calorieDelta)
    }

    func testAdaptivePlanRequiresAdherenceBeforeChangingCalories() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let now = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-07-12T12:00:00Z"))
        let days = (0..<14).map { offset in
            AdaptivePlanDay(
                date: calendar.date(byAdding: .day, value: -offset, to: now)!,
                calories: offset < 5 ? 1_900 : 1_500,
                isComplete: true
            )
        }
        let review = AdaptivePlanEngine.review(
            days: days,
            weights: adaptiveWeights(slope: -0.1, now: now, calendar: calendar),
            mode: .lose,
            weeklyRate: 0.5,
            calorieRange: 1_800...2_000,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(review.state, .followCurrentPlan)
        XCTAssertEqual(review.rangeAdherence ?? -1, 5.0 / 14.0, accuracy: 0.001)
        XCTAssertNil(review.calorieDelta)
    }

    func testAdaptivePlanProposesSmallConfirmedAdjustments() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let now = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-07-12T12:00:00Z"))
        let days = (0..<14).map { offset in
            AdaptivePlanDay(date: calendar.date(byAdding: .day, value: -offset, to: now)!, calories: 1_900, isComplete: true)
        }

        let slow = AdaptivePlanEngine.review(
            days: days,
            weights: adaptiveWeights(slope: -0.1, now: now, calendar: calendar),
            mode: .lose,
            weeklyRate: 0.5,
            calorieRange: 1_800...2_000,
            now: now,
            calendar: calendar
        )
        XCTAssertEqual(slow.state, .adjustment)
        XCTAssertEqual(slow.calorieDelta, -100)
        XCTAssertEqual(slow.proposedRange, 1_700...1_900)

        let fast = AdaptivePlanEngine.review(
            days: days,
            weights: adaptiveWeights(slope: -0.9, now: now, calendar: calendar),
            mode: .lose,
            weeklyRate: 0.5,
            calorieRange: 1_800...2_000,
            now: now,
            calendar: calendar
        )
        XCTAssertEqual(fast.calorieDelta, 100)
        XCTAssertEqual(fast.proposedRange, 1_900...2_100)

        let paused = AdaptivePlanEngine.review(
            days: days,
            weights: adaptiveWeights(slope: -0.1, now: now, calendar: calendar),
            mode: .lose,
            weeklyRate: 0.5,
            calorieRange: 1_800...2_000,
            lastAdjustmentDate: calendar.date(byAdding: .day, value: -2, to: now),
            now: now,
            calendar: calendar
        )
        XCTAssertEqual(paused.state, .recentlyAdjusted)
        XCTAssertNil(paused.calorieDelta)
    }

    func testAdaptivePlanRegressionUsesTrendAcrossAllWeights() throws {
        let formatter = ISO8601DateFormatter()
        let points = [
            AdaptiveWeightPoint(date: formatter.date(from: "2026-07-01T08:00:00Z")!, weight: 80),
            AdaptiveWeightPoint(date: formatter.date(from: "2026-07-08T08:00:00Z")!, weight: 79.5),
            AdaptiveWeightPoint(date: formatter.date(from: "2026-07-15T08:00:00Z")!, weight: 79)
        ]
        XCTAssertEqual(try XCTUnwrap(AdaptivePlanEngine.weeklySlope(points)), -0.5, accuracy: 0.001)
    }

    @MainActor
    func testAdaptivePlanBackupRoundTripAndLegacyDefaults() throws {
        let schema = Schema([MealEntry.self, BodyMeasurement.self, ActivityDay.self, RecoveryDay.self, DailyPlanCheckIn.self, WorkoutEntry.self, CoachMessage.self])
        let source = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        source.mainContext.insert(DailyPlanCheckIn(externalID: "plan-check-in:test", date: .now, hunger: 4, energy: 2))
        try source.mainContext.save()
        let settings = CaltrackBackup.PlanSettings(
            goalMode: PlanGoalMode.lose.rawValue,
            weeklyRate: 0.5,
            targetWeight: 75,
            lastAdjustmentTimestamp: 1_783_890_000,
            calorieMin: 1_800,
            calorieMax: 2_000,
            proteinMin: 160,
            proteinMax: 190
        )
        let backup = BackupService.make(
            meals: [],
            measurements: [],
            activities: [],
            checkIns: try source.mainContext.fetch(FetchDescriptor<DailyPlanCheckIn>()),
            planSettings: settings,
            workouts: [],
            messages: []
        )
        let encoded = try JSONEncoder().encode(backup)
        let decoded = try JSONDecoder().decode(CaltrackBackup.self, from: encoded)
        XCTAssertEqual(decoded.planSettings, settings)
        XCTAssertEqual(decoded.checkIns.first?.hunger, 4)

        let destination = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        XCTAssertEqual(try BackupService.restore(decoded, into: destination.mainContext), 1)
        XCTAssertEqual(try destination.mainContext.fetch(FetchDescriptor<DailyPlanCheckIn>()).first?.energy, 2)
        XCTAssertEqual(UserDefaults.standard.double(forKey: "planLastAdjustmentTimestamp"), 1_783_890_000)

        let legacy = #"{"version":1,"exportedAt":"2026-07-12T12:00:00Z","meals":[],"measurements":[],"activities":[],"workouts":[],"messages":[]}"#
        let legacyBackup = try BackupService.decode(Data(legacy.utf8))
        XCTAssertTrue(legacyBackup.checkIns.isEmpty)
        XCTAssertNil(legacyBackup.planSettings)
    }

    private func adaptiveWeights(slope: Double, now: Date, calendar: Calendar) -> [AdaptiveWeightPoint] {
        [-12, -8, -4, 0].map { offset in
            AdaptiveWeightPoint(
                date: calendar.date(byAdding: .day, value: offset, to: now)!,
                weight: 80 + slope * Double(offset) / 7
            )
        }
    }
}
