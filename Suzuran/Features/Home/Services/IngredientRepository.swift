import Foundation

/// Minimal data type representing a scanned ingredient product analysis.
/// Used by the Home feature to determine ingredient recommendations.
struct IngredientScanData: Equatable {
    /// Unique identifier for this ingredient scan.
    let id: UUID
    /// Timestamp when the scan was performed.
    let scannedAt: Date
    /// Normalized ingredient names detected in the scanned product.
    let detectedIngredients: [String]
}

/// Repository protocol for accessing ingredient scan data in the Home feature.
/// Implementations may fetch from persistence, network, or fixture data.
protocol IngredientRepository {
    /// Returns the most recent ingredient scan, or nil if none exists.
    func latestIngredientScan() async throws -> IngredientScanData?
}
