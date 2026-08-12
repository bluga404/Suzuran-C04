import Foundation

protocol AcneProfileProviding {
    func getActiveAcneTypes() -> [AcneType]
    func hasScanned() -> Bool
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

    func hasScanned() -> Bool {
        return !historyStore.records.isEmpty
    }
}
