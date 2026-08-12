import Foundation

/// User-owned skincare product model.
struct SkincareProduct: Identifiable, Equatable, Hashable, Codable {
    let id: UUID
    var name: String
    var brand: String
    var category: SkincareCategory
    var ingredients: [IngredientReference]
    var isUsedCurrently: Bool

    init(
        id: UUID = UUID(),
        name: String,
        brand: String,
        category: SkincareCategory,
        ingredients: [IngredientReference] = [],
        isUsedCurrently: Bool = true
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.category = category
        self.ingredients = ingredients
        self.isUsedCurrently = isUsedCurrently
    }
}
