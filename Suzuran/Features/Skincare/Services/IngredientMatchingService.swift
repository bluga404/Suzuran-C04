import Foundation

/// Pure matching service that resolves the user's product ingredients against
/// their active acne profile and produces the deduplicated, stably-ordered list
/// of ``MatchedIngredient`` values consumed by the Skincare Home "Matched
/// Ingredient" section.
///
/// Behavioral contract (Req 5.4, 5.6, 7.1–7.5):
/// - Matching is performed on Canonical_ID (``IngredientReference/id``), not on
///   display name. Two raw ingredient strings that canonicalize to the same ID
///   are treated as the same ingredient (Req 7.1, 7.2).
/// - The function is **pure**: no internal state is retained between calls; the
///   result depends only on the supplied `products` and `profile` (Req 5.6, 7.4).
/// - Output is **deterministic and stable**: results are unique by Canonical_ID
///   and sorted ascending by `reference.id`; each ``MatchedIngredient/matchedAcneTypes``
///   is sorted ascending by ``AcneType/rawValue`` (Req 7.3, 7.4, 7.5).
///
/// - SeeAlso: ``AcneIngredientRepositoryProtocol``, ``MatchedIngredient``.
protocol IngredientMatchingServicing {

    /// Returns the deduplicated, stably-ordered set of ``MatchedIngredient``
    /// values produced by matching every ingredient in `products` against the
    /// user's active acne `profile`.
    ///
    /// - Parameters:
    ///   - products: The user's saved skincare products. Order does not affect
    ///     the output ordering.
    ///   - profile: The user's active ``AcneType``s (typically produced by
    ///     ``AcneProfileProviding``). An empty profile yields an empty result.
    /// - Returns: A list of ``MatchedIngredient`` values, unique by
    ///   ``IngredientReference/id`` and sorted ascending by that id.
    ///
    /// The function is pure — same input always yields the same output.
    func match(products: [SkincareProduct], profile: [AcneType]) -> [MatchedIngredient]
}

/// Concrete, stateless implementation of ``IngredientMatchingServicing``.
///
/// Composes ``AcneIngredientRepositoryProtocol`` for O(1) Canonical_ID lookups
/// and per-ingredient acne-type resolution. Because the repository is itself a
/// thin adapter over the shared, pre-decoded `IngredientDB`, `match` is cheap
/// enough to run synchronously on every profile/product change (Req 7.4).
///
struct IngredientMatchingService: IngredientMatchingServicing {

    // MARK: - Dependencies

    /// Repository responsible for Canonical_ID → recommendation lookup and
    /// per-ingredient acne-type resolution. Injected via protocol so the
    /// service is trivially testable with an in-memory fake.
    let acneRepo: AcneIngredientRepositoryProtocol

    // MARK: - Init

    init(acneRepo: AcneIngredientRepositoryProtocol) {
        self.acneRepo = acneRepo
    }

    // MARK: - IngredientMatchingServicing

    func match(products: [SkincareProduct], profile: [AcneType]) -> [MatchedIngredient] {
        // Empty profile → no active acne types → nothing can match (Req 8.2 propagation).
        guard !profile.isEmpty else { return [] }

        // Track products containing each canonical ID (Req 7.2, 13.2).
        var productNamesForID: [String: Set<String>] = [:]
        var referenceForID: [String: IngredientReference] = [:]

        for product in products {
            for ingredient in product.ingredients {
                referenceForID[ingredient.id] = ingredient
                if productNamesForID[ingredient.id] == nil {
                    productNamesForID[ingredient.id] = [product.name]
                } else {
                    productNamesForID[ingredient.id]?.insert(product.name)
                }
            }
        }

        var results: [MatchedIngredient] = []

        for (id, reference) in referenceForID {
            // 2. Must have a reference recommendation in AcneIngredients.json.
            guard let recommendation = acneRepo.recommendation(byCanonicalID: id) else {
                continue
            }

            // 3. Must target at least one of the user's active acne types.
            let matchedTypes = acneRepo.matchedAcneTypes(
                for: id,
                activeTypes: profile
            )
            guard !matchedTypes.isEmpty else { continue }

            // 4. Emit — sort matched acne types by rawValue for deterministic
            //    per-ingredient ordering (Req 7.4, 7.5).
            let productNames = Array(productNamesForID[id] ?? []).sorted()
            
            results.append(
                MatchedIngredient(
                    reference: reference,
                    recommendation: recommendation,
                    matchedAcneTypes: matchedTypes.sorted { $0.rawValue < $1.rawValue },
                    foundInProducts: productNames
                )
            )
        }

        // 5. Stable, deterministic output ordering by Canonical_ID ascending (Req 7.5).
        return results.sorted { $0.reference.id < $1.reference.id }
    }
}
