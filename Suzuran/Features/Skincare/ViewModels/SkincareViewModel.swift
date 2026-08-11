import SwiftUI
import Combine

@MainActor
final class SkincareViewModel: ObservableObject {
    @Published private(set) var products: [SkincareProduct] = []
    @Published private(set) var activeAcneTypes: [AcneType] = []
    @Published private(set) var matchedRecommendations: [UUID: [MatchedRecommendation]] = [:]

    private let skincareRepository: SkincareProductRepositoryProtocol
    private let ingredientRepository: SkincareIngredientRepository
    private let acneProfileProvider: AcneProfileProviding

    init(
        skincareRepository: SkincareProductRepositoryProtocol,
        ingredientRepository: SkincareIngredientRepository,
        acneProfileProvider: AcneProfileProviding
    ) {
        self.skincareRepository = skincareRepository
        self.ingredientRepository = ingredientRepository
        self.acneProfileProvider = acneProfileProvider
        loadData()
    }

    func loadData() {
        self.products = skincareRepository.fetchProducts()
        self.activeAcneTypes = acneProfileProvider.getActiveAcneTypes()
        calculateAllMatches()
    }

    private func calculateAllMatches() {
        var matches: [UUID: [MatchedRecommendation]] = [:]
        for product in products {
            matches[product.id] = IngredientMatcher.match(
                product: product,
                activeAcneTypes: activeAcneTypes,
                repository: ingredientRepository
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
