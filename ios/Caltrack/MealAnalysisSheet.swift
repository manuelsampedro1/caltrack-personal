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
                    Label(
                        analysis.items.count == 1 ? "1 componente detectado" : "\(analysis.items.count) componentes detectados",
                        systemImage: "viewfinder.circle.fill"
                    )
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CaltrackTheme.green)
                    if !analysis.warning.isEmpty {
                        Label(analysis.warning, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(CaltrackTheme.coral)
                    }
                }
            }
            MealComponentsEditor(meal: $editable, startsExpanded: true)
            editor
        }
    }

    private var editor: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                Eyebrow(text: "Total final")
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
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-grok-analysis-fixture") {
            let analysis = MealAnalysisFixture.analysis
            editable = EditableMeal(analysis: analysis)
            phase = .result(analysis)
            return
        }
#endif
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

#if DEBUG
enum MealAnalysisFixture {
    static let analysis = FoodAnalysis(
        title: "Pollo, arroz y verduras",
        items: [
            .init(name: "Pechuga de pollo", portion: "220 g", calories: 330, proteinG: 55, carbsG: 0, fatG: 8),
            .init(name: "Arroz cocido", portion: "250 g", calories: 330, proteinG: 7, carbsG: 74, fatG: 2),
            .init(name: "Brócoli y zanahoria", portion: "180 g", calories: 90, proteinG: 5, carbsG: 15, fatG: 1),
            .init(name: "Aceite de oliva", portion: "7 g", calories: 60, proteinG: 0, carbsG: 0, fatG: 7)
        ],
        calories: 810,
        proteinG: 67,
        carbsG: 89,
        fatG: 18,
        confidence: 0.86,
        assumptions: ["Arroz cocido", "Una cucharada pequeña de aceite"],
        warning: "Comprueba el aceite y la cantidad de arroz."
    )

    static var image: UIImage {
        let size = CGSize(width: 900, height: 700)
        return UIGraphicsImageRenderer(size: size).image { context in
            UIColor(red: 0.06, green: 0.07, blue: 0.09, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            UIColor(red: 0.88, green: 0.86, blue: 0.80, alpha: 1).setFill()
            context.cgContext.fillEllipse(in: CGRect(x: 125, y: 25, width: 650, height: 650))
            UIColor(red: 0.83, green: 0.69, blue: 0.45, alpha: 1).setFill()
            context.cgContext.fillEllipse(in: CGRect(x: 190, y: 110, width: 300, height: 250))
            UIColor(red: 0.64, green: 0.31, blue: 0.18, alpha: 1).setFill()
            context.cgContext.fill(CGRect(x: 450, y: 135, width: 230, height: 95))
            context.cgContext.fill(CGRect(x: 430, y: 250, width: 250, height: 90))
            UIColor(red: 0.23, green: 0.55, blue: 0.26, alpha: 1).setFill()
            for origin in [CGPoint(x: 250, y: 400), CGPoint(x: 370, y: 430), CGPoint(x: 520, y: 405), CGPoint(x: 610, y: 465)] {
                context.cgContext.fillEllipse(in: CGRect(origin: origin, size: CGSize(width: 110, height: 100)))
            }
            UIColor(red: 0.91, green: 0.46, blue: 0.16, alpha: 1).setFill()
            context.cgContext.fillEllipse(in: CGRect(x: 440, y: 500, width: 150, height: 55))
        }
    }
}
#endif

private extension View {
    func fieldStyle() -> some View {
        self
            .padding(.horizontal, 13)
            .frame(height: 46)
            .background(CaltrackTheme.cardRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
