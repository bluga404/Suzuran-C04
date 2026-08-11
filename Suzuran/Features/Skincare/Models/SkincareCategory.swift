import Foundation

enum SkincareCategory: String, Codable, CaseIterable, Identifiable {
    case cleanser = "Cleanser"
    case toner = "Toner"
    case serum = "Serum"
    case moisturizer = "Moisturizer"
    case sunscreen = "Sunscreen"
    case faceMask = "Face Mask"
    case other = "Other"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        return self.rawValue
    }
    
    var iconName: String {
        switch self {
        case .cleanser: return "bubbles.and.sparkles"
        case .toner: return "drop"
        case .serum: return "flask"
        case .moisturizer: return "drop.fill"
        case .sunscreen: return "sun.max"
        case .faceMask: return "face.dashed"
        case .other: return "sparkles"
        }
    }
}
