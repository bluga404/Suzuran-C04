import Foundation

struct SkincareProduct: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var brand: String
    var category: SkincareCategory
    var ingredients: [IngredientReference]
    var isUsedCurrently: Bool
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        brand: String,
        category: SkincareCategory,
        ingredients: [IngredientReference] = [],
        isUsedCurrently: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.category = category
        self.ingredients = ingredients
        self.isUsedCurrently = isUsedCurrently
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
