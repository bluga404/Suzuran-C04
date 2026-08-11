import Foundation

struct MatchedRecommendation: Identifiable, Equatable {
    var id: String { recommendation.ingredientName }
    let recommendation: SkincareIngredientRecommendation
    let matchedAcneTypes: [AcneType]
}

final class IngredientMatcher {
    
    /// Matches a skincare product's ingredients against the user's active acne types.
    /// Returns the matched recommendations along with details on which acne types they target.
    static func match(
        product: SkincareProduct,
        activeAcneTypes: [AcneType],
        repository: SkincareIngredientRepository
    ) -> [MatchedRecommendation] {
        var matches: [MatchedRecommendation] = []
        
        for ingredient in product.ingredients {
            // Find if there is a recommendation for this ingredient
            guard let recommendation = repository.getRecommendation(for: ingredient) else {
                continue
            }
            
            // Check which active acne types are addressed by this ingredient
            let matchedTypes = activeAcneTypes.filter { acneType in
                matchesAcneType(acneType, recommendation: recommendation)
            }
            
            // If it matches at least one active acne type, add it to recommendations!
            if !matchedTypes.isEmpty {
                matches.append(
                    MatchedRecommendation(
                        recommendation: recommendation,
                        matchedAcneTypes: matchedTypes
                    )
                )
            }
        }
        
        return matches
    }
    
    private static func matchesAcneType(_ acneType: AcneType, recommendation: SkincareIngredientRecommendation) -> Bool {
        let targets = recommendation.acneTypes.lowercased()
        let query = acneType.displayName.lowercased()
        
        // 1. Direct match (e.g. "pustule" in "Whitehead, Blackhead, Papule, Pustule")
        if targets.contains(query) {
            return true
        }
        
        // 2. Semantic matching for related terms
        if acneType == .blackhead || acneType == .whitehead {
            if targets.contains("comedonal") || targets.contains("mild acne") {
                return true
            }
        }
        
        if acneType == .papule || acneType == .pustule {
            if targets.contains("inflammatory") || targets.contains("mild acne") {
                return true
            }
        }
        
        if acneType == .nodule || acneType == .cyst {
            if targets.contains("severe acne") || targets.contains("inflammatory") {
                return true
            }
        }
        
        return false
    }
}
