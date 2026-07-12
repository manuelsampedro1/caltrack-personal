import PhotosUI
import SwiftUI
import UIKit

struct BodyCheckInDraft {
    var date: Date = .now
    var weight = ""
    var bodyFat = ""
    var waist = ""
    var photoData: Data?

    init() {}

    init(measurement: BodyMeasurement) {
        date = measurement.date
        weight = Self.format(measurement.weight)
        bodyFat = Self.format(measurement.bodyFat)
        waist = Self.format(measurement.waist)
        photoData = measurement.photoData
    }

    var weightValue: Double? { number(weight) }
    var bodyFatValue: Double? { number(bodyFat) }
    var waistValue: Double? { number(waist) }

    var validationMessage: String? {
        if !weight.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && weightValue == nil {
            return "Revisa el peso."
        }
        if !bodyFat.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && bodyFatValue == nil {
            return "Revisa el porcentaje de grasa."
        }
        if !waist.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && waistValue == nil {
            return "Revisa la cintura."
        }
        if let weightValue, !(25...400).contains(weightValue) { return "El peso debe estar entre 25 y 400 kg." }
        if let bodyFatValue, !(1...75).contains(bodyFatValue) { return "La grasa debe estar entre 1 y 75 %." }
        if let waistValue, !(30...300).contains(waistValue) { return "La cintura debe estar entre 30 y 300 cm." }
        if weightValue == nil, bodyFatValue == nil, waistValue == nil, photoData == nil {
            return "Añade al menos una medida o una foto."
        }
        return nil
    }

    var isValid: Bool { validationMessage == nil }

    private func number(_ value: String) -> Double? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let number = Double(trimmed.replacingOccurrences(of: ",", with: ".")) else { return nil }
        return number
    }

    private static func format(_ value: Double?) -> String {
        value?.formatted(.number.precision(.fractionLength(0...1))) ?? ""
    }
}

enum ProgressPhotoProcessor {
    static func compressedJPEG(from data: Data, maxPixel: CGFloat = 1_600, quality: CGFloat = 0.82) -> Data? {
        guard let source = UIImage(data: data), source.size.width > 0, source.size.height > 0 else { return nil }
        let longest = max(source.size.width, source.size.height)
        let scale = min(1, maxPixel / longest)
        let size = CGSize(width: max(1, source.size.width * scale), height: max(1, source.size.height * scale))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let image = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            UIColor.black.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))
            source.draw(in: CGRect(origin: .zero, size: size))
        }
        return image.jpegData(compressionQuality: quality)
    }

#if DEBUG
    static var testingPhoto: Data? {
        let size = CGSize(width: 900, height: 1_200)
        let image = UIGraphicsImageRenderer(size: size).image { context in
            let colors = [UIColor(red: 0.12, green: 0.16, blue: 0.24, alpha: 1).cgColor, UIColor(red: 0.38, green: 0.58, blue: 0.98, alpha: 1).cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1])!
            context.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
            UIColor.white.withAlphaComponent(0.18).setFill()
            context.cgContext.fillEllipse(in: CGRect(x: 250, y: 170, width: 400, height: 400))
            context.cgContext.fill(CGRect(x: 180, y: 620, width: 540, height: 420))
        }
        return image.jpegData(compressionQuality: 0.82)
    }
#endif
}

struct BodyCheckInSheet: View {
    let title: String
    let initial: BodyCheckInDraft
    let onSave: (BodyCheckInDraft) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var draft: BodyCheckInDraft
    @State private var photoItem: PhotosPickerItem?
    @State private var loadingPhoto = false
    @State private var photoError: String?

    init(
        title: String = "Nuevo check-in",
        initial: BodyCheckInDraft = BodyCheckInDraft(),
        onSave: @escaping (BodyCheckInDraft) -> Void
    ) {
        self.title = title
        self.initial = initial
        self.onSave = onSave
        _draft = State(initialValue: initial)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CaltrackTheme.canvas.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        measurementCard
                        photoCard
                        privacyCard
                    }
                    .padding(14)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { save() }
                        .fontWeight(.semibold)
                        .disabled(!draft.isValid || loadingPhoto)
                        .accessibilityIdentifier("saveBodyCheckIn")
                }
            }
        }
        .presentationDetents([.large])
        .onChange(of: photoItem) { _, item in loadPhoto(item) }
        .onAppear {
#if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-body-photo-fixture"), draft.photoData == nil {
                draft.photoData = ProgressPhotoProcessor.testingPhoto
            }
