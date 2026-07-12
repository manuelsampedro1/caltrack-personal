import SwiftUI
import WidgetKit

#if DEBUG
struct WidgetPreviewGallery: View {
    private let snapshot = WidgetSnapshot.preview

    var body: some View {
        ZStack {
            CaltrackTheme.canvas.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 5) {
                        Eyebrow(text: "Validación visual")
                        Text("Widgets de Caltrack")
                            .font(.largeTitle.weight(.black))
                        Text("Las mismas vistas que renderiza WidgetKit, sin datos reales.")
                            .font(.subheadline)
                            .foregroundStyle(CaltrackTheme.muted)
                    }

                    previewSection(title: "Pantalla de inicio") {
                        HStack(alignment: .top, spacing: 14) {
                            widgetFrame(width: 164, height: 164, identifier: "widgetPreviewSmall") {
                                CaltrackWidgetContent(snapshot: snapshot, family: .systemSmall)
                            }
                            widgetFrame(width: 164, height: 164, identifier: "widgetPreviewEmpty") {
                                CaltrackWidgetContent(snapshot: .empty(), family: .systemSmall)
                            }
                        }
                        widgetFrame(width: 342, height: 164, identifier: "widgetPreviewMedium") {
                            CaltrackWidgetContent(snapshot: snapshot, family: .systemMedium)
                        }
                    }

                    previewSection(title: "Pantalla de bloqueo") {
                        HStack(spacing: 14) {
                            accessoryFrame(width: 80, height: 80, identifier: "widgetPreviewCircular") {
                                CaltrackWidgetContent(snapshot: snapshot, family: .accessoryCircular)
                            }
                            accessoryFrame(width: 220, height: 80, identifier: "widgetPreviewRectangular") {
                                CaltrackWidgetContent(snapshot: snapshot, family: .accessoryRectangular)
                            }
                        }
                        accessoryFrame(width: 342, height: 38, identifier: "widgetPreviewInline") {
                            CaltrackWidgetContent(snapshot: snapshot, family: .accessoryInline)
                        }
                    }

                    previewSection(title: "Privacidad") {
                        widgetFrame(width: 342, height: 164, identifier: "widgetPreviewPrivate") {
                            CaltrackWidgetContent(snapshot: snapshot, family: .systemMedium)
                                .redacted(reason: .privacy)
                        }
                    }
                }
                .padding(18)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func previewSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.weight(.bold))
            content()
        }
    }

    private func widgetFrame<Content: View>(width: CGFloat, height: CGFloat, identifier: String, @ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(14)
            .frame(width: width, height: height)
            .background(WidgetPalette.canvas, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.white.opacity(0.1)) }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(identifier)
    }

    private func accessoryFrame<Content: View>(width: CGFloat, height: CGFloat, identifier: String, @ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(8)
            .frame(width: width, height: height)
            .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(identifier)
    }
}
#endif
