import Foundation

/// Represents the three face scanning angles used in the 3-angle capture flow.
enum FaceZone: String, CaseIterable, Equatable, Codable {
    case front
    case leftAngle
    case rightAngle

    static let scanZones: [FaceZone] = [.front, .leftAngle, .rightAngle]

    var displayName: String {
        switch self {
        case .front: return "Front Side"
        case .leftAngle: return "Left Side"
        case .rightAngle: return "Right Side"
        }
    }

    var instruction: String {
        switch self {
        case .front: return "Look Straight Ahead"
        case .leftAngle: return "Turn Your Head to the Right"
        case .rightAngle: return "Turn Your Head to the Left"
        }
    }

    var order: Int {
        switch self {
        case .front: return 1
        case .leftAngle: return 2
        case .rightAngle: return 3
        }
    }
}
