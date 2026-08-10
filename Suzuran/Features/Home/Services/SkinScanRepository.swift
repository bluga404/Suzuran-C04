import Foundation

/// Repository protocol for accessing skin scan data in the Home feature.
/// Implementations may fetch from persistence, network, or fixture data.
protocol SkinScanRepository {
    /// Returns the most recent skin scan, or nil if no scans exist.
    func latestScan() async throws -> SkinScan?

    /// Returns the most recent scan created before the given date, or nil if none exists.
    /// - Parameter date: The reference date; only scans with `createdAt` before this date are considered.
    func previousScan(before date: Date) async throws -> SkinScan?

    /// Returns the scan matching the given ID, or nil if not found.
    /// - Parameter id: The UUID of the scan to retrieve.
    func scan(byID id: UUID) async throws -> SkinScan?
}
