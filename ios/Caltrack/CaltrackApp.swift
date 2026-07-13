import SwiftData
import SwiftUI

@main
struct CaltrackApp: App {
    private let persistence = PersistenceStore.open()

    var body: some Scene {
        WindowGroup {
            Group {
                switch persistence {
                case .success(let container):
                    RootView()
                        .modelContainer(container)
                case .failure:
                    StorageUnavailableView()
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

enum PersistenceStore {
    static func open(arguments: [String] = ProcessInfo.processInfo.arguments) -> Result<ModelContainer, Error> {
        if arguments.contains("-simulate-storage-failure") {
            return .failure(PersistenceError.simulated)
        }
        let schema = Schema([MealEntry.self, BodyMeasurement.self, ActivityDay.self, RecoveryDay.self, DailyPlanCheckIn.self, WorkoutEntry.self, CoachMessage.self])
        if let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            try? FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        }
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return .success(try ModelContainer(for: schema, configurations: [configuration]))
        } catch {
            return .failure(error)
        }
    }

    private enum PersistenceError: Error {
        case simulated
    }
}

private struct StorageUnavailableView: View {
    var body: some View {
        ZStack {
            CaltrackTheme.canvas.ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: "externaldrive.badge.exclamationmark")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(CaltrackTheme.coral)
                    .accessibilityHidden(true)
                Text("No podemos abrir tus datos")
                    .font(.title2.bold())
                Text("Tus registros siguen en el iPhone. Cierra Caltrack y vuelve a abrirla. Si continúa, contacta con soporte antes de reinstalar.")
                    .font(.subheadline)
                    .foregroundStyle(CaltrackTheme.muted)
                    .multilineTextAlignment(.center)
                Link(destination: CaltrackLinks.support) {
                    Label("Abrir soporte", systemImage: "lifepreserver.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .foregroundStyle(.black)
                        .background(CaltrackTheme.green, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                Link("Política de privacidad", destination: CaltrackLinks.privacy)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CaltrackTheme.green)
            }
            .padding(24)
            .frame(maxWidth: 480)
        }
    }
}
