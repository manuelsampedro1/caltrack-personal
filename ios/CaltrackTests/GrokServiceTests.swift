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
}
