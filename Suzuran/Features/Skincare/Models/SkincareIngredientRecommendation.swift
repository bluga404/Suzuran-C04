import Foundation

struct RisksAndSafety: Codable, Hashable {
    let common: String?
    let serious: String?
    let rare: String?
    
    enum CodingKeys: String, CodingKey {
        case common = "Common"
        case serious = "Serious"
        case rare = "Rare"
    }
}

struct IngredientInteraction: Codable, Hashable {
    let ingredient: String
    let effect: String
    let description: String
    
    enum CodingKeys: String, CodingKey {
        case ingredient = "Ingredient"
        case effect = "Effect"
        case description = "Description"
    }
}

struct SkincareIngredientRecommendation: Identifiable, Codable, Hashable {
    var id: String { ingredientName }

    let ingredientName: String
    let alternativesName: String?
    let acneTypes: String
    let description: String
    let concentrationAndUsage: String
    let application: String
    let ingredientInteractions: [IngredientInteraction]?
    let risksAndSafety: RisksAndSafety
    let researchPapers: String?

    enum CodingKeys: String, CodingKey {
        case ingredientName = "Ingredients"
        case alternativesName = "Alternatives Name"
        case acneTypes = "Acne Types"
        case description = "Description"
        case concentrationAndUsage = "Concentration & Usage"
        case application = "Application"
        case ingredientInteractions = "Ingredient Interactions"
        case risksAndSafety = "Risks & Safety"
        case researchPapers = "Research Papers"
    }
}
