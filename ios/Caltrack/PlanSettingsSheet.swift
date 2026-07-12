import SwiftUI
import UIKit

struct PlanSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let save: (PlanGoalMode, Double, Double?) -> Void
    @State private var mode: PlanGoalMode
    @State private var weeklyRate: Double
    @State private var targetWeight: String

    init(mode: PlanGoalMode, weeklyRate: Double, targetWeight: Double?, save: @escaping (PlanGoalMode, Double, Double?) -> Void) {
        self.save = save
        _mode = State(initialValue: mode == .notSet ? .lose : mode)
        _weeklyRate = State(initialValue: weeklyRate == 0 ? 0.5 : weeklyRate)
        _targetWeight = State(initialValue: targetWeight.map { $0.formatted(.number.precision(.fractionLength(0...1))) } ?? "")
    }

    private var parsedTargetWeight: Double? {
        guard !targetWeight.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return Double(targetWeight.replacingOccurrences(of: ",", with: "."))
    }

    private var targetIsValid: Bool {
        guard let parsedTargetWeight else { return targetWeight.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return (20...400).contains(parsedTargetWeight)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Objetivo", selection: $mode) {
                        Text("Perder").tag(PlanGoalMode.lose)
                        Text("Mantener").tag(PlanGoalMode.maintain)
                        Text("Ganar").tag(PlanGoalMode.gain)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("planGoalMode")
                } header: {
                    Text("Objetivo")
                } footer: {
                    Text("Caltrack compara tu tendencia real con este rumbo. No calcula un diagnóstico ni cambia el plan sin tu permiso.")
                }

                if mode != .maintain {
                    Section {
                        Picker("Ritmo", selection: $weeklyRate) {
                            Text("0,25 kg").tag(0.25)
                            Text("0,50 kg").tag(0.5)
                        }
                        .pickerStyle(.segmented)
                        .accessibilityIdentifier("planWeeklyRate")
                    } header: {
                        Text("Ritmo semanal")
                    } footer: {
                        Text("Se usa como referencia de tendencia, no como promesa de resultado.")
                    }
                }

                Section {
                    TextField("Opcional", text: $targetWeight)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("planTargetWeight")
                    if !targetIsValid {
                        Text("Introduce un peso entre 20 y 400 kg.")
                            .font(.caption)
                            .foregroundStyle(CaltrackTheme.coral)
                    }
                } header: {
                    Text("Peso objetivo, kg")
                } footer: {
                    Text("Sirve para mostrar contexto. No modifica por sí solo tus calorías.")
                }

                Section {
                    Label("7 días cerrados como mínimo", systemImage: "checkmark.circle")
                    Label("3 pesos separados por una semana", systemImage: "scalemass")
                    Label("Ajustes de 100 kcal con confirmación", systemImage: "hand.tap")
                } header: {
                    Text("Cómo decide")
                }
            }
            .scrollContentBackground(.hidden)
            .background(CaltrackTheme.canvas)
            .navigationTitle("Plan adaptativo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        save(mode, mode == .maintain ? 0 : weeklyRate, parsedTargetWeight)
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        dismiss()
                    }
                    .disabled(!targetIsValid)
                    .accessibilityIdentifier("savePlanSettings")
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
