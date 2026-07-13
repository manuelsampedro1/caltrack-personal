import Charts
import PhotosUI
import SwiftData
import SwiftUI
import UIKit
import WidgetKit

private enum CaptureFlow: String, Identifiable {
    case camera
    case barcode

    var id: String { rawValue }
}

enum DashboardRequest: Equatable {
    case camera
    case barcode
}

@MainActor
struct DashboardView: View {
    @Binding var requestedAction: DashboardRequest?
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MealEntry.date, order: .reverse) private var meals: [MealEntry]
    @Query(sort: \BodyMeasurement.date, order: .reverse) private var measurements: [BodyMeasurement]
    @Query(sort: \ActivityDay.date, order: .reverse) private var activityDays: [ActivityDay]
    @Query(sort: \RecoveryDay.date, order: .reverse) private var recoveryDays: [RecoveryDay]
    @Query(sort: \DailyPlanCheckIn.date, order: .reverse) private var planCheckIns: [DailyPlanCheckIn]
    @Query(sort: \WorkoutEntry.startDate, order: .reverse) private var workouts: [WorkoutEntry]
    @AppStorage("calorieMin") private var calorieMin = 1_800.0
    @AppStorage("calorieMax") private var calorieMax = 2_000.0
    @AppStorage("proteinMin") private var proteinMin = 160.0
    @AppStorage("proteinMax") private var proteinMax = 190.0
    @AppStorage("fiberTarget") private var fiberTarget = 25.0
    @AppStorage("healthConnected") private var healthConnected = false
    @AppStorage("hevyConnected") private var hevyConnected = false
    @AppStorage("hevyBackfillCompleted") private var hevyBackfillCompleted = false
    @AppStorage("grokConnected") private var grokConnected = false
    @AppStorage("healthNutritionEnabled") private var healthNutritionEnabled = false
    @AppStorage("planGoalMode") private var planGoalModeRaw = PlanGoalMode.notSet.rawValue
    @AppStorage("planWeeklyRate") private var planWeeklyRate = 0.5
    @AppStorage("planTargetWeight") private var planTargetWeight = 0.0
    @AppStorage("planLastAdjustmentTimestamp") private var planLastAdjustmentTimestamp = 0.0

    @State private var health = HealthKitService()
    @State private var selectedImage: UIImage?
    @State private var photoItem: PhotosPickerItem?
    @State private var captureFlow: CaptureFlow?
    @State private var showingSettings = false
    @State private var showingAnalysis = false
    @State private var showingManualEntry = false
    @State private var editingMeal: MealEntry?
    @State private var healthMessage: String?
    @State private var workoutMessage: String?
    @State private var workoutSyncing = false
    @State private var showingDailyCheckIn = false
    @State private var showingPlanSettings = false
    @State private var showingPlanAdjustmentConfirmation = false

    private var todayMeals: [MealEntry] {
        meals.filter { Calendar.current.isDateInToday($0.date) }
    }

    private var todayTotals: (calories: Double, protein: Double) {
        CaltrackMath.totals(for: todayMeals)
    }

    private var todayFiber: FiberSummary {
        CaltrackMath.fiberSummary(for: todayMeals)
    }

    private var frequentMeals: [FrequentMeal] {
        FoodLibrary.frequentMeals(meals: meals)
    }

    private var todayPlanCheckIn: DailyPlanCheckIn? {
        planCheckIns.first { Calendar.current.isDateInToday($0.date) }
    }

    private var planGoalMode: PlanGoalMode {
        PlanGoalMode(rawValue: planGoalModeRaw) ?? .notSet
    }

    private var adaptivePlanReview: AdaptivePlanReview {
        AdaptivePlanEngine.review(
            days: adaptivePlanDays(),
            weights: measurements.compactMap { measurement in
                measurement.weight.map { AdaptiveWeightPoint(date: measurement.date, weight: $0) }
            },
            mode: planGoalMode,
            weeklyRate: planWeeklyRate,
            calorieRange: CaltrackMath.orderedRange(calorieMin, calorieMax),
            lastAdjustmentDate: planLastAdjustmentTimestamp > 0 ? Date(timeIntervalSince1970: planLastAdjustmentTimestamp) : nil
        )
    }

    private var widgetSnapshot: WidgetSnapshot {
        let calories = CaltrackMath.orderedRange(calorieMin, calorieMax)
        return WidgetSnapshot(
            day: Calendar.current.startOfDay(for: .now),
            generatedAt: .now,
            calories: todayTotals.calories,
            protein: todayTotals.protein,
            fiber: todayFiber.hasData ? todayFiber.value : nil,
            calorieMin: calories.lowerBound,
            calorieMax: calories.upperBound,
            proteinMin: min(proteinMin, proteinMax),
            fiberTarget: fiberTarget,
            mealCount: todayMeals.count,
            nutritionComplete: todayPlanCheckIn?.nutritionComplete == true,
            planTitle: adaptivePlanReview.title
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CaltrackTheme.canvas.ignoresSafeArea()
                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, 14)
                        .padding(.bottom, 10)
                        .background(CaltrackTheme.canvas)
                        .zIndex(1)
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            connectionCard
                            captureCard
                            if !frequentMeals.isEmpty { frequentMealsCard }
                            todayCard
                            adaptivePlanCard
                            workoutCard
                            weeklyCard
                            coachCard
                        }
                        .padding(.horizontal, 14)
                        .padding(.bottom, 34)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(item: $captureFlow) { flow in
                switch flow {
                case .camera:
                    CameraPicker { image in
                        selectedImage = image
                        showingAnalysis = true
                    }
                    .ignoresSafeArea()
                case .barcode:
                    BarcodeLookupSheet { editable in
                        saveMeal(editable, imageData: nil, source: "Open Food Facts")
                    } onManual: {
                        showingManualEntry = true
                    }
                }
            }
            .sheet(isPresented: $showingAnalysis) {
                if let selectedImage {
                    MealAnalysisSheet(image: selectedImage) { editable, imageData in
                        saveMeal(editable, imageData: imageData)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingManualEntry) {
                ManualMealSheet { editable, date in
                    saveMeal(editable, imageData: nil, date: date, source: "manual")
                }
            }
            .sheet(isPresented: $showingDailyCheckIn) {
                DailyPlanCheckInSheet(
                    date: .now,
                    existing: todayPlanCheckIn,
                    save: saveDailyPlanCheckIn,
                    reopen: reopenTodayPlanCheckIn
                )
            }
            .sheet(isPresented: $showingPlanSettings) {
                PlanSettingsSheet(
                    mode: planGoalMode,
                    weeklyRate: planWeeklyRate,
                    targetWeight: planTargetWeight > 0 ? planTargetWeight : nil
                ) { mode, rate, targetWeight in
                    planGoalModeRaw = mode.rawValue
                    planWeeklyRate = rate
                    planTargetWeight = targetWeight ?? 0
                    planLastAdjustmentTimestamp = 0
                }
            }
            .alert("Aplicar nuevo rango", isPresented: $showingPlanAdjustmentConfirmation) {
                Button("Cancelar", role: .cancel) {}
                Button("Aplicar") { applyAdaptivePlanAdjustment() }
            } message: {
                if let proposed = adaptivePlanReview.proposedRange {
                    Text("Tu rango pasará de \(Int(calorieMin)) a \(Int(calorieMax)) kcal, a \(Int(proposed.lowerBound)) a \(Int(proposed.upperBound)) kcal. Podrás editarlo después en Ajustes.")
                }
            }
            .sheet(item: $editingMeal) { meal in
                ManualMealSheet(title: "Editar comida", initial: EditableMeal(meal: meal), date: meal.date) { editable, date in
                    updateMeal(meal, with: editable, date: date)
                }
            }
            .onChange(of: photoItem) { _, item in load(item) }
            .onChange(of: showingSettings) { _, showing in
                guard !showing else { return }
                Task { _ = await syncHevy() }
            }
            .task {
                seedTestingDataIfNeeded()
                if healthConnected {
                    do {
                        try await health.refresh()
                        persistHealthSnapshot()
                        persistHealthActivity()
                        persistHealthRecovery()
                        persistHealthWorkouts()
                    } catch {
                        healthMessage = "No se pudo sincronizar Salud: \(error.localizedDescription)"
                    }
                }
                _ = await syncHevy()
            }
            .task(id: widgetSnapshot) {
                if WidgetSnapshotStore.save(widgetSnapshot) {
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
            .onAppear { handleRequestedAction() }
            .onChange(of: requestedAction) { _, _ in handleRequestedAction() }
        }
    }

    private func handleRequestedAction() {
        guard let requestedAction else { return }
        self.requestedAction = nil
        DispatchQueue.main.async {
            switch requestedAction {
            case .camera: captureFlow = .camera
            case .barcode: captureFlow = .barcode
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    Image(systemName: "fork.knife")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.black)
                        .frame(width: 30, height: 30)
                        .background(CaltrackTheme.green, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                    Text("Caltrack")
                        .font(.title3.weight(.black))
                        .tracking(-0.5)
                }
                Text("\(calorieMin.formatted(.number.precision(.fractionLength(0)))) a \(calorieMax.formatted(.number.precision(.fractionLength(0)))) kcal · \(proteinMin.formatted(.number.precision(.fractionLength(0)))) a \(proteinMax.formatted(.number.precision(.fractionLength(0)))) g proteína")
                    .font(.caption2)
                    .foregroundStyle(CaltrackTheme.muted)
            }
            Spacer()
            Button { showingSettings = true } label: {
                Image(systemName: "gearshape.fill")
                    .font(.subheadline)
                    .frame(width: 38, height: 38)
                    .background(CaltrackTheme.card, in: Circle())
                    .overlay { Circle().stroke(CaltrackTheme.line) }
            }
            .accessibilityLabel("Ajustes")
        }
        .padding(.horizontal, 4)
        .padding(.top, 10)
    }

    private var captureCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                Eyebrow(text: "Registro con Grok Vision")
                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Haz una foto.\nGrok calcula el plato.")
                            .font(.title2.weight(.bold))
                            .tracking(-0.6)
                        Text("Revisa porciones y macros antes de guardarlo.")
                            .font(.subheadline)
                            .foregroundStyle(CaltrackTheme.muted)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "sparkles")
                        .font(.system(size: 33, weight: .medium))
                        .foregroundStyle(CaltrackTheme.green)
                }

                Button {
                    captureFlow = .camera
                } label: {
                    Label("Fotografiar comida", systemImage: "camera.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .foregroundStyle(.black)
                        .background(CaltrackTheme.green, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .sensoryFeedback(.impact(weight: .medium), trigger: captureFlow)

                HStack(spacing: 8) {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label("Fotos", systemImage: "photo.on.rectangle")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(CaltrackTheme.cardRaised, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    }
                    .accessibilityLabel("Fototeca")
                    Button { captureFlow = .barcode } label: {
                        Label("Código", systemImage: "barcode.viewfinder")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(CaltrackTheme.cardRaised, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    }
                    Button { showingManualEntry = true } label: {
                        Label("Manual", systemImage: "square.and.pencil")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(CaltrackTheme.cardRaised, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    }
                }
            }
        }
    }

    private var weeklyCard: some View {
        let days = weeklyDays()
        return Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Eyebrow(text: "Últimos 7 días")
                        Text("Rumbo al objetivo")
                            .font(.title3.weight(.bold))
                    }
                    Spacer()
                    MetricPill(text: "hoy \(Int(todayTotals.calories)) kcal")
                }
                Chart(days) { day in
                    BarMark(x: .value("Día", day.label), y: .value("Calorías", day.calories))
                        .foregroundStyle(day.calories > calorieMax ? CaltrackTheme.coral : CaltrackTheme.green)
                        .cornerRadius(5)
                    RuleMark(y: .value("Objetivo", calorieMax))
                        .foregroundStyle(.white.opacity(0.45))
                        .lineStyle(.init(lineWidth: 1))
                }
                .chartYScale(domain: 0...max(calorieMax * 1.2, days.map(\.calories).max() ?? 1))
                .chartYAxis(.hidden)
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel().foregroundStyle(CaltrackTheme.muted)
                    }
                }
                .frame(height: 150)
            }
        }
    }

    private var frequentMealsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Eyebrow(text: "Un toque")
                        Text("Comidas frecuentes").font(.title3.weight(.bold))
                    }
                    Spacer()
                    Image(systemName: "clock.arrow.circlepath").foregroundStyle(CaltrackTheme.green)
                }
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(frequentMeals) { suggestion in
                            Button { repeatMeal(suggestion) } label: {
                                VStack(alignment: .leading, spacing: 7) {
                                    Text(suggestion.name)
                                        .font(.subheadline.weight(.semibold))
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                    Text("\(Int(suggestion.calories)) kcal · \(Int(suggestion.protein)) g P")
                                        .font(.caption)
                                        .foregroundStyle(CaltrackTheme.muted)
                                    Label("Repetir", systemImage: "plus.circle.fill")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(CaltrackTheme.green)
                                }
                                .padding(12)
                                .frame(width: 180, height: 116, alignment: .topLeading)
                                .background(CaltrackTheme.cardRaised, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Repetir \(suggestion.name)")
                            .accessibilityHint("Añade esta comida al día de hoy")
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private var connectionCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Eyebrow(text: "Conexiones")
                    Spacer()
                    Label("Solo en tu iPhone", systemImage: "lock.fill")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(CaltrackTheme.muted)
                }

                HStack(spacing: 8) {
                    connectionTile(
                    title: "Salud",
                    detail: healthConnectionDetail,
                    icon: "heart.fill",
                    color: .red,
                    action: connectHealth
                    )
                    connectionTile(
                    title: "Hevy",
                    detail: hevyConnected || KeychainStore.read(account: HevyService.apiKeyAccount) != nil ? "Preparado" : "Añadir clave",
                    icon: "dumbbell.fill",
                    color: CaltrackTheme.blue
                    ) { showingSettings = true }
                    connectionTile(
                    title: "Grok",
                    detail: grokConnected || KeychainStore.read(account: GrokService.apiKeyAccount) != nil ? "Preparado" : "Añadir clave",
                    icon: "sparkles",
                    color: CaltrackTheme.green
                    ) { showingSettings = true }
                }

                if let latest = measurements.first(where: { $0.source == "HealthKit" }) ?? measurements.first {
                    HStack(spacing: 8) {
                        healthMetric(latest.weight, suffix: "kg", label: "peso")
                        healthMetric(latest.bodyFat, suffix: "%", label: "grasa")
                        healthMetric(latest.waist, suffix: "cm", label: "cintura")
                    }
                }
                if let healthMessage {
                    Text(healthMessage)
                        .font(.caption)
                        .foregroundStyle(health.state.isFailure ? CaltrackTheme.coral : CaltrackTheme.muted)
                }
            }
        }
    }

    private func connectionTile(title: String, detail: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(color)
                    .frame(width: 30, height: 30)
                    .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                Text(title)
                    .font(.caption.weight(.bold))
                HStack(spacing: 4) {
                    if title == "Salud", health.state == .loading {
                        ProgressView().controlSize(.mini)
                    }
                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(CaltrackTheme.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 84, alignment: .leading)
            .padding(10)
            .background(CaltrackTheme.cardRaised, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title == "Salud" ? (healthConnected ? "Sincronizar Salud" : "Conectar Salud") : title)
        .accessibilityValue(detail)
        .disabled(title == "Salud" && health.state == .loading)
    }

    private var workoutCard: some View {
        let recent = workouts.filter { $0.startDate >= Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .distantPast }
        return Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Eyebrow(text: "Hevy · Strava · Salud")
                        Text("Entrenamientos")
                            .font(.title3.weight(.bold))
                    }
                    Spacer()
                    MetricPill(text: "\(recent.count) esta semana")
                }

                if workouts.isEmpty {
                    Text("Conecta Salud para importar Strava y Hevy. Si tienes Hevy Pro, añade su clave en Ajustes para recuperar ejercicios, series y cargas.")
                        .font(.subheadline)
                        .foregroundStyle(CaltrackTheme.muted)
                } else {
                    ForEach(Array(workouts.prefix(5))) { workout in
                        WorkoutRow(workout: workout)
                        if workout.id != workouts.prefix(5).last?.id { Divider().overlay(CaltrackTheme.line) }
                    }
                }

                Button {
                    Task { await syncAllWorkouts() }
                } label: {
                    HStack {
                        if workoutSyncing { ProgressView().controlSize(.small) }
                        Text("Sincronizar entrenamientos")
                        Spacer()
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .frame(height: 46)
                    .background(CaltrackTheme.cardRaised, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                }
                .disabled(workoutSyncing)
                if let workoutMessage {
                    Text(workoutMessage)
                        .font(.caption)
                        .foregroundStyle(workoutMessage.contains("No se pudo") ? CaltrackTheme.coral : CaltrackTheme.muted)
                }
            }
        }
    }

    private var todayCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 15) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Hoy")
                        .font(.title3.weight(.bold))
                    MetricPill(text: "\(todayMeals.count) registros")
                    Spacer()
                    Text("\(Int(todayTotals.calories)) / \(Int(calorieMax)) kcal")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(todayTotals.calories > calorieMax ? CaltrackTheme.coral : .white)
                }
                ProgressView(value: min(todayTotals.calories, calorieMax), total: calorieMax)
                    .tint(todayTotals.calories > calorieMax ? CaltrackTheme.coral : CaltrackTheme.green)
                nutrientProgress(
                    title: "Proteína",
                    value: todayTotals.protein,
                    target: proteinMin,
                    suffix: "g",
                    color: CaltrackTheme.blue
                )
                if todayFiber.hasData {
                    nutrientProgress(
                        title: "Fibra",
                        value: todayFiber.value,
                        target: fiberTarget,
                        suffix: "g",
                        color: CaltrackTheme.amber
                    )
                    if !todayFiber.isComplete {
                        Label("Fibra disponible en \(todayFiber.knownMeals) de \(todayFiber.totalMeals) comidas", systemImage: "exclamationmark.circle")
                            .font(.caption2)
                            .foregroundStyle(CaltrackTheme.muted)
                    }
                } else if !todayMeals.isEmpty {
                    Label("Añade fibra al editar una comida para ver su progreso", systemImage: "leaf")
                        .font(.caption2)
                        .foregroundStyle(CaltrackTheme.muted)
                }

                if let activity = activityDays.first(where: { Calendar.current.isDateInToday($0.date) }), activity.totalEnergy > 0 {
                    let balance = todayTotals.calories - activity.totalEnergy
                    HStack {
                        Label("Gasto estimado \(Int(activity.totalEnergy)) kcal", systemImage: "flame.fill")
                        Spacer()
                        Text("Balance \(balance > 0 ? "+" : "")\(Int(balance)) kcal")
                            .foregroundStyle(balance <= 0 && balance >= -1_000 ? CaltrackTheme.green : CaltrackTheme.coral)
                    }
                    .font(.caption.weight(.semibold))
                }

                if todayMeals.isEmpty {
                    ContentUnavailableView("Nada registrado", systemImage: "fork.knife", description: Text("La primera foto del día aparecerá aquí."))
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(CaltrackTheme.muted)
                } else {
                    ForEach(todayMeals) { meal in
                        MealRow(meal: meal) {
                            editingMeal = meal
                        } repeatMeal: {
                            repeatMeal(meal)
                        } delete: {
                            deleteMeal(meal)
                        }
                        if meal.id != todayMeals.last?.id { Divider().overlay(CaltrackTheme.line) }
                    }
                }

                Divider().overlay(CaltrackTheme.line)
                Button {
                    showingDailyCheckIn = true
                } label: {
                    HStack(spacing: 11) {
                        Image(systemName: todayPlanCheckIn?.nutritionComplete == true ? "checkmark.circle.fill" : "circle")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(todayPlanCheckIn?.nutritionComplete == true ? CaltrackTheme.green : CaltrackTheme.muted)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(todayPlanCheckIn?.nutritionComplete == true ? "Día cerrado" : "Cerrar el día")
                                .font(.subheadline.weight(.semibold))
                            Text(todayPlanCheckIn?.nutritionComplete == true ? "Hambre \(todayPlanCheckIn?.hunger ?? 3)/5 · Energía \(todayPlanCheckIn?.energy ?? 3)/5" : "Confirma que has registrado todo")
                                .font(.caption)
                                .foregroundStyle(CaltrackTheme.muted)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(CaltrackTheme.muted)
                    }
                    .padding(.horizontal, 12)
                    .frame(minHeight: 54)
                    .background(CaltrackTheme.cardRaised, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(todayMeals.isEmpty)
                .opacity(todayMeals.isEmpty ? 0.55 : 1)
                .accessibilityIdentifier("dailyPlanCheckIn")
            }
        }
    }

    private func nutrientProgress(title: String, value: Double, target: Double, suffix: String, color: Color) -> some View {
        VStack(spacing: 5) {
            HStack {
                Text(title)
                Spacer()
                Text("\(value.formatted(.number.precision(.fractionLength(0...1)))) / \(target.formatted(.number.precision(.fractionLength(0...1)))) \(suffix)")
                    .monospacedDigit()
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(CaltrackTheme.muted)
            ProgressView(value: min(max(value, 0), max(target, 1)), total: max(target, 1))
                .tint(color)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(title == "Fibra" ? "todayFiberProgress" : "todayProteinProgress")
        .accessibilityValue("\(Int(value.rounded())) de \(Int(target.rounded())) \(suffix)")
    }

    private var adaptivePlanCard: some View {
        let review = adaptivePlanReview
        return Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Eyebrow(text: "Plan adaptativo")
                        Text(review.title)
                            .font(.title3.weight(.bold))
                    }
                    Spacer()
                    Image(systemName: planStateIcon(review.state))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(planStateColor(review.state))
                        .frame(width: 38, height: 38)
                        .background(planStateColor(review.state).opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Text(review.message)
                    .font(.subheadline)
                    .foregroundStyle(CaltrackTheme.muted)

                if planGoalMode != .notSet {
                    HStack(spacing: 8) {
                        planMetric("\(review.completeDays)/14", label: "días")
                        planMetric(review.actualWeeklyRate.map(formatWeeklyRate) ?? "-", label: "real")
                        planMetric(formatWeeklyRate(review.targetWeeklyRate), label: "objetivo")
                    }
                    if let adherence = review.rangeAdherence {
                        ProgressView(value: adherence)
                            .tint(adherence >= AdaptivePlanEngine.minimumAdherence ? CaltrackTheme.green : CaltrackTheme.coral)
                        Text("\(Int((adherence * 100).rounded()))% de días cerrados dentro del rango")
                            .font(.caption)
                            .foregroundStyle(CaltrackTheme.muted)
                    }
                }

                if let proposed = review.proposedRange, let delta = review.calorieDelta {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Rango propuesto").font(.caption).foregroundStyle(CaltrackTheme.muted)
                            Text("\(Int(proposed.lowerBound)) a \(Int(proposed.upperBound)) kcal")
                                .font(.headline.monospacedDigit())
                        }
                        Spacer()
                        MetricPill(text: "\(delta > 0 ? "+" : "")\(Int(delta)) kcal")
                    }
                    Button {
                        showingPlanAdjustmentConfirmation = true
                    } label: {
                        Label("Revisar y aplicar", systemImage: "checkmark.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .foregroundStyle(.black)
                            .background(CaltrackTheme.green, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .accessibilityIdentifier("applyAdaptivePlan")
                }

                Button {
                    showingPlanSettings = true
                } label: {
                    HStack {
                        Label(planGoalMode == .notSet ? "Configurar mi plan" : "Editar objetivo", systemImage: "target")
                        Spacer()
                        if planTargetWeight > 0 {
                            Text("\(planTargetWeight.formatted(.number.precision(.fractionLength(0...1)))) kg")
                                .foregroundStyle(CaltrackTheme.muted)
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(CaltrackTheme.muted)
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .frame(height: 46)
                    .background(CaltrackTheme.cardRaised, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("configureAdaptivePlan")

                Text("Tendencia personal, no consejo médico. Ningún cambio se aplica sin confirmación.")
                    .font(.caption2)
                    .foregroundStyle(CaltrackTheme.muted)
            }
        }
    }

    private func planMetric(_ value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value).font(.subheadline.monospacedDigit().weight(.bold))
            Text(label).font(.caption2).foregroundStyle(CaltrackTheme.muted)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CaltrackTheme.cardRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func planStateIcon(_ state: AdaptivePlanState) -> String {
        switch state {
        case .needsConfiguration: "target"
        case .collecting: "hourglass"
        case .followCurrentPlan: "arrow.triangle.2.circlepath"
        case .stable: "checkmark.circle.fill"
        case .recentlyAdjusted: "clock.badge.checkmark"
        case .adjustment: "slider.horizontal.3"
        case .safetyLimit: "exclamationmark.shield.fill"
        }
    }

    private func planStateColor(_ state: AdaptivePlanState) -> Color {
        switch state {
        case .stable, .recentlyAdjusted: CaltrackTheme.green
        case .collecting, .needsConfiguration, .followCurrentPlan, .adjustment: CaltrackTheme.blue
        case .safetyLimit: CaltrackTheme.coral
        }
    }

    private func formatWeeklyRate(_ value: Double) -> String {
        let sign = value > 0 ? "+" : ""
        return "\(sign)\(value.formatted(.number.precision(.fractionLength(2)))) kg"
    }

    private func adaptivePlanDays() -> [AdaptivePlanDay] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return (0..<AdaptivePlanEngine.windowDays).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let calories = meals.filter { calendar.isDate($0.date, inSameDayAs: date) }.reduce(0) { $0 + $1.calories }
            let complete = planCheckIns.contains { $0.nutritionComplete && calendar.isDate($0.date, inSameDayAs: date) }
            return AdaptivePlanDay(date: date, calories: calories, isComplete: complete)
        }
    }

    private func saveDailyPlanCheckIn(hunger: Int, energy: Int) {
        let calendar = Calendar.current
        let date = calendar.startOfDay(for: .now)
        if let existing = todayPlanCheckIn {
            existing.date = date
            existing.nutritionComplete = true
            existing.hunger = hunger
            existing.energy = energy
        } else {
            modelContext.insert(DailyPlanCheckIn(
                externalID: "plan-check-in:\(Int(date.timeIntervalSince1970))",
                date: date,
                hunger: hunger,
                energy: energy
            ))
        }
        try? modelContext.save()
    }

    private func reopenTodayPlanCheckIn() {
        todayPlanCheckIn?.nutritionComplete = false
        try? modelContext.save()
    }

    private func applyAdaptivePlanAdjustment() {
        guard let proposed = adaptivePlanReview.proposedRange else { return }
        calorieMin = proposed.lowerBound
        calorieMax = proposed.upperBound
        planLastAdjustmentTimestamp = Date.now.timeIntervalSince1970
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private var coachCard: some View {
        let score = todayMeals.isEmpty ? 0 : CaltrackMath.adherence(
            calories: todayTotals.calories,
            protein: todayTotals.protein,
            calorieRange: CaltrackMath.orderedRange(calorieMin, calorieMax),
            proteinRange: CaltrackMath.orderedRange(proteinMin, proteinMax)
        )
        return Card {
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    Circle().stroke(CaltrackTheme.cardRaised, lineWidth: 7)
                    Circle().trim(from: 0, to: Double(score) / 100)
                        .stroke(CaltrackTheme.green, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(score)%").font(.headline.weight(.black))
                }
                .frame(width: 74, height: 74)
                VStack(alignment: .leading, spacing: 6) {
                    Eyebrow(text: "Análisis del día")
                    Text(coachTitle(score: score))
                        .font(.headline)
                    Text(coachText())
                        .font(.subheadline)
                        .foregroundStyle(CaltrackTheme.muted)
                }
            }
        }
    }

    private func healthMetric(_ value: Double?, suffix: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value.map { $0.formatted(.number.precision(.fractionLength(1))) } ?? "-")
                .font(.title3.weight(.bold))
            Text("\(suffix) · \(label)")
                .font(.caption2)
                .foregroundStyle(CaltrackTheme.muted)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CaltrackTheme.cardRaised, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    private func weeklyDays() -> [DayTotal] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return (0..<7).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let total = meals.filter { calendar.isDate($0.date, inSameDayAs: date) }.reduce(0) { $0 + $1.calories }
            return DayTotal(date: date, calories: total)
        }
    }

    private func load(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) else { return }
            selectedImage = image
            showingAnalysis = true
            photoItem = nil
        }
    }

    private func saveMeal(_ editable: EditableMeal, imageData: Data?, date: Date = .now, source: String = "Grok Vision") {
        let meal = MealEntry(
            date: date,
            name: editable.name,
            calories: editable.number(editable.calories),
            protein: editable.number(editable.protein),
            carbohydrates: editable.number(editable.carbohydrates),
            fat: editable.number(editable.fat),
            fiber: editable.fiberValue,
            photoData: imageData,
            components: editable.persistedComponents,
            source: source,
            confidence: editable.confidence,
            assumption: editable.assumption
        )
        modelContext.insert(meal)
        try? modelContext.save()
        syncNutritionIfEnabled(meal)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func updateMeal(_ meal: MealEntry, with editable: EditableMeal, date: Date) {
        meal.date = date
        meal.name = editable.name
        meal.calories = editable.number(editable.calories)
        meal.protein = editable.number(editable.protein)
        meal.carbohydrates = editable.number(editable.carbohydrates)
        meal.fat = editable.number(editable.fat)
        meal.fiber = editable.fiberValue
        meal.confidence = editable.confidence
        meal.assumption = editable.assumption
        meal.updateComponents(editable.persistedComponents)
        try? modelContext.save()
        syncNutritionIfEnabled(meal)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func repeatMeal(_ suggestion: FrequentMeal) {
        insertRepeatedMeal(
            name: suggestion.name,
            calories: suggestion.calories,
            protein: suggestion.protein,
            carbohydrates: suggestion.carbohydrates,
            fat: suggestion.fat,
            fiber: suggestion.fiber,
            components: suggestion.components
        )
    }

    private func repeatMeal(_ meal: MealEntry) {
        insertRepeatedMeal(name: meal.name, calories: meal.calories, protein: meal.protein, carbohydrates: meal.carbohydrates, fat: meal.fat, fiber: meal.fiber, components: meal.components)
    }

    private func insertRepeatedMeal(name: String, calories: Double, protein: Double, carbohydrates: Double, fat: Double, fiber: Double? = nil, components: [MealComponent] = []) {
        let meal = MealEntry(
            name: name,
            calories: calories,
            protein: protein,
            carbohydrates: carbohydrates,
            fat: fat,
            fiber: fiber,
            components: components,
            source: "repeated",
            assumption: "Repetida desde el historial"
        )
        modelContext.insert(meal)
        try? modelContext.save()
        syncNutritionIfEnabled(meal)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func deleteMeal(_ meal: MealEntry) {
        let id = meal.id
        modelContext.delete(meal)
        try? modelContext.save()
        guard healthNutritionEnabled else { return }
        Task {
            do {
                try await HealthNutritionService().delete(mealID: id)
            } catch {
                healthMessage = "La comida se borró de Caltrack, pero no de Salud: \(error.localizedDescription)"
            }
        }
    }

    private func syncNutritionIfEnabled(_ meal: MealEntry) {
        guard healthNutritionEnabled else { return }
        Task {
            do {
                try await HealthNutritionService().upsert(meal)
            } catch {
                healthMessage = "La comida está en Caltrack, pero Salud no pudo guardarla: \(error.localizedDescription)"
            }
        }
    }

    private func persistHealthSnapshot() {
        let snapshots = health.measurementHistory.isEmpty ? [health.snapshot].compactMap { $0 } : health.measurementHistory
        guard !snapshots.isEmpty else { return }
        let calendar = Calendar.current
        var stored = (try? modelContext.fetch(FetchDescriptor<BodyMeasurement>())) ?? measurements
        for snapshot in snapshots where snapshot.weight != nil || snapshot.bodyFat != nil || snapshot.waist != nil {
            if let existing = stored.first(where: { $0.source == "HealthKit" && calendar.isDate($0.date, inSameDayAs: snapshot.date) }) {
                if let weight = snapshot.weight { existing.weight = weight }
                if let bodyFat = snapshot.bodyFat { existing.bodyFat = bodyFat }
                if let waist = snapshot.waist { existing.waist = waist }
                existing.date = max(existing.date, snapshot.date)
            } else {
                let entry = BodyMeasurement(date: snapshot.date, weight: snapshot.weight, bodyFat: snapshot.bodyFat, waist: snapshot.waist, source: "HealthKit")
                modelContext.insert(entry)
                stored.append(entry)
            }
        }
        try? modelContext.save()
    }

    private func persistHealthWorkouts() {
        var stored = (try? modelContext.fetch(FetchDescriptor<WorkoutEntry>())) ?? workouts
        for snapshot in health.workouts {
            if let existing = stored.first(where: { $0.externalID == snapshot.externalID }) {
                update(existing, from: snapshot)
                continue
            }
            let isHevy = WorkoutMatch.isHevySource(name: snapshot.source, bundle: snapshot.sourceBundle)
            if isHevy, stored.contains(where: { $0.source == "Hevy" && abs($0.startDate.timeIntervalSince(snapshot.startDate)) < 600 }) {
                continue
            }
            let entry = WorkoutEntry(
                externalID: snapshot.externalID,
                startDate: snapshot.startDate,
                endDate: snapshot.endDate,
                title: snapshot.title,
                activityType: snapshot.activityType,
                durationMinutes: snapshot.durationMinutes,
                calories: snapshot.calories,
                distanceKm: snapshot.distanceKm,
                source: snapshot.source,
                sourceBundle: snapshot.sourceBundle
            )
            modelContext.insert(entry)
            stored.append(entry)
        }
        try? modelContext.save()
    }

    private func persistHealthActivity() {
        var stored = (try? modelContext.fetch(FetchDescriptor<ActivityDay>())) ?? activityDays
        for snapshot in health.activityHistory {
            if let existing = stored.first(where: { $0.externalID == snapshot.externalID }) {
                existing.date = snapshot.date
                existing.activeEnergy = snapshot.activeEnergy
                existing.restingEnergy = snapshot.restingEnergy
                existing.steps = snapshot.steps
            } else {
                let entry = ActivityDay(
                    externalID: snapshot.externalID,
                    date: snapshot.date,
                    activeEnergy: snapshot.activeEnergy,
                    restingEnergy: snapshot.restingEnergy,
                    steps: snapshot.steps
                )
                modelContext.insert(entry)
                stored.append(entry)
            }
        }
        try? modelContext.save()
    }

    private func persistHealthRecovery() {
        var stored = (try? modelContext.fetch(FetchDescriptor<RecoveryDay>())) ?? recoveryDays
        for snapshot in health.recoveryHistory {
            if let existing = stored.first(where: { $0.externalID == snapshot.externalID }) {
                existing.date = snapshot.date
                existing.sleepMinutes = snapshot.sleepMinutes
                existing.coreMinutes = snapshot.coreMinutes
                existing.deepMinutes = snapshot.deepMinutes
                existing.remMinutes = snapshot.remMinutes
                existing.restingHeartRate = snapshot.restingHeartRate
                existing.hrvSDNN = snapshot.hrvSDNN
                existing.source = snapshot.source
            } else {
                let entry = RecoveryDay(
                    externalID: snapshot.externalID,
                    date: snapshot.date,
                    sleepMinutes: snapshot.sleepMinutes,
                    coreMinutes: snapshot.coreMinutes,
                    deepMinutes: snapshot.deepMinutes,
                    remMinutes: snapshot.remMinutes,
                    restingHeartRate: snapshot.restingHeartRate,
                    hrvSDNN: snapshot.hrvSDNN,
                    source: snapshot.source
                )
                modelContext.insert(entry)
                stored.append(entry)
            }
        }
        try? modelContext.save()
    }

    private func syncAllWorkouts() async {
        workoutSyncing = true
        defer { workoutSyncing = false }
        do {
            if healthConnected {
                try await health.refresh()
                persistHealthSnapshot()
                persistHealthActivity()
                persistHealthRecovery()
                persistHealthWorkouts()
            }
            let hasHevyKey = KeychainStore.read(account: HevyService.apiKeyAccount) != nil
            if await syncHevy(), !hasHevyKey { workoutMessage = "Actualizado ahora" }
        } catch {
            workoutMessage = "No se pudo sincronizar Salud: \(error.localizedDescription)"
        }
    }

    private var healthConnectionDetail: String {
        switch health.state {
        case .loading: "Preparando"
        case .unavailable: "No disponible"
        case .failed: "Reintentar"
        case .ready: "Preparada"
        case .idle: healthConnected ? "Sincronizar" : "Conectar"
        }
    }

    private func connectHealth() {
        Task {
            await health.connectAndRead()
            switch health.state {
            case .ready:
                healthConnected = true
                healthMessage = "Salud preparada. Importaremos únicamente los datos que autorices."
                persistHealthSnapshot()
                persistHealthActivity()
                persistHealthRecovery()
                persistHealthWorkouts()
                _ = await syncHevy()
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            case .unavailable:
                healthConnected = false
                healthMessage = "Apple Salud solo está disponible en la app instalada en un iPhone."
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            case .failed(let message):
                healthConnected = false
                healthMessage = "No se pudo preparar Salud: \(message)"
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            default:
                break
            }
        }
    }

    private func syncHevy() async -> Bool {
        guard let apiKey = KeychainStore.read(account: HevyService.apiKeyAccount) else { return true }
        do {
            let isInitialBackfill = !hevyBackfillCompleted
            let batch = try await HevyService().fetchWorkoutBatch(
                apiKey: apiKey,
                maxPages: isInitialBackfill ? 10 : 1
            )
            var stored = (try? modelContext.fetch(FetchDescriptor<WorkoutEntry>())) ?? workouts
            for dto in batch.workouts {
                let candidate = dto.makeEntry()
                if let existing = stored.first(where: { $0.externalID == candidate.externalID }) {
                    update(existing, from: candidate)
                } else if let healthMatch = stored.first(where: {
                    WorkoutMatch.representsSameSession(sourceName: $0.source, sourceBundle: $0.sourceBundle, startDate: $0.startDate, hevyStartDate: candidate.startDate)
                }) {
                    update(healthMatch, from: candidate)
                } else {
                    modelContext.insert(candidate)
                    stored.append(candidate)
                }
            }
            try modelContext.save()
            hevyBackfillCompleted = true
            if isInitialBackfill, batch.isTruncated {
                workoutMessage = "Hevy actualizado. Importados los 100 entrenamientos más recientes."
            } else {
                workoutMessage = "Hevy actualizado ahora"
            }
            return true
        } catch {
            workoutMessage = "No se pudo sincronizar Hevy: \(error.localizedDescription)"
            return false
        }
    }

    private func update(_ workout: WorkoutEntry, from snapshot: HealthWorkoutSnapshot) {
        workout.startDate = snapshot.startDate
        workout.endDate = snapshot.endDate
        workout.title = snapshot.title
        workout.activityType = snapshot.activityType
        workout.durationMinutes = snapshot.durationMinutes
        workout.calories = snapshot.calories
        workout.distanceKm = snapshot.distanceKm
        workout.source = snapshot.source
        workout.sourceBundle = snapshot.sourceBundle
    }

    private func update(_ workout: WorkoutEntry, from imported: WorkoutEntry) {
        workout.externalID = imported.externalID
        workout.startDate = imported.startDate
        workout.endDate = imported.endDate
        workout.title = imported.title
        workout.activityType = imported.activityType
        workout.durationMinutes = imported.durationMinutes
        workout.source = imported.source
        workout.sourceBundle = imported.sourceBundle
        workout.updateExercises(imported.exercises)
    }

    private func coachTitle(score: Int) -> String {
        if todayMeals.isEmpty { return "Empieza con una foto" }
        if score >= 80 { return "Vas dentro del plan" }
        return "Todavía hay margen hoy"
    }

    private func coachText() -> String {
        if todayMeals.isEmpty { return "Grok hará la primera estimación. Tú corriges y confirmas." }
        if todayTotals.protein < proteinMin { return "Te faltan aproximadamente \(Int(proteinMin - todayTotals.protein)) g de proteína para el mínimo." }
        if todayTotals.calories > calorieMax { return "Has superado el máximo configurado. Revisa aceites, salsas y porciones estimadas." }
        if todayFiber.hasData, todayFiber.isComplete, todayFiber.value < fiberTarget {
            return "Proteína cubierta. Te faltan aproximadamente \(Int((fiberTarget - todayFiber.value).rounded())) g de fibra para la referencia diaria."
        }
        if !todayFiber.isComplete {
            return "Proteína cubierta y calorías dentro del rango. Completa la fibra de las comidas para comparar con la referencia."
        }
        return "Proteína cubierta, calorías dentro del rango y fibra revisada."
    }

    private func seedTestingDataIfNeeded() {
#if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-seed-superapp") {
            seedSuperAppTestingData()
            return
        }
        guard arguments.contains("-seed-workouts"), workouts.isEmpty else { return }
        modelContext.insert(WorkoutEntry(
            externalID: "hevy:ui-test",
            startDate: .now.addingTimeInterval(-3_600),
            endDate: .now,
            title: "Torso",
            activityType: "Fuerza",
            durationMinutes: 60,
            calories: 320,
            source: "Hevy",
            sourceBundle: "com.hevyapp.hevy",
            exerciseCount: 2,
            setCount: 7,
            totalVolumeKg: 3_840,
            exercises: [
                WorkoutExerciseSummary(name: "Press banca", setCount: 3, bestWeight: 60, bestReps: 4, volumeKg: 1_200, rpe: 9),
                WorkoutExerciseSummary(name: "Jalón al pecho", setCount: 4, bestWeight: 70, bestReps: 8, volumeKg: 2_640, rpe: 8)
            ]
        ))
        try? modelContext.save()
#endif
    }

#if DEBUG
    private func seedSuperAppTestingData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        for meal in (try? modelContext.fetch(FetchDescriptor<MealEntry>())) ?? [] { modelContext.delete(meal) }
        for measurement in (try? modelContext.fetch(FetchDescriptor<BodyMeasurement>())) ?? [] { modelContext.delete(measurement) }
        for activity in (try? modelContext.fetch(FetchDescriptor<ActivityDay>())) ?? [] { modelContext.delete(activity) }
        for recovery in (try? modelContext.fetch(FetchDescriptor<RecoveryDay>())) ?? [] { modelContext.delete(recovery) }
        for checkIn in (try? modelContext.fetch(FetchDescriptor<DailyPlanCheckIn>())) ?? [] { modelContext.delete(checkIn) }
        for workout in (try? modelContext.fetch(FetchDescriptor<WorkoutEntry>())) ?? [] { modelContext.delete(workout) }
        for message in (try? modelContext.fetch(FetchDescriptor<CoachMessage>())) ?? [] { modelContext.delete(message) }
        try? modelContext.save()

        for offset in 0..<14 {
            let day = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            let variation = Double((offset % 4) * 45)
            modelContext.insert(MealEntry(date: day.addingTimeInterval(28_800), name: "Yogur, fruta y proteína", calories: 430 + variation, protein: 42, carbohydrates: 48, fat: 9, fiber: 9, source: "Grok Vision", confidence: 0.88))
            modelContext.insert(MealEntry(
                date: day.addingTimeInterval(43_200),
                name: "Pollo con arroz",
                calories: 720,
                protein: 62,
                carbohydrates: 74,
                fat: 18,
                fiber: 2,
                components: [
                    MealComponent(id: UUID(uuidString: "00000000-0000-0000-0000-000000000101")!, name: "Pechuga de pollo", portion: "220 g", calories: 330, protein: 55, carbohydrates: 0, fat: 8, fiber: 0),
                    MealComponent(id: UUID(uuidString: "00000000-0000-0000-0000-000000000102")!, name: "Arroz cocido", portion: "250 g", calories: 330, protein: 7, carbohydrates: 74, fat: 2, fiber: 2),
                    MealComponent(id: UUID(uuidString: "00000000-0000-0000-0000-000000000103")!, name: "Aceite de oliva", portion: "7 g", calories: 60, protein: 0, carbohydrates: 0, fat: 8, fiber: 0)
                ],
                source: "Grok Vision",
                confidence: 0.91
            ))
            modelContext.insert(MealEntry(date: day.addingTimeInterval(64_800), name: "Salmón y verduras", calories: 610, protein: 55, carbohydrates: 32, fat: 28, fiber: 8, source: "manual"))
        }
        for index in 0..<9 {
            let date = calendar.date(byAdding: .day, value: -(index * 4), to: today)?.addingTimeInterval(43_200) ?? today
            modelContext.insert(BodyMeasurement(date: date, weight: 79.4 + Double(index) * 0.23, bodyFat: 14.2 + Double(index) * 0.14, waist: 81.0 + Double(index) * 0.3, source: "HealthKit"))
        }
        for offset in 0..<14 {
            let date = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            modelContext.insert(ActivityDay(
                externalID: "health-activity:super-ui-\(offset)",
                date: date,
                activeEnergy: 520 + Double((offset % 5) * 35),
                restingEnergy: 1_860,
                steps: 7_800 + Double((offset % 4) * 900)
            ))
            modelContext.insert(RecoveryDay(
                externalID: "health-recovery:super-ui-\(offset)",
                date: date,
                sleepMinutes: 420 + Double((offset % 4) * 18),
                coreMinutes: 235 + Double((offset % 3) * 12),
                deepMinutes: 62 + Double((offset % 3) * 8),
                remMinutes: 94 + Double((offset % 2) * 11),
                restingHeartRate: 54 + Double(offset % 4),
                hrvSDNN: 46 + Double((offset % 5) * 3),
                source: "Apple Watch"
            ))
            modelContext.insert(DailyPlanCheckIn(
                externalID: "plan-check-in:super-ui-\(offset)",
                date: date,
                hunger: 2 + (offset % 3),
                energy: 3 + (offset % 2)
            ))
        }
        for index in 0..<4 {
            let start = calendar.date(byAdding: .day, value: -(index * 2), to: today)?.addingTimeInterval(43_200) ?? today
            modelContext.insert(WorkoutEntry(
                externalID: "hevy:super-ui-\(index)",
                startDate: start.addingTimeInterval(-4_200),
                endDate: start,
                title: ["Upper B", "Lower A", "Upper A", "Delts y brazos"][index],
                activityType: "Fuerza",
                durationMinutes: Double([67, 55, 72, 48][index]),
                source: "Hevy",
                sourceBundle: "com.hevyapp.hevy",
                exercises: [
                    WorkoutExerciseSummary(name: "Press de pecho", setCount: 4, bestWeight: 55 + Double(index) * 5, bestReps: 8, volumeKg: 1_760, rpe: 8),
                    WorkoutExerciseSummary(name: "Jalón al pecho", setCount: 4, bestWeight: 60, bestReps: 10, volumeKg: 2_000, rpe: 8)
                ]
            ))
        }
        modelContext.insert(CoachMessage(date: .now.addingTimeInterval(-120), role: "user", content: "¿Qué patrón debería mejorar esta semana?"))
        modelContext.insert(CoachMessage(date: .now.addingTimeInterval(-60), role: "assistant", content: "Tu proteína es consistente y el entrenamiento está cubierto. La principal mejora es reducir la variación de calorías entre días. Acción para esta semana: deja planificada la cena antes de las 18:00."))
        planGoalModeRaw = PlanGoalMode.lose.rawValue
        planWeeklyRate = 0.5
        planTargetWeight = 75
        planLastAdjustmentTimestamp = 0
        calorieMin = 1_800
        calorieMax = 2_000
        proteinMin = 160
        proteinMax = 190
        fiberTarget = 25
        try? modelContext.save()
    }
#endif
}

