import Foundation

struct DefaultAcneAnalysisRepository: AcneAnalysisRepository {
    private let remoteDataSource: AcneDetectionRemoteDataSource
    private let localDataSource: AcneHistoryLocalDataSource

    init(
        remoteDataSource: AcneDetectionRemoteDataSource,
        localDataSource: AcneHistoryLocalDataSource
    ) {
        self.remoteDataSource = remoteDataSource
        self.localDataSource = localDataSource
    }

    func analyze(imageData: Data, capturedAt: Date) async throws -> AcneAnalysis {
        let response = try await remoteDataSource.analyze(imageData: imageData, capturedAt: capturedAt)
        await localDataSource.save(response)
        return try AcneAnalysisMapper.map(response)
    }

    func history() async throws -> [AcneAnalysis] {
        let records = await localDataSource.fetchAll()
        return try records.map(AcneAnalysisMapper.map)
    }
}
