import SwiftUI
import Combine

/// Skincare Home ViewModel.
///
/// Owns the state rendered by `SkincareView` (Home) and the shared list of
/// products consumed by `SkincareDetailView` / `EditSkincareView`. All
/// dependencies are protocol-based so the ViewModel can be constructed with
/// in-memory fakes in tests and swapped independently by `SkincareFactory`
/// (Req 5.5, 22.2).
///
/// Behavioral contract:
/// - `matchedIngredients` is the deduplicated, stably-ordered output of
///   `IngredientMatchingServicing.match(products:profile:)` (Req 7.3–7.5,
///   13.2, 13.3). Uniqueness by Canonical_ID is enforced by the matcher.
/// - `loadData()` refetches products + acne profile, then runs
///   `recomputeMatches()`; every mutating flow ends by calling `loadData()`
///   so the published state is always consistent with the repository.
/// - Delete flow uses a two-step confirmation via `SkincareAlert`
///   (Req 17.1–17.5) — `requestDelete` chooses `.deleteProduct` vs
///   `.deleteLastProduct` based on the current product count, `confirmDelete`
///   performs the repo call and reloads.
///
@MainActor
final class SkincareViewModel: ObservableObject {

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
        products = productRepo.fetchProducts()
        activeAcneTypes = profile.getActiveAcneTypes()
        recomputeMatches()
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

    // MARK: - Mutations

    /// Persists a new product and reloads state.
    func addProduct(_ product: SkincareProduct) {
        productRepo.addProduct(product)
        loadData()
    }

    /// Updates an existing product and reloads state.
    func updateProduct(_ product: SkincareProduct) {
        productRepo.updateProduct(product)
        loadData()
    }

    // MARK: - Delete flow (Req 17.1–17.5)

    /// Chooses the correct confirmation alert based on the current product count.
    /// When deleting the last product, the Home returns to the empty state after
    /// confirmation (Req 17.4) — the alert message differs accordingly.
    func requestDelete(_ product: SkincareProduct) {
        if products.count <= 1 {
            alert = .deleteLastProduct(product)
        } else {
            alert = .deleteProduct(product)
        }
    }

    /// Executes the actual delete against the repository, then reloads.
    ///
    /// The current `SkincareProductRepositoryProtocol.deleteProduct(id:)` is
    /// non-throwing (errors are logged internally by the concrete repository).
    /// To still surface an I/O failure to the user (Req 17.5, 19.5) we treat
    /// "product still present after delete + reload" as a failed deletion and
    /// set `errorMessage` from the localized ``SkincareError/deleteFailed`` copy.
    func confirmDelete(_ product: SkincareProduct) {
        productRepo.deleteProduct(id: product.id)
        loadData()
        if products.contains(where: { $0.id == product.id }) {
            errorMessage = SkincareError.deleteFailed.errorDescription
        }
    }

    // MARK: - Per-product match helpers

    /// Returns the subset of `matchedIngredients` whose canonical ingredient
    /// appears in `product`. Used by ``SkincareDetailView`` and ``SkincareCard``
    /// to show per-product matches (Req 12.4, 14.3).
    func matchedIngredients(in product: SkincareProduct) -> [MatchedIngredient] {
        let productIngredientIDs = Set(product.ingredients.map { $0.id })
        return matchedIngredients.filter { productIngredientIDs.contains($0.reference.id) }
    }

    /// Returns the ``MatchedIngredient`` for a specific ingredient of a product,
    /// or `nil` when that ingredient does not match the active acne profile.
    func matched(for reference: IngredientReference) -> MatchedIngredient? {
        matchedIngredients.first { $0.reference.id == reference.id }
    }
}
