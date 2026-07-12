import SwiftUI
import UIKit

struct ProgressPhotoViewer: View {
    let measurement: BodyMeasurement
    @Environment(\.dismiss) private var dismiss
    @State private var scale = 1.0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                if let data = measurement.photoData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .gesture(
                            MagnifyGesture()
                                .onChanged { value in scale = min(max(value.magnification, 1), 4) }
                                .onEnded { value in
                                    withAnimation(.snappy) { scale = min(max(value.magnification, 1), 4) }
                                }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation(.snappy) { scale = scale > 1 ? 1 : 2 }
                        }
                        .accessibilityLabel("Foto de progreso ampliable")
                } else {
                    ContentUnavailableView("Foto no disponible", systemImage: "photo.badge.exclamationmark")
                }

                VStack {
                    Spacer()
                    HStack(spacing: 16) {
                        metric(measurement.weight, suffix: "kg", label: "peso")
                        metric(measurement.bodyFat, suffix: "%", label: "grasa")
                        metric(measurement.waist, suffix: "cm", label: "cintura")
                    }
                    .padding(14)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .padding(16)
                }
            }
            .navigationTitle(measurement.date.formatted(.dateTime.day().month(.wide).year().locale(Locale(identifier: "es_ES"))))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Cerrar") { dismiss() } }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func metric(_ value: Double?, suffix: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value.map { "\($0.formatted(.number.precision(.fractionLength(1)))) \(suffix)" } ?? "-")
                .font(.headline.monospacedDigit())
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
