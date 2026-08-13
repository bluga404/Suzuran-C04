import Foundation

/// Represents the user's face readiness state during scanning.
/// Each case provides a localized message and whether capture is allowed.
enum FaceScanReadiness: Equatable {
    case countingDown(Int)
    case searchingFace
    case faceOutOfGuide
    case tooFar
    case wrongAngle(String)
    case unstable
    case ready

    /// Localized instruction message displayed to the user (Bahasa Indonesia).
    var message: String {
        switch self {
        case .countingDown(let seconds):
            return "Get ready in \(seconds)..."
        case .searchingFace:
            return "Searching for face..."
        case .faceOutOfGuide:
            return "Position your face within the oval"
        case .tooFar:
            return "Move Your Head a Little Closer"
        case .wrongAngle(let direction):
            return "Turn your head to the \(direction)"
        case .unstable:
            return "Hold steady..."
        case .ready:
            return "Ready"
        }
    }

    /// Returns `true` only when the face is in a valid position and stable enough for capture.
    var allowsCapture: Bool {
        switch self {
        case .ready:
            return true
        case .countingDown, .searchingFace, .faceOutOfGuide, .tooFar, .wrongAngle, .unstable:
            return false
        }
    }
}
