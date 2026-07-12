import AppIntents

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
