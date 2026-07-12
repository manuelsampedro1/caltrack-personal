import SwiftUI

struct RootView: View {
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            DashboardView()
                .tag(0)
                .tabItem { Label("Hoy", systemImage: "sun.max.fill") }

            ProgressDashboardView()
                .tag(1)
                .tabItem { Label("Progreso", systemImage: "chart.xyaxis.line") }

            CoachView()
                .tag(2)
                .tabItem { Label("Entrenador", systemImage: "sparkles") }
        }
        .tint(CaltrackTheme.green)
        .toolbarBackground(CaltrackTheme.canvas.opacity(0.96), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
