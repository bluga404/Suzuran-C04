import Foundation

/// Supplies the user's active ``AcneType`` list to the Skincare module.
protocol AcneProfileProviding {
    func getActiveAcneTypes() -> [AcneType]
}

/// Real implementation that derives the active acne profile from the latest
/// persisted scan (Req 8.1–8.6).
///
/// Reads the newest ``ScanRecord`` through an injected closure rather than
/// holding a strong reference to `ScanHistoryStore`, keeping the Skincare module
/// decoupled from app-level state (design.md Opsi A). The closure is supplied by
/// ``SkincareFactory/scanHistoryStoreProvider`` and wired once, additively, in
/// `AppContainer.live()`.
///
/// Behavior:
/// - No scan yet / provider not wired ⇒ returns `[]` (Req 8.2, 8.6).
/// - "Active" = every acne type with `count > 0` on the latest scan, excluding
///   `.unknown` (Req 8.3).
/// - Output sorted ascending by `rawValue` for deterministic ordering.
/// - No network, no ML inference — read-only (Req 8.4).
///
final class AcneProfileProvider: AcneProfileProviding {

    private let latestRecordProvider: () -> ScanRecord?
    private let logger: AppLogging

    init(latestRecordProvider: @escaping () -> ScanRecord?, logger: AppLogging = AppLogger()) {
        self.latestRecordProvider = latestRecordProvider
        self.logger = logger
    }

    func getActiveAcneTypes() -> [AcneType] {
        guard let latest = latestRecordProvider() else {
            // No scan stored, or provider not wired — fail soft (Req 8.2, 8.6).
            return []
        }
        return latest.acneTypeCounts
            .filter { $0.count > 0 && $0.acneType != .unknown }   // Req 8.3
            .map { $0.acneType }
            .sorted { $0.rawValue < $1.rawValue }                  // deterministic
    }
}
