import Foundation

enum FaceZone: String, CaseIterable, Equatable, Codable {
    case front
    case leftAngle
    case rightAngle
    
    // Obsolete for backwards compatibility
    case forehead
    case rightCheek
    case leftCheek
    case nose
    case chin

    static let scanZones: [FaceZone] = [.front, .leftAngle, .rightAngle]

    var displayName: String {
        switch self {
        case .front: return "Depan"
        case .leftAngle: return "Kiri"
        case .rightAngle: return "Kanan"
        case .forehead: return "Jidat"
        case .rightCheek: return "Pipi Kanan"
        case .leftCheek: return "Pipi Kiri"
        case .nose: return "Hidung"
        case .chin: return "Dagu"
        }
    }

    var instruction: String {
        switch self {
        case .front: return "Posisi Lurus ke Depan"
        case .leftAngle: return "Putar Wajah ke Kiri"
        case .rightAngle: return "Putar Wajah ke Kanan"
        default: return "Posisikan wajah Anda"
        }
    }

    var order: Int {
        switch self {
        case .front: return 1
        case .leftAngle: return 2
        case .rightAngle: return 3
        case .forehead: return 4
        case .rightCheek: return 5
        case .leftCheek: return 6
        case .nose: return 7
        case .chin: return 8
        }
    }
}
