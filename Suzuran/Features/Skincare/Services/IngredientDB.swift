import Foundation
import Combine

/// Shared in-memory database of skincare ingredient references and acne recommendations.
///
/// Responsible for decoding the bundled JSON files (`cosing.json` and
/// `AcneIngredients.json`) **exactly once** per app session and exposing them to
/// downstream repositories. Both `CosingIngredientRepository` (cosing lookup) and
/// `AcneIngredientRepository` (acne mapping) read from the same shared instance,
/// which prevents the double-parse that currently occurs when
/// `SkincareFactory.makeView()` is invoked multiple times (Req 6.6).
///
/// The decode runs on a background queue; `isLoaded` transitions to `true` on the
/// main thread once both files finish loading. Consumers that need to wait for
/// search-capable state (e.g., ingredient search UI) should observe `isLoaded`.
///
/// Lookups are exposed as pre-built canonical-ID indices for O(1) access, keyed by
/// the same `IngredientReference.canonicalize(_:)` function used everywhere else
/// in the Skincare module (Req 7.1, 7.2).
///
/// - SeeAlso: `IngredientReference`, `SkincareIngredientRecommendation`
final class IngredientDB: ObservableObject {

    // MARK: - Shared instance

    /// Process-wide shared instance. Initialization begins on first access;
    /// the JSON decode runs on a background queue.
    static let shared = IngredientDB()

    // MARK: - Exposed state

    /// All ingredient references decoded from `cosing.json`.
    ///
    /// Populated on the main thread once loading completes. Empty until `isLoaded`
    /// emits `true`.
    private(set) var cosingEntries: [IngredientReference] = []

    /// O(1) lookup from Canonical_ID → `IngredientReference` (cosing).
    private(set) var cosingIndexByCanonicalID: [String: IngredientReference] = [:]

    /// All acne-related ingredient recommendations decoded from `AcneIngredients.json`.
    private(set) var acneRecommendations: [SkincareIngredientRecommendation] = []

    /// O(1) lookup from Canonical_ID → recommendation.
    private(set) var acneRecommendationIndexByCanonicalID: [String: SkincareIngredientRecommendation] = [:]

    /// Emits `true` on the main thread when both JSON files have finished loading.
    /// Consumers that gate UI on load-completion should observe this via Combine or
    /// SwiftUI (`@ObservedObject` / `@StateObject`).
    @Published private(set) var isLoaded: Bool = false

    // MARK: - Init

    private let logger: AppLogging

    private init() {
        self.logger = AppLogger()
        load()
    }

    // MARK: - Loading

    private func load() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }

            let acne = Self.decodeAcneRecommendations(logger: self.logger)
            let acneIndex = Self.indexAcneRecommendations(acne)
            let (cosingEntries, cosingIndex) = Self.decodeCosingEntries(logger: self.logger)

            DispatchQueue.main.async {
                self.cosingEntries = cosingEntries
                self.cosingIndexByCanonicalID = cosingIndex
                self.acneRecommendations = acne
                self.acneRecommendationIndexByCanonicalID = acneIndex
                self.isLoaded = true
                self.logger.info(
                    "[Skincare] IngredientDB loaded: cosing=\(cosingEntries.count), acne=\(acne.count)"
                )
            }
        }
    }

    // MARK: - Decoders

    private static func decodeAcneRecommendations(
        logger: AppLogging
    ) -> [SkincareIngredientRecommendation] {
        guard let url = Bundle.main.url(forResource: "AcneIngredients", withExtension: "json") else {
            logger.error("[Skincare] IngredientDB: AcneIngredients.json not found in bundle")
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([SkincareIngredientRecommendation].self, from: data)
        } catch {
            logger.error(
                "[Skincare] IngredientDB: failed to decode AcneIngredients.json: \(error)"
            )
            return []
        }
    }

    private static func indexAcneRecommendations(
        _ recommendations: [SkincareIngredientRecommendation]
    ) -> [String: SkincareIngredientRecommendation] {
        var index: [String: SkincareIngredientRecommendation] = [:]
        index.reserveCapacity(recommendations.count)
        for rec in recommendations {
            let canonicalID = IngredientReference.canonicalize(rec.ingredientName)
            // First occurrence wins so the mapping is deterministic if the JSON ever
            // contains duplicate ingredient names.
            if index[canonicalID] == nil {
                index[canonicalID] = rec
            }
        }
        return index
    }

    private static func decodeCosingEntries(
        logger: AppLogging
    ) -> ([IngredientReference], [String: IngredientReference]) {
        guard let url = Bundle.main.url(forResource: "cosing", withExtension: "json") else {
            logger.error("[Skincare] IngredientDB: cosing.json not found in bundle")
            return ([], [:])
        }
        do {
            let data = try Data(contentsOf: url)
            let wrapper = try JSONDecoder().decode(CosingIndexWrapper.self, from: data)

            var entries: [IngredientReference] = []
            var index: [String: IngredientReference] = [:]
            entries.reserveCapacity(wrapper.ingredientIndex.count)
            index.reserveCapacity(wrapper.ingredientIndex.count)

            for rawName in wrapper.ingredientIndex.keys {
                // cosing.json keys are stored lowercased; capitalize for display,
                // while `canonicalize(_:)` re-lowers for the ID (idempotent).
                let displayName = rawName.capitalized
                let ref = IngredientReference(fromRawName: displayName)
                if index[ref.id] == nil {
                    index[ref.id] = ref
                    entries.append(ref)
                }
            }
            return (entries, index)
        } catch {
            logger.error(
                "[Skincare] IngredientDB: failed to decode cosing.json: \(error)"
            )
            return ([], [:])
        }
    }

    // MARK: - Nested types

    /// Minimal wrapper matching the top-level shape of `cosing.json`.
    /// Only the `ingredientIndex` map is required by this module.
    private struct CosingIndexWrapper: Decodable {
        let ingredientIndex: [String: Int]
    }
}
