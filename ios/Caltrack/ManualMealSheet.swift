import SwiftUI
import UIKit

struct ManualMealSheet: View {
    let title: String
    let onSave: (EditableMeal, Date) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var editable: EditableMeal
    @State private var date: Date
    private let showsComponentsEditor: Bool

    init(title: String = "Registrar manualmente", initial: EditableMeal = EditableMeal(), date: Date = .now, onSave: @escaping (EditableMeal, Date) -> Void) {
        self.title = title
        self.onSave = onSave
        self.showsComponentsEditor = !initial.components.isEmpty
        _editable = State(initialValue: initial)
        _date = State(initialValue: date)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CaltrackTheme.canvas.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        if !showsComponentsEditor {
                            Card {
                                VStack(alignment: .leading, spacing: 8) {
                                    Eyebrow(text: "Entrada exacta")
                                    Text("Añade lo que ya conoces")
                                        .font(.title2.weight(.bold))
                                    Text("Ideal para etiquetas, recetas pesadas o una corrección rápida.")
                                        .font(.subheadline)
                                        .foregroundStyle(CaltrackTheme.muted)
                                }
                            }
                        }

                        if showsComponentsEditor {
                            MealComponentsEditor(meal: $editable, startsExpanded: false)
                        }

                        Card {
                            VStack(alignment: .leading, spacing: 14) {
                                manualField("Nombre", text: $editable.name, keyboard: .default)
                                DatePicker("Momento", selection: $date, displayedComponents: [.date, .hourAndMinute])
                                    .tint(CaltrackTheme.green)
                                HStack(spacing: 10) {
                                    manualField("Kcal", text: $editable.calories)
                                    manualField("Proteína", text: $editable.protein)
                                }
                                HStack(spacing: 10) {
                                    manualField("Carbohidratos", text: $editable.carbohydrates)
                                    manualField("Grasa", text: $editable.fat)
                                }

                                Button {
                                    onSave(editable, date)
                                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                                    dismiss()
                                } label: {
                                    Label("Guardar comida", systemImage: "checkmark.circle.fill")
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
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
            }
        }
    }

    private func manualField(_ label: String, text: Binding<String>, keyboard: UIKeyboardType = .decimalPad) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(CaltrackTheme.muted)
            TextField(label, text: text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(keyboard == .default ? .sentences : .never)
                .padding(.horizontal, 13)
                .frame(height: 46)
                .background(CaltrackTheme.cardRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .frame(maxWidth: .infinity)
    }
}
