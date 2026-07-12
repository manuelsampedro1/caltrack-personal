import XCTest

final class CaltrackUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testMainPhotoFlowAndSettingsAreReachable() {
        let app = XCUIApplication()
        let liveHevyKey = ProcessInfo.processInfo.environment["CALTRACK_TEST_HEVY_KEY"]
        app.launchArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryL"]
        if liveHevyKey == nil { app.launchArguments.append("-seed-superapp") }
        app.launch()

        XCTAssertTrue(app.buttons["Conectar Salud"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["Fotografiar comida"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["Fototeca"].exists)
        XCTAssertTrue(app.buttons["Manual"].exists)
        XCTAssertTrue(app.tabBars.buttons["Hoy"].exists)
        XCTAssertTrue(app.tabBars.buttons["Progreso"].exists)
        XCTAssertTrue(app.tabBars.buttons["Entrenador"].exists)

        let homeScreenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        homeScreenshot.name = "Caltrack connections and photo"
        homeScreenshot.lifetime = .keepAlways
        add(homeScreenshot)

        app.buttons["Ajustes"].tap()
        XCTAssertTrue(app.navigationBars["Ajustes"].waitForExistence(timeout: 3))
        let healthSettingsScreenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        healthSettingsScreenshot.name = "Caltrack Health nutrition settings"
        healthSettingsScreenshot.lifetime = .keepAlways
        add(healthSettingsScreenshot)
        for _ in 0..<4 where !app.secureTextFields["Clave de xAI"].isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(app.secureTextFields["Clave de xAI"].waitForExistence(timeout: 3))
        for _ in 0..<4 where !app.secureTextFields["Clave de API de Hevy"].isHittable {
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
        for _ in 0..<8 where !app.buttons["Exportar copia privada"].isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(app.switches["Recordatorio diario"].exists)
        XCTAssertTrue(app.buttons["Exportar copia privada"].isHittable)
        XCTAssertTrue(app.buttons["Restaurar o fusionar copia"].exists)
        app.buttons["Listo"].tap()

        let dashboardScroll = app.scrollViews.firstMatch
        for _ in 0..<6 where !app.staticTexts["Entrenamientos"].isHittable {
            dashboardScroll.swipeUp()
        }
        XCTAssertTrue(app.staticTexts["Entrenamientos"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Entrenamientos"].isHittable)
        Thread.sleep(forTimeInterval: 1)
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Caltrack workouts card"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testManualEntryProgressAndCoachTabs() {
        let app = XCUIApplication()
        app.launchArguments = ["-seed-superapp", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryL"]
        app.launch()

        XCTAssertTrue(app.buttons["Manual"].waitForExistence(timeout: 8))
        app.buttons["Manual"].tap()
        XCTAssertTrue(app.navigationBars["Registrar manualmente"].waitForExistence(timeout: 3))
        app.textFields["Nombre"].tap()
        app.textFields["Nombre"].typeText("Avena de prueba")
        app.textFields["Kcal"].tap()
        app.textFields["Kcal"].typeText("520")
        app.textFields["Proteína"].tap()
        app.textFields["Proteína"].typeText("38")
        app.buttons["Guardar comida"].tap()
        XCTAssertTrue(app.staticTexts["Avena de prueba"].waitForExistence(timeout: 4))

        app.tabBars.buttons["Progreso"].tap()
        XCTAssertTrue(app.navigationBars["Progreso"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["Últimos 14 días"].exists)
        let progressScreenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        progressScreenshot.name = "Caltrack progress"
        progressScreenshot.lifetime = .keepAlways
        add(progressScreenshot)
        for _ in 0..<4 where !app.staticTexts["Ingesta y gasto"].isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(app.staticTexts["Ingesta y gasto"].isHittable)
        let balanceScreenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        balanceScreenshot.name = "Caltrack energy balance"
        balanceScreenshot.lifetime = .keepAlways
        add(balanceScreenshot)

        app.tabBars.buttons["Entrenador"].tap()
        XCTAssertTrue(app.navigationBars["Entrenador"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["ANÁLISIS LOCAL"].exists)
        for _ in 0..<3 where !app.staticTexts["Profundiza en tus datos"].isHittable { app.swipeUp() }
        XCTAssertTrue(app.staticTexts["Profundiza en tus datos"].waitForExistence(timeout: 3))
        let coachScreenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        coachScreenshot.name = "Caltrack coach"
        coachScreenshot.lifetime = .keepAlways
        add(coachScreenshot)
    }

    func testFrequentMealsAndSearch() {
        let app = XCUIApplication()
        app.launchArguments = ["-seed-superapp", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryL"]
        app.launch()

        let repeatButton = app.buttons["Repetir Pollo con arroz"]
        for _ in 0..<3 where !repeatButton.isHittable { app.swipeUp() }
        XCTAssertTrue(repeatButton.waitForExistence(timeout: 4))
        let frequentScreenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        frequentScreenshot.name = "Caltrack frequent meals"
        frequentScreenshot.lifetime = .keepAlways
        add(frequentScreenshot)
        repeatButton.tap()

        app.tabBars.buttons["Progreso"].tap()
        let search = app.searchFields["Buscar comidas"]
        XCTAssertTrue(search.waitForExistence(timeout: 4))
        search.tap()
        search.typeText("Salmón")
        XCTAssertTrue(app.staticTexts["Salmón y verduras"].waitForExistence(timeout: 4))
    }

    func testOnboardingCanBeSkipped() {
        let app = XCUIApplication()
        app.launchArguments = ["-force-onboarding", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryL"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Tu dieta, cuerpo y entrenamiento, sin ruido"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Empezar"].exists)
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Caltrack onboarding"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        app.buttons["Omitir introducción"].tap()
        XCTAssertTrue(app.tabBars.buttons["Hoy"].waitForExistence(timeout: 4))
    }

    func testCriticalActionsAtAccessibilityTextSize() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-seed-superapp",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityExtraExtraLarge"
        ]
        app.launch()

        XCTAssertTrue(app.buttons["Fotografiar comida"].waitForExistence(timeout: 6))
        XCTAssertTrue(app.buttons["Fototeca"].exists)
        XCTAssertTrue(app.buttons["Manual"].exists)
        XCTAssertTrue(app.tabBars.buttons["Progreso"].exists)
    }
}
