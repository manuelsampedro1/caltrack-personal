import SwiftUI
import UIKit

struct BarcodeLookupSheet: View {
    private enum Phase {
        case scanning
        case manual
        case loading
        case result(BarcodeProduct)
        case failed(String)
    }

    let onSave: (EditableMeal) -> Void
    let onManual: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var phase: Phase = .scanning
    @State private var barcode = ""
    @State private var amount = "100"
    @State private var editable = EditableMeal()
    @State private var lookupStarted = false

    var body: some View {
        NavigationStack {
            ZStack {
                CaltrackTheme.canvas.ignoresSafeArea()
                content
            }
            .navigationTitle("Escanear producto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
            }
        }
        .presentationDetents([.large])
        .onAppear {
#if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-barcode-fixture") { phase = .manual }
#endif
        }
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .scanning:
            scanner
        case .manual:
            manualLookup
        case .loading:
            loading
        case .result(let product):
            result(product)
        case .failed(let message):
            failure(message)
        }
    }

    private var scanner: some View {
        ZStack {
            BarcodeScannerView { code in
                barcode = code
                lookup(code)
            } onFailure: { message in
                if case .scanning = phase { phase = .failed(message) }
            }
            LinearGradient(colors: [.black.opacity(0.72), .clear, .black.opacity(0.82)], startPoint: .top, endPoint: .bottom)
                .allowsHitTesting(false)
            VStack(spacing: 20) {
                VStack(spacing: 7) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(CaltrackTheme.green)
                    Text("Enfoca el código de barras")
                        .font(.title3.weight(.bold))
                    Text("La lectura se detiene en cuanto detecta un producto.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.76))
                        .multilineTextAlignment(.center)
                }
                Spacer()
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(CaltrackTheme.green, style: StrokeStyle(lineWidth: 3, dash: [16, 8]))
                    .frame(height: 180)
                    .padding(.horizontal, 24)
                    .accessibilityHidden(true)
                Spacer()
                Button {
                    phase = .manual
                } label: {
                    Label("Introducir código", systemImage: "keyboard")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                }
            }
            .padding(20)
        }
    }

    private var manualLookup: some View {
        ScrollView {
            VStack(spacing: 14) {
                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Eyebrow(text: "EAN o UPC")
                        Text("Busca el producto por código")
                            .font(.title2.weight(.bold))
                        Text("Solo se envía el número a Open Food Facts. Nunca se envían fotos ni datos de Salud.")
                            .font(.subheadline)
                            .foregroundStyle(CaltrackTheme.muted)
                    }
                }
                Card {
                    VStack(alignment: .leading, spacing: 14) {
                        TextField("Código de 8 a 14 dígitos", text: $barcode)
                            .keyboardType(.numberPad)
                            .textContentType(.none)
                            .padding(.horizontal, 13)
                            .frame(height: 50)
                            .background(CaltrackTheme.cardRaised, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                            .accessibilityIdentifier("barcodeField")
                        Button { lookup(barcode) } label: {
                            Label("Buscar producto", systemImage: "magnifyingglass")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .foregroundStyle(.black)
                                .background(CaltrackTheme.green, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .disabled(barcode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || lookupStarted)
                        Button("Volver a la cámara") { phase = .scanning }
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(14)
        }
        .scrollIndicators(.hidden)
    }

    private var loading: some View {
        VStack(spacing: 15) {
            ProgressView().controlSize(.large).tint(CaltrackTheme.green)
            Text("Buscando el producto").font(.headline)
            Text(barcode).font(.caption.monospaced()).foregroundStyle(CaltrackTheme.muted)
        }
    }

    private func result(_ product: BarcodeProduct) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 3) {
                                Eyebrow(text: "Producto encontrado")
                                Text(product.name).font(.title2.weight(.bold))
                                if !product.brands.isEmpty {
                                    Text(product.brands).font(.subheadline).foregroundStyle(CaltrackTheme.muted)
                                }
                            }
                            Spacer()
                            if let score = product.nutriScore {
                                MetricPill(text: "Nutri-Score \(score.uppercased())", color: nutriScoreColor(score).opacity(0.22))
                            }
                        }
                        HStack {
                            Label(product.code, systemImage: "barcode")
                            Spacer()
                            if !product.servingSize.isEmpty { Text("Ración: \(product.servingSize)") }
                        }
                        .font(.caption)
                        .foregroundStyle(CaltrackTheme.muted)
                        Text("Por 100 g: \(Int(product.caloriesPer100)) kcal · \(product.proteinPer100.formatted(.number.precision(.fractionLength(0...1)))) g P · \(product.carbohydratesPer100.formatted(.number.precision(.fractionLength(0...1)))) g C · \(product.fatPer100.formatted(.number.precision(.fractionLength(0...1)))) g G")
                            .font(.caption)
                            .foregroundStyle(CaltrackTheme.muted)
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 14) {
                        Eyebrow(text: "Confirma lo consumido")
                        VStack(alignment: .leading, spacing: 6) {
                            Text("CANTIDAD, G O ML").font(.caption2.weight(.bold)).foregroundStyle(CaltrackTheme.muted)
                            TextField("100", text: $amount)
                                .keyboardType(.decimalPad)
                                .padding(.horizontal, 13)
                                .frame(height: 46)
                                .background(CaltrackTheme.cardRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .accessibilityIdentifier("barcodeAmountField")
                                .onChange(of: amount) { _, value in updateAmount(value, product: product) }
                        }
                        TextField("Nombre", text: $editable.name)
                            .barcodeFieldStyle()
                            .accessibilityIdentifier("barcodeNameField")
                        HStack(spacing: 10) {
                            macroField("Kcal", text: $editable.calories)
                            macroField("Proteína", text: $editable.protein)
                        }
                        HStack(spacing: 10) {
                            macroField("Carbohidratos", text: $editable.carbohydrates)
                            macroField("Grasa", text: $editable.fat)
                        }
                        Label("Open Food Facts es una base colaborativa. Contrasta el resultado con la etiqueta y corrige cualquier dato dudoso.", systemImage: "checkmark.shield")
                            .font(.caption)
                            .foregroundStyle(CaltrackTheme.muted)
                        Link("Datos: Open Food Facts, ODbL", destination: URL(string: "https://world.openfoodfacts.org/terms-of-use")!)
                            .font(.caption.weight(.semibold))
                        Button {
                            guard editable.isValid else { return }
                            onSave(editable)
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            dismiss()
                        } label: {
                            Label("Guardar producto", systemImage: "checkmark.circle.fill")
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
            .padding(14)
        }
        .scrollIndicators(.hidden)
    }

    private func failure(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "barcode.viewfinder")
                .font(.system(size: 46, weight: .semibold))
                .foregroundStyle(CaltrackTheme.coral)
            Text("No se pudo completar la búsqueda").font(.title3.weight(.bold))
            Text(message).font(.subheadline).foregroundStyle(CaltrackTheme.muted).multilineTextAlignment(.center)
            Button("Introducir otro código") {
                barcode = ""
                phase = .manual
            }
            .buttonStyle(.borderedProminent)
            .tint(CaltrackTheme.green)
            .foregroundStyle(.black)
            Button("Registrar manualmente") {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { onManual() }
            }
            .buttonStyle(.bordered)
        }
        .padding(24)
    }

    private func macroField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased()).font(.caption2.weight(.bold)).foregroundStyle(CaltrackTheme.muted)
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .barcodeFieldStyle()
                .accessibilityIdentifier(macroIdentifier(label))
        }
        .frame(maxWidth: .infinity)
    }

    private func lookup(_ code: String) {
        guard !lookupStarted else { return }
        lookupStarted = true
        phase = .loading
        Task {
            defer { lookupStarted = false }
            do {
                let product: BarcodeProduct
#if DEBUG
                if ProcessInfo.processInfo.arguments.contains("-barcode-fixture") {
                    _ = try OpenFoodFactsService.normalizedBarcode(code)
                    product = .testingFixture
                } else {
                    product = try await OpenFoodFactsService().product(barcode: code)
                }
#else
                product = try await OpenFoodFactsService().product(barcode: code)
#endif
                amount = defaultAmount(product.servingSize)
                editable = product.editableMeal(amount: numericAmount)
                phase = .result(product)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } catch {
                phase = .failed(error.localizedDescription)
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        }
    }

    private var numericAmount: Double {
        Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private func updateAmount(_ value: String, product: BarcodeProduct) {
        guard Double(value.replacingOccurrences(of: ",", with: ".")) != nil else { return }
        editable = product.editableMeal(amount: numericAmount)
    }

    private func defaultAmount(_ servingSize: String) -> String {
        let token = servingSize
            .replacingOccurrences(of: ",", with: ".")
            .split(whereSeparator: { !$0.isNumber && $0 != "." })
            .first
        guard let token, let value = Double(token), value > 0 else { return "100" }
        return value.formatted(.number.precision(.fractionLength(0...1)))
    }

    private func nutriScoreColor(_ score: String) -> Color {
        switch score.lowercased() {
        case "a", "b": CaltrackTheme.green
        case "c": .yellow
        default: CaltrackTheme.coral
        }
    }

    private func macroIdentifier(_ label: String) -> String {
        switch label {
        case "Kcal": "barcodeCaloriesField"
        case "Proteína": "barcodeProteinField"
        case "Carbohidratos": "barcodeCarbohydratesField"
        default: "barcodeFatField"
        }
    }
}

private extension View {
    func barcodeFieldStyle() -> some View {
        padding(.horizontal, 13)
            .frame(height: 46)
            .background(CaltrackTheme.cardRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
