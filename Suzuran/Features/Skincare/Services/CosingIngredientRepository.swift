import Foundation

/// Abstraction over the cosing ingredient reference database.
///
/// Both concrete repositories read from the shared `IngredientDB`, which decodes
/// the underlying JSON exactly once per app session.
///
/// - SeeAlso: `AcneIngredientRepositoryProtocol`, `IngredientDB`
protocol IngredientRepositoryProtocol {

    /// `true` once `IngredientDB` has finished decoding `cosing.json`. Consumers that
    /// gate UI on load-completion (e.g., ingredient search) should observe the
    /// underlying `IngredientDB` directly for reactive updates.
    var isLoaded: Bool { get }

    /// Substring search across the cosing reference database.
    ///
    /// Matching is case- and punctuation-insensitive because both the query and each
    /// entry are compared via `IngredientReference.canonicalize(_:)` (Req 6.4, 7.1).
    /// Returns an empty array for empty or whitespace-only queries.
    func search(query: String) -> [IngredientReference]

    /// O(1) lookup by Canonical_ID.
    ///
    /// The `id` must already be canonical (i.e., produced by
    /// `IngredientReference.canonicalize(_:)`). Callers that hold a raw display
    /// string should use ``find(byRawName:)`` instead.
    func find(byCanonicalID id: String) -> IngredientReference?

    /// Convenience lookup that canonicalizes `name` before hitting the index.
    ///
    /// Two raw strings that canonicalize to the same ID resolve to the same
    /// reference (Req 3.4, 7.2).
    func find(byRawName name: String) -> IngredientReference?
}

/// Concrete cosing-ingredient repository backed by the shared `IngredientDB`.
///
/// The repository is a thin adapter over pre-built indices in `IngredientDB`; it
/// holds no state of its own and is safe to construct per-scope from the shared
/// singleton without duplicating decode work (Req 6.6).
///
/// - Note: Named `CosingIngredientRepository` to disambiguate from the pre-existing
///   `IngredientRepository` protocol in `Suzuran/Features/Home/Services/`, which
///   cannot be modified under this spec's path allowlist. The design-doc name
///   (`IngredientRepository`) is preserved conceptually via the protocol
///   ``IngredientRepositoryProtocol``.
final class CosingIngredientRepository: IngredientRepositoryProtocol {

    // MARK: - Constants

    /// Upper bound on the number of results returned by ``search(query:)``.
    /// Chosen to match the historical cap of `SkincareIngredientRepository` so UI
    private static let maxSearchResults = 40

    // MARK: - Dependencies

    private let db: IngredientDB

    // MARK: - Init

    init(db: IngredientDB) {
        self.db = db
    }

    // MARK: - IngredientRepositoryProtocol

    var isLoaded: Bool {
        db.isLoaded
    }

    func search(query: String) -> [IngredientReference] {
        let canonicalQuery = IngredientReference.canonicalize(query)
        guard !canonicalQuery.isEmpty else { return [] }

        var results: [IngredientReference] = []
        results.reserveCapacity(Self.maxSearchResults)

        for entry in db.cosingEntries {
            // `entry.normalizedName` equals `entry.id`, both derived via
            // `canonicalize(_:)`, so a substring compare on the canonical form is
            // stable regardless of casing/punctuation in the source display name.
            if entry.normalizedName.contains(canonicalQuery) {
                results.append(entry)
                if results.count >= Self.maxSearchResults { break }
            }
        }
        return results
    }

    func find(byCanonicalID id: String) -> IngredientReference? {
        db.cosingIndexByCanonicalID[id]
    }

    func find(byRawName name: String) -> IngredientReference? {
        let canonicalID = IngredientReference.canonicalize(name)
        guard !canonicalID.isEmpty else { return nil }
        return db.cosingIndexByCanonicalID[canonicalID]
    }
}
