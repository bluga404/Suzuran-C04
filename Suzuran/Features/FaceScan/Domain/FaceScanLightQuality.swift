import Foundation

enum FaceScanLightQuality: Equatable {
    case unknown
    case low    // too dim for reliable capture
    case adequate
    case good

    var title: String {
        switch self {
        case .unknown: return "Unknown"
        case .low: return "Low"
        case .adequate: return "Adequate"
        case .good: return "Good"
        }
    }

    var accessibilityDescription: String {
        switch self {
        case .unknown: return "Light level unknown"
        case .low: return "Low light"
        case .adequate: return "Adequate light"
        case .good: return "Good light"
        }
    }
}
