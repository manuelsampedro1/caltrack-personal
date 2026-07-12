import Charts
import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MealEntry.date, order: .reverse) private var meals: [MealEntry]
    @Query(sort: \BodyMeasurement.date, order: .reverse) private var measurements: [BodyMeasurement]
    @AppStorage("calorieMin") private var calorieMin = 1_800.0
    @AppStorage("calorieMax") private var calorieMax = 2_000.0
    @AppStorage("proteinMin") private var proteinMin = 160.0
    @AppStorage("proteinMax") private var proteinMax = 190.0
    @AppStorage("healthConnected") private var healthConnected = false

    @State private var health = HealthKitService()
    @State private var selectedImage: UIImage?
    @State private var photoItem: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var showingSettings = false
    @State private var showingAnalysis = false
    @State private var healthMessage: String?

    private var todayMeals: [MealEntry] {
        meals.filter { Calendar.current.isDateInToday($0.date) }
    }

    private var todayTotals: (calories: Double, protein: Double) {
        CaltrackMath.totals(for: todayMeals)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CaltrackTheme.canvas.ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: 14) {
                        header
                        captureCard
                        weeklyCard
                        healthCard
                        todayCard
                        coachCard
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 34)
                }
                .scrollIndicators(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $showingCamera) {
                CameraPicker { image in
                    selectedImage = image
                    showingAnalysis = true
                }
                .ignoresSafeArea()
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
            .onChange(of: photoItem) { _, item in load(item) }
            .task {
                guard healthConnected else { return }
                try? await health.refresh()
                persistHealthSnapshot()
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    Text("🥩")
                    Text("caltrack")
                        .font(.title2.weight(.black))
                        .tracking(-0.8)
                }
                Text("\(calorieMin.formatted(.number.precision(.fractionLength(0))))-\(calorieMax.formatted(.number.precision(.fractionLength(0)))) kcal · \(proteinMin.formatted(.number.precision(.fractionLength(0))))-\(proteinMax.formatted(.number.precision(.fractionLength(0)))) g proteína")
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
                    Image(systemName: "camera.macro")
                        .font(.system(size: 33, weight: .medium))
                        .foregroundStyle(CaltrackTheme.green)
                }

                Button {
                    showingCamera = true
                } label: {
                    Label("Fotografiar comida", systemImage: "camera.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .foregroundStyle(.black)
                        .background(CaltrackTheme.green, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .sensoryFeedback(.impact(weight: .medium), trigger: showingCamera)

                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label("Elegir una foto", systemImage: "photo.on.rectangle")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(CaltrackTheme.cardRaised, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
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

    private var healthCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Eyebrow(text: "Apple Salud")
                        Text("Tu cuerpo, actualizado")
                            .font(.title3.weight(.bold))
                    }
                    Spacer()
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                        .font(.title2)
                }
                if let latest = measurements.first(where: { $0.source == "HealthKit" }) ?? measurements.first {
                    HStack(spacing: 10) {
                        healthMetric(latest.weight, suffix: "kg", label: "peso")
                        healthMetric(latest.bodyFat, suffix: "%", label: "grasa")
                        healthMetric(latest.waist, suffix: "cm", label: "cintura")
                    }
                    Text("Actualizado (latest.date.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundStyle(CaltrackTheme.muted)
                } else {
                    Text("Lee peso, grasa corporal y cintura directamente de Salud. Tú decides el permiso.")
                        .font(.subheadline)
                        .foregroundStyle(CaltrackTheme.muted)
                }
                Button {
                    Task {
                        await health.connectAndRead()
                        healthConnected = true
                        persistHealthSnapshot()
                        if case .failed(let message) = health.state { healthMessage = message }
                    }
                } label: {
                    HStack {
                        if health.state == .loading { ProgressView().controlSize(.small) }
                        Text(healthConnected ? "Sincronizar ahora" : "Conectar Salud")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .frame(height: 46)
                    .background(CaltrackTheme.cardRaised, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                }
                .disabled(health.state == .loading)
                if let healthMessage {
                    Text(healthMessage).font(.caption).foregroundStyle(CaltrackTheme.coral)
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
                HStack {
                    Text("\(Int(todayTotals.protein)) g proteína")
                    Spacer()
                    Text("objetivo \(Int(proteinMin))-\(Int(proteinMax)) g")
                }
                .font(.caption)
                .foregroundStyle(CaltrackTheme.muted)

                if todayMeals.isEmpty {
                    ContentUnavailableView("Nada registrado", systemImage: "fork.knife", description: Text("La primera foto del día aparecerá aquí."))
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(CaltrackTheme.muted)
                } else {
                    ForEach(todayMeals) { meal in
                        MealRow(meal: meal) {
                            modelContext.delete(meal)
                            try? modelContext.save()
                        }
                        if meal.id != todayMeals.last?.id { Divider().overlay(CaltrackTheme.line) }
                    }
                }
            }
        }
    }

    private var coachCard: some View {
        let score = CaltrackMath.adherence(calories: todayTotals.calories, protein: todayTotals.protein, calorieRange: calorieMin...calorieMax, proteinRange: proteinMin...proteinMax)
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

    private func saveMeal(_ editable: EditableMeal, imageData: Data?) {
        let meal = MealEntry(
            name: editable.name,
            calories: editable.number(editable.calories),
            protein: editable.number(editable.protein),
            carbohydrates: editable.number(editable.carbohydrates),
            fat: editable.number(editable.fat),
            photoData: imageData,
            source: "Grok Vision",
            confidence: editable.confidence,
            assumption: editable.assumption
        )
        modelContext.insert(meal)
        try? modelContext.save()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func persistHealthSnapshot() {
        guard let snapshot = health.snapshot,
              snapshot.weight != nil || snapshot.bodyFat != nil || snapshot.waist != nil else { return }
        if let existing = measurements.first(where: { $0.source == "HealthKit" && abs($0.date.timeIntervalSince(snapshot.date)) < 1 }) {
            existing.weight = snapshot.weight
            existing.bodyFat = snapshot.bodyFat
            existing.waist = snapshot.waist
        } else {
            modelContext.insert(BodyMeasurement(date: snapshot.date, weight: snapshot.weight, bodyFat: snapshot.bodyFat, waist: snapshot.waist, source: "HealthKit"))
        }
        try? modelContext.save()
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
        return "Proteína cubierta y calorías dentro del rango configurado."
    }
}

private struct DayTotal: Identifiable {
    let date: Date
    let calories: Double
    var id: Date { date }
    var label: String { date.formatted(.dateTime.weekday(.narrow)) }
}

private struct MealRow: View {
    let meal: MealEntry
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
                Text("\(Int(meal.protein)) g P · \(Int(meal.carbohydrates)) g C · \(Int(meal.fat)) g G")
                    .font(.caption2).foregroundStyle(CaltrackTheme.muted)
            }
            Spacer()
            Text("\(Int(meal.calories)) kcal").font(.subheadline.weight(.bold))
            Menu {
                Button("Eliminar", systemImage: "trash", role: .destructive, action: delete)
            } label: {
                Image(systemName: "ellipsis").frame(width: 30, height: 40)
            }
        }
    }
}
