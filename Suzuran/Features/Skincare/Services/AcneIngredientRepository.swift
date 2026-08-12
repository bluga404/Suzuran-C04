import Foundation
import Combine

final class AcneIngredientRepository: AcneIngredientRepositoryProtocol {
    private var recommendations: [SkincareIngredientRecommendation] = []
    private var recommendationMap: [String: SkincareIngredientRecommendation] = [:]

    init() {
        loadRecommendations()
    }

    private func loadRecommendations() {
        guard let url = Bundle.main.url(forResource: "AcneIngredients", withExtension: "json") else {
            print("[AcneIngredientRepository] ❌ AcneIngredients.json not found in bundle")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let recs = try JSONDecoder().decode([SkincareIngredientRecommendation].self, from: data)
            self.recommendations = recs
            for rec in recs {
                self.recommendationMap[rec.ingredientName.lowercased()] = rec
            }
            print("[AcneIngredientRepository] ✅ Loaded \(recs.count) ingredient recommendations")
        } catch {
            print("[AcneIngredientRepository] ❌ Failed to load AcneIngredients.json: \(error)")
        }
    }

    func getRecommendation(for normalizedName: String) -> SkincareIngredientRecommendation? {
        return recommendationMap[normalizedName]
    }
    
    func searchRecommendations(query: String) -> [IngredientReference] {
        guard !query.isEmpty else { return [] }
        let cleanQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        return recommendations
            .map { $0.ingredientName }
            .filter { $0.lowercased().contains(cleanQuery) }
            .map { IngredientReference(id: UUID().uuidString, name: $0) }
    }
    
    func getAllRecommendations() -> [SkincareIngredientRecommendation] {
        return recommendations
    }
}
