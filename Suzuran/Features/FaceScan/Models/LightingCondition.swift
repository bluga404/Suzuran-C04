import Foundation

/// Represents the current lighting condition of the camera feed.
enum LightingCondition: Equatable {
    case good
    case tooDark
    case tooBright
    
    var title: String {
        return "Light Indicator"
    }
    
    var subtitle: String {
        switch self {
        case .good: return "Good"
        case .tooDark: return "Low light"
        case .tooBright: return "Too bright"
        }
    }
    
    var isWarning: Bool {
        self != .good
    }
}
