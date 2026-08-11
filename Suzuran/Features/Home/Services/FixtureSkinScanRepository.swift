import Foundation

/// Fixture implementation of SkinScanRepository for development and SwiftUI previews.
/// Returns nil by default so the app starts in the empty state.
final class FixtureSkinScanRepository: SkinScanRepository {
    func latestScan() async throws -> SkinScan? {
        nil
    }

    func previousScan(before date: Date) async throws -> SkinScan? {
        nil
    }

    func scan(byID id: UUID) async throws -> SkinScan? {
        nil
    }
}
