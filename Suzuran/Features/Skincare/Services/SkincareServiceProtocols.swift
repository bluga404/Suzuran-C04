import Foundation
import Combine
import UIKit

// OCR Service
protocol OCRService {
    func recognizeText(from image: UIImage) async throws -> String
}

// Extraction Pipeline
protocol IngredientExtractionService {
    func extractIngredients(from text: String) -> [OCRIngredientResult]
}

// Repository for Cosing database
protocol CosingIngredientRepositoryProtocol: ObservableObject {
    var isLoaded: Bool { get }
    func searchIngredients(query: String) -> [IngredientReference]
}

// Repository for Acne ingredient profiles
protocol AcneIngredientRepositoryProtocol: ObservableObject {
    func getRecommendation(for normalizedName: String) -> SkincareIngredientRecommendation?
    func searchRecommendations(query: String) -> [IngredientReference]
    func getAllRecommendations() -> [SkincareIngredientRecommendation]
}

// Matching Service
protocol IngredientMatchingService {
    static func getMatches(
        for ingredients: [IngredientReference],
        activeAcneTypes: [AcneType],
        repository: AcneIngredientRepositoryProtocol
    ) -> [MatchedRecommendation]
}
