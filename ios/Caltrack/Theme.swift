import SwiftUI

enum CaltrackTheme {
    static let canvas = Color(red: 0.045, green: 0.052, blue: 0.064)
    static let card = Color(red: 0.086, green: 0.098, blue: 0.12)
    static let cardRaised = Color(red: 0.12, green: 0.135, blue: 0.16)
    static let line = Color.white.opacity(0.08)
    static let muted = Color(red: 0.57, green: 0.60, blue: 0.66)
    static let green = Color(red: 0.45, green: 0.88, blue: 0.53)
    static let coral = Color(red: 0.98, green: 0.43, blue: 0.42)
    static let blue = Color(red: 0.40, green: 0.58, blue: 0.98)
}

struct Card<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CaltrackTheme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(CaltrackTheme.line, lineWidth: 1)
            }
    }
}

struct Eyebrow: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.caption2.weight(.bold))
            .tracking(1.4)
            .foregroundStyle(CaltrackTheme.muted)
    }
}

struct MetricPill: View {
    let text: String
    var color = CaltrackTheme.cardRaised

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.82))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(color, in: Capsule())
    }
}
