import Foundation

/// Fixture implementation of IngredientRepository for development and SwiftUI previews.
/// Returns nil by default so the app starts in the empty state.
final class FixtureIngredientRepository: IngredientRepository {
    func latestIngredientScan() async throws -> IngredientScanData? {
        nil
    }
}
