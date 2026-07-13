import SwiftData
import SwiftUI
import UIKit

struct CoachView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MealEntry.date, order: .reverse) private var meals: [MealEntry]
    @Query(sort: \BodyMeasurement.date, order: .reverse) private var measurements: [BodyMeasurement]
    @Query(sort: \ActivityDay.date, order: .reverse) private var activityDays: [ActivityDay]
    @Query(sort: \DailyPlanCheckIn.date, order: .reverse) private var planCheckIns: [DailyPlanCheckIn]
    @Query(sort: \WorkoutEntry.startDate, order: .reverse) private var workouts: [WorkoutEntry]
    @Query(sort: \CoachMessage.date) private var messages: [CoachMessage]
    @AppStorage("calorieMin") private var calorieMin = 1_800.0
    @AppStorage("calorieMax") private var calorieMax = 2_000.0
    @AppStorage("proteinMin") private var proteinMin = 160.0
    @AppStorage("proteinMax") private var proteinMax = 190.0
    @AppStorage("fiberTarget") private var fiberTarget = 25.0
    @AppStorage("planGoalMode") private var planGoalModeRaw = PlanGoalMode.notSet.rawValue
    @AppStorage("planWeeklyRate") private var planWeeklyRate = 0.5
    @State private var question = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingSettings = false

    private let quickQuestions = [
        "¿Qué debería mejorar esta semana?",
        "¿Estoy perdiendo grasa sin comprometer músculo?",
        "¿Qué patrón está frenando mi progreso?"
    ]

    private var report: InsightReport {
        InsightEngine.report(
            meals: meals,
            measurements: measurements,
            workouts: workouts,
            calorieRange: CaltrackMath.orderedRange(calorieMin, calorieMax),
            proteinRange: CaltrackMath.orderedRange(proteinMin, proteinMax),
            fiberTarget: fiberTarget
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CaltrackTheme.canvas.ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: 14) {
                        localReportCard
                        quickQuestionsCard
                        conversationCard
                    }
                    .padding(14)
                    .padding(.bottom, 88)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Entrenador")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if !messages.isEmpty {
                        Menu {
                            Button("Borrar conversación", systemImage: "trash", role: .destructive) { clearConversation() }
                        } label: { Image(systemName: "ellipsis.circle") }
                    }
                    Button { showingSettings = true } label: { Image(systemName: "gearshape.fill") }
                        .accessibilityLabel("Ajustes")
                }
            }
            .safeAreaInset(edge: .bottom) { composer }
            .sheet(isPresented: $showingSettings) { SettingsView() }
        }
    }

    private var localReportCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Eyebrow(text: "Análisis local")
                        Text(report.title).font(.title3.weight(.bold))
                    }
                    Spacer()
                    MetricPill(text: "\(report.score)%")
                }
                Text(report.summary).font(.subheadline).foregroundStyle(CaltrackTheme.muted)
                ForEach(report.observations, id: \.self) { observation in
                    Label(observation, systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                        .symbolRenderingMode(.hierarchical)
                }
            }
        }
    }

    private var quickQuestionsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Eyebrow(text: "Pregunta a Grok")
                        Text("Profundiza en tus datos").font(.title3.weight(.bold))
                    }
                    Spacer()
                    Image(systemName: "sparkles").foregroundStyle(CaltrackTheme.green)
                }
                Text("Solo al preguntar se envía a xAI un resumen de 30 días. Nunca se incluyen fotos, claves ni identificadores de Salud.")
                    .font(.caption).foregroundStyle(CaltrackTheme.muted)
                ForEach(quickQuestions, id: \.self) { prompt in
                    Button {
                        question = prompt
                        Task { await sendQuestion() }
                    } label: {
                        HStack {
                            Text(prompt).multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                        }
                        .font(.subheadline.weight(.semibold))
                        .padding(12)
                        .background(CaltrackTheme.cardRaised, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading)
                }
            }
        }
    }

    private var conversationCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "Conversación privada")
                if messages.isEmpty {
                    ContentUnavailableView("Todavía no hay preguntas", systemImage: "bubble.left.and.bubble.right", description: Text("El análisis local funciona sin IA. Configura xAI para conversar con tus datos."))
                        .foregroundStyle(CaltrackTheme.muted)
                } else {
                    ForEach(messages) { message in
                        VStack(alignment: message.role == "user" ? .trailing : .leading, spacing: 4) {
                            Text(message.role == "user" ? "Tú" : "Grok")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(CaltrackTheme.muted)
                            Text(message.content)
                                .font(.subheadline)
                                .padding(12)
                                .background(message.role == "user" ? CaltrackTheme.blue.opacity(0.2) : CaltrackTheme.cardRaised, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .textSelection(.enabled)
                        }
                        .frame(maxWidth: .infinity, alignment: message.role == "user" ? .trailing : .leading)
                    }
                }
                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                        .font(.caption).foregroundStyle(CaltrackTheme.coral)
                    if KeychainStore.read(account: GrokService.apiKeyAccount) == nil {
                        Button("Configurar xAI") { showingSettings = true }
                            .font(.subheadline.weight(.semibold))
                    }
                }
                if isLoading {
                    HStack(spacing: 9) {
                        ProgressView().controlSize(.small).tint(CaltrackTheme.green)
                        Text("Grok está revisando tus tendencias").font(.caption).foregroundStyle(CaltrackTheme.muted)
                    }
                }
            }
        }
    }

    private var composer: some View {
        HStack(spacing: 10) {
            TextField("Pregunta sobre tu progreso", text: $question, axis: .vertical)
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(CaltrackTheme.cardRaised, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                .submitLabel(.send)
                .onSubmit { Task { await sendQuestion() } }
            Button { Task { await sendQuestion() } } label: {
                Image(systemName: "arrow.up")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.black)
                    .frame(width: 44, height: 44)
                    .background(CaltrackTheme.green, in: Circle())
            }
            .disabled(question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            .accessibilityLabel("Enviar pregunta")
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }

    @MainActor
    private func sendQuestion() async {
        let prompt = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty, !isLoading else { return }
        guard let apiKey = KeychainStore.read(account: GrokService.apiKeyAccount) else {
            errorMessage = GrokError.missingAPIKey.localizedDescription
            return
        }
        question = ""
        errorMessage = nil
        isLoading = true
        let userMessage = CoachMessage(role: "user", content: prompt)
        modelContext.insert(userMessage)
        try? modelContext.save()
        do {
            let context = CoachContextBuilder.build(
                meals: meals,
                measurements: measurements,
                workouts: workouts,
                activities: activityDays,
                checkIns: planCheckIns,
                planMode: PlanGoalMode(rawValue: planGoalModeRaw) ?? .notSet,
                planWeeklyRate: planWeeklyRate,
                calorieRange: CaltrackMath.orderedRange(calorieMin, calorieMax),
                proteinRange: CaltrackMath.orderedRange(proteinMin, proteinMax),
                fiberTarget: fiberTarget
            )
            let response = try await CoachService().ask(question: prompt, context: context, apiKey: apiKey)
            modelContext.insert(CoachMessage(role: "assistant", content: response))
            try modelContext.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            errorMessage = error.localizedDescription
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        isLoading = false
    }

    private func clearConversation() {
        messages.forEach(modelContext.delete)
        try? modelContext.save()
    }
}
