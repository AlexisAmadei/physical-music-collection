import AVFoundation
import SwiftUI
import VisionKit

/// Scan (Android `ScanScreen`): asks for the camera, scans one barcode, then shows "Looking up <code>…" while the app
/// model asks the Catalog. "Enter manually" skips scanning. The decisions live in `Scan.swift`; this view only shows
/// `app.scanState` and hands it the barcode read.
struct ScanScreen: View {
    @Bindable var app: AppModel
    @State private var camera = AVCaptureDevice.authorizationStatus(for: .video)

    var body: some View {
        ZStack {
            switch (camera, app.scanState) {
            case (.notDetermined, _):
                Color.clear
            case (.authorized, .scanning):
                BarcodeScanner { code in Task { await app.scanned(code) } }
                    .ignoresSafeArea()
            case (.authorized, .lookingUp(let code)):
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Looking up \(code)…")
                        .textStyle(Typography.body)
                        .foregroundStyle(Palette.ink)
                }
            default:
                Text("Camera permission needed")
                    .textStyle(Typography.body)
                    .foregroundStyle(Palette.ink)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            Button { app.enterManually() } label: { OutlinedButtonLabel(text: "Enter manually") }
                .buttonStyle(.plain)
                .padding(16)
        }
        .background(Palette.surface)
        .task {
            if camera == .notDetermined {
                _ = await AVCaptureDevice.requestAccess(for: .video)
                camera = AVCaptureDevice.authorizationStatus(for: .video)
            }
        }
    }
}

/// The VisionKit live barcode scanner. Hands each new barcode it reads to `onCode`; the app model keeps the first.
/// Leaving the view (Scan switches to "Looking up…") stops the camera.
/// Without a supported camera (the simulator) it shows the empty surface.
private struct BarcodeScanner: View {
    let onCode: (String) -> Void

    var body: some View {
        if DataScannerViewController.isSupported {
            Scanner(onCode: onCode)
        } else {
            Palette.thumb
        }
    }

    private struct Scanner: UIViewControllerRepresentable {
        let onCode: (String) -> Void

        func makeUIViewController(context: Context) -> DataScannerViewController {
            let scanner = DataScannerViewController(
                recognizedDataTypes: [.barcode()],
                qualityLevel: .balanced,
                recognizesMultipleItems: false,
                isHighFrameRateTrackingEnabled: false,
                isHighlightingEnabled: true
            )
            scanner.delegate = context.coordinator
            return scanner
        }

        func updateUIViewController(_ scanner: DataScannerViewController, context: Context) {
            context.coordinator.onCode = onCode
            if !scanner.isScanning { try? scanner.startScanning() }
        }

        static func dismantleUIViewController(_ scanner: DataScannerViewController, coordinator: Coordinator) {
            scanner.stopScanning()
        }

        func makeCoordinator() -> Coordinator { Coordinator(onCode: onCode) }

        @MainActor final class Coordinator: NSObject, DataScannerViewControllerDelegate {
            var onCode: (String) -> Void

            init(onCode: @escaping (String) -> Void) { self.onCode = onCode }

            func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
                for case .barcode(let barcode) in addedItems {
                    if let code = barcode.payloadStringValue, !code.isEmpty {
                        onCode(code)
                        return
                    }
                }
            }
        }
    }
}

/// A capsule outlined in the muted color (Android `OutlinedButton`): "Enter manually", "Add manually".
struct OutlinedButtonLabel: View {
    let text: LocalizedStringKey

    var body: some View {
        Text(text)
            .textStyle(Typography.body)
            .fontWeight(.medium)
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, 20)
            .frame(height: 48)
            .background(Palette.surface, in: .capsule)
            .overlay(Capsule().stroke(Palette.muted))
            .contentShape(.capsule)
    }
}
