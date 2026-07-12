import AppIntents
import Foundation

enum QuickAction: String, CaseIterable, Sendable {
    case camera
    case barcode
    case bodyCheckIn
    case progress
}

enum QuickActionStore {
    private static let key = "pendingQuickAction"

    static func set(_ action: QuickAction, defaults: UserDefaults = .standard) {
        defaults.set(action.rawValue, forKey: key)
    }

    static func consume(defaults: UserDefaults = .standard) -> QuickAction? {
        guard let rawValue = defaults.string(forKey: key) else { return nil }
        defaults.removeObject(forKey: key)
        return QuickAction(rawValue: rawValue)
    }

    static func fromLaunchArguments(_ arguments: [String]) -> QuickAction? {
        guard let index = arguments.firstIndex(of: "-quick-action"), arguments.indices.contains(index + 1) else { return nil }
        return QuickAction(rawValue: arguments[index + 1])
    }
}

struct CaptureMealIntent: AppIntent {
    static let targetAction: QuickAction = .camera
    static var title: LocalizedStringResource = "Fotografiar comida"
    static var description = IntentDescription("Abre Caltrack directamente en la cámara para registrar una comida.")

    @available(iOS, introduced: 17.0, deprecated: 26.0)
    static var openAppWhenRun: Bool { true }

    @available(iOS 26.0, *)
    static var supportedModes: IntentModes { .foreground(.immediate) }

    func perform() async throws -> some IntentResult {
        QuickActionStore.set(Self.targetAction)
        return .result()
    }
}

struct ScanProductIntent: AppIntent {
    static let targetAction: QuickAction = .barcode
    static var title: LocalizedStringResource = "Escanear producto"
    static var description = IntentDescription("Abre el lector de códigos de Caltrack para registrar un producto envasado.")

    @available(iOS, introduced: 17.0, deprecated: 26.0)
    static var openAppWhenRun: Bool { true }

    @available(iOS 26.0, *)
    static var supportedModes: IntentModes { .foreground(.immediate) }

    func perform() async throws -> some IntentResult {
        QuickActionStore.set(Self.targetAction)
        return .result()
    }
}

struct NewBodyCheckInIntent: AppIntent {
    static let targetAction: QuickAction = .bodyCheckIn
    static var title: LocalizedStringResource = "Nuevo check-in"
    static var description = IntentDescription("Abre un nuevo check-in corporal en Caltrack.")

    @available(iOS, introduced: 17.0, deprecated: 26.0)
    static var openAppWhenRun: Bool { true }

    @available(iOS 26.0, *)
    static var supportedModes: IntentModes { .foreground(.immediate) }

    func perform() async throws -> some IntentResult {
        QuickActionStore.set(Self.targetAction)
        return .result()
    }
}

struct OpenProgressIntent: AppIntent {
    static let targetAction: QuickAction = .progress
    static var title: LocalizedStringResource = "Abrir progreso"
    static var description = IntentDescription("Abre las tendencias de nutrición, cuerpo y entrenamiento en Caltrack.")

    @available(iOS, introduced: 17.0, deprecated: 26.0)
    static var openAppWhenRun: Bool { true }

    @available(iOS 26.0, *)
    static var supportedModes: IntentModes { .foreground(.immediate) }

    func perform() async throws -> some IntentResult {
        QuickActionStore.set(Self.targetAction)
        return .result()
    }
}

struct CaltrackShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CaptureMealIntent(),
            phrases: [
                "Fotografiar comida con \(.applicationName)",
                "Registrar una comida con \(.applicationName)"
            ],
            shortTitle: "Fotografiar comida",
            systemImageName: "camera.fill"
        )
        AppShortcut(
            intent: ScanProductIntent(),
            phrases: [
                "Escanear producto con \(.applicationName)",
                "Abrir código en \(.applicationName)"
            ],
            shortTitle: "Escanear producto",
            systemImageName: "barcode.viewfinder"
        )
        AppShortcut(
            intent: NewBodyCheckInIntent(),
            phrases: [
                "Nuevo check-in en \(.applicationName)",
                "Registrar peso en \(.applicationName)"
            ],
            shortTitle: "Nuevo check-in",
            systemImageName: "scalemass.fill"
        )
        AppShortcut(
            intent: OpenProgressIntent(),
            phrases: [
                "Ver mi progreso en \(.applicationName)",
                "Abrir progreso en \(.applicationName)"
            ],
            shortTitle: "Abrir progreso",
            systemImageName: "chart.xyaxis.line"
        )
    }

    static var shortcutTileColor: ShortcutTileColor { .lime }
}
