import Foundation
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
        case .cyst: return "Cyst"
        case .nodule: return "Nodule"
        case .papule: return "Papule"
        case .pustule: return "Pustule"
        case .whitehead: return "Whitehead"
        case .unknown: return "Jerawat"
        }
    }

    var severityWeight: Float {
        switch self {
        case .blackhead, .whitehead: return 0.5
        case .papule: return 1.0
        case .pustule: return 2.0
        case .nodule, .cyst: return 3.0
        case .unknown: return 1.0
        }
    }

    var color: Color {
        switch self {
        case .whitehead: return AppColor.acneWhitehead
        case .blackhead: return AppColor.acneBlackhead
        case .papule: return AppColor.acnePapule
        case .pustule: return AppColor.acnePustule
        case .nodule: return AppColor.acneNodule
        case .cyst: return AppColor.acneCyst
        case .unknown: return AppColor.textSecondary
        }
    }

    var uiColor: UIColor {
        #if canImport(UIKit)
        return UIColor(self.color)
        #else
        return .gray
        #endif
    }
}
