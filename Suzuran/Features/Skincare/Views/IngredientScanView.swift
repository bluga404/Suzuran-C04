import SwiftUI
import AVFoundation
import PhotosUI
import Combine

struct IngredientScanView: View {
    @ObservedObject var viewModel: AddSkincareViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var isShowingInstruction = false
    @State private var selectedItem: PhotosPickerItem?
    @StateObject private var cameraManager = CameraManager()

    /// First-time auto-present flag store (Req 11.5).
    private let kvStore: KeyValueStore = UserDefaultsKeyValueStore(userDefaults: .standard)
    private let hasSeenInstructionKey = "suzuran.skincare.hasSeenScanInstructionModal"

    var body: some View {
        NavigationStack {
            ZStack {
                // Camera Preview
                CameraPreview(session: cameraManager.session)

                // Dark overlay with cutout box
                Color.black.opacity(0.5)
                    .reverseMask {
                        RoundedRectangle(cornerRadius: AppCornerRadius.md)
                            .frame(width: 350, height: 450)
                    }

                // Viewfinder border
                RoundedRectangle(cornerRadius: AppCornerRadius.md)
                    .stroke(AppColor.accentPrimary, style: StrokeStyle(lineWidth: 2, dash: [5]))
                    .frame(width: 350, height: 450)

                VStack {
                    // Top Controls
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }

                        Spacer()

                        Button(action: { isShowingInstruction = true }) {
                            Image(systemName: "info")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                    }
                    .padding()

                    Spacer()

                    // Bottom Controls
                    HStack(spacing: 40) {
                        // Gallery Upload
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Image(systemName: "photo")
                                .font(.system(size: 24))
                                .foregroundStyle(.white)
                                .padding(16)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }

                        // Capture Button
                        Button(action: { cameraManager.capturePhoto() }) {
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                                .frame(width: 70, height: 70)
                                .overlay(
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 58, height: 58)
                                )
                        }

                        // Flash Toggle
                        Button(action: { cameraManager.toggleFlash() }) {
                            Image(systemName: cameraManager.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(cameraManager.isFlashOn ? AppColor.accentPrimary : .white)
                                .padding(16)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.bottom, 40)
                }

                // Loading Overlay
                if viewModel.isScanning {
                    ZStack {
                        Color.black.opacity(0.6).ignoresSafeArea()
                        VStack(spacing: AppSpacing.sm) {
                            ProgressView().tint(.white)
                            Text("Membaca teks...")
                                .font(Font.bodyParagraph)
                                .foregroundStyle(.white)
                        }
                        .padding(AppSpacing.lg)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(AppCornerRadius.md)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $isShowingInstruction) {
                ScanInstructionModalView(onDismiss: { isShowingInstruction = false })
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await processImage(image)
                    }
                }
            }
            .onChange(of: cameraManager.capturedImage) { _, image in
                if let image = image {
                    Task { await processImage(image) }
                }
            }
            .alert(
                "Gagal Memindai",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .onAppear {
                cameraManager.checkPermissionAndStart()
                if !kvStore.bool(forKey: hasSeenInstructionKey) {
                    isShowingInstruction = true
                    kvStore.set(true, forKey: hasSeenInstructionKey)
                }
            }
            .onDisappear {
                cameraManager.stopSession()
            }
            .ignoresSafeArea()
        }
    }

    private func processImage(_ image: UIImage) async {
        await viewModel.processImage(image)
        if viewModel.errorMessage == nil {
            dismiss()
        }
    }
}

// MARK: - Reverse Mask

private extension View {
    func reverseMask<Mask: View>(
        @ViewBuilder _ mask: () -> Mask
    ) -> some View {
        self.mask(
            ZStack {
                Rectangle()
                mask()
                    .blendMode(.destinationOut)
            }
        )
    }
}

// MARK: - Camera Manager

class CameraManager: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var session = AVCaptureSession()
    @Published var capturedImage: UIImage?
    @Published var isFlashOn = false

    private let output = AVCapturePhotoOutput()

    func checkPermissionAndStart() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.setupSession()
                    }
                }
            }
        default:
            break
        }
    }

    private func setupSession() {
        #if targetEnvironment(simulator)
        return
        #else
        guard !session.isRunning else { return }
        session.beginConfiguration()

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            session.commitConfiguration()
            return
        }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        if session.canAddOutput(output) {
            session.addOutput(output)
        }

        session.commitConfiguration()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
        #endif
    }

    func stopSession() {
        #if targetEnvironment(simulator)
        return
        #else
        if session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.stopRunning()
            }
        }
        #endif
    }

    func capturePhoto() {
        #if targetEnvironment(simulator)
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor.red.cgColor)
        context.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.capturedImage = img
        return
        #else
        let settings = AVCapturePhotoSettings()
        settings.flashMode = isFlashOn ? .on : .off
        output.capturePhoto(with: settings, delegate: self)
        #endif
    }

    func toggleFlash() {
        isFlashOn.toggle()
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else { return }
        DispatchQueue.main.async {
            self.capturedImage = image
        }
    }
}

// MARK: - Camera Preview

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .black

        #if targetEnvironment(simulator)
        let label = UILabel()
        label.text = "Simulator Camera\nTap Capture to mock"
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .center
        label.frame = view.bounds
        view.addSubview(label)
        #else
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        #endif

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
