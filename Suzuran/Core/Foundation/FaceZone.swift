import Foundation

enum FaceZone: String, CaseIterable, Equatable, Codable {
    case forehead
    case rightCheek
    case leftCheek
    case nose
    case chin

    static let scanZones: [FaceZone] = [.forehead, .rightCheek, .leftCheek, .nose, .chin]

    var displayName: String {
        switch self {
        case .forehead: return "Jidat"
        case .rightCheek: return "Pipi Kanan"
        case .leftCheek: return "Pipi Kiri"
        case .nose: return "Hidung"
        case .chin: return "Dagu"
        }
    }

    var instruction: String {
        // Obsolete in new flow, but kept for compatibility or fallback
        return "Posisikan wajah Anda di tengah layar"
    }

    var order: Int {
        switch self {
        case .forehead: return 1
        case .rightCheek: return 2
        case .leftCheek: return 3
        case .nose: return 4
        case .chin: return 5
        }
    }
}
