import Foundation

/// In-memory implementation of SkinScanRepository that stores real scan results.
/// Used as a shared singleton so the FaceScan completion flow can persist scans
/// that the Home feature then reads.
final class InMemorySkinScanRepository: SkinScanRepository {

    /// Thread-safe storage for scans using an actor-isolated array.
    private var scans: [SkinScan] = []
    private let lock = NSLock()

    // MARK: - Write

    /// Saves a new scan to the in-memory store.
    /// - Parameter scan: The fully populated `SkinScan` to persist.
    func save(_ scan: SkinScan) {
        lock.withLock {
            scans.append(scan)
        }
    }

    // MARK: - SkinScanRepository

    func latestScan() async throws -> SkinScan? {
        lock.withLock {
            scans.max(by: { $0.createdAt < $1.createdAt })
        }
    }

    func previousScan(before date: Date) async throws -> SkinScan? {
        lock.withLock {
            scans
                .filter { $0.createdAt < date }
                .max(by: { $0.createdAt < $1.createdAt })
        }
    }

    func scan(byID id: UUID) async throws -> SkinScan? {
        lock.withLock {
            scans.first(where: { $0.id == id })
        }
    }
}
