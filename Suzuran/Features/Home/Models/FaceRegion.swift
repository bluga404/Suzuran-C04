import Foundation

/// Represents the 5 facial zones used for GAGS (Global Acne Grading System) scoring.
/// Each region has an associated GAGS factor and display name in Bahasa Indonesia.
enum FaceRegion: String, Codable, CaseIterable, Identifiable {
    case forehead
    case rightCheek
    case leftCheek
    case nose
    case chin

    var id: String { rawValue }

    /// GAGS zone factor: Forehead = 2, Right Cheek = 2, Left Cheek = 2, Nose = 1, Chin = 1
    var gagsFactor: Int {
        switch self {
        case .forehead, .rightCheek, .leftCheek: return 2
        case .nose, .chin: return 1
        }
    }

    /// User-facing display name in Bahasa Indonesia.
    var displayName: String {
        switch self {
        case .forehead: return "Dahi"
        case .rightCheek: return "Pipi Kanan"
        case .leftCheek: return "Pipi Kiri"
        case .nose: return "Hidung"
        case .chin: return "Dagu"
        }
    }
    
    /// User-facing display name in English.
    var englishDisplayName: String {
        switch self {
        case .forehead: return "Forehead"
        case .rightCheek: return "Right Cheek"
        case .leftCheek: return "Left Cheek"
        case .nose: return "Nose"
        case .chin: return "Chin"
        }
    }

    /// Display order per spec: Forehead, Left Cheek, Right Cheek, Chin, Nose
    static let displayOrder: [FaceRegion] = [
        .forehead, .leftCheek, .rightCheek, .chin, .nose
    ]
}
