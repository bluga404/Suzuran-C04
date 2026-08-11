import Foundation

struct SkincareProduct: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var brand: String
    var category: String
    var ingredients: [String]
    var isUsedCurrently: Bool

    init(
        id: UUID = UUID(),
        name: String,
        brand: String,
        category: String,
        ingredients: [String] = [],
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