private struct DayTotal: Identifiable {
    let date: Date
    let calories: Double
    var id: Date { date }
    var label: String { date.formatted(.dateTime.weekday(.narrow).locale(Locale(identifier: "es_ES"))) }
}

private struct MealRow: View {
    let meal: MealEntry
    let edit: () -> Void
    let repeatMeal: () -> Void
    let delete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let data = meal.photoData, let image = UIImage(data: data) {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    Image(systemName: "fork.knife").foregroundStyle(CaltrackTheme.muted)
                }
            }
            .frame(width: 48, height: 48)
            .background(CaltrackTheme.cardRaised)
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(meal.name).font(.subheadline.weight(.semibold)).lineLimit(1)
                Text(mealMacroSummary)
                    .font(.caption2).foregroundStyle(CaltrackTheme.muted)
            }
            Spacer()
            Text("\(Int(meal.calories)) kcal").font(.subheadline.weight(.bold))
            Menu {
                Button("Repetir ahora", systemImage: "plus.circle", action: repeatMeal)
                Button("Editar", systemImage: "pencil", action: edit)
                Button("Eliminar", systemImage: "trash", role: .destructive, action: delete)
            } label: {
                Image(systemName: "ellipsis").frame(width: 30, height: 40)
            }
            .accessibilityLabel("Opciones de \(meal.name)")
        }
    }

    private var mealMacroSummary: String {
        let base = "\(Int(meal.protein)) g P · \(Int(meal.carbohydrates)) g C · \(Int(meal.fat)) g G"
        guard let fiber = meal.fiber else { return base }
        return "\(base) · \(fiber.formatted(.number.precision(.fractionLength(0...1)))) g F"
    }
}

