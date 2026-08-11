import Foundation

protocol AcneProfileProviding {
    func getActiveAcneTypes() -> [AcneType]
}

final class AcneProfileProvider: AcneProfileProviding {
    private let historyStore: ScanHistoryStore

    init(historyStore: ScanHistoryStore) {
        self.historyStore = historyStore
    }

    func getActiveAcneTypes() -> [AcneType] {
        guard let latestScan = historyStore.records.first else {
            return []
        }
        return latestScan.acneTypeCounts.map { $0.acneType }
    }
}
