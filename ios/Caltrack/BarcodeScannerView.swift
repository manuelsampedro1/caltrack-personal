import AVFoundation
import SwiftUI
import UIKit

struct BarcodeScannerView: UIViewControllerRepresentable {
    let onCode: (String) -> Void
    let onFailure: (String) -> Void

    func makeUIViewController(context: Context) -> BarcodeScannerViewController {
        BarcodeScannerViewController(onCode: onCode, onFailure: onFailure)
    }

    func updateUIViewController(_ uiViewController: BarcodeScannerViewController, context: Context) {}

    static func dismantleUIViewController(_ uiViewController: BarcodeScannerViewController, coordinator: ()) {
        uiViewController.stop()
    }
}

final class BarcodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.manuelsampedro.caltrack.barcode")
    private let onCode: (String) -> Void
    private let onFailure: (String) -> Void
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var hasEmitted = false

    init(onCode: @escaping (String) -> Void, onFailure: @escaping (String) -> Void) {
        self.onCode = onCode
        self.onFailure = onFailure
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(layer)
        previewLayer = layer
        prepareCamera()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    func stop() {
        sessionQueue.async { [session] in
            if session.isRunning { session.stopRunning() }
        }
    }

    private func prepareCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureAndStart()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let self else { return }
                if granted { self.configureAndStart() }
                else { self.fail("La cámara no tiene permiso. Puedes introducir el código manualmente.") }
            }
        case .denied, .restricted:
            fail("La cámara no está disponible. Puedes introducir el código manualmente.")
        @unknown default:
            fail("No se pudo preparar la cámara.")
        }
    }

    private func configureAndStart() {
        sessionQueue.async { [weak self] in
            guard let self, !self.session.isRunning else { return }
            guard let camera = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: camera),
                  self.session.canAddInput(input) else {
                self.fail("Este dispositivo no ofrece una cámara compatible.")
                return
            }

            self.session.beginConfiguration()
            self.session.sessionPreset = .high
            self.session.addInput(input)
            let output = AVCaptureMetadataOutput()
            guard self.session.canAddOutput(output) else {
                self.session.commitConfiguration()
                self.fail("No se pudo activar el lector de códigos.")
                return
            }
            self.session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: self.sessionQueue)
            let desired: [AVMetadataObject.ObjectType] = [.ean8, .ean13, .upce, .code128, .code39, .code93, .itf14]
            output.metadataObjectTypes = desired.filter { output.availableMetadataObjectTypes.contains($0) }
            self.session.commitConfiguration()
            self.session.startRunning()
        }
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard !hasEmitted,
              let object = metadataObjects.compactMap({ $0 as? AVMetadataMachineReadableCodeObject }).first,
              let code = object.stringValue,
              !code.isEmpty else { return }
        hasEmitted = true
        if session.isRunning { session.stopRunning() }
        DispatchQueue.main.async { [onCode] in onCode(code) }
    }

    private func fail(_ message: String) {
        DispatchQueue.main.async { [onFailure] in onFailure(message) }
    }
}
