import SwiftUI

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
        case .cyst:      return "Cyst"
        case .nodule:    return "Nodule"
        case .papule:    return "Papule"
        case .pustule:   return "Pustule"
        case .whitehead: return "Whitehead"
        case .unknown:   return "Jerawat"
        }
    }

    /// Consistent colour used for YOLO bounding boxes AND the Type & Number list.
    var color: Color {
        switch self {
        case .blackhead: return Color(red: 0.55, green: 0.35, blue: 0.10)   // brown
        case .cyst:      return Color(red: 0.85, green: 0.15, blue: 0.15)   // red
        case .nodule:    return Color(red: 0.55, green: 0.15, blue: 0.75)   // purple
        case .papule:    return Color(red: 0.95, green: 0.45, blue: 0.10)   // orange
        case .pustule:   return Color(red: 0.90, green: 0.75, blue: 0.05)   // yellow
        case .whitehead: return Color(red: 0.80, green: 0.80, blue: 0.85)   // light blue-grey
        case .unknown:   return Color.gray
        }
    }
}
