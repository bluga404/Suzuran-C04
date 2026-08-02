import Foundation

final class InMemoryAcneHistoryLocalDataSource: AcneHistoryLocalDataSource {
    private var storage: [AcneAnalysisResponseDTO] = []

    func save(_ analysis: AcneAnalysisResponseDTO) async {
        storage.insert(analysis, at: 0)
    }

    func fetchAll() async -> [AcneAnalysisResponseDTO] {
        storage
    }
}
