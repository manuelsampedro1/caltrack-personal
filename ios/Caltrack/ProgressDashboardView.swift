import Charts
import SwiftData
import SwiftUI

struct ProgressDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MealEntry.date, order: .reverse) private var meals: [MealEntry]
    @Query(sort: \BodyMeasurement.date, order: .reverse) private var measurements: [BodyMeasurement]
    @Query(sort: \ActivityDay.date, order: .reverse) private var activityDays: [ActivityDay]
    @Query(sort: \WorkoutEntry.startDate, order: .reverse) private var workouts: [WorkoutEntry]
    @AppStorage("calorieMin") private var calorieMin = 1_800.0
    @AppStorage("calorieMax") private var calorieMax = 2_000.0
    @AppStorage("proteinMin") private var proteinMin = 160.0
    @AppStorage("proteinMax") private var proteinMax = 190.0
    @State private var nutritionMetric = "Calorías"
    @State private var showingSettings = false
    @State private var editingMeal: MealEntry?

    private var nutritionDays: [NutritionDay] {
        InsightEngine.nutritionDays(meals: meals, count: 14)
    }

    private var recentWorkouts: [WorkoutEntry] {
        let start = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .distantPast
        return workouts.filter { $0.startDate >= start }
    }

    private var report: InsightReport {
        InsightEngine.report(
            meals: meals,
            measurements: measurements,
            workouts: workouts,
            calorieRange: calorieMin...calorieMax,
            proteinRange: proteinMin...proteinMax
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CaltrackTheme.canvas.ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: 14) {
                        summaryCard
                        nutritionCard
                        energyCard
                        bodyCard
                        trainingCard
                        historyCard
                    }
                    .padding(14)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Progreso")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingSettings = true } label: { Image(systemName: "gearshape.fill") }
                        .accessibilityLabel("Ajustes")
                }
            }
            .sheet(isPresented: $showingSettings) { SettingsView() }
            .sheet(item: $editingMeal) { meal in
                ManualMealSheet(title: "Editar comida", initial: EditableMeal(meal: meal), date: meal.date) { editable, date in
                    meal.date = date
                    meal.name = editable.name
                    meal.calories = editable.number(editable.calories)
                    meal.protein = editable.number(editable.protein)
                    meal.carbohydrates = editable.number(editable.carbohydrates)
                    meal.fat = editable.number(editable.fat)
                    meal.confidence = editable.confidence
                    meal.assumption = editable.assumption
                    try? modelContext.save()
                }
            }
        }
    }

    private var summaryCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Eyebrow(text: "Lectura de 14 días")
                        Text(report.title).font(.title3.weight(.bold))
                    }
                    Spacer()
                    ZStack {
                        Circle().stroke(CaltrackTheme.cardRaised, lineWidth: 6)
                        Circle()
                            .trim(from: 0, to: Double(report.score) / 100)
                            .stroke(CaltrackTheme.green, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text("\(report.score)").font(.headline.monospacedDigit().weight(.black))
                    }
                    .frame(width: 62, height: 62)
                    .accessibilityLabel("Puntuación de constancia")
                    .accessibilityValue("\(report.score) de 100")
                }
                Text(report.summary)
                    .font(.subheadline)
                    .foregroundStyle(CaltrackTheme.muted)
                HStack(spacing: 8) {
                    progressMetric("\(meals.count)", label: "comidas")
                    progressMetric("\(recentWorkouts.count)", label: "entrenos")
                    progressMetric(measurements.first?.weight.map { $0.formatted(.number.precision(.fractionLength(1))) } ?? "-", label: "kg")
                }
            }
        }
    }

    private var nutritionCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Eyebrow(text: "Nutrición")
                        Text("Últimos 14 días").font(.title3.weight(.bold))
                    }
                    Spacer()
                }
                Picker("Métrica", selection: $nutritionMetric) {
                    Text("Calorías").tag("Calorías")
                    Text("Proteína").tag("Proteína")
                }
                .pickerStyle(.segmented)

                Chart {
                    ForEach(nutritionDays) { day in
                        BarMark(
                            x: .value("Día", day.date, unit: .day),
                            y: .value(nutritionMetric, nutritionMetric == "Calorías" ? day.calories : day.protein)
                        )
                        .foregroundStyle(barColor(for: day))
                        .cornerRadius(4)
                    }
                    RuleMark(y: .value("Objetivo", nutritionMetric == "Calorías" ? calorieMax : proteinMin))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineStyle(.init(lineWidth: 1, dash: [4]))
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                        AxisValueLabel(format: .dateTime.day().month(.narrow))
                            .foregroundStyle(CaltrackTheme.muted)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine().foregroundStyle(CaltrackTheme.line)
                        AxisValueLabel().foregroundStyle(CaltrackTheme.muted)
                    }
                }
                .frame(height: 190)
            }
        }
    }

    private var bodyCard: some View {
        let values = Array(measurements.filter { $0.weight != nil }.prefix(30).reversed())
        let weights = values.compactMap(\.weight)
        let weightDomain = ((weights.min() ?? 0) - 1)...((weights.max() ?? 1) + 1)
        return Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Eyebrow(text: "Composición")
                        Text("Evolución corporal").font(.title3.weight(.bold))
                    }
                    Spacer()
                    Image(systemName: "figure.stand").foregroundStyle(CaltrackTheme.blue)
                }
                if values.isEmpty {
                    ContentUnavailableView("Sin mediciones", systemImage: "scalemass", description: Text("Conecta Salud para importar peso, grasa y cintura."))
                        .foregroundStyle(CaltrackTheme.muted)
                } else {
                    HStack(spacing: 8) {
                        progressMetric(values.last?.weight.map { "\($0.formatted(.number.precision(.fractionLength(1))))" } ?? "-", label: "kg")
                        progressMetric(values.last?.bodyFat.map { "\($0.formatted(.number.precision(.fractionLength(1))))" } ?? "-", label: "% grasa")
                        progressMetric(values.last?.waist.map { "\($0.formatted(.number.precision(.fractionLength(1))))" } ?? "-", label: "cm cintura")
                    }
                    Chart(values) { measurement in
                        if let weight = measurement.weight {
                            LineMark(x: .value("Fecha", measurement.date), y: .value("Peso", weight))
                                .foregroundStyle(CaltrackTheme.blue)
                                .interpolationMethod(.catmullRom)
                            PointMark(x: .value("Fecha", measurement.date), y: .value("Peso", weight))
                                .foregroundStyle(CaltrackTheme.blue)
                        }
                    }
                    .chartYScale(domain: weightDomain)
                    .chartXAxis(.hidden)
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisGridLine().foregroundStyle(CaltrackTheme.line)
                            AxisValueLabel().foregroundStyle(CaltrackTheme.muted)
                        }
                    }
                    .frame(height: 150)
                }
            }
        }
    }

    private var energyCard: some View {
        let calendar = Calendar.current
        let todayActivity = activityDays.first { calendar.isDateInToday($0.date) }
        let todayNutrition = nutritionDays.last
        let points = activityDays.compactMap { activity -> EnergyBalancePoint? in
            guard let nutrition = nutritionDays.first(where: { calendar.isDate($0.date, inSameDayAs: activity.date) }), nutrition.calories > 0, activity.totalEnergy > 0 else { return nil }
            return EnergyBalancePoint(date: activity.date, balance: nutrition.calories - activity.totalEnergy)
        }.sorted { $0.date < $1.date }
        return Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Eyebrow(text: "Balance estimado")
                        Text("Ingesta y gasto").font(.title3.weight(.bold))
                    }
                    Spacer()
                    Image(systemName: "flame.fill").foregroundStyle(CaltrackTheme.coral)
                }
                if let activity = todayActivity, activity.totalEnergy > 0 {
                    let intake = todayNutrition?.calories ?? 0
                    let balance = intake - activity.totalEnergy
                    HStack(spacing: 8) {
                        progressMetric("\(Int(intake))", label: "kcal comidas")
                        progressMetric("\(Int(activity.totalEnergy))", label: "kcal gasto")
                        progressMetric("\(balance > 0 ? "+" : "")\(Int(balance))", label: "balance")
                    }
                    if !points.isEmpty {
                        Chart {
                            ForEach(points) { point in
                                BarMark(x: .value("Día", point.date, unit: .day), y: .value("Balance", point.balance))
                                    .foregroundStyle(point.balance > 0 ? CaltrackTheme.coral : CaltrackTheme.green)
                                    .cornerRadius(4)
                            }
                            RuleMark(y: .value("Equilibrio", 0))
                                .foregroundStyle(.white.opacity(0.45))
                        }
                        .chartXAxis(.hidden)
                        .chartYAxis {
                            AxisMarks(position: .leading) { _ in
                                AxisGridLine().foregroundStyle(CaltrackTheme.line)
                                AxisValueLabel().foregroundStyle(CaltrackTheme.muted)
                            }
                        }
                        .frame(height: 140)
                    }
                    Text("Estimación basada en energía activa y basal de Salud. Los relojes y las etiquetas tienen margen de error; importa más la tendencia del peso.")
                        .font(.caption).foregroundStyle(CaltrackTheme.muted)
                } else {
                    ContentUnavailableView("Sin gasto diario", systemImage: "flame", description: Text("Conecta Salud para importar energía activa, basal y pasos."))
                        .foregroundStyle(CaltrackTheme.muted)
                }
            }
        }
    }

    private var trainingCard: some View {
        let duration = recentWorkouts.reduce(0) { $0 + $1.durationMinutes }
        let volume = recentWorkouts.reduce(0) { $0 + $1.totalVolumeKg }
        return Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Eyebrow(text: "Entrenamiento")
                        Text("Esta semana").font(.title3.weight(.bold))
                    }
                    Spacer()
                    Image(systemName: "dumbbell.fill").foregroundStyle(CaltrackTheme.blue)
                }
                HStack(spacing: 8) {
                    progressMetric("\(recentWorkouts.count)", label: "sesiones")
                    progressMetric("\(Int(duration))", label: "min")
                    progressMetric(volume > 0 ? "\(Int(volume / 1_000))k" : "-", label: "kg volumen")
                }
                if recentWorkouts.isEmpty {
                    Text("Los entrenamientos de Hevy y Strava aparecerán al sincronizar.")
                        .font(.subheadline).foregroundStyle(CaltrackTheme.muted)
                } else {
                    ForEach(recentWorkouts.prefix(4)) { workout in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(workout.title).font(.subheadline.weight(.semibold))
                                Text(workout.startDate.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).locale(Locale(identifier: "es_ES"))))
                                    .font(.caption).foregroundStyle(CaltrackTheme.muted)
                            }
                            Spacer()
                            Text("\(Int(workout.durationMinutes)) min").font(.caption.weight(.semibold))
                        }
                        if workout.id != recentWorkouts.prefix(4).last?.id { Divider().overlay(CaltrackTheme.line) }
                    }
                }
            }
        }
    }

    private var historyCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Eyebrow(text: "Historial")
                        Text("Comidas recientes").font(.title3.weight(.bold))
                    }
                    Spacer()
                    MetricPill(text: "\(meals.count) total")
                }
                if meals.isEmpty {
                    Text("Todavía no hay comidas guardadas.")
                        .font(.subheadline).foregroundStyle(CaltrackTheme.muted)
                } else {
                    ForEach(meals.prefix(20)) { meal in
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(meal.name).font(.subheadline.weight(.semibold)).lineLimit(1)
                                Text(meal.date.formatted(.dateTime.day().month(.abbreviated).hour().minute().locale(Locale(identifier: "es_ES"))))
                                    .font(.caption2).foregroundStyle(CaltrackTheme.muted)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(Int(meal.calories)) kcal").font(.subheadline.weight(.bold))
                                Text("\(Int(meal.protein)) g proteína").font(.caption2).foregroundStyle(CaltrackTheme.blue)
                            }
                            Menu {
                                Button("Editar", systemImage: "pencil") { editingMeal = meal }
                                Button("Eliminar", systemImage: "trash", role: .destructive) {
                                    modelContext.delete(meal)
                                    try? modelContext.save()
                                }
                            } label: {
                                Image(systemName: "ellipsis").frame(width: 28, height: 36)
                            }
                        }
                        if meal.id != meals.prefix(20).last?.id { Divider().overlay(CaltrackTheme.line) }
                    }
                }
            }
        }
    }

    private func progressMetric(_ value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value).font(.headline.monospacedDigit().weight(.bold)).lineLimit(1).minimumScaleFactor(0.7)
            Text(label).font(.caption2).foregroundStyle(CaltrackTheme.muted).lineLimit(1)
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CaltrackTheme.cardRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func barColor(for day: NutritionDay) -> Color {
        if nutritionMetric == "Proteína" { return day.protein >= proteinMin ? CaltrackTheme.green : CaltrackTheme.blue }
        return day.calories > calorieMax ? CaltrackTheme.coral : CaltrackTheme.green
    }
}

private struct EnergyBalancePoint: Identifiable {
    let date: Date
    let balance: Double
    var id: Date { date }
}
