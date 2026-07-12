import XCTest

final class CaltrackUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testMainPhotoFlowAndSettingsAreReachable() {
        let app = XCUIApplication()
        let liveHevyKey = ProcessInfo.processInfo.environment["CALTRACK_TEST_HEVY_KEY"]
        if liveHevyKey == nil { app.launchArguments = ["-seed-workouts"] }
        app.launch()

        XCTAssertTrue(app.buttons["Conectar Salud"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["Fotografiar comida"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["Elegir una foto"].exists)

        let homeScreenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        homeScreenshot.name = "Caltrack connections and photo"
        homeScreenshot.lifetime = .keepAlways
        add(homeScreenshot)

        app.buttons["Ajustes"].tap()
        XCTAssertTrue(app.navigationBars["Ajustes"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.secureTextFields["Clave de xAI"].exists)
        for _ in 0..<3 where !app.secureTextFields["Clave de API de Hevy"].exists {
            app.swipeUp()
        }
        let hevyField = app.secureTextFields["Clave de API de Hevy"]
        XCTAssertTrue(hevyField.waitForExistence(timeout: 3))
        if let liveHevyKey {
            hevyField.tap()
            hevyField.typeText(liveHevyKey)
            app.buttons["Validar y conectar Hevy"].tap()
            let connected = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Conectado.'")).firstMatch
            XCTAssertTrue(connected.waitForExistence(timeout: 15))
        }
        app.buttons["Listo"].tap()

        for _ in 0..<6 where !app.staticTexts["Entrenamientos"].isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(app.staticTexts["Entrenamientos"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Entrenamientos"].isHittable)
        Thread.sleep(forTimeInterval: 1)
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Caltrack workouts card"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
