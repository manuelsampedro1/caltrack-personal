import Combine
import SwiftUI

struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var selection = 0
    @State private var showingOnboarding = false
    @State private var queuedQuickAction: QuickAction?
    @State private var dashboardRequest: DashboardRequest?
    @State private var progressRequest: ProgressRequest?
    @State private var readLaunchAction = false

    var body: some View {
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-preview-widgets") {
            WidgetPreviewGallery()
        } else if ProcessInfo.processInfo.arguments.contains("-preview-meal-analysis") {
            MealAnalysisSheet(image: MealAnalysisFixture.image) { _, _ in }
        } else {
            mainContent
        }
#else
        mainContent
#endif
    }

    private var mainContent: some View {
        TabView(selection: $selection) {
            DashboardView(requestedAction: $dashboardRequest)
                .tag(0)
                .tabItem { Label("Hoy", systemImage: "sun.max.fill") }

            ProgressDashboardView(requestedAction: $progressRequest)
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
            captureQuickAction()
        }
        .onChange(of: hasCompletedOnboarding) { _, completed in
            if !completed { showingOnboarding = true }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { captureQuickAction() }
        }
        .onReceive(
            NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
                .receive(on: RunLoop.main)
        ) { _ in
            captureQuickAction()
        }
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingView {
                hasCompletedOnboarding = true
                showingOnboarding = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { routeQuickActionIfPossible() }
            }
        }
    }

    private func captureQuickAction() {
        if !readLaunchAction {
            queuedQuickAction = QuickActionStore.fromLaunchArguments(ProcessInfo.processInfo.arguments) ?? queuedQuickAction
            readLaunchAction = true
        }
        if let pending = QuickActionStore.consume() { queuedQuickAction = pending }
        routeQuickActionIfPossible()
    }

    private func routeQuickActionIfPossible() {
        guard !showingOnboarding, let action = queuedQuickAction else { return }
        queuedQuickAction = nil
        switch action {
        case .camera:
            selection = 0
            dashboardRequest = .camera
        case .barcode:
            selection = 0
            dashboardRequest = .barcode
        case .bodyCheckIn:
            selection = 1
            progressRequest = .bodyCheckIn
        case .progress:
            selection = 1
        }
    }
}
