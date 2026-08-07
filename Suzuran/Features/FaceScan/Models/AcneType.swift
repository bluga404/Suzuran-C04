import Foundation

enum AcneType: String, CaseIterable, Identifiable, Equatable, Codable {
    case blackhead
    case cyst
    case nodule
    case papule
    case pustule
    case whitehead
    case unknown

    var id: String { rawValue }

    /// Maps YOLO class_id (0–5) to the corresponding acne type.
    /// Any value outside 0–5 maps to `.unknown`.
    init(classId: Int) {
        switch classId {
        case 0: self = .blackhead
        case 1: self = .cyst
        case 2: self = .nodule
        case 3: self = .papule
        case 4: self = .pustule
        case 5: self = .whitehead
        default: self = .unknown
        }
    }

    var displayName: String {
        switch self {
        case .blackhead: return "Blackhead"
        case .cyst: return "Cyst"
        case .nodule: return "Nodule"
        case .papule: return "Papule"
        case .pustule: return "Pustule"
        case .whitehead: return "Whitehead"
        case .unknown: return "Jerawat"
        }
    }
}
