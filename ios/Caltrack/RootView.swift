import SwiftUI

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var selection = 0
    @State private var showingOnboarding = false

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
        .onAppear {
            let arguments = ProcessInfo.processInfo.arguments
            if arguments.contains("-force-onboarding") {
                showingOnboarding = true
                return
            }
            let testing = arguments.contains("-seed-superapp") || arguments.contains("-seed-workouts") || arguments.contains("-skip-onboarding")
            showingOnboarding = !hasCompletedOnboarding && !testing
        }
        .onChange(of: hasCompletedOnboarding) { _, completed in
            if !completed { showingOnboarding = true }
        }
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingView {
                hasCompletedOnboarding = true
                showingOnboarding = false
            }
        }
    }
}
