import AVFoundation

enum FaceScanFlashOption: String, CaseIterable, Identifiable {
    case off
    case auto
    case on

    var id: String { rawValue }

    var title: String {
        switch self {
        case .off:
            return "Off"
        case .auto:
            return "Auto"
        case .on:
            return "On"
        }
    }

    var captureFlashMode: AVCaptureDevice.FlashMode {
        switch self {
        case .off:
            return .off
        case .auto:
            return .auto
        case .on:
            return .on
        }
    }

    static func from(_ mode: AVCaptureDevice.FlashMode) -> FaceScanFlashOption {
        switch mode {
        case .off:
            return .off
        case .auto:
            return .auto
        case .on:
            return .on
        @unknown default:
            return .off
        }
    }
}
