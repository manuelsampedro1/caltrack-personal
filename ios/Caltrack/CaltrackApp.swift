import SwiftData
import SwiftUI

@main
struct CaltrackApp: App {
    private let container: ModelContainer = {
        let schema = Schema([MealEntry.self, BodyMeasurement.self, ActivityDay.self, RecoveryDay.self, DailyPlanCheckIn.self, WorkoutEntry.self, CoachMessage.self])
        if let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            try? FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        }
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("No se pudo abrir la base local: \(error.localizedDescription)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(container)
    }
}
