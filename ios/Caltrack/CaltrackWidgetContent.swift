import AppIntents
import SwiftUI
import WidgetKit

enum WidgetPalette {
    static let canvas = Color(red: 0.045, green: 0.052, blue: 0.064)
    static let raised = Color(red: 0.12, green: 0.135, blue: 0.16)
    static let muted = Color(red: 0.57, green: 0.60, blue: 0.66)
    static let green = Color(red: 0.45, green: 0.88, blue: 0.53)
    static let blue = Color(red: 0.40, green: 0.58, blue: 0.98)
    static let amber = Color(red: 0.96, green: 0.72, blue: 0.32)
    static let coral = Color(red: 0.98, green: 0.43, blue: 0.42)
}

struct CaltrackWidgetContent: View {
    @Environment(\.redactionReasons) private var redactionReasons

    let snapshot: WidgetSnapshot
    let family: WidgetFamily

    var body: some View {
        switch family {
        case .systemMedium:
            medium
        case .accessoryInline:
            inline
        case .accessoryCircular:
            circular
        case .accessoryRectangular:
            rectangular
        default:
            small
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 8) {
            smallHeader
            HStack(alignment: .center, spacing: 8) {
                calorieRing(size: 50)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Int(snapshot.calories)) kcal")
                        .font(.headline.weight(.black).monospacedDigit())
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text("de \(Int(snapshot.calorieMax))")
                        .font(.caption2)
                        .foregroundStyle(WidgetPalette.muted)
                    Text("\(Int(snapshot.protein)) g P")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(WidgetPalette.blue)
                        .lineLimit(1)
                    if let fiber = snapshot.fiber {
                        Text("\(Int(fiber)) g fibra")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(WidgetPalette.amber)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .privacySensitive()
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                actionButton(intent: CaptureMealIntent(), icon: "camera.fill", label: "Foto")
                actionButton(intent: ScanProductIntent(), icon: "barcode.viewfinder", label: "Código")
            }
        }
    }

    private var smallHeader: some View {
        HStack(spacing: 5) {
            Image(systemName: snapshot.nutritionComplete ? "checkmark.circle.fill" : "fork.knife")
                .font(.caption.weight(.bold))
                .foregroundStyle(snapshot.nutritionComplete ? WidgetPalette.green : calorieColor)
            Text("Caltrack")
                .font(.caption.weight(.bold))
                .lineLimit(1)
            Spacer(minLength: 4)
            Label("\(snapshot.mealCount)", systemImage: "takeoutbag.and.cup.and.straw.fill")
                .font(.caption2)
                .foregroundStyle(WidgetPalette.muted)
                .labelStyle(.titleAndIcon)
                .privacySensitive()
        }
    }

    private var medium: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 9) {
                widgetHeader
                HStack(spacing: 12) {
                    calorieRing(size: 62)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("\(Int(snapshot.calories)) / \(Int(snapshot.calorieMax)) kcal")
                            .font(.subheadline.weight(.bold).monospacedDigit())
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                        progress(value: calorieProgress, color: calorieColor)
                        Text("\(Int(snapshot.protein)) / \(Int(snapshot.proteinMin)) g proteína")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(WidgetPalette.blue)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                        if let fiber = snapshot.fiber {
                            Text("\(Int(fiber)) / \(Int(snapshot.fiberTarget ?? 25)) g fibra")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(WidgetPalette.amber)
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                        }
                    }
                }
                .privacySensitive()
                Spacer(minLength: 0)
                Text(snapshot.planTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(WidgetPalette.muted)
                    .lineLimit(1)
                    .privacySensitive()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 8) {
                actionButton(intent: CaptureMealIntent(), icon: "camera.fill", label: "Foto")
                actionButton(intent: ScanProductIntent(), icon: "barcode.viewfinder", label: "Código")
                actionButton(intent: NewBodyCheckInIntent(), icon: "scalemass.fill", label: "Peso")
            }
            .frame(width: 92)
        }
    }

    private var inline: some View {
        Label {
            Text("\(Int(snapshot.calories))/\(Int(snapshot.calorieMax)) kcal · \(Int(snapshot.protein)) g P")
                .privacySensitive()
        } icon: {
            Image(systemName: snapshot.nutritionComplete ? "checkmark.circle.fill" : "fork.knife")
        }
    }

    private var circular: some View {
        Gauge(value: calorieProgress) {
            Image(systemName: "fork.knife")
        } currentValueLabel: {
            Text("\(Int((calorieProgress * 100).rounded()))")
                .font(.caption2.weight(.bold).monospacedDigit())
                .privacySensitive()
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .widgetAccentable()
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label("Caltrack", systemImage: snapshot.nutritionComplete ? "checkmark.circle.fill" : "fork.knife")
                    .font(.caption.weight(.bold))
                Spacer()
                Text(snapshot.nutritionComplete ? "Cerrado" : "Hoy")
                    .font(.caption2)
            }
            Text("\(Int(snapshot.calories)) / \(Int(snapshot.calorieMax)) kcal")
                .font(.headline.monospacedDigit())
            ProgressView(value: calorieProgress)
                .tint(.primary)
            Text("\(Int(snapshot.protein)) / \(Int(snapshot.proteinMin)) g proteína")
                .font(.caption2)
        }
        .privacySensitive()
    }

    private var widgetHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: snapshot.nutritionComplete ? "checkmark.circle.fill" : "fork.knife")
                .font(.caption.weight(.bold))
                .foregroundStyle(snapshot.nutritionComplete ? WidgetPalette.green : calorieColor)
            Text("Caltrack")
                .font(.caption.weight(.bold))
            Spacer()
            Text(snapshot.mealCount == 1 ? "1 comida" : "\(snapshot.mealCount) comidas")
                .font(.caption2)
                .foregroundStyle(WidgetPalette.muted)
                .privacySensitive()
        }
    }

    private func calorieRing(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(WidgetPalette.raised, lineWidth: 7)
            Circle()
                .trim(from: 0, to: min(calorieProgress, 1))
                .stroke(calorieColor, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Image(systemName: snapshot.nutritionComplete ? "checkmark" : "fork.knife")
                .font(.caption.weight(.black))
                .foregroundStyle(calorieColor)
        }
        .frame(width: size, height: size)
    }

    private func metricValue(_ value: Double, unit: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(Int(value).formatted())
                .font(.title3.weight(.black).monospacedDigit())
            Text(unit)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(WidgetPalette.muted)
        }
    }

    private func progress(value: Double, color: Color) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(WidgetPalette.raised)
                Capsule().fill(color).frame(width: proxy.size.width * min(value, 1))
            }
        }
        .frame(height: 5)
    }

    private func actionButton<I: AppIntent>(intent: I, icon: String, label: String) -> some View {
        Button(intent: intent) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                Text(label)
                    .lineLimit(1)
            }
            .font(.caption2.weight(.bold))
            .frame(maxWidth: .infinity)
            .frame(height: 30)
            .foregroundStyle(.white)
            .background(WidgetPalette.raised, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var calorieProgress: Double {
        if redactionReasons.contains(.privacy) { return 0 }
        return snapshot.calories / max(snapshot.calorieMax, 1)
    }

    private var calorieColor: Color {
        snapshot.calories > snapshot.calorieMax ? WidgetPalette.coral : WidgetPalette.green
    }
}
