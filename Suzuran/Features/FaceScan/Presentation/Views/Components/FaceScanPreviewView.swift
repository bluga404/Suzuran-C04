import AVFoundation
import SwiftUI
import UIKit

struct FaceScanPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let previewView = PreviewView()
        previewView.session = session
        previewView.updatePreviewConnectionIfNeeded()
        return previewView
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.session = session
        uiView.updatePreviewConnectionIfNeeded()
    }
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    private var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    var session: AVCaptureSession? {
        get { previewLayer.session }
        set { previewLayer.session = newValue }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updatePreviewConnectionIfNeeded()
    }

    func updatePreviewConnectionIfNeeded() {
        previewLayer.videoGravity = .resizeAspectFill

        guard let connection = previewLayer.connection else { return }

        if connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = true
        }
    }
}
