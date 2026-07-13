import AppIntents
import SwiftData
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MealEntry.date, order: .reverse) private var meals: [MealEntry]
    @Query(sort: \BodyMeasurement.date, order: .reverse) private var measurements: [BodyMeasurement]
    @Query(sort: \ActivityDay.date, order: .reverse) private var activityDays: [ActivityDay]
    @Query(sort: \RecoveryDay.date, order: .reverse) private var recoveryDays: [RecoveryDay]
    @Query(sort: \DailyPlanCheckIn.date, order: .reverse) private var planCheckIns: [DailyPlanCheckIn]
    @Query(sort: \WorkoutEntry.startDate, order: .reverse) private var workouts: [WorkoutEntry]
    @Query(sort: \CoachMessage.date) private var messages: [CoachMessage]
    @AppStorage("calorieMin") private var calorieMin = 1_800.0
    @AppStorage("calorieMax") private var calorieMax = 2_000.0
    @AppStorage("proteinMin") private var proteinMin = 160.0
    @AppStorage("proteinMax") private var proteinMax = 190.0
    @AppStorage("fiberTarget") private var fiberTarget = 25.0
    @AppStorage("hevyConnected") private var hevyConnected = false
    @AppStorage("grokConnected") private var grokConnected = false
    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @AppStorage("reminderHour") private var reminderHour = 21
    @AppStorage("reminderMinute") private var reminderMinute = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("healthNutritionEnabled") private var healthNutritionEnabled = false
    @AppStorage("planGoalMode") private var planGoalModeRaw = PlanGoalMode.notSet.rawValue
    @AppStorage("planWeeklyRate") private var planWeeklyRate = 0.5
    @AppStorage("planTargetWeight") private var planTargetWeight = 0.0
    @AppStorage("planLastAdjustmentTimestamp") private var planLastAdjustmentTimestamp = 0.0
    @State private var apiKey = ""
    @State private var hevyKey = ""
    @State private var validatingGrok = false
    @State private var validatingHevy = false
    @State private var grokMessage: String?
    @State private var hevyMessage: String?
    @State private var reminderMessage: String?
    @State private var backupMessage: String?
    @State private var backupDocument: CaltrackBackupDocument?
    @State private var showingExporter = false
    @State private var showingImporter = false
    @State private var healthNutritionMessage: String?
    @State private var healthNutritionSyncing = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("Salud se conecta desde la primera tarjeta de Caltrack. Lee peso, composición, recuperación y entrenamientos solo después de mostrar el permiso de Apple.", systemImage: "heart.text.square.fill")
                        .font(.subheadline)
                    Toggle("Guardar nutrición en Salud", isOn: $healthNutritionEnabled)
                        .onChange(of: healthNutritionEnabled) { _, enabled in
                            Task { await updateHealthNutrition(enabled: enabled) }
                        }
                    if healthNutritionEnabled {
                        Button {
                            Task { await syncNutritionHistory() }
                        } label: {
                            HStack {
                                if healthNutritionSyncing { ProgressView().controlSize(.small) }
                                Label("Sincronizar comidas existentes", systemImage: "arrow.triangle.2.circlepath")
                            }
                        }
                        .disabled(healthNutritionSyncing)
                    }
                    if let healthNutritionMessage {
                        Text(healthNutritionMessage)
                            .font(.caption)
                            .foregroundStyle(healthNutritionEnabled ? .secondary : CaltrackTheme.coral)
                    }
                } header: {
                    Text("Apple Salud")
                } footer: {
                    Text("La escritura es opcional. Caltrack guarda como comida las calorías, proteína, carbohidratos, grasa y fibra que confirmes. Si no autorizas fibra, los cuatro nutrientes anteriores siguen sincronizando. Desactivarla no borra datos ya guardados.")
                }

                Section {
                    connectionHeader(
                        title: "Análisis de comidas",
                        connected: KeychainStore.read(account: GrokService.apiKeyAccount) != nil,
                        color: CaltrackTheme.green
                    )
                    SecureField("Clave de xAI", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .privacySensitive()
                    Button {
                        Task { await validateAndSaveGrok() }
                    } label: {
                        validationButton(title: "Validar y guardar xAI", loading: validatingGrok)
                    }
                    .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || validatingGrok)
                    Link("Crear clave en xAI", destination: URL(string: "https://console.x.ai/")!)
                    if let grokMessage { statusText(grokMessage, success: grokConnected) }
                    if KeychainStore.read(account: GrokService.apiKeyAccount) != nil {
                        Button("Eliminar clave de xAI", role: .destructive) {
                            KeychainStore.remove(account: GrokService.apiKeyAccount)
                            apiKey = ""
                            grokConnected = false
                            grokMessage = "Clave eliminada"
                        }
                    }
                } header: {
                    Text("Grok Vision")
                } footer: {
                    Text("Grok analiza la foto y devuelve alimentos, porciones y macros editables. No necesitas una segunda clave de OpenAI.")
                }

                Section {
                    connectionHeader(
                        title: "Detalle de fuerza",
                        connected: KeychainStore.read(account: HevyService.apiKeyAccount) != nil,
                        color: CaltrackTheme.blue
                    )
                    SecureField("Clave de API de Hevy", text: $hevyKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .privacySensitive()
                    Button {
                        Task { await validateAndSaveHevy() }
                    } label: {
                        validationButton(title: "Validar y conectar Hevy", loading: validatingHevy)
                    }
                    .disabled(hevyKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || validatingHevy)
                    Link("Crear o copiar clave en Hevy", destination: URL(string: "https://hevy.com/settings?developer")!)
                    if let hevyMessage { statusText(hevyMessage, success: hevyConnected) }
                    if KeychainStore.read(account: HevyService.apiKeyAccount) != nil {
                        Button("Desconectar Hevy", role: .destructive) {
                            KeychainStore.remove(account: HevyService.apiKeyAccount)
                            hevyKey = ""
                            hevyConnected = false
                            hevyMessage = "Hevy desconectado"
                        }
                    }
                } header: {
                    Text("Hevy Pro")
                } footer: {
                    Text("Añade rutina, ejercicios, series, repeticiones, cargas, RPE y volumen. La clave se valida antes de guardarse y permanece en Keychain.")
                }

                Section("Strava") {
                    Text("En Strava activa Ajustes > Gestionar apps y dispositivos > Salud > Enviar a Salud. Caltrack lo importará desde Apple Salud.")
                        .font(.subheadline)
                    Label("No necesita clave ni acceso directo a Strava", systemImage: "checkmark.shield")
                        .foregroundStyle(.secondary)
                }

                Section("Objetivos diarios") {
                    numberRow("Calorías mínimas", value: pairedMinimum($calorieMin, maximum: $calorieMax), range: 1_000...6_000, step: 50)
                    numberRow("Calorías máximas", value: pairedMaximum($calorieMax, minimum: $calorieMin), range: 1_000...6_000, step: 50)
                    numberRow("Proteína mínima", value: pairedMinimum($proteinMin, maximum: $proteinMax), range: 0...500, step: 5)
                    numberRow("Proteína máxima", value: pairedMaximum($proteinMax, minimum: $proteinMin), range: 0...500, step: 5)
                    numberRow("Fibra", value: $fiberTarget, range: 5...60, step: 1)
                }

                Section {
                    Toggle("Recordatorio diario", isOn: $reminderEnabled)
                        .onChange(of: reminderEnabled) { _, enabled in
                            Task { await updateReminder(enabled: enabled) }
                        }
                    if reminderEnabled {
                        DatePicker("Hora", selection: reminderTime, displayedComponents: .hourAndMinute)
                    }
                    if let reminderMessage {
                        Text(reminderMessage).font(.caption).foregroundStyle(reminderEnabled ? .secondary : CaltrackTheme.coral)
                    }
                } header: {
                    Text("Recordatorio")
                } footer: {
                    Text("Se programa en el iPhone. No usa servidor, seguimiento ni notificaciones comerciales.")
                }

                Section {
                    shortcutRow("Fotografiar comida", phrase: "Fotografiar comida con Caltrack", icon: "camera.fill")
                    shortcutRow("Escanear producto", phrase: "Escanear producto con Caltrack", icon: "barcode.viewfinder")
                    shortcutRow("Nuevo check-in", phrase: "Nuevo check-in en Caltrack", icon: "scalemass.fill")
                    shortcutRow("Abrir progreso", phrase: "Ver mi progreso en Caltrack", icon: "chart.xyaxis.line")
                    ShortcutsLink {}
                        .shortcutsLinkStyle(.dark)
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel("Abrir Atajos")
                        .accessibilityIdentifier("openSystemShortcuts")
                } header: {
                    Text("Atajos y Siri")
                } footer: {
                    Text("Úsalos desde Siri, Spotlight, Atajos o el botón Acción. Solo abren la pantalla elegida y no comparten tus datos.")
                }

                Section {
                    Button {
                        backupDocument = CaltrackBackupDocument(backup: BackupService.make(
                            meals: meals,
                            measurements: measurements,
                            activities: activityDays,
                            recovery: recoveryDays,
                            checkIns: planCheckIns,
                            planSettings: .init(
                                goalMode: planGoalModeRaw,
                                weeklyRate: planWeeklyRate,
                                targetWeight: planTargetWeight > 0 ? planTargetWeight : nil,
                                lastAdjustmentTimestamp: planLastAdjustmentTimestamp > 0 ? planLastAdjustmentTimestamp : nil,
                                calorieMin: calorieMin,
                                calorieMax: calorieMax,
                                proteinMin: proteinMin,
                                proteinMax: proteinMax,
                                fiberTarget: fiberTarget
                            ),
                            workouts: workouts,
                            messages: messages
                        ))
                        showingExporter = true
                    } label: {
                        Label("Exportar copia privada", systemImage: "square.and.arrow.up")
                    }
                    Button { showingImporter = true } label: {
                        Label("Restaurar o fusionar copia", systemImage: "square.and.arrow.down")
                    }
                    if let backupMessage {
                        Text(backupMessage).font(.caption).foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Tus datos")
                } footer: {
                    Text("El JSON incluye comidas, componentes, fibra, fotos, medidas, recuperación, cierres diarios, objetivos, entrenamientos y conversación. Nunca incluye claves de xAI o Hevy.")
                }

                Section("Privacidad") {
                    Label("Comidas, recuperación, fotos y entrenamientos se guardan en este iPhone", systemImage: "iphone.gen3")
                    Label("Salud requiere permiso explícito", systemImage: "heart.text.square")
                    Label("Cada estimación se confirma antes de guardar", systemImage: "checkmark.seal")
                }

                Section("Ayuda") {
                    Button {
                        hasCompletedOnboarding = false
                        dismiss()
                    } label: {
                        Label("Ver introducción", systemImage: "questionmark.circle")
                    }
                }
            }
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Listo") { dismiss() } }
            }
            .onAppear {
                grokConnected = KeychainStore.read(account: GrokService.apiKeyAccount) != nil
                hevyConnected = KeychainStore.read(account: HevyService.apiKeyAccount) != nil
            }
        }
        .fileExporter(
            isPresented: $showingExporter,
            document: backupDocument,
            contentTypes: [.json],
            defaultFilename: "Caltrack-\(Date.now.formatted(.iso8601.year().month().day()))"
        ) { result in
            switch result {
            case .success:
                backupMessage = "Copia exportada correctamente"
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            case .failure(let error):
                backupMessage = "No se pudo exportar: \(error.localizedDescription)"
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        }
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json]) { result in
            do {
                let url = try result.get()
                let accessing = url.startAccessingSecurityScopedResource()
                defer { if accessing { url.stopAccessingSecurityScopedResource() } }
                let backup = try BackupService.decode(Data(contentsOf: url))
                let count = try BackupService.restore(backup, into: modelContext)
                backupMessage = count == 0 ? "La copia ya estaba completamente restaurada" : "Restaurados \(count) registros"
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } catch {
                backupMessage = "No se pudo restaurar: \(error.localizedDescription)"
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        }
    }

    private func connectionHeader(title: String, connected: Bool, color: Color) -> some View {
        HStack {
            Text(title).font(.subheadline.weight(.semibold))
            Spacer()
            Label(connected ? "Preparado" : "Sin configurar", systemImage: connected ? "checkmark.circle.fill" : "circle.dashed")
                .font(.caption.weight(.semibold))
                .foregroundStyle(connected ? color : .secondary)
        }
    }

    private func shortcutRow(_ title: String, phrase: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(CaltrackTheme.green)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text("“\(phrase)”").font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func validationButton(title: String, loading: Bool) -> some View {
        HStack {
            if loading { ProgressView().controlSize(.small) }
            Text(loading ? "Comprobando…" : title)
        }
        .frame(maxWidth: .infinity)
    }

    private func statusText(_ text: String, success: Bool) -> some View {
        Label(text, systemImage: success ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
            .font(.caption)
            .foregroundStyle(success ? CaltrackTheme.green : CaltrackTheme.coral)
    }

    private func numberRow(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double) -> some View {
        Stepper(value: value, in: range, step: step) {
            HStack {
                Text(title)
                Spacer()
                Text(Int(value.wrappedValue).formatted()).foregroundStyle(.secondary)
            }
        }
    }

    private func pairedMinimum(_ minimum: Binding<Double>, maximum: Binding<Double>) -> Binding<Double> {
        Binding {
            minimum.wrappedValue
        } set: { newValue in
            minimum.wrappedValue = newValue
            if maximum.wrappedValue < newValue { maximum.wrappedValue = newValue }
        }
    }

    private func pairedMaximum(_ maximum: Binding<Double>, minimum: Binding<Double>) -> Binding<Double> {
        Binding {
            maximum.wrappedValue
        } set: { newValue in
            maximum.wrappedValue = newValue
            if minimum.wrappedValue > newValue { minimum.wrappedValue = newValue }
        }
    }

    private var reminderTime: Binding<Date> {
        Binding {
            Calendar.current.date(bySettingHour: reminderHour, minute: reminderMinute, second: 0, of: .now) ?? .now
        } set: { date in
            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            reminderHour = components.hour ?? 21
            reminderMinute = components.minute ?? 0
            guard reminderEnabled else { return }
            Task { await updateReminder(enabled: true) }
        }
    }

    @MainActor
    private func updateReminder(enabled: Bool) async {
        if !enabled {
            ReminderService.cancel()
            reminderMessage = "Recordatorio desactivado"
            return
        }
        do {
            try await ReminderService.scheduleDaily(hour: reminderHour, minute: reminderMinute)
            reminderMessage = "Te avisaremos cada día a las \(String(format: "%02d:%02d", reminderHour, reminderMinute))"
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            reminderEnabled = false
            reminderMessage = error.localizedDescription
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }

    @MainActor
    private func updateHealthNutrition(enabled: Bool) async {
        guard enabled else {
            healthNutritionMessage = "Las nuevas comidas no se enviarán a Salud"
            return
        }
        do {
            try await HealthNutritionService().requestAuthorization()
            healthNutritionMessage = "Las nuevas comidas se guardarán también en Salud"
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            healthNutritionEnabled = false
            healthNutritionMessage = error.localizedDescription
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }

    @MainActor
    private func syncNutritionHistory() async {
        healthNutritionSyncing = true
        defer { healthNutritionSyncing = false }
        do {
            let service = HealthNutritionService()
            try await service.requestAuthorization()
            let count = try await service.syncAll(meals)
            healthNutritionMessage = count == 1 ? "1 comida sincronizada con Salud" : "\(count) comidas sincronizadas con Salud"
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            healthNutritionMessage = error.localizedDescription
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }

    @MainActor
    private func validateAndSaveGrok() async {
        let candidate = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        validatingGrok = true
        grokMessage = nil
        defer { validatingGrok = false }
        do {
            try await GrokService().validateAPIKey(candidate)
            try KeychainStore.save(candidate, account: GrokService.apiKeyAccount)
            apiKey = ""
            grokConnected = true
            grokMessage = "xAI preparado para analizar fotos"
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            grokConnected = KeychainStore.read(account: GrokService.apiKeyAccount) != nil
            grokMessage = error.localizedDescription
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }

    @MainActor
    private func validateAndSaveHevy() async {
        let candidate = hevyKey.trimmingCharacters(in: .whitespacesAndNewlines)
        validatingHevy = true
        hevyMessage = nil
        defer { validatingHevy = false }
        do {
            let workouts = try await HevyService().fetchRecentWorkouts(apiKey: candidate, pageSize: 1)
            try KeychainStore.save(candidate, account: HevyService.apiKeyAccount)
            hevyKey = ""
            hevyConnected = true
            hevyMessage = workouts.first.map { "Conectado. Último: \($0.title)" } ?? "Conectado. Todavía no hay entrenamientos"
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            hevyConnected = KeychainStore.read(account: HevyService.apiKeyAccount) != nil
            hevyMessage = error.localizedDescription
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}
