import Foundation

/// Represents the user's face readiness state during scanning.
/// Each case provides a localized message and whether capture is allowed.
enum FaceScanReadiness: Equatable {
    case searchingFace
    case faceOutOfGuide
    case tooFar
    case wrongAngle(String)
    case unstable
    case ready

    /// Localized instruction message displayed to the user (Bahasa Indonesia).
    var message: String {
        switch self {
        case .searchingFace:
            return "Mencari wajah..."
        case .faceOutOfGuide:
            return "Wajah di luar area"
        case .tooFar:
            return "Terlalu jauh"
        case .wrongAngle(let direction):
            return "Putar wajah ke \(direction)"
        case .unstable:
            return "Tahan posisi..."
        case .ready:
            return "Siap"
        }
    }

    /// Returns `true` only when the face is in a valid position and stable enough for capture.
    var allowsCapture: Bool {
        switch self {
        case .ready:
            return true
        case .searchingFace, .faceOutOfGuide, .tooFar, .wrongAngle, .unstable:
            return false
        }
    }
}
