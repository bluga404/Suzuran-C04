import SwiftUI
import Combine

@MainActor
final class SkincareViewModel: ObservableObject {
    enum RecommendationStatus: Equatable {
        case notFound
        case found(productCategory: String)
    }

    struct RecommendedIngredientDisplay: Identifiable {
        let id = UUID()
        let recommendation: SkincareIngredientRecommendation
        let status: RecommendationStatus
    }

    @Published private(set) var products: [SkincareProduct] = []
    @Published private(set) var activeAcneTypes: [AcneType] = []
    @Published private(set) var hasScanned: Bool = false
    @Published private(set) var matchedRecommendations: [UUID: [MatchedRecommendation]] = [:]
    @Published private(set) var generalRecommendations: [RecommendedIngredientDisplay] = []
    @Published var pendingProducts: [SkincareProduct] = []

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
        for (productId, recommendations) in matchedRecommendations {
            let productName = products.first(where: { $0.id == productId })?.name ?? "Unknown Product"
            for rec in recommendations {
                if unique[rec.id] != nil {
                    if !unique[rec.id]!.foundInProducts.contains(productName) {
                        unique[rec.id]!.foundInProducts.append(productName)
                    }
                } else {
                    var newRec = rec
                    newRec.foundInProducts = [productName]
                    unique[rec.id] = newRec
                }
            }
        }
        return Array(unique.values).sorted { $0.recommendation.ingredientName < $1.recommendation.ingredientName }
    }

    func loadData() {
        self.products = skincareRepository.fetchProducts()
        self.hasScanned = acneProfileProvider.hasScanned()
        self.activeAcneTypes = acneProfileProvider.getActiveAcneTypes()
        calculateAllMatches()
        calculateGeneralRecommendations()
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

    private func calculateGeneralRecommendations() {
        guard !activeAcneTypes.isEmpty else {
            self.generalRecommendations = []
            return
        }

        let allRecs = acneRepository.getAllRecommendations()
        var displays: [RecommendedIngredientDisplay] = []

        for rec in allRecs {
            // Check if recommendation targets any active acne type
            let recAcneNames = rec.acneTypes.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            let matchesActive = activeAcneTypes.contains { activeType in
                recAcneNames.contains(activeType.displayName.lowercased())
            }

            if matchesActive {
                // Check if it's found in any of the user's ACTIVE products
                let activeProducts = products.filter { $0.isUsedCurrently }
                var foundCategory: String? = nil

                for product in activeProducts {
                    if product.ingredients.contains(where: { $0.normalizedName == rec.ingredientName.lowercased() || (rec.alternativesName?.lowercased().contains($0.normalizedName) ?? false) }) {
                        foundCategory = product.category.displayName
                        break
                    }
                }

                let status: RecommendationStatus = foundCategory != nil ? .found(productCategory: foundCategory!) : .notFound
                displays.append(RecommendedIngredientDisplay(recommendation: rec, status: status))
            }
        }

        // Sort: found first, then by name
        displays.sort { (a, b) -> Bool in
            if case .found = a.status, case .notFound = b.status { return true }
            if case .notFound = a.status, case .found = b.status { return false }
            return a.recommendation.ingredientName < b.recommendation.ingredientName
        }

        self.generalRecommendations = displays
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

    // MARK: - Pending Products

    func addPendingProduct(_ product: SkincareProduct) {
        pendingProducts.append(product)
    }

    func updatePendingProduct(_ product: SkincareProduct) {
        if let index = pendingProducts.firstIndex(where: { $0.id == product.id }) {
            pendingProducts[index] = product
        }
    }

    func deletePendingProduct(id: UUID) {
        pendingProducts.removeAll { $0.id == id }
    }

    func saveAllPending() {
        for product in pendingProducts {
            skincareRepository.addProduct(product)
        }
        pendingProducts.removeAll()
        loadData()
    }
}
