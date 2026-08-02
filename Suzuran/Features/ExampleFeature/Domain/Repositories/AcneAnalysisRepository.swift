import Foundation

protocol AcneAnalysisRepository {
    func analyze(imageData: Data, capturedAt: Date) async throws -> AcneAnalysis
    func history() async throws -> [AcneAnalysis]
}
