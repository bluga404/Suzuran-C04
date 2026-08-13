import AVFoundation
import SwiftUI

/// A UIViewRepresentable that wraps AVCaptureVideoPreviewLayer for displaying
/// the live camera feed within SwiftUI.
///
/// Uses a custom UIView subclass that resizes the preview layer in layoutSubviews,
/// ensuring the camera feed renders correctly even when SwiftUI lays out the view
/// after creation (which means bounds are .zero at makeUIView time).
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewContainerView {
        let view = PreviewContainerView()
        view.previewLayer.session = session
        return view
    }

    func updateUIView(_ uiView: PreviewContainerView, context: Context) {
        uiView.previewLayer.session = session
    }
}

/// Container view that correctly sizes the preview layer on every layout pass.
final class PreviewContainerView: UIView {
    let previewLayer = AVCaptureVideoPreviewLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }
}
