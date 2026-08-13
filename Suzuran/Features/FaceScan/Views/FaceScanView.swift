import SwiftUI
import UIKit

/// The main face scan screen that orchestrates the entire scanning flow.
/// Switches rendering based on `viewModel.phase` to show permission request,
/// live scanning, processing, results, or error states.
///
/// The ViewModel is owned via `@StateObject` so it persists across body re-evaluations
/// and only one AVCaptureSession + AcneDetectionService is ever created.
///
/// Requirements: 2.3, 2.4, 4.5, 5.6
struct FaceScanView: View {
    @StateObject private var viewModel: FaceScanViewModel
    let onScanSaved: (FaceScanSession, FaceScanResultModel) -> Void
    let onDismiss: () -> Void

    /// Tracks completedAngles changes to trigger haptic feedback on zone capture.
    @State private var lastCompletedAngles: Int = 0

    /// Haptic feedback generator for zone capture completion.
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .medium)

    init(
        viewModel: @autoclosure @escaping () -> FaceScanViewModel,
        onScanSaved: @escaping (FaceScanSession, FaceScanResultModel) -> Void = { _, _ in },
        onDismiss: @escaping () -> Void
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel())
        self.onScanSaved = onScanSaved
        self.onDismiss = onDismiss
    }

    var body: some View {
        ZStack {
            // Phase-based content
            phaseContent
        }
        .ignoresSafeArea()
        .onAppear {
            hapticGenerator.prepare()
            viewModel.onViewAppear()
        }
        .onDisappear {
            viewModel.onViewDisappear()
        }
        .onChange(of: viewModel.completedAngles) { _, newValue in
            if newValue > lastCompletedAngles {
                hapticGenerator.impactOccurred()
            }
            lastCompletedAngles = newValue
        }
    }

    // MARK: - Phase Content

    @ViewBuilder
    private var phaseContent: some View {
        switch viewModel.phase {
        case .requestingPermission:
            requestingPermissionView

        case .permissionDenied:
            permissionDeniedView

        case .scanning:
            scanningView

        case .processing:
            processingView

        case .completed(let result):
            FaceScanResultView(
                result: result,
                onDone: {
                    if let session = viewModel.lastSession {
                        onScanSaved(session, result)
                    }
                    onDismiss()
                },
                onRetake: {
                    viewModel.retry()
                }
            )

        case .error(let message):
            errorView(message: message)
        }
    }

    // MARK: - Requesting Permission

    private var requestingPermissionView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            LoadingStateView(
                title: "Meminta Izin Kamera",
                subtitle: "Mohon izinkan akses kamera untuk memulai pemindaian"
            )

            // Back button in top-leading corner so users can exit if stuck
            VStack {
                HStack {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(Font.cardTitle)
                            .foregroundStyle(.white)
                            .padding(AppSpacing.sm)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .padding(.leading, AppSpacing.md)
                    .padding(.top, 60)
                    Spacer()
                }
                Spacer()
            }
        }
    }

    // MARK: - Permission Denied

    private var permissionDeniedView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: AppSpacing.lg) {
                Image(systemName: "camera.fill")
                    .font(Font.system(size: 48, weight: .regular))
                    .foregroundStyle(.white.opacity(0.6))

                Text("Akses Kamera Ditolak")
                    .font(Font.bodyParagraph)
                    .foregroundStyle(.white)

                Text("Buka Pengaturan untuk mengizinkan akses kamera")
                    .font(Font.description)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)

                Button {
                    openSettings()
                } label: {
                    Text("Buka Pengaturan")
                        .font(Font.description)
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: AppCornerRadius.md)
                                .fill(.ultraThinMaterial)
                        )
                }

                Button {
                    onDismiss()
                } label: {
                    Text("Kembali")
                        .font(Font.description)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(AppSpacing.lg)
        }
    }

    // MARK: - Scanning

    private var scanningView: some View {
        ZStack {
            // Layer 1: Full-screen camera preview
            CameraPreviewView(session: viewModel.captureSession)
                .ignoresSafeArea()

            // Layer 2: Fullscreen dark & blurred overlay with a cut-out hole for the face oval guide
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                Color.black.opacity(0.60)
            }
            .ignoresSafeArea()
            .mask {
                Rectangle()
                    .fill(Color.black)
                    .overlay(
                        Ellipse()
                            .frame(width: 320, height: 440)
                            .blendMode(.destinationOut)
                    )
            }
            .compositingGroup()
            .allowsHitTesting(false)

            // Layer 3: Face guide overlay (centered oval) and progress ring combined
            FaceGuideOverlayView(
                isReady: viewModel.readiness == .ready,
                holdProgress: viewModel.holdProgress,
                completedAngles: viewModel.completedAngles
            )

            // Layer 4: Top & Bottom UI Controls Overlay (ON TOP of dark mask)
            VStack {
                // Top Bar with Native iOS 26 Glass Close Button
                HStack(alignment: .center) {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(14)
                            .glassEffect(.regular.interactive(), in: Circle())
                    }

                    Spacer()
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, 60) // Clear dynamic island

                Spacer()

                // Instruction text
                LightingIndicatorView(
                    readiness: viewModel.readiness,
                    completedAngles: viewModel.completedAngles,
                    targetName: viewModel.currentAngleTarget.displayName
                )
                .padding(.bottom, 80)
            }
        }
        .colorScheme(.dark)
    }

    // MARK: - Processing

    private var processingView: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: AppSpacing.lg) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("Menganalisis...")
                    .font(Font.bodyParagraph)
                    .foregroundStyle(.white)

                Text("Memproses gambar dengan AI")
                    .font(Font.description)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(AppSpacing.xl)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.lg)
                    .fill(.ultraThinMaterial)
            )
        }
    }

    // MARK: - Error

    private func errorView(message: String) -> some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: AppSpacing.lg) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(Font.system(size: 44, weight: .regular))
                    .foregroundStyle(AppColor.accentDanger)

                Text("Terjadi Kesalahan")
                    .font(Font.bodyParagraph)
                    .foregroundStyle(.white)

                Text(message)
                    .font(Font.description)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)

                VStack(spacing: AppSpacing.sm) {
                    Button {
                        viewModel.retry()
                    } label: {
                        Text("Coba Lagi")
                            .font(Font.description)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: AppCornerRadius.md)
                                    .fill(.ultraThinMaterial)
                            )
                    }

                    Button {
                        onDismiss()
                    } label: {
                        Text("Kembali")
                            .font(Font.description)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding(.top, AppSpacing.sm)
            }
            .padding(AppSpacing.xl)
        }
    }

    // MARK: - Helpers

    private func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsURL)
    }
}
