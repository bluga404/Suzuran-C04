import SwiftUI
import UIKit

/// The main face scan screen that orchestrates the entire scanning flow.
/// Switches rendering based on `viewModel.phase` to show permission request,
/// live scanning, processing, results, or error states.
///
/// Requirements: 2.3, 2.4, 4.5, 5.6
struct FaceScanView: View {
    @ObservedObject private var viewModel: FaceScanViewModel
    let onDismiss: () -> Void
    let onSave: (FaceScanResultModel) -> Void

    /// Tracks completedAngles changes to trigger haptic feedback on zone capture.
    @State private var lastCompletedAngles: Int = 0

    /// Haptic feedback generator for zone capture completion.
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .medium)

    init(
        viewModel: FaceScanViewModel,
        onDismiss: @escaping () -> Void,
        onSave: @escaping (FaceScanResultModel) -> Void = { _ in }
    ) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self.onDismiss = onDismiss
        self.onSave = onSave
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
            FaceScanResultView(result: result, onDone: {
                onSave(result)
                onDismiss()
            })

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
        }
    }

    // MARK: - Permission Denied

    private var permissionDeniedView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: AppSpacing.lg) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.white.opacity(0.6))

                Text("Akses Kamera Ditolak")
                    .font(AppTypography.subtitle)
                    .foregroundStyle(.white)

                Text("Buka Pengaturan untuk mengizinkan akses kamera")
                    .font(AppTypography.body)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)

                Button {
                    openSettings()
                } label: {
                    Text("Buka Pengaturan")
                        .font(AppTypography.bodyBold)
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
                        .font(AppTypography.body)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(AppSpacing.lg)
        }
    }

    // MARK: - Scanning

    private var scanningView: some View {
        ZStack {
            // Full-screen camera preview
            CameraPreviewView(session: viewModel.captureSession)
                .ignoresSafeArea()

            // Face guide overlay (centered oval)
            FaceGuideOverlayView(isReady: viewModel.readiness == .ready)

            // Scan progress ring around the face guide
            ScanProgressView(
                holdProgress: viewModel.holdProgress,
                completedAngles: viewModel.completedAngles
            )
            .frame(width: 270, height: 370)

            // Bottom instruction and controls
            VStack {
                Spacer()

                // Instruction text
                LightingIndicatorView(readiness: viewModel.readiness)
                    .padding(.bottom, AppSpacing.sm)

                // Close button with Liquid Glass material
                HStack {
                    Spacer()

                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(.ultraThinMaterial))
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)
            }
        }
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
                    .font(AppTypography.subtitle)
                    .foregroundStyle(.white)

                Text("Memproses gambar dengan AI")
                    .font(AppTypography.body)
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
                    .font(.system(size: 44))
                    .foregroundStyle(AppColor.accentDanger)

                Text("Terjadi Kesalahan")
                    .font(AppTypography.subtitle)
                    .foregroundStyle(.white)

                Text(message)
                    .font(AppTypography.body)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)

                VStack(spacing: AppSpacing.sm) {
                    Button {
                        viewModel.retry()
                    } label: {
                        Text("Coba Lagi")
                            .font(AppTypography.bodyBold)
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
                            .font(AppTypography.body)
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

#Preview {
    // Note: Preview requires a mock or real AcneDetectionService.
    // This serves as a layout preview reference.
    ZStack {
        Color.black.ignoresSafeArea()
        Text("FaceScanView Preview")
            .foregroundStyle(.white)
    }
}
