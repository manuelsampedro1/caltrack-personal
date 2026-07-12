import XCTest

final class CaltrackUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testMainPhotoFlowAndSettingsAreReachable() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.buttons["Fotografiar comida"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["Elegir una foto"].exists)

        app.buttons["Ajustes"].tap()
        XCTAssertTrue(app.navigationBars["Ajustes"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.secureTextFields["xai-…"].exists)
        app.buttons["Listo"].tap()

        app.swipeUp()
        XCTAssertTrue(app.buttons["Conectar Salud"].waitForExistence(timeout: 3))
    }
}
