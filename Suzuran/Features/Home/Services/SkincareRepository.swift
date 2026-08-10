import Foundation

/// Minimal data type representing a skincare product tracked by the user.
/// Used by the Home feature to check ingredient recommendation status.
struct SkincareProduct: Identifiable, Equatable {
    /// Unique identifier for this product.
    let id: UUID
    /// User-facing product name.
    let name: String
    /// Normalized ingredient names contained in this product.
    let ingredients: [String]
}

/// Repository protocol for accessing skincare product data in the Home feature.
/// Implementations may fetch from persistence, network, or fixture data.
protocol SkincareRepository {
    /// Returns all skincare products tracked by the user.
    func products() async throws -> [SkincareProduct]
}
