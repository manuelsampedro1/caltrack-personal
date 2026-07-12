import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("calorieMin") private var calorieMin = 1_800.0
    @AppStorage("calorieMax") private var calorieMax = 2_000.0
    @AppStorage("proteinMin") private var proteinMin = 160.0
    @AppStorage("proteinMax") private var proteinMax = 190.0
    @State private var apiKey = ""
    @State private var keySaved = false
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

                Section("Objetivos diarios") {
                    numberRow("Calorías mínimas", value: $calorieMin, step: 50)
                    numberRow("Calorías máximas", value: $calorieMax, step: 50)
                    numberRow("Proteína mínima", value: $proteinMin, step: 5)
                    numberRow("Proteína máxima", value: $proteinMax, step: 5)
                }

                Section("Privacidad") {
                    Label("Las comidas y fotos se guardan en este iPhone", systemImage: "iphone.gen3")
                    Label("Salud requiere permiso explícito de Apple", systemImage: "heart.text.square")
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
}
