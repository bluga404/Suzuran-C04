import SwiftUI

struct FaceScanView: View {
    @StateObject private var viewModel: FaceScanViewModel
    let onDismiss: () -> Void

    init(viewModel: FaceScanViewModel, onDismiss: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onDismiss = onDismiss
    }

    var body: some View {
        ZStack {
            switch viewModel.phase {
            case .requestingPermission:
                LoadingStateView(
                    title: "Meminta Izin Kamera",
                    subtitle: "Izinkan akses kamera untuk memulai scan wajah."
                )

            case .permissionDenied:
                PermissionStateView(
                    title: "Akses Kamera Ditolak",
                    message: "Aplikasi membutuhkan akses kamera untuk memindai wajah Anda.",
                    actionTitle: "Coba Lagi",
                    action: viewModel.startScan
                )

            case .positioningFace, .scanning:
                cameraView

            case .processing:
                LoadingStateView(
                    title: "Menganalisis Wajah",
                    subtitle: "Model YOLO sedang mendeteksi jerawat di seluruh permukaan wajah..."
                )

            case let .completed(resultModel):
                FaceScanResultView(result: resultModel, onDone: onDismiss)

            case let .error(message):
                ErrorStateView(
                    title: "Gagal Scan Wajah",
                    message: message,
                    primaryActionTitle: "Coba Lagi",
                    onPrimaryAction: viewModel.retry
                )
            }
        }
        .onAppear(perform: viewModel.startScan)
        .onDisappear(perform: viewModel.stopScan)
        .appScreenContainer()
    }

    @ViewBuilder
    private var cameraView: some View {
        ZStack {
            // Live Camera Feed
            CameraPreviewView(session: viewModel.captureSession)
                .edgesIgnoringSafeArea(.all)

            // Focus Box Overlay (Oval) with hold progress
            FaceGuideOverlayView(
                isFaceInPosition: viewModel.isFaceInPosition,
                currentZone: viewModel.currentZone,
                holdProgress: viewModel.zoneProgress,
                readiness: viewModel.readiness,
                targetZones: viewModel.scanTargetZones,
                instruction: viewModel.scanInstruction
            )

            // Top Header: Lighting & Cancel Button
            VStack {
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.white.opacity(0.85))
                    }

                    Spacer()

                    LightingIndicatorView(condition: viewModel.lightingCondition)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.lg)

                Spacer()

                // Bottom: Scan Progress for 5 zones with hold indicator
                ScanProgressView(
                    completedZones: viewModel.completedZones,
                    currentZone: viewModel.currentZone,
                    holdProgress: viewModel.zoneProgress
                )
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.xl)
            }
        }
    }
}
