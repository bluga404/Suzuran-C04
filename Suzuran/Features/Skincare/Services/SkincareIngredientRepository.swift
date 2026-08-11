import Foundation
import Combine

final class SkincareIngredientRepository: ObservableObject {
    @Published private(set) var isLoaded = false
    private var cosingNames: [String] = []
    private var recommendations: [SkincareIngredientRecommendation] = []
    private var recommendationMap: [String: SkincareIngredientRecommendation] = [:]

    init() {
        loadRecommendations()
        loadCosingDatabase()
    }

    private func loadRecommendations() {
        guard let url = Bundle.main.url(forResource: "AcneIngredients", withExtension: "json") else {
            print("[SkincareIngredientRepository] ❌ AcneIngredients.json not found in bundle")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let recs = try JSONDecoder().decode([SkincareIngredientRecommendation].self, from: data)
            self.recommendations = recs
            for rec in recs {
                self.recommendationMap[rec.ingredientName.lowercased()] = rec
            }
            print("[SkincareIngredientRepository] ✅ Loaded \(recs.count) ingredient recommendations")
        } catch {
            print("[SkincareIngredientRepository] ❌ Failed to load AcneIngredients.json: \(error)")
        }
    }

    private func loadCosingDatabase() {
        guard let url = Bundle.main.url(forResource: "cosing", withExtension: "json") else {
            print("[SkincareIngredientRepository] ❌ cosing.json not found in bundle")
            self.isLoaded = true
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data = try Data(contentsOf: url)
                
                struct CosIngIndexWrapper: Codable {
                    let ingredientIndex: [String: Int]
                }
                
                let indexWrapper = try JSONDecoder().decode(CosIngIndexWrapper.self, from: data)
                let names = Array(indexWrapper.ingredientIndex.keys)
                let capitalizedNames = names.map { $0.capitalized }
                
                DispatchQueue.main.async {
                    self.cosingNames = capitalizedNames
                    self.isLoaded = true
                    print("[SkincareIngredientRepository] ✅ Loaded \(self.cosingNames.count) CosIng ingredients in background")
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoaded = true
                }
                print("[SkincareIngredientRepository] ❌ Failed to load cosing.json: \(error)")
            }
        }
    }

    func searchIngredients(query: String) -> [String] {
        guard !query.isEmpty else { return [] }
        let cleanQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Match in recommended ingredients first (high priority)
        let matchingRecs = recommendations
            .map { $0.ingredientName }
            .filter { $0.lowercased().contains(cleanQuery) }
            
        // Match in cosing next
        let matchingCosing = cosingNames
            .filter { $0.lowercased().contains(cleanQuery) }
            .prefix(30)
            
        var results = Array(matchingRecs)
        for name in matchingCosing {
            if !results.contains(where: { $0.caseInsensitiveCompare(name) == .orderedSame }) {
                results.append(name)
            }
        }
        return Array(results.prefix(40))
    }

    func getRecommendation(for name: String) -> SkincareIngredientRecommendation? {
        return recommendationMap[name.lowercased()]
    }
}
