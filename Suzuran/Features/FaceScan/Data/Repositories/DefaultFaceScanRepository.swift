import Foundation

struct DefaultFaceScanRepository: FaceScanRepository {
    private let mlDataSource: MLAcneDetectionDataSourceProtocol
    private let localDataSource: FaceScanLocalDataSourceProtocol

    init(
        mlDataSource: MLAcneDetectionDataSourceProtocol,
        localDataSource: FaceScanLocalDataSourceProtocol
    ) {
        self.mlDataSource = mlDataSource
        self.localDataSource = localDataSource
    }

    func detectAcne(in imageData: Data) async throws -> [AcneDetection] {
        let results = try await mlDataSource.detect(in: imageData)
        return results.map(FaceScanMapper.map)
    }

    func saveScanSession(_ session: FaceScanSession) async throws {
        try await localDataSource.saveSession(session)
    }

    func scanHistory() async throws -> [FaceScanSession] {
        try await localDataSource.fetchHistory()
    }
}
