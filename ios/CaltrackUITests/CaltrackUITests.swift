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
        let reminder = app.switches["Recordatorio diario"]
        for _ in 0..<8 where !reminder.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(reminder.isHittable)
        for _ in 0..<8 where !app.buttons["Exportar copia privada"].isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(app.buttons["Exportar copia privada"].isHittable)
        for _ in 0..<3 where !app.buttons["Restaurar o fusionar copia"].exists {
            app.swipeUp()
        }
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
        app.textFields["Fibra opcional"].tap()
        app.textFields["Fibra opcional"].typeText("12")
        app.buttons["Guardar comida"].tap()
        XCTAssertTrue(app.staticTexts["Avena de prueba"].waitForExistence(timeout: 4))
        let fiberProgress = app.descendants(matching: .any)["todayFiberProgress"]
        for _ in 0..<4 where !fiberProgress.isHittable { app.swipeUp() }
        XCTAssertTrue(fiberProgress.waitForExistence(timeout: 4))
        XCTAssertTrue(fiberProgress.value as? String == "31 de 25 g")
        let fiberTodayScreenshot = XCTAttachment(screenshot: app.screenshot())
        fiberTodayScreenshot.name = "Caltrack daily fiber progress"
        fiberTodayScreenshot.lifetime = .keepAlways
        add(fiberTodayScreenshot)

        app.tabBars.buttons["Progreso"].tap()
        XCTAssertTrue(app.navigationBars["Progreso"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["Últimos 14 días"].exists)
        XCTAssertTrue(app.buttons["Fibra"].exists)
        app.buttons["Fibra"].tap()
        XCTAssertTrue(app.staticTexts["Fibra disponible en 43 de 43 comidas"].waitForExistence(timeout: 4))
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

    func testDetectedMealComponentsCanBeCorrectedAndPersisted() {
        let app = XCUIApplication()
        app.launchArguments = ["-seed-superapp", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryL"]
        app.launch()

        let options = app.buttons["Opciones de Pollo con arroz"].firstMatch
        for _ in 0..<6 where !options.isHittable { app.swipeUp() }
        XCTAssertTrue(options.waitForExistence(timeout: 5))
        options.tap()
        app.buttons["Editar"].tap()

        XCTAssertTrue(app.navigationBars["Editar comida"].waitForExistence(timeout: 4))
        app.staticTexts["Componentes del plato"].tap()
        let chickenCalories = app.textFields["mealComponentCalories-00000000-0000-0000-0000-000000000101"]
        XCTAssertTrue(chickenCalories.waitForExistence(timeout: 4))
        replaceText(in: chickenCalories, with: "400")

        app.staticTexts["Componentes del plato"].tap()
        app.staticTexts["Componentes del plato"].tap()
        XCTAssertEqual(chickenCalories.value as? String, "400")
        let editorScreenshot = XCTAttachment(screenshot: app.screenshot())
        editorScreenshot.name = "Caltrack editable meal components"
        editorScreenshot.lifetime = .keepAlways
        add(editorScreenshot)

        app.staticTexts["Componentes del plato"].tap()
        let totalCalories = app.textFields["Kcal"]
        for _ in 0..<4 where !totalCalories.isHittable { app.swipeUp() }
        XCTAssertTrue(totalCalories.waitForExistence(timeout: 4))
        XCTAssertEqual(totalCalories.value as? String, "790")
        app.buttons["Guardar comida"].tap()
        XCTAssertTrue(app.staticTexts["790 kcal"].waitForExistence(timeout: 5))

        let editedOptions = app.buttons["Opciones de Pollo con arroz"].firstMatch
        XCTAssertTrue(editedOptions.waitForExistence(timeout: 4))
        editedOptions.tap()
        app.buttons["Editar"].tap()
        app.staticTexts["Componentes del plato"].tap()
        XCTAssertEqual(app.textFields["mealComponentCalories-00000000-0000-0000-0000-000000000101"].value as? String, "400")

        let componentNames = app.textFields.matching(NSPredicate(format: "identifier BEGINSWITH 'mealComponentName-'"))
        XCTAssertEqual(componentNames.count, 3)
        let addComponent = app.buttons["addMealComponent"]
        for _ in 0..<6 where !addComponent.isHittable { app.swipeUp() }
        XCTAssertTrue(addComponent.isHittable)
        addComponent.tap()
        XCTAssertEqual(componentNames.count, 4)
        let deleteButtons = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'deleteMealComponent-'"))
        deleteButtons.element(boundBy: 3).tap()
        XCTAssertEqual(componentNames.count, 3)
        for _ in 0..<6 { app.swipeDown() }
        for _ in 0..<3 { deleteButtons.firstMatch.tap() }
        XCTAssertTrue(app.staticTexts["Sin componentes"].waitForExistence(timeout: 3))
        let emptyScreenshot = XCTAttachment(screenshot: app.screenshot())
        emptyScreenshot.name = "Caltrack empty meal components"
        emptyScreenshot.lifetime = .keepAlways
        add(emptyScreenshot)
    }

    func testPhotoAnalysisFixtureShowsEditableBreakdownWithoutAPI() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-preview-meal-analysis",
            "-grok-analysis-fixture",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryL"
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["ESTIMACIÓN DE GROK"].waitForExistence(timeout: 6))
        XCTAssertTrue(app.staticTexts["4 componentes detectados"].exists)
        XCTAssertTrue(app.staticTexts["4 componentes · 810 kcal · 67 g P · 9 g F"].exists)
        let componentNames = app.textFields.matching(NSPredicate(format: "identifier BEGINSWITH 'mealComponentName-'"))
        XCTAssertEqual(componentNames.count, 4)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Caltrack Grok photo precision review"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        let save = app.buttons["Guardar en el día"]
        for _ in 0..<8 where !save.isHittable { app.swipeUp() }
        XCTAssertTrue(save.waitForExistence(timeout: 4))
        XCTAssertTrue(save.isEnabled)
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

    func testBarcodeProductCanBeConfirmedWithoutCameraOrNetwork() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-seed-superapp",
            "-barcode-fixture",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryL"
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["Comidas frecuentes"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["Código"].waitForExistence(timeout: 6))
        app.buttons["Código"].tap()
        let field = app.textFields["barcodeField"]
        XCTAssertTrue(field.waitForExistence(timeout: 4))
        field.tap()
        field.typeText("3017620422003")
        app.buttons["Buscar producto"].tap()

        XCTAssertTrue(app.staticTexts["Nutella"].waitForExistence(timeout: 4))
        XCTAssertEqual(app.textFields["barcodeAmountField"].value as? String, "15")
        XCTAssertFalse((app.textFields["barcodeCaloriesField"].value as? String ?? "").isEmpty)
        XCTAssertFalse((app.textFields["barcodeFiberField"].value as? String ?? "").isEmpty)
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Caltrack barcode confirmation"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        app.buttons["Guardar producto"].tap()
        XCTAssertTrue(app.staticTexts["Nutella · Ferrero"].waitForExistence(timeout: 4))
    }

    func testBodyCheckInCanBeSavedAndEditedAtAccessibilityTextSize() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-seed-superapp",
            "-body-photo-fixture",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityExtraLarge"
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["Comidas frecuentes"].waitForExistence(timeout: 8))
        app.tabBars.buttons["Progreso"].tap()
        let addButton = app.buttons["addBodyCheckIn"]
        for _ in 0..<6 where !addButton.isHittable { app.swipeUp() }
        XCTAssertTrue(addButton.waitForExistence(timeout: 4))
        addButton.tap()

        let weight = app.textFields["checkInWeight"]
        XCTAssertTrue(weight.waitForExistence(timeout: 4))
        let formScreenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        formScreenshot.name = "Caltrack body check-in form"
        formScreenshot.lifetime = .keepAlways
        add(formScreenshot)
        weight.tap()
        weight.typeText("78.9")
        app.buttons["saveBodyCheckIn"].tap()

        let value = app.staticTexts["manualCheckInValue"]
        XCTAssertTrue(value.waitForExistence(timeout: 5))
        XCTAssertTrue(value.label.contains("78"))
        app.buttons["Opciones del check-in"].tap()
        app.buttons["Editar"].tap()

        let waist = app.textFields["checkInWaist"]
        XCTAssertTrue(waist.waitForExistence(timeout: 4))
        waist.tap()
        waist.typeText("80.5")
        app.buttons["saveBodyCheckIn"].tap()
        XCTAssertTrue(app.staticTexts["manualCheckInValue"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["manualCheckInValue"].label.contains("80"))

        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Caltrack body check-in"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        let photo = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Foto de progreso del'")).firstMatch
        for _ in 0..<3 where !photo.isHittable { app.swipeUp() }
        XCTAssertTrue(photo.waitForExistence(timeout: 4))
        photo.tap()
        XCTAssertTrue(app.images["Foto de progreso ampliable"].waitForExistence(timeout: 4))
        let viewerScreenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        viewerScreenshot.name = "Caltrack progress photo viewer"
        viewerScreenshot.lifetime = .keepAlways
        add(viewerScreenshot)
        app.buttons["Cerrar"].tap()
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
        XCTAssertTrue(app.buttons["Código"].exists)
        XCTAssertTrue(app.buttons["Manual"].exists)
        XCTAssertTrue(app.tabBars.buttons["Progreso"].exists)
    }

    func testWidgetGalleryRendersHomeLockEmptyAndPrivateStates() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-preview-widgets",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryL"
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["Widgets de Caltrack"].waitForExistence(timeout: 8))
        let gallery = app.scrollViews.firstMatch
        XCTAssertTrue(app.otherElements["widgetPreviewSmall"].exists)
        XCTAssertTrue(app.otherElements["widgetPreviewEmpty"].exists)
        XCTAssertTrue(app.otherElements["widgetPreviewMedium"].exists)
        XCTAssertTrue(app.otherElements["widgetPreviewRectangular"].exists)
        XCTAssertTrue(app.otherElements["widgetPreviewCircular"].exists)
        XCTAssertTrue(app.otherElements["widgetPreviewInline"].exists)
        let home = XCTAttachment(screenshot: app.screenshot())
        home.name = "Caltrack home and Lock Screen widgets"
        home.lifetime = .keepAlways
        add(home)

        gallery.swipeUp()
        let privateWidget = app.otherElements["widgetPreviewPrivate"]
        XCTAssertTrue(privateWidget.waitForExistence(timeout: 4))
        let privacy = XCTAttachment(screenshot: app.screenshot())
        privacy.name = "Caltrack private widget redaction"
        privacy.lifetime = .keepAlways
        add(privacy)
    }

    func testQuickActionsOpenBarcodeAndBodyCheckInDestinations() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-seed-superapp",
            "-barcode-fixture",
            "-quick-action",
            "barcode",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryL"
        ]
        app.launch()

        XCTAssertTrue(app.textFields["barcodeField"].waitForExistence(timeout: 8))

        app.terminate()
        app.launchArguments = [
            "-seed-superapp",
            "-quick-action",
            "bodyCheckIn",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryL"
        ]
        app.launch()

        XCTAssertTrue(app.textFields["checkInWeight"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.navigationBars["Nuevo check-in"].exists)
    }

    func testSystemShortcutsAreDiscoverableInSettings() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-seed-superapp",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryL"
        ]
        app.launch()

        XCTAssertTrue(app.buttons["Ajustes"].waitForExistence(timeout: 8))
        app.buttons["Ajustes"].tap()

        let shortcutsLink = app.buttons["openSystemShortcuts"]
        for _ in 0..<12 where !shortcutsLink.isHittable { app.swipeUp() }
        XCTAssertTrue(shortcutsLink.waitForExistence(timeout: 4))
        XCTAssertTrue(shortcutsLink.isHittable)
        XCTAssertTrue(app.staticTexts["Fotografiar comida"].exists)
        XCTAssertTrue(app.staticTexts["Escanear producto"].exists)
        XCTAssertTrue(app.staticTexts["Nuevo check-in"].exists)
        XCTAssertTrue(app.staticTexts["Abrir progreso"].exists)

        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Caltrack App Shortcuts"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testRecoveryTrendsAreVisibleWithoutOpaqueScore() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-seed-superapp",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryL"
        ]
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Progreso"].waitForExistence(timeout: 8))
        app.tabBars.buttons["Progreso"].tap()
        let card = app.otherElements["recoveryCard"]
        for _ in 0..<6 where !card.isHittable { app.swipeUp() }
        XCTAssertTrue(card.waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["Recuperación"].exists)
        XCTAssertTrue(app.buttons["Sueño"].exists)
        XCTAssertTrue(app.buttons["FC reposo"].exists)
        XCTAssertTrue(app.buttons["HRV"].exists)
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'readiness score'")).firstMatch.exists)

        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Caltrack recovery trends"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    private func replaceText(in field: XCUIElement, with value: String) {
        field.tap()
        let current = field.value as? String ?? ""
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
        field.typeText(value)
    }

    func testAdaptivePlanClosesDayAndAppliesOnlyAfterConfirmation() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-seed-superapp",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryL"
        ]
        app.launch()

        XCTAssertTrue(app.buttons["Fotografiar comida"].waitForExistence(timeout: 8))
        let dailyCheckIn = app.buttons["dailyPlanCheckIn"]
        for _ in 0..<8 where !dailyCheckIn.isHittable { app.swipeUp() }
        XCTAssertTrue(dailyCheckIn.waitForExistence(timeout: 4))
        dailyCheckIn.tap()

        let dailySheet = app.navigationBars["Cierre del día"]
        XCTAssertTrue(dailySheet.waitForExistence(timeout: 4))
        let dailyScreenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        dailyScreenshot.name = "Caltrack daily close"
        dailyScreenshot.lifetime = .keepAlways
        add(dailyScreenshot)
        XCTAssertTrue(app.buttons["reopenDailyCheckIn"].exists)
        app.buttons["reopenDailyCheckIn"].tap()

        XCTAssertTrue(dailyCheckIn.waitForExistence(timeout: 4))
        dailyCheckIn.tap()
        XCTAssertTrue(app.buttons["hunger5"].waitForExistence(timeout: 4))
        app.buttons["hunger5"].tap()
        app.buttons["energy2"].tap()
        app.buttons["saveDailyCheckIn"].tap()
        XCTAssertTrue(app.staticTexts["Hambre 5/5 · Energía 2/5"].waitForExistence(timeout: 4))

        let stableTitle = app.staticTexts["Mantén el rango"]
        for _ in 0..<4 where !stableTitle.isHittable { app.swipeUp() }
        XCTAssertTrue(stableTitle.waitForExistence(timeout: 4))
        XCTAssertTrue(stableTitle.isHittable)
        let configure = app.buttons["configureAdaptivePlan"]
        for _ in 0..<3 where !configure.isHittable { app.swipeUp() }
        XCTAssertTrue(configure.waitForExistence(timeout: 4))
        XCTAssertTrue(configure.isHittable)
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Caltrack adaptive weekly plan"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        configure.tap()
        XCTAssertTrue(app.navigationBars["Plan adaptativo"].waitForExistence(timeout: 4))
        let settingsScreenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        settingsScreenshot.name = "Caltrack adaptive plan settings"
        settingsScreenshot.lifetime = .keepAlways
        add(settingsScreenshot)
        app.buttons["Mantener"].tap()
        app.buttons["savePlanSettings"].tap()

        XCTAssertTrue(app.staticTexts["Propuesta para esta semana"].waitForExistence(timeout: 4))
        app.buttons["applyAdaptivePlan"].tap()
        XCTAssertTrue(app.alerts["Aplicar nuevo rango"].waitForExistence(timeout: 3))
        app.alerts["Aplicar nuevo rango"].buttons["Aplicar"].tap()
        XCTAssertTrue(app.staticTexts["Deja actuar el último cambio"].waitForExistence(timeout: 4))
    }
}
