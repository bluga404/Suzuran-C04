import Foundation

enum FaceScanArea: String, CaseIterable, Identifiable, Hashable {
    case rightCheek
    case leftCheek
    case forehead
    case chin
    case centerFace

    var id: String { rawValue }

    static var captureOrder: [FaceScanArea] {
        [.rightCheek, .leftCheek, .forehead, .chin, .centerFace]
    }

    var title: String {
        switch self {
        case .rightCheek:
            return "Right Cheek"
        case .leftCheek:
            return "Left Cheek"
        case .forehead:
            return "Forehead"
        case .chin:
            return "Chin"
        case .centerFace:
            return "Center"
        }
    }

    var instruction: String {
        switch self {
        case .rightCheek:
            return "Turn your face slightly to your right."
        case .leftCheek:
            return "Turn your face slightly to your left."
        case .forehead:
            return "Tilt your head down a little to expose your forehead."
        case .chin:
            return "Lift your chin slightly."
        case .centerFace:
            return "Look straight at the camera."
        }
    }
}