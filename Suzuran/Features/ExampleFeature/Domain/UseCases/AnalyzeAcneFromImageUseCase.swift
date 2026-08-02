import Foundation

struct AnalyzeAcneFromImageUseCase {
    struct Input: Equatable {
        let imageData: Data
        let capturedAt: Date
    }

    private let repository: AcneAnalysisRepository

    init(repository: AcneAnalysisRepository) {
        self.repository = repository
    }

    func execute(_ input: Input) async throws -> AcneAnalysis {
        guard !input.imageData.isEmpty else {
            throw AcneAnalysisDomainError.emptyImageData
        }

        let analysis = try await repository.analyze(imageData: input.imageData, capturedAt: input.capturedAt)

        guard analysis.confidence >= 0.2 else {
            throw AcneAnalysisDomainError.lowConfidence
        }

        return analysis
    }
}
