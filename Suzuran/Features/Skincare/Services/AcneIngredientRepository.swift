import Foundation

/// Abstraction over the acne-ingredient recommendation database (`AcneIngredients.json`).
///
/// Split from the legacy `SkincareIngredientRepository` so cosing lookup and acne
/// recommendation lookup have single responsibilities (Req 6.1, 6.2, 6.3). Both
/// concrete repositories read from the shared `IngredientDB`, which decodes the
/// underlying JSON exactly once per app session (Req 6.6).
///
/// This repository is intentionally decoupled from `IngredientRepositoryProtocol`;
/// composition of the two happens at the matching layer
/// (`IngredientMatchingServicing`) or ViewModel (Req 6.3).
///
/// - SeeAlso: `IngredientRepositoryProtocol`, `IngredientDB`,
///   `IngredientMatchingServicing`
protocol AcneIngredientRepositoryProtocol {

    /// Returns every `SkincareIngredientRecommendation` that targets at least one of
    /// the supplied `acneTypes` (Req 5.3, 6.5).
    ///
    /// Matching semantics are the same as ``matchedAcneTypes(for:activeTypes:)``:
    /// direct substring match on the recommendation's comma-separated `acneTypes`
    /// field plus a small set of semantic aliases (e.g., "comedonal" ⇢ blackhead /
    /// whitehead). Ordering follows the order of `db.acneRecommendations` (i.e.,
    /// source-file order) so results are deterministic across calls.
    ///
    /// Passing an empty `acneTypes` returns an empty array.
    func recommendations(for acneTypes: [AcneType]) -> [SkincareIngredientRecommendation]

    /// O(1) lookup by Canonical_ID (Req 6.5, 7.1).
    ///
    /// The `id` must already be canonical (i.e., produced by
    /// `IngredientReference.canonicalize(_:)`). Two raw ingredient strings that
    /// canonicalize to the same ID resolve to the same recommendation.
    func recommendation(byCanonicalID id: String) -> SkincareIngredientRecommendation?

    /// Returns the subset of `activeTypes` that the recommendation identified by
    /// `id` targets (Req 5.3, 7.3).
    ///
    /// If no recommendation exists for `id`, the result is an empty array. The
    /// output preserves the order of `activeTypes` so callers that want a stable
    /// display order can pass a pre-sorted list (`IngredientMatchingService`
    /// re-sorts by `AcneType.rawValue` before wrapping in `MatchedIngredient`).
    func matchedAcneTypes(for id: String, activeTypes: [AcneType]) -> [AcneType]
}

/// Concrete acne-ingredient repository backed by the shared `IngredientDB`.
///
/// The repository is a thin adapter over pre-built indices in `IngredientDB`; it
/// holds no state of its own and is safe to construct per-scope from the shared
/// singleton without duplicating decode work (Req 6.6).
final class AcneIngredientRepository: AcneIngredientRepositoryProtocol {

    // MARK: - Dependencies

    private let db: IngredientDB

    // MARK: - Init

    init(db: IngredientDB) {
        self.db = db
    }

    // MARK: - AcneIngredientRepositoryProtocol

    func recommendations(for acneTypes: [AcneType]) -> [SkincareIngredientRecommendation] {
        guard !acneTypes.isEmpty else { return [] }
        return db.acneRecommendations.filter { recommendation in
            acneTypes.contains { acneType in
                Self.matchesAcneType(acneType, recommendation: recommendation)
            }
        }
    }

    func recommendation(byCanonicalID id: String) -> SkincareIngredientRecommendation? {
        db.acneRecommendationIndexByCanonicalID[id]
    }

    func matchedAcneTypes(for id: String, activeTypes: [AcneType]) -> [AcneType] {
        guard let recommendation = db.acneRecommendationIndexByCanonicalID[id] else {
            return []
        }
        return activeTypes.filter { acneType in
            Self.matchesAcneType(acneType, recommendation: recommendation)
        }
    }

    // MARK: - Matching

    /// Determines whether `recommendation.acneTypes` (a comma-separated string in
    /// `AcneIngredients.json`) targets the given `acneType`.
    ///
    /// The logic here mirrors the legacy `IngredientMatcher.matchesAcneType(_:recommendation:)`
    /// so behavior stays consistent as callers migrate from
    /// `SkincareIngredientRepository` + `IngredientMatcher` to the split
    /// repositories + `IngredientMatchingService` (Req 6.2, 6.3).
    ///
    /// Matching rules:
    /// 1. Direct case-insensitive substring match on the recommendation's
    ///    `acneTypes` field (e.g., `"Pustule"` matches
    ///    `"Whitehead, Blackhead, Papule, Pustule"`).
    /// 2. Semantic aliases for related terms in the reference data:
    ///    - `.blackhead`, `.whitehead` ⇢ `"comedonal"` / `"mild acne"`
    ///    - `.papule`, `.pustule`       ⇢ `"inflammatory"` / `"mild acne"`
    ///    - `.nodule`, `.cyst`          ⇢ `"severe acne"` / `"inflammatory"`
    private static func matchesAcneType(
        _ acneType: AcneType,
        recommendation: SkincareIngredientRecommendation
    ) -> Bool {
        let targets = recommendation.acneTypes.lowercased()
        let query = acneType.displayName.lowercased()

        // 1. Direct match (e.g. "pustule" in "Whitehead, Blackhead, Papule, Pustule")
        if targets.contains(query) {
            return true
        }

        // 2. Semantic matching for related terms
        switch acneType {
        case .blackhead, .whitehead:
            if targets.contains("comedonal") || targets.contains("mild acne") {
                return true
            }
        case .papule, .pustule:
            if targets.contains("inflammatory") || targets.contains("mild acne") {
                return true
            }
        case .nodule, .cyst:
            if targets.contains("severe acne") || targets.contains("inflammatory") {
                return true
            }
        case .unknown:
            break
        }

        return false
    }
}
