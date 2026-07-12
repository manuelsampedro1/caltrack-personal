import XCTest
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
}
