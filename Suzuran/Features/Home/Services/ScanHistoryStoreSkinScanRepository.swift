import Foundation

/// Adapts `ScanHistoryStore` (disk-persisted JSON) to the `SkinScanRepository` protocol
/// so that `HomeSummaryViewModel` reads real, persisted scan data instead of the
/// in-memory-only `InMemorySkinScanRepository` which is wiped on every app restart.
///
/// This is the real source of truth for the Home/Summary screen after app restarts.
/// `ScanHistoryStore` writes scan records to `Documents/scan_history.json`, so data
/// survives process termination.
final class ScanHistoryStoreSkinScanRepository: SkinScanRepository {

    private let store: ScanHistoryStore

    init(store: ScanHistoryStore) {
        self.store = store
    }

    // MARK: - SkinScanRepository

    func latestScan() async throws -> SkinScan? {
        // ScanHistoryStore.records is already sorted newest-first
        guard let record = store.records.first else { return nil }
        return skinScan(from: record)
    }

    func previousScan(before date: Date) async throws -> SkinScan? {
        let previous = store.records.first { $0.date < date }
        return previous.map { skinScan(from: $0) }
    }

    func scan(byID id: UUID) async throws -> SkinScan? {
        store.records.first { $0.id == id }.map { skinScan(from: $0) }
    }

    // MARK: - Mapping

    /// Maps a disk-persisted `ScanRecord` into the Home feature's `SkinScan` domain model.
    private func skinScan(from record: ScanRecord) -> SkinScan {
        // Build [AcneType: Int] from the record's flat type-count list
        let acneCounts: [AcneType: Int] = record.acneTypeCounts.reduce(into: [:]) { dict, entry in
            dict[entry.acneType] = entry.count
        }

        // Build [FaceRegion: [AcneType: Int]] from per-area type counts if available
        let regionCounts: [FaceRegion: [AcneType: Int]]
        if let areaTypeCounts = record.areaTypeCounts, !areaTypeCounts.isEmpty {
            regionCounts = areaTypeCounts.reduce(into: [:]) { dict, entry in
                if let region = faceRegion(from: entry.key) {
                    dict[region] = entry.value.reduce(into: [:]) { typeDict, typeCount in
                        typeDict[typeCount.acneType] = typeCount.count
                    }
                }
            }
        } else {
            // Fallback: distribute total acneCounts equally across all regions
            regionCounts = FaceRegion.allCases.reduce(into: [:]) { dict, region in
                dict[region] = acneCounts
            }
        }

        // Recompute weighted count and GAGS from stored data for consistency
        let calculator = HomeScoreCalculator()
        let weighted = calculator.calculateWeightedAcneCount(counts: acneCounts)
        let gags = calculator.calculateGAGS(regionCounts: regionCounts)

        return SkinScan(
            id: record.id,
            userID: UUID(), // anonymous — not tracked in ScanRecord
            createdAt: record.date,
            overallScore: record.skinScore,
            weightedAcneCount: weighted,
            gagsScore: gags.total,
            acneCounts: acneCounts,
            regionCounts: regionCounts,
            regionGagsScores: gags.zoneScores,
            imageReference: nil,
            modelVersion: nil,
            scanProtocolVersion: nil
        )
    }

    /// Maps `ScanRecord.FaceArea` → `FaceRegion` by matching raw string values.
    private func faceRegion(from area: ScanRecord.FaceArea) -> FaceRegion? {
        switch area {
        case .forehead:   return .forehead
        case .rightCheek: return .rightCheek
        case .leftCheek:  return .leftCheek
        case .nose:       return .nose
        case .chin:       return .chin
        }
    }
}
