import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("calorieMin") private var calorieMin = 1_800.0
    @AppStorage("calorieMax") private var calorieMax = 2_000.0
    @AppStorage("proteinMin") private var proteinMin = 160.0
    @AppStorage("proteinMax") private var proteinMax = 190.0
    @AppStorage("hevyConnected") private var hevyConnected = false
    @AppStorage("grokConnected") private var grokConnected = false
    @State private var apiKey = ""
    @State private var hevyKey = ""
    @State private var validatingGrok = false
    @State private var validatingHevy = false
    @State private var grokMessage: String?
    @State private var hevyMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("Salud se conecta desde la primera tarjeta de Caltrack. Lee peso, composición y entrenamientos solo después de mostrar el permiso de Apple.", systemImage: "heart.text.square.fill")
                        .font(.subheadline)
                } header: {
                    Text("Apple Salud")
                } footer: {
                    Text("Esta conexión solo existe en la app nativa instalada en el iPhone. Safari y la PWA no pueden acceder a HealthKit.")
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
                    numberRow("Calorías mínimas", value: $calorieMin, step: 50)
                    numberRow("Calorías máximas", value: $calorieMax, step: 50)
                    numberRow("Proteína mínima", value: $proteinMin, step: 5)
                    numberRow("Proteína máxima", value: $proteinMax, step: 5)
                }

                Section("Privacidad") {
                    Label("Comidas, fotos y entrenamientos se guardan en este iPhone", systemImage: "iphone.gen3")
                    Label("Salud requiere permiso explícito", systemImage: "heart.text.square")
                    Label("Cada estimación se confirma antes de guardar", systemImage: "checkmark.seal")
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

    private func numberRow(_ title: String, value: Binding<Double>, step: Double) -> some View {
        Stepper(value: value, in: 0...6_000, step: step) {
            HStack {
                Text(title)
                Spacer()
                Text(Int(value.wrappedValue).formatted()).foregroundStyle(.secondary)
            }
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
