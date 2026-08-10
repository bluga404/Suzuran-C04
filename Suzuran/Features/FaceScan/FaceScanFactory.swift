import SwiftUI

/// Simplified factory for the Face Scan feature.
/// Uses an autoclosure for the ViewModel so it can be lazily constructed by
/// `@StateObject` inside `FaceScanView`, ensuring only ONE instance exists
/// per view lifecycle.
///
/// Requirements: 1.3, 1.5
enum FaceScanFactory {
    @MainActor
    static func makeView(
        onScanSaved: @escaping (FaceScanSession) -> Void = { _ in },
        onDismiss: @escaping () -> Void = {}
    ) -> some View {
        FaceScanView(
            viewModel: FaceScanViewModel(acneDetectionService: AcneDetectionService()),
            onScanSaved: onScanSaved,
            onDismiss: onDismiss
        )
    }
}
