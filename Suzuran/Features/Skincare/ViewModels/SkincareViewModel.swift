import SwiftUI
import Combine

@MainActor
final class SkincareViewModel: ObservableObject {
    @Published private(set) var products: [SkincareProduct] = []
    @Published private(set) var activeAcneTypes: [AcneType] = []
    @Published private(set) var matchedRecommendations: [UUID: [MatchedRecommendation]] = [:]

    private let skincareRepository: SkincareProductRepositoryProtocol
    private let acneRepository: AcneIngredientRepositoryProtocol
    private let acneProfileProvider: AcneProfileProviding

    init(
        skincareRepository: SkincareProductRepositoryProtocol,
        acneRepository: AcneIngredientRepositoryProtocol,
        acneProfileProvider: AcneProfileProviding
    ) {
        self.skincareRepository = skincareRepository
        self.acneRepository = acneRepository
        self.acneProfileProvider = acneProfileProvider
        loadData()
    }

    var uniqueMatchedRecommendations: [MatchedRecommendation] {
        var unique: [String: MatchedRecommendation] = [:]
        for (_, recommendations) in matchedRecommendations {
            for rec in recommendations {
                unique[rec.id] = rec
            }
        }
        return Array(unique.values).sorted { $0.recommendation.ingredientName < $1.recommendation.ingredientName }
    }

    func loadData() {
        self.products = skincareRepository.fetchProducts()
        self.activeAcneTypes = acneProfileProvider.getActiveAcneTypes()
        calculateAllMatches()
    }

    private func calculateAllMatches() {
        var matches: [UUID: [MatchedRecommendation]] = [:]
        for product in products {
            matches[product.id] = IngredientMatcher.getMatches(
                for: product.ingredients,
                activeAcneTypes: activeAcneTypes,
                repository: acneRepository
            )
        }
        self.matchedRecommendations = matches
    }

    func getRecommendations(for product: SkincareProduct) -> [MatchedRecommendation] {
        return matchedRecommendations[product.id] ?? []
    }

    func addProduct(_ product: SkincareProduct) {
        skincareRepository.addProduct(product)
        loadData()
    }

    func updateProduct(_ product: SkincareProduct) {
        skincareRepository.updateProduct(product)
        loadData()
    }

    func deleteProduct(id: UUID) {
        skincareRepository.deleteProduct(id: id)
        loadData()
    }
}
