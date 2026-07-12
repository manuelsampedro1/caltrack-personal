import SwiftUI
import UIKit

struct MealComponentsEditor: View {
    @Binding var meal: EditableMeal
    @State private var isExpanded: Bool
    @FocusState private var isEditingField: Bool

    init(meal: Binding<EditableMeal>, startsExpanded: Bool) {
        _meal = meal
        _isExpanded = State(initialValue: startsExpanded)
    }

    var body: some View {
        Card {
            DisclosureGroup(isExpanded: $isExpanded) {
                VStack(alignment: .leading, spacing: 12) {
                    if meal.components.isEmpty {
                        emptyState
                    } else {
                        ForEach($meal.components) { $component in
                            componentCard(component: $component)
                        }
                    }

                    HStack(spacing: 10) {
                        Button {
                            meal.components.append(EditableMealComponent())
                            isExpanded = true
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Label("Añadir", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(CaltrackTheme.green)
                        .accessibilityIdentifier("addMealComponent")

                        Button {
                            meal.recalculateFromComponents()
                            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        } label: {
                            Label("Recalcular", systemImage: "sum")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(CaltrackTheme.green)
                        .foregroundStyle(.black)
                        .disabled(meal.components.isEmpty)
                        .accessibilityIdentifier("recalculateMealComponents")
                    }

                    Text("Los totales se actualizan al cambiar un componente. Después puedes ajustar el total final si conoces una cifra más precisa.")
                        .font(.caption2)
                        .foregroundStyle(CaltrackTheme.muted)
                }
                .padding(.top, 12)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "fork.knife")
                        .foregroundStyle(CaltrackTheme.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Componentes del plato")
                            .font(.headline)
                        Text(componentCountText)
                            .font(.caption)
                            .foregroundStyle(CaltrackTheme.muted)
                    }
                }
            }
            .tint(CaltrackTheme.green)
        }
        .onChange(of: meal.components) { _, _ in
            meal.recalculateFromComponents()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("OK") { isEditingField = false }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "plus.viewfinder")
                .font(.title2)
                .foregroundStyle(CaltrackTheme.muted)
            Text("Sin componentes")
                .font(.subheadline.weight(.semibold))
            Text("Añade aceite, salsa, bebida o cualquier parte que falte.")
                .font(.caption)
                .foregroundStyle(CaltrackTheme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func componentCard(component: Binding<EditableMealComponent>) -> some View {
        let identifier = component.wrappedValue.id.uuidString
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                TextField("Alimento", text: component.name)
                    .font(.subheadline.weight(.semibold))
                    .textInputAutocapitalization(.sentences)
                    .focused($isEditingField)
                    .accessibilityIdentifier("mealComponentName-\(identifier)")
                Button(role: .destructive) {
                    let id = component.wrappedValue.id
                    meal.components.removeAll { $0.id == id }
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                } label: {
                    Image(systemName: "trash")
                        .frame(width: 34, height: 34)
                }
                .accessibilityLabel("Eliminar componente")
                .accessibilityIdentifier("deleteMealComponent-\(identifier)")
            }

            TextField("Porción, por ejemplo 180 g", text: component.portion)
                .font(.caption)
                .focused($isEditingField)
                .padding(.horizontal, 11)
                .frame(height: 42)
                .background(CaltrackTheme.canvas.opacity(0.7), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .accessibilityIdentifier("mealComponentPortion-\(identifier)")

            HStack(spacing: 8) {
                metricField("Kcal", text: component.calories, identifier: "mealComponentCalories-\(identifier)")
                metricField("Proteína", text: component.protein, identifier: "mealComponentProtein-\(identifier)")
            }
            HStack(spacing: 8) {
                metricField("Carbos", text: component.carbohydrates, identifier: "mealComponentCarbs-\(identifier)")
                metricField("Grasa", text: component.fat, identifier: "mealComponentFat-\(identifier)")
            }
        }
        .padding(12)
        .background(CaltrackTheme.cardRaised, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func metricField(_ title: String, text: Binding<String>, identifier: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(CaltrackTheme.muted)
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .font(.subheadline.monospacedDigit())
                .focused($isEditingField)
                .padding(.horizontal, 10)
                .frame(height: 40)
                .background(CaltrackTheme.canvas.opacity(0.7), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .accessibilityIdentifier(identifier)
        }
        .frame(maxWidth: .infinity)
    }

    private var componentCountText: String {
        guard !meal.components.isEmpty else { return "Añade el desglose si lo necesitas" }
        let count = meal.components.count == 1 ? "1 componente" : "\(meal.components.count) componentes"
        return "\(count) · \(Int(EditableMeal.number(meal.calories))) kcal · \(Int(EditableMeal.number(meal.protein))) g P"
    }
}
