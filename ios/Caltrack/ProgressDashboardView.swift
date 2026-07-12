import Charts
import SwiftData
import SwiftUI
import UIKit

private enum ProgressSheet: Identifiable {
    case settings
    case editMeal(MealEntry)
    case newBodyCheckIn
    case editBodyCheckIn(BodyMeasurement)

    var id: String {
        switch self {
        case .settings: "settings"
        case .editMeal(let meal): "meal:\(meal.id.uuidString)"
        case .newBodyCheckIn: "body:new"
        case .editBodyCheckIn(let measurement): "body:\(measurement.id.uuidString)"
        }
    }
}

enum ProgressRequest: Equatable {
    case bodyCheckIn
}

struct ProgressDashboardView: View {
    @Binding var requestedAction: ProgressRequest?
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MealEntry.date, order: .reverse) private var meals: [MealEntry]
    @Query(sort: \BodyMeasurement.date, order: .reverse) private var measurements: [BodyMeasurement]
    @Query(sort: \ActivityDay.date, order: .reverse) private var activityDays: [ActivityDay]
    @Query(sort: \WorkoutEntry.startDate, order: .reverse) private var workouts: [WorkoutEntry]
    @AppStorage("calorieMin") private var calorieMin = 1_800.0
    @AppStorage("calorieMax") private var calorieMax = 2_000.0
    @AppStorage("proteinMin") private var proteinMin = 160.0
    @AppStorage("proteinMax") private var proteinMax = 190.0
    @AppStorage("healthNutritionEnabled") private var healthNutritionEnabled = false
    @State private var nutritionMetric = "Calorías"
    @State private var activeSheet: ProgressSheet?
    @State private var selectedProgressPhoto: BodyMeasurement?
    @State private var searchText = ""
    @State private var nutritionSyncMessage: String?

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

    private var filteredMeals: [MealEntry] {
        let query = FoodLibrary.normalizedName(searchText)
        guard !query.isEmpty else { return meals }
        return meals.filter { meal in
            FoodLibrary.normalizedName(meal.name).contains(query)
                || FoodLibrary.normalizedName(meal.source).contains(query)
                || meal.date.formatted(.dateTime.day().month(.wide).year().locale(Locale(identifier: "es_ES"))).localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CaltrackTheme.canvas.ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: 14) {
                        if searchText.isEmpty {
                            summaryCard
                            nutritionCard
                            energyCard
                            bodyCard
                            trainingCard
                            historyCard
                        } else {
                            historyCard
                        }
                    }
                    .padding(14)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Progreso")
            .searchable(text: $searchText, prompt: "Buscar comidas")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { activeSheet = .settings } label: { Image(systemName: "gearshape.fill") }
                        .accessibilityLabel("Ajustes")
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .settings:
                    SettingsView()
                case .editMeal(let meal):
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
                        syncNutritionIfEnabled(meal)
                    }
                case .newBodyCheckIn:
                    BodyCheckInSheet { draft in saveBodyCheckIn(draft) }
                case .editBodyCheckIn(let measurement):
                    BodyCheckInSheet(title: "Editar check-in", initial: BodyCheckInDraft(measurement: measurement)) { draft in
                        saveBodyCheckIn(draft, editing: measurement)
                    }
                }
            }
            .fullScreenCover(item: $selectedProgressPhoto) { measurement in
                ProgressPhotoViewer(measurement: measurement)
            }
            .onAppear { handleRequestedAction() }
            .onChange(of: requestedAction) { _, _ in handleRequestedAction() }
        }
    }

    private func handleRequestedAction() {
        guard requestedAction == .bodyCheckIn else { return }
        requestedAction = nil
        DispatchQueue.main.async { activeSheet = .newBodyCheckIn }
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
                    progressMetric(measurements.first(where: { $0.weight != nil })?.weight.map { $0.formatted(.number.precision(.fractionLength(1))) } ?? "-", label: "kg")
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
        let values = Array(bodyTrendPoints().filter { $0.weight != nil }.suffix(30))
        let weights = values.compactMap(\.weight)
        let weightDomain = ((weights.min() ?? 0) - 1)...((weights.max() ?? 1) + 1)
        let photos = measurements.filter { $0.photoData != nil }
        let manual = measurements.filter { $0.source == "manual" }
        return Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Eyebrow(text: "Composición")
                        Text("Evolución corporal").font(.title3.weight(.bold))
                    }
                    Spacer()
                    Button { activeSheet = .newBodyCheckIn } label: {
                        Label("Check-in", systemImage: "plus")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 11)
                            .frame(height: 34)
                            .background(CaltrackTheme.blue.opacity(0.18), in: Capsule())
                    }
                    .accessibilityIdentifier("addBodyCheckIn")
                }
                if values.isEmpty {
                    ContentUnavailableView("Sin mediciones", systemImage: "scalemass", description: Text("Conecta Salud o crea un check-in manual."))
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

                if !photos.isEmpty {
                    Divider().overlay(CaltrackTheme.line)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("FOTOS DE PROGRESO")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(CaltrackTheme.muted)
                        ScrollView(.horizontal) {
                            HStack(spacing: 10) {
                                ForEach(photos.prefix(8)) { measurement in
                                    Button { selectedProgressPhoto = measurement } label: {
                                        progressPhotoThumbnail(measurement)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Foto de progreso del \(measurement.date.formatted(.dateTime.day().month(.wide).year().locale(Locale(identifier: "es_ES"))))")
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                    }
                }

                if !manual.isEmpty {
                    Divider().overlay(CaltrackTheme.line)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CHECK-INS MANUALES")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(CaltrackTheme.muted)
                        ForEach(manual.prefix(3)) { measurement in
                            bodyCheckInRow(measurement)
                            if measurement.id != manual.prefix(3).last?.id { Divider().overlay(CaltrackTheme.line) }
                        }
                    }
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
                    MetricPill(text: searchText.isEmpty ? "\(meals.count) total" : "\(filteredMeals.count) resultados")
                }
                if let nutritionSyncMessage {
                    Text(nutritionSyncMessage)
                        .font(.caption)
                        .foregroundStyle(CaltrackTheme.coral)
                }
                if filteredMeals.isEmpty {
                    Text(searchText.isEmpty ? "Todavía no hay comidas guardadas." : "No hay comidas que coincidan con la búsqueda.")
                        .font(.subheadline).foregroundStyle(CaltrackTheme.muted)
                } else {
                    ForEach(filteredMeals.prefix(30)) { meal in
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
                                Button("Repetir ahora", systemImage: "plus.circle") { repeatMeal(meal) }
                                Button("Editar", systemImage: "pencil") { activeSheet = .editMeal(meal) }
                                Button("Eliminar", systemImage: "trash", role: .destructive) {
                                    deleteMeal(meal)
                                }
                            } label: {
                                Image(systemName: "ellipsis").frame(width: 28, height: 36)
                            }
                        }
                        if meal.id != filteredMeals.prefix(30).last?.id { Divider().overlay(CaltrackTheme.line) }
                    }
                }
            }
        }
    }

    private func progressPhotoThumbnail(_ measurement: BodyMeasurement) -> some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let data = measurement.photoData, let image = UIImage(data: data) {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    Color.clear
                }
            }
            .frame(width: 112, height: 146)
            .clipped()
            LinearGradient(colors: [.clear, .black.opacity(0.82)], startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 2) {
                Text(measurement.date.formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: "es_ES"))))
                    .font(.caption.weight(.bold))
                if let weight = measurement.weight {
                    Text("\(weight.formatted(.number.precision(.fractionLength(1)))) kg")
                        .font(.caption2)
                }
            }
            .foregroundStyle(.white)
            .padding(9)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(CaltrackTheme.line) }
    }

    private func bodyCheckInRow(_ measurement: BodyMeasurement) -> some View {
        HStack(spacing: 10) {
            Image(systemName: measurement.photoData == nil ? "scalemass" : "person.crop.rectangle")
                .foregroundStyle(CaltrackTheme.blue)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(measurement.date.formatted(.dateTime.day().month(.wide).year().locale(Locale(identifier: "es_ES"))))
                    .font(.subheadline.weight(.semibold))
                Text(bodyMetricSummary(measurement))
                    .font(.caption)
                    .foregroundStyle(CaltrackTheme.muted)
                    .accessibilityIdentifier("manualCheckInValue")
            }
            Spacer()
            Menu {
                Button("Editar", systemImage: "pencil") { activeSheet = .editBodyCheckIn(measurement) }
                if measurement.photoData != nil {
                    Button("Ver foto", systemImage: "photo") { selectedProgressPhoto = measurement }
                }
                Button("Eliminar", systemImage: "trash", role: .destructive) { deleteBodyCheckIn(measurement) }
            } label: {
                Image(systemName: "ellipsis").frame(width: 32, height: 40)
            }
            .accessibilityLabel("Opciones del check-in")
        }
    }

    private func bodyMetricSummary(_ measurement: BodyMeasurement) -> String {
        var values = [String]()
        if let weight = measurement.weight { values.append("\(weight.formatted(.number.precision(.fractionLength(1)))) kg") }
        if let bodyFat = measurement.bodyFat { values.append("\(bodyFat.formatted(.number.precision(.fractionLength(1)))) % grasa") }
        if let waist = measurement.waist { values.append("\(waist.formatted(.number.precision(.fractionLength(1)))) cm cintura") }
        if measurement.photoData != nil { values.append("foto") }
        return values.joined(separator: " · ")
    }

    private func saveBodyCheckIn(_ draft: BodyCheckInDraft, editing: BodyMeasurement? = nil) {
        guard draft.isValid else { return }
        let target: BodyMeasurement
        if let editing {
            target = editing
        } else if let sameDay = measurements.first(where: { $0.source == "manual" && Calendar.current.isDate($0.date, inSameDayAs: draft.date) }) {
            target = sameDay
        } else {
            target = BodyMeasurement(source: "manual")
            modelContext.insert(target)
        }
        target.date = draft.date
        target.weight = draft.weightValue
        target.bodyFat = draft.bodyFatValue
        target.waist = draft.waistValue
        target.photoData = draft.photoData
        target.source = "manual"
        try? modelContext.save()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func deleteBodyCheckIn(_ measurement: BodyMeasurement) {
        guard measurement.source == "manual" else { return }
        modelContext.delete(measurement)
        try? modelContext.save()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
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

    private func bodyTrendPoints() -> [BodyTrendPoint] {
        let calendar = Calendar.current
        var days = [Date: BodyTrendPoint]()
        for measurement in measurements.sorted(by: { $0.date < $1.date }) {
            let day = calendar.startOfDay(for: measurement.date)
            var point = days[day] ?? BodyTrendPoint(date: measurement.date)
            point.date = max(point.date, measurement.date)
            if let weight = measurement.weight { point.weight = weight }
            if let bodyFat = measurement.bodyFat { point.bodyFat = bodyFat }
            if let waist = measurement.waist { point.waist = waist }
            days[day] = point
        }
        return days.values.sorted { $0.date < $1.date }
    }

    private func barColor(for day: NutritionDay) -> Color {
        if nutritionMetric == "Proteína" { return day.protein >= proteinMin ? CaltrackTheme.green : CaltrackTheme.blue }
        return day.calories > calorieMax ? CaltrackTheme.coral : CaltrackTheme.green
    }

    private func repeatMeal(_ meal: MealEntry) {
        let repeated = MealEntry(
            name: meal.name,
            calories: meal.calories,
            protein: meal.protein,
            carbohydrates: meal.carbohydrates,
            fat: meal.fat,
            source: "repeated",
            assumption: "Repetida desde el historial"
        )
        modelContext.insert(repeated)
        try? modelContext.save()
        syncNutritionIfEnabled(repeated)
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
                nutritionSyncMessage = "La comida se borró de Caltrack, pero no de Salud: \(error.localizedDescription)"
            }
        }
    }

    private func syncNutritionIfEnabled(_ meal: MealEntry) {
        guard healthNutritionEnabled else { return }
        Task {
            do {
                try await HealthNutritionService().upsert(meal)
            } catch {
                nutritionSyncMessage = "Salud no pudo actualizar esta comida: \(error.localizedDescription)"
            }
        }
    }
}

private struct BodyTrendPoint: Identifiable {
    var date: Date
    var weight: Double?
    var bodyFat: Double?
    var waist: Double?
    var id: Date { Calendar.current.startOfDay(for: date) }
}

private struct EnergyBalancePoint: Identifiable {
    let date: Date
    let balance: Double
    var id: Date { date }
}
