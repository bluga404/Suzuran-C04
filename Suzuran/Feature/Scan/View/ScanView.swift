import SwiftUI
import PhotosUI

struct ScanView: View {
    @StateObject private var viewModel = ScanViewModel()
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                content
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .onDisappear {
                viewModel.stopCamera()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .idle:
            idleView
        case .camera:
            cameraView
        case .processing:
            processingView
        case .result:
            resultView
        }
    }

    // MARK: - Idle

    private var idleView: some View {
        VStack(spacing: 24) {
            Text("Scan Your Skin")
                .font(.title)
                .fontWeight(.bold)

            Text("Use the camera or pick a photo to detect acne.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                Button(action: { Task { await viewModel.startCamera() } }) {
                    scanButtonLabel("Scan", icon: "camera.fill")
                }

                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    scanButtonLabel("Upload Image", icon: "photo.fill")
                }
            }
            .padding(.horizontal, 32)

            if viewModel.permissionState == .denied {
                permanentDeniedView
            }
        }
        .padding()
        .onChange(of: selectedPhoto) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    viewModel.handlePickedImage(data)
                } else {
                    viewModel.errorMessage = "The selected image could not be loaded."
                }
            }
        }
    }

    private var permanentDeniedView: some View {
        VStack(spacing: 8) {
            Text("Camera access is disabled.")
                .font(.subheadline)
            Text("Enable camera access in Settings to use the Scan feature.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        }
        .padding()
    }

    private func scanButtonLabel(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Camera

    private var cameraView: some View {
        GeometryReader { proxy in
            ZStack {
                CameraPreview(session: viewModel.cameraService.session)
                    .ignoresSafeArea()

                VStack {
                    HStack {
                        Button(action: { viewModel.reset() }) {
                            Image(systemName: "xmark")
                                .font(.headline)
                                .padding(10)
                                .background(.black.opacity(0.5))
                                .clipShape(Circle())
                        }

                        Spacer()

                        Button(action: { viewModel.toggleCamera() }) {
                            Image(systemName: "arrow.triangle.2.circlepath.camera")
                                .font(.headline)
                                .padding(10)
                                .background(.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                    }
                    Spacer()

                    Button(action: { viewModel.capturePhoto() }) {
                        Circle()
                            .stroke(.white, lineWidth: 4)
                            .frame(width: 72, height: 72)
                            .overlay(
                                Circle()
                                    .fill(.white)
                                    .frame(width: 56, height: 56)
                            )
                    }
                }
                .padding()
            }
        }
    }

    // MARK: - Processing

    private var processingView: some View {
        VStack(spacing: 20) {
            if let image = viewModel.capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            ProgressView("Analyzing your skin...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    // MARK: - Result

    private var resultView: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let image = viewModel.capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                } else if let result = viewModel.result {
                    resultCard(result)
                    if !viewModel.detections.isEmpty {
                        detectionList(viewModel.detections)
                    }
                } else {
                    Text("No acne detected")
                        .font(.headline)
                }

                HStack(spacing: 12) {
                    Button(action: { Task { await viewModel.startCamera() } }) {
                        Text("Scan Again")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Text("Upload Another")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemFill))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
        }
        .onChange(of: selectedPhoto) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    viewModel.handlePickedImage(data)
                } else {
                    viewModel.errorMessage = "The selected image could not be loaded."
                }
            }
        }
    }

    private func resultCard(_ result: PredictionResult) -> some View {
        VStack(spacing: 8) {
            Text("Acne Type")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(result.acneType)
                .font(.title2)
                .fontWeight(.semibold)

            Text("Confidence")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
            Text(percentString(result.confidence))
                .font(.title2)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func detectionList(_ detections: [AcneDetection]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(detections.count) lesion\(detections.count == 1 ? "" : "s") detected")
                .font(.headline)

            ForEach(detections) { detection in
                HStack {
                    Text(detection.label)
                    Spacer()
                    Text(percentString(detection.confidence))
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
                .padding(.vertical, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func percentString(_ value: Double) -> String {
        String(format: "%.1f%%", value * 100)
    }
}

#Preview {
    ScanView()
}