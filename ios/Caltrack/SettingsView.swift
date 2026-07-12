import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("calorieMin") private var calorieMin = 1_800.0
    @AppStorage("calorieMax") private var calorieMax = 2_000.0
    @AppStorage("proteinMin") private var proteinMin = 160.0
    @AppStorage("proteinMax") private var proteinMax = 190.0
    @State private var apiKey = ""
    @State private var hevyKey = ""
    @State private var keySaved = false
    @State private var hevyKeySaved = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Grok Vision") {
                    SecureField("xai-…", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Text("Se guarda cifrada en Keychain y se envía solo a api.x.ai. Nunca se añade al repositorio.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button(keySaved ? "Clave guardada" : "Guardar clave") { saveKey() }
                        .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    if KeychainStore.read(account: GrokService.apiKeyAccount) != nil {
                        Button("Eliminar clave", role: .destructive) {
                            KeychainStore.remove(account: GrokService.apiKeyAccount)
                            apiKey = ""
                            keySaved = false
                        }
                    }
                }

                Section("Hevy Pro") {
                    SecureField("Clave de API de Hevy", text: $hevyKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Text("Añade el detalle de ejercicios, series, repeticiones, cargas, RPE y volumen. La API oficial requiere Hevy Pro.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button(hevyKeySaved ? "Clave de Hevy guardada" : "Guardar clave de Hevy") { saveHevyKey() }
                        .disabled(hevyKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Link("Crear o copiar clave en Hevy", destination: URL(string: "https://hevy.com/settings?developer")!)
                    if KeychainStore.read(account: HevyService.apiKeyAccount) != nil {
                        Button("Eliminar clave de Hevy", role: .destructive) {
                            KeychainStore.remove(account: HevyService.apiKeyAccount)
                            hevyKey = ""
                            hevyKeySaved = false
                        }
                    }
                }

                Section("Strava") {
                    Text("Caltrack importa Strava desde Apple Salud. En Strava activa Ajustes > Gestionar apps y dispositivos > Salud > Enviar a Salud.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Label("No necesita clave ni acceso a tu cuenta de Strava", systemImage: "checkmark.shield")
                }

                Section("Objetivos diarios") {
                    numberRow("Calorías mínimas", value: $calorieMin, step: 50)
                    numberRow("Calorías máximas", value: $calorieMax, step: 50)
                    numberRow("Proteína mínima", value: $proteinMin, step: 5)
                    numberRow("Proteína máxima", value: $proteinMax, step: 5)
                }

                Section("Privacidad") {
                    Label("Las comidas y fotos se guardan en este iPhone", systemImage: "iphone.gen3")
                    Label("Medidas y entrenamientos de Salud requieren permiso explícito", systemImage: "heart.text.square")
                    Label("Cada estimación se confirma antes de guardar", systemImage: "checkmark.seal")
                }

                if let errorMessage {
                    Section { Text(errorMessage).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Listo") { dismiss() } }
            }
            .onAppear {
                if KeychainStore.read(account: GrokService.apiKeyAccount) != nil { keySaved = true }
                if KeychainStore.read(account: HevyService.apiKeyAccount) != nil { hevyKeySaved = true }
            }
        }
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

    private func saveKey() {
        do {
            try KeychainStore.save(apiKey.trimmingCharacters(in: .whitespacesAndNewlines), account: GrokService.apiKeyAccount)
            keySaved = true
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveHevyKey() {
        do {
            try KeychainStore.save(hevyKey.trimmingCharacters(in: .whitespacesAndNewlines), account: HevyService.apiKeyAccount)
            hevyKeySaved = true
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
