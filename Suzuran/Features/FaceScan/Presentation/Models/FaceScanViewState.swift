import Foundation

enum FaceScanPhase: Equatable {
    case requestingPermission
    case permissionDenied
    case positioningFace
    case scanning(currentZone: FaceZone, capturedCount: Int)
    case processing
    case completed(FaceScanResultModel)
    case error(message: String)
}

enum FaceScanReadiness: Equatable {
    case searchingFace
    case faceOutOfGuide
    case insufficientLighting
    case targetNotVisible(String)
    case wrongPose(String)
    case unstable
    case ready

    var message: String {
        switch self {
        case .searchingFace:
            return "Wajah belum terdeteksi"
        case .faceOutOfGuide:
            return "Posisikan wajah di dalam panduan"
        case .insufficientLighting:
            return "Pencahayaan terlalu rendah"
        case let .targetNotVisible(message), let .wrongPose(message):
            return message
        case .unstable:
            return "Tahan wajah tetap stabil"
        case .ready:
            return "Posisi tepat — tahan wajah Anda"
        }
    }

    var allowsCapture: Bool {
        self == .ready
    }
}
