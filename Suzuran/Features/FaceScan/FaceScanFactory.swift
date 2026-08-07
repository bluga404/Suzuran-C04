import SwiftUI

/// Simplified factory for the Face Scan feature.
/// Directly instantiates AcneDetectionService → FaceScanViewModel → FaceScanView.
/// No UseCase, Repository, DataSource, or Mapper abstractions.
///
/// Requirements: 1.3, 1.5
enum FaceScanFactory {
    @MainActor
    static func makeView(onDismiss: @escaping () -> Void = {}) -> some View {
        let acneDetectionService = AcneDetectionService()
        let viewModel = FaceScanViewModel(acneDetectionService: acneDetectionService)
        return FaceScanView(viewModel: viewModel, onDismiss: onDismiss)
    }
}
