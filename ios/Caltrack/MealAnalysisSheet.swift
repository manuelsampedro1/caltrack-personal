import SwiftUI
import UIKit

struct MealAnalysisSheet: View {
    enum Phase {
        case loading
        case result(FoodAnalysis)
        case failed(String)
        case manual
    }

    let image: UIImage
    let onSave: (EditableMeal, Data?) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var phase: Phase = .loading
    @State private var editable = EditableMeal()
    @State private var hasStarted = false

    var body: some View {
        NavigationStack {
            ZStack {
                CaltrackTheme.canvas.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 240)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                        switch phase {
                        case .loading:
                            analyzingView
                        case .result(let analysis):
                            resultView(analysis)
                        case .failed(let message):
                            errorView(message)
                        case .manual:
                            editor
                        }
                    }
                    .padding(14)
                }
            }
            .navigationTitle("Analizar comida")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .task { await startOnce() }
        }
        .presentationDetents([.large])
    }

    private var analyzingView: some View {
        Card {
            VStack(spacing: 14) {
                ProgressView().controlSize(.large).tint(CaltrackTheme.green)
                Text("Grok está mirando el plato")
                    .font(.headline)
                Text("Identificando alimentos, porciones, aceite, salsas y macros.")
                    .font(.subheadline)
                    .foregroundStyle(CaltrackTheme.muted)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
        }
    }

    private func resultView(_ analysis: FoodAnalysis) -> some View {
        VStack(spacing: 14) {
            Card {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Eyebrow(text: "Estimación de Grok")
                            Text(analysis.title).font(.title3.weight(.bold))
                        }
                        Spacer()
                        MetricPill(text: "\(Int(analysis.confidence * 100))% confianza", color: analysis.confidence >= 0.75 ? CaltrackTheme.green.opacity(0.22) : CaltrackTheme.coral.opacity(0.2))
                    }
                    ForEach(analysis.items) { item in
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name).font(.subheadline.weight(.semibold))
                                Text(item.portion).font(.caption).foregroundStyle(CaltrackTheme.muted)
                            }
                            Spacer()
                            Text("\(Int(item.calories)) kcal").font(.subheadline.weight(.bold))
                        }
                        Divider().overlay(CaltrackTheme.line)
                    }
                    if !analysis.warning.isEmpty {
                        Label(analysis.warning, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(CaltrackTheme.coral)
                    }
                }
            }
            editor
        }
    }

    private var editor: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                Eyebrow(text: "Confirma antes de guardar")
                TextField("Nombre", text: $editable.name)
                    .textInputAutocapitalization(.sentences)
                    .fieldStyle()
                HStack(spacing: 10) {
                    numberField("kcal", text: $editable.calories)
                    numberField("proteína", text: $editable.protein)
                }
                HStack(spacing: 10) {
                    numberField("carbos", text: $editable.carbohydrates)
                    numberField("grasa", text: $editable.fat)
                }
                if !editable.assumption.isEmpty {
                    Text("Supuestos: \(editable.assumption)")
                        .font(.caption)
                        .foregroundStyle(CaltrackTheme.muted)
                }
                Text("La foto no permite medir cantidades exactas ni ingredientes ocultos. Corrige cualquier dato dudoso.")
                    .font(.caption2)
                    .foregroundStyle(CaltrackTheme.muted)
                Button {
                    guard editable.isValid else { return }
                    onSave(editable, image.jpegData(compressionQuality: 0.72))
                    dismiss()
                } label: {
                    Text("Guardar en el día")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .foregroundStyle(.black)
                        .background(editable.isValid ? CaltrackTheme.green : CaltrackTheme.muted, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(!editable.isValid)
            }
        }
    }

    private func errorView(_ message: String) -> some View {
        Card {
            VStack(spacing: 14) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(CaltrackTheme.coral)
                Text("No se pudo analizar").font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(CaltrackTheme.muted)
                    .multilineTextAlignment(.center)
                Button("Registrar manualmente") { phase = .manual }
                    .buttonStyle(.borderedProminent)
                    .tint(CaltrackTheme.green)
                    .foregroundStyle(.black)
                Button("Reintentar") {
                    phase = .loading
                    Task { await analyze() }
                }
                    .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }

    private func numberField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased()).font(.caption2.weight(.bold)).foregroundStyle(CaltrackTheme.muted)
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .fieldStyle()
        }
    }

    private func startOnce() async {
        guard !hasStarted else { return }
        hasStarted = true
        await analyze()
    }

    private func analyze() async {
        do {
            guard let apiKey = KeychainStore.read(account: GrokService.apiKeyAccount) else { throw GrokError.missingAPIKey }
            let analysis = try await GrokService().analyze(image: image, apiKey: apiKey)
            editable = EditableMeal(analysis: analysis)
            phase = .result(analysis)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            phase = .failed(error.localizedDescription)
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}

private extension View {
    func fieldStyle() -> some View {
        self
            .padding(.horizontal, 13)
            .frame(height: 46)
            .background(CaltrackTheme.cardRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
