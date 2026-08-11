import Foundation


/// Repository protocol for accessing skincare product data in the Home feature.
/// Implementations may fetch from persistence, network, or fixture data.
protocol SkincareRepository {
    /// Returns all skincare products tracked by the user.
    func products() async throws -> [SkincareProduct]
}
