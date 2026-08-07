import Foundation

enum AcneSeverity: String, Equatable, Codable {
    case clear
    case mild
    case moderate
    case severe

    /// Determines severity based on total acne count:
    /// - 0 = clear
    /// - 1–5 = mild
    /// - 6–15 = moderate
    /// - 16+ = severe
    init(totalCount: Int) {
        switch totalCount {
        case 0:
            self = .clear
        case 1...5:
            self = .mild
        case 6...15:
            self = .moderate
        default:
            self = .severe
        }
    }
}
