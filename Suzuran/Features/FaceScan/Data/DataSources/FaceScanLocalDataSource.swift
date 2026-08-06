import Foundation

protocol FaceScanLocalDataSourceProtocol {
    func saveSession(_ session: FaceScanSession) async throws
    func fetchHistory() async throws -> [FaceScanSession]
}

final class FaceScanLocalDataSource: FaceScanLocalDataSourceProtocol {
    private let keyValueStore: KeyValueStore
    private let storageKey = "suzuran.faceScan.history"

    init(keyValueStore: KeyValueStore) {
        self.keyValueStore = keyValueStore
    }

    func saveSession(_ session: FaceScanSession) async throws {
        var currentHistory = try await fetchHistory()
        currentHistory.insert(session, at: 0)

        let encoder = JSONEncoder()
        let data = try encoder.encode(currentHistory)
        keyValueStore.set(data, forKey: storageKey)
    }

    func fetchHistory() async throws -> [FaceScanSession] {
        guard let data = keyValueStore.data(forKey: storageKey) else {
            return []
        }

        let decoder = JSONDecoder()
        return try decoder.decode([FaceScanSession].self, from: data)
    }
}
