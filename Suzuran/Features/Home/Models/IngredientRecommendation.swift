import Foundation

/// Represents whether a recommended ingredient is found in the user's scanned products.
enum IngredientStatus: Equatable {
    case notFound
    case found(products: [SkincareProduct])
}

/// A skincare ingredient with its normalized and display names.
struct Ingredient: Equatable {
    /// Normalized lowercase name used for matching
    let name: String
    /// User-facing display name
    let displayName: String
}

/// A recommended skincare ingredient with detailed reference and status in the user's routine.
struct IngredientRecommendation: Identifiable, Equatable {
    let id: UUID
    /// The recommended ingredient
    let ingredient: Ingredient
    /// The detailed recommendation from the database, containing the description and reference information
    let detail: SkincareIngredientRecommendation
    /// Whether the ingredient was found in the user's scanned products
    let status: IngredientStatus
}
