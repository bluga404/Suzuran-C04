import Foundation

/// Fixture implementation of SkincareRepository for development and SwiftUI previews.
/// Returns an empty array by default so the app starts in the empty state.
final class FixtureSkincareRepository: SkincareRepository {
    func products() async throws -> [SkincareProduct] {
        []
    }
}
