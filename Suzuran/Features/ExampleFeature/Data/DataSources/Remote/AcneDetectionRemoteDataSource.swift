import Foundation

protocol AcneDetectionRemoteDataSource {
    func analyze(imageData: Data, capturedAt: Date) async throws -> AcneAnalysisResponseDTO
}