private struct WorkoutRow: View {
    let workout: WorkoutEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(sourceColor)
                    .frame(width: 28, height: 28)
                    .background(sourceColor.opacity(0.13), in: RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 3) {
                    Text(workout.title).font(.subheadline.weight(.bold))
                    Text(workout.startDate.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).locale(Locale(identifier: "es_ES"))))
                        .font(.caption2).foregroundStyle(CaltrackTheme.muted)
                }
                Spacer()
                MetricPill(text: sourceLabel, color: sourceColor.opacity(0.16))
            }
            HStack(spacing: 12) {
                Label("\(Int(workout.durationMinutes)) min", systemImage: "clock")
                if let calories = workout.calories { Label("\(Int(calories)) kcal", systemImage: "flame") }
                if let distance = workout.distanceKm { Label("\(distance.formatted(.number.precision(.fractionLength(1)))) km", systemImage: "point.topleft.down.to.point.bottomright.curvepath") }
            }
            .font(.caption)
            .foregroundStyle(CaltrackTheme.muted)

            if workout.setCount > 0 {
                Text("\(workout.exerciseCount) ejercicios · \(workout.setCount) series · \(Int(workout.totalVolumeKg).formatted()) kg de volumen")
                    .font(.caption.weight(.semibold))
                ForEach(workout.exercises.prefix(3)) { exercise in
                    HStack {
                        Text(exercise.name).lineLimit(1)
                        Spacer()
                        if let weight = exercise.bestWeight, let reps = exercise.bestReps {
                            Text("\(weight.formatted(.number.precision(.fractionLength(0...1)))) kg × \(reps)")
                                .foregroundStyle(CaltrackTheme.green)
                        }
                    }
                    .font(.caption)
                }
            }
        }
        .padding(.vertical, 3)
    }

    private var normalizedSource: String { "\(workout.source) \(workout.sourceBundle)".lowercased() }
    private var sourceLabel: String {
        if normalizedSource.contains("hevy") { return "Hevy" }
        if normalizedSource.contains("strava") { return "Strava" }
        return workout.source.isEmpty ? "Salud" : workout.source
    }
    private var sourceColor: Color {
        if normalizedSource.contains("strava") { return .orange }
        if normalizedSource.contains("hevy") { return CaltrackTheme.blue }
        return .red
    }
    private var icon: String {
        if workout.activityType.localizedCaseInsensitiveContains("fuerza") { return "dumbbell.fill" }
        if workout.activityType.localizedCaseInsensitiveContains("running") { return "figure.run" }
        if workout.activityType.localizedCaseInsensitiveContains("ciclismo") { return "bicycle" }
        return "figure.mixed.cardio"
    }
}
