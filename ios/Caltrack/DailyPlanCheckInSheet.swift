import SwiftUI
import UIKit

struct DailyPlanCheckInSheet: View {
    @Environment(\.dismiss) private var dismiss
    let date: Date
    let existing: DailyPlanCheckIn?
    let save: (Int, Int) -> Void
    let reopen: () -> Void
    @State private var hunger: Int
    @State private var energy: Int

    init(date: Date, existing: DailyPlanCheckIn?, save: @escaping (Int, Int) -> Void, reopen: @escaping () -> Void) {
        self.date = date
        self.existing = existing
        self.save = save
        self.reopen = reopen
        _hunger = State(initialValue: existing?.hunger ?? 3)
        _energy = State(initialValue: existing?.energy ?? 3)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CaltrackTheme.canvas.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        Card {
                            VStack(alignment: .leading, spacing: 8) {
                                Image(systemName: existing?.nutritionComplete == true ? "checkmark.circle.fill" : "checkmark.circle")
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundStyle(CaltrackTheme.green)
                                Text(existing?.nutritionComplete == true ? "Revisa tu cierre" : "¿Está todo registrado?")
                                    .font(.title2.weight(.bold))
                                Text("Usaremos solo los días que cierres para revisar el plan semanal. Puedes editar o reabrir este día después.")
                                    .font(.subheadline)
                                    .foregroundStyle(CaltrackTheme.muted)
                            }
                        }

                        Card {
                            VStack(alignment: .leading, spacing: 18) {
                                ratingRow(
                                    title: "Hambre",
                                    detail: "1 nada, 5 mucha",
                                    icon: "fork.knife",
                                    selection: $hunger,
                                    identifier: "hunger"
                                )
                                Divider().overlay(CaltrackTheme.line)
                                ratingRow(
                                    title: "Energía",
                                    detail: "1 muy baja, 5 muy alta",
                                    icon: "bolt.fill",
                                    selection: $energy,
                                    identifier: "energy"
                                )
                            }
                        }

                        Button {
                            save(hunger, energy)
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            dismiss()
                        } label: {
                            Label(existing?.nutritionComplete == true ? "Guardar cambios" : "Cerrar el día", systemImage: "checkmark.circle.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .foregroundStyle(.black)
                                .background(CaltrackTheme.green, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .accessibilityIdentifier("saveDailyCheckIn")

                        if existing?.nutritionComplete == true {
                            Button("Marcar como incompleto", role: .destructive) {
                                reopen()
                                dismiss()
                            }
                            .frame(maxWidth: .infinity)
                            .accessibilityIdentifier("reopenDailyCheckIn")
                        }
                    }
                    .padding(14)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Cierre del día")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func ratingRow(title: String, detail: String, icon: String, selection: Binding<Int>, identifier: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(CaltrackTheme.blue)
                    .frame(width: 30, height: 30)
                    .background(CaltrackTheme.blue.opacity(0.14), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(detail).font(.caption).foregroundStyle(CaltrackTheme.muted)
                }
            }
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { value in
                    Button {
                        selection.wrappedValue = value
                    } label: {
                        Text("\(value)")
                            .font(.headline.monospacedDigit())
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .foregroundStyle(selection.wrappedValue == value ? .black : .white)
                            .background(selection.wrappedValue == value ? CaltrackTheme.blue : CaltrackTheme.cardRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(title) \(value) de 5")
                    .accessibilityIdentifier("\(identifier)\(value)")
                }
            }
        }
    }
}