#endif
        }
    }

    private var measurementCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Eyebrow(text: "Composición corporal")
                    Text("Registra solo lo que tengas")
                        .font(.title3.weight(.bold))
                    Text("Salud seguirá sincronizándose por separado. Este registro es manual y editable.")
                        .font(.subheadline)
                        .foregroundStyle(CaltrackTheme.muted)
                }

                DatePicker("Fecha", selection: $draft.date, in: ...Date.now)
                    .datePickerStyle(.compact)

                Group {
                    if dynamicTypeSize.isAccessibilitySize {
                        VStack(spacing: 10) { measurementFields }
                    } else {
                        HStack(spacing: 10) { measurementFields }
                    }
                }

                if let message = draft.validationMessage {
                    Label(message, systemImage: "info.circle")
                        .font(.caption)
                        .foregroundStyle(CaltrackTheme.muted)
                }
            }
        }
    }

    private var photoCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Eyebrow(text: "Opcional")
                        Text("Foto de progreso").font(.title3.weight(.bold))
                    }
                    Spacer()
                    Image(systemName: "person.crop.rectangle")
                        .foregroundStyle(CaltrackTheme.blue)
                }

                if let data = draft.photoData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .accessibilityLabel("Foto de progreso seleccionada")
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "figure.stand")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundStyle(CaltrackTheme.blue)
                        Text("Misma luz, distancia y postura para comparar mejor.")
                            .font(.subheadline)
                            .foregroundStyle(CaltrackTheme.muted)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .background(CaltrackTheme.cardRaised, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                if loadingPhoto {
                    HStack { ProgressView(); Text("Preparando foto").font(.subheadline) }
                } else {
                    HStack(spacing: 10) {
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            Label(draft.photoData == nil ? "Elegir foto" : "Cambiar foto", systemImage: "photo.on.rectangle")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .foregroundStyle(.black)
                                .background(CaltrackTheme.green, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .accessibilityIdentifier("chooseProgressPhoto")
                        if draft.photoData != nil {
                            Button(role: .destructive) {
                                draft.photoData = nil
                                photoItem = nil
                            } label: {
                                Image(systemName: "trash")
                                    .frame(width: 48, height: 48)
                                    .background(CaltrackTheme.cardRaised, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .accessibilityLabel("Quitar foto")
                        }
                    }
                }

                if let photoError {
                    Label(photoError, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(CaltrackTheme.coral)
                }
            }
        }
    }

    private var privacyCard: some View {
        Card {
            Label("La foto se comprime y se guarda solo en este iPhone. No se envía a Grok ni a ningún servicio. Se incluirá en tu copia privada.", systemImage: "lock.shield.fill")
                .font(.caption)
                .foregroundStyle(CaltrackTheme.muted)
        }
    }

    private func bodyField(_ title: String, suffix: String, text: Binding<String>, identifier: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased()).font(.caption2.weight(.bold)).foregroundStyle(CaltrackTheme.muted)
            HStack(spacing: 4) {
                TextField("-", text: text)
                    .keyboardType(.decimalPad)
                    .font(.headline.monospacedDigit())
                    .accessibilityIdentifier(identifier)
                Text(suffix).font(.caption).foregroundStyle(CaltrackTheme.muted)
            }
            .padding(.horizontal, 11)
            .frame(height: 46)
            .background(CaltrackTheme.cardRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var measurementFields: some View {
        bodyField("Peso", suffix: "kg", text: $draft.weight, identifier: "checkInWeight")
        bodyField("Grasa", suffix: "%", text: $draft.bodyFat, identifier: "checkInBodyFat")
        bodyField("Cintura", suffix: "cm", text: $draft.waist, identifier: "checkInWaist")
    }

    private func loadPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        loadingPhoto = true
        photoError = nil
        Task {
            defer { loadingPhoto = false }
            do {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let compressed = ProgressPhotoProcessor.compressedJPEG(from: data) else {
                    photoError = "No se pudo preparar esta imagen."
                    return
                }
                draft.photoData = compressed
            } catch {
                photoError = "No se pudo cargar la foto: \(error.localizedDescription)"
            }
        }
    }

    private func save() {
        guard draft.isValid else { return }
        onSave(draft)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}
