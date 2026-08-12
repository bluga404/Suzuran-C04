import Foundation

/// Enum representasi kategori produk skincare pengguna.
enum SkincareCategory: String, Codable, CaseIterable, Identifiable {
    case cleanser
    case toner
    case serum
    case moisturizer
    case sunscreen
    case treatment

    // MARK: - Identifiable

    var id: String { rawValue }

    // MARK: - Display

    var displayName: String {
        switch self {
        case .cleanser:    return "Pembersih"
        case .toner:       return "Toner"
        case .serum:       return "Serum"
        case .moisturizer: return "Pelembap"
        case .sunscreen:   return "Sunscreen"
        case .treatment:   return "Treatment"
        }
    }

    var iconSystemName: String {
        switch self {
        case .cleanser:    return "bubbles.and.sparkles"
        case .toner:       return "drop"
        case .serum:       return "drop.halffull"
        case .moisturizer: return "drop.fill"
        case .sunscreen:   return "sun.max"
        case .treatment:   return "cross.case"
        }
    }
}
