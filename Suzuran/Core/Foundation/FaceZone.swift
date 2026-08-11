import Foundation

/// Represents the three face scanning angles used in the 3-angle capture flow.
enum FaceZone: String, CaseIterable, Equatable, Codable {
    case front
    case leftAngle
    case rightAngle

    static let scanZones: [FaceZone] = [.front, .leftAngle, .rightAngle]

    var displayName: String {
        switch self {
        case .front: return "Depan"
        case .leftAngle: return "Kiri"
        case .rightAngle: return "Kanan"
        }
    }

    var instruction: String {
        switch self {
        case .front: return "Posisi Lurus ke Depan"
        case .leftAngle: return "Putar Wajah ke Kanan"
        case .rightAngle: return "Putar Wajah ke Kiri"
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
