import Foundation

struct SkincareIngredientRecommendation: Identifiable, Codable, Hashable {
    var id: String { ingredientName }

    let ingredientName: String
    let alternativesName: String?
    let acneTypes: String
    let description: String
    let concentrationAndUsage: String
    let application: String
    let ingredientInteractions: String?
    let risksAndSafety: String
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
