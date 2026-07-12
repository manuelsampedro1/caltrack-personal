import XCTest

final class CaltrackUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testMainPhotoFlowAndSettingsAreReachable() {
        let app = XCUIApplication()
        app.launchArguments = ["-seed-workouts"]
        app.launch()

        XCTAssertTrue(app.buttons["Fotografiar comida"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["Elegir una foto"].exists)

        app.buttons["Ajustes"].tap()
        XCTAssertTrue(app.navigationBars["Ajustes"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.secureTextFields["xai-…"].exists)
        for _ in 0..<3 where !app.secureTextFields["Clave de API de Hevy"].exists {
            app.swipeUp()
        }
        XCTAssertTrue(app.secureTextFields["Clave de API de Hevy"].waitForExistence(timeout: 3))
        app.buttons["Listo"].tap()

        app.swipeUp()
        XCTAssertTrue(app.buttons["Conectar Salud"].waitForExistence(timeout: 3))
        for _ in 0..<4 where !app.staticTexts["Entrenamientos"].exists {
            app.swipeUp()
        }
        XCTAssertTrue(app.staticTexts["Entrenamientos"].waitForExistence(timeout: 3))
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Caltrack workouts card"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
