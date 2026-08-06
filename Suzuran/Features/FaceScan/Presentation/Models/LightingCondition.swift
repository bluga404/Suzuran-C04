import SwiftUI

enum LightingCondition: Equatable {
    case tooLow
    case acceptable
    case good

    var color: Color {
        switch self {
        case .tooLow:
            return AppColor.accentDanger
        case .acceptable:
            return Color.orange
        case .good:
            return AppColor.accentPrimary
        }
    }

    var iconName: String {
        switch self {
        case .tooLow:
            return "sun.min.fill"
        case .acceptable:
            return "sun.max"
        case .good:
            return "sun.max.fill"
        }
    }

    var message: String {
        switch self {
        case .tooLow:
            return "Cahaya kurang — pindah ke tempat lebih terang"
        case .acceptable:
            return "Cahaya lumayan — pencahayaan sedang"
        case .good:
            return "Pencahayaan bagus"
        }
    }
}
