import Foundation

protocol AcneHistoryLocalDataSource {
    func save(_ analysis: AcneAnalysisResponseDTO) async
    func fetchAll() async -> [AcneAnalysisResponseDTO]
}
