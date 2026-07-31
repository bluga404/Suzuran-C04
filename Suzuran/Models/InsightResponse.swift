import Foundation

struct InsightResponse: Codable {
    let trendSummary: String
    let ingredientInsight: String
    let recommendationToAdd: String
    let recommendationToAvoid: String
    let encouragement: String
    
    enum CodingKeys: String, CodingKey {
        case trendSummary = "trend_summary"
        case ingredientInsight = "ingredient_insight"
        case recommendationToAdd = "recommendation_to_add"
        case recommendationToAvoid = "recommendation_to_avoid"
        case encouragement = "encouragement"
    }
}
