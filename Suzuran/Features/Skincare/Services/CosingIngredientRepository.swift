import Foundation
import Combine

final class CosingIngredientRepository: CosingIngredientRepositoryProtocol {
    @Published private(set) var isLoaded = false
    private var cosingNames: [String] = []

    init() {
        loadCosingDatabase()
    }

    private func loadCosingDatabase() {
        guard let url = Bundle.main.url(forResource: "cosing", withExtension: "json") else {
            print("[CosingIngredientRepository] ❌ cosing.json not found in bundle")
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
                    print("[CosingIngredientRepository] ✅ Loaded \(self.cosingNames.count) CosIng ingredients in background")
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoaded = true
                }
                print("[CosingIngredientRepository] ❌ Failed to load cosing.json: \(error)")
            }
        }
    }

    func searchIngredients(query: String) -> [IngredientReference] {
        guard !query.isEmpty else { return [] }
        let cleanQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            
        let matchingCosing = cosingNames
            .filter { $0.lowercased().contains(cleanQuery) }
            .prefix(40)
            
        return matchingCosing.map { IngredientReference(id: UUID().uuidString, name: $0) }
    }
}
