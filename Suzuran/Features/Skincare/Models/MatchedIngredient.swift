import Foundation

/// A user product ingredient that matched at least one of the user's active acne types.
///
/// `MatchedIngredient` is the output shape of ``IngredientMatchingServicing`` and is what
/// the Skincare Home renders in the "Matched Ingredient" section (Req 13). Uniqueness and
/// stable ordering across products are guaranteed by matching on ``IngredientReference/id``
/// (Canonical_ID), not on display name (Req 7.1, 7.2, 7.3, 13.2, 13.3).
///
/// - `reference`: The canonical ingredient identity from the user's product list.
/// - `recommendation`: The reference recommendation entry sourced from `AcneIngredients.json`.
/// - `matchedAcneTypes`: The subset of the user's active ``AcneType``s that this ingredient targets.
///
/// - Note: Replaces the earlier `MatchedRecommendation` type. Existing view/caller sites
///
struct MatchedIngredient: Identifiable, Equatable {

    /// The canonical ingredient identity (source of truth for matching).
    let reference: IngredientReference

    /// The reference recommendation from `AcneIngredients.json` for this ingredient.
    let recommendation: SkincareIngredientRecommendation

    /// The subset of the user's active acne types that this ingredient targets.
    let matchedAcneTypes: [AcneType]

    /// Identity is derived from the Canonical_ID so deduplication across products is
    /// deterministic and matches the semantics used by ``IngredientMatchingServicing`` (Req 13.2).
    var id: String { reference.id }
}
