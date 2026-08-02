import Foundation

struct GetAcneAnalysisHistoryUseCase {
    private let repository: AcneAnalysisRepository

    init(repository: AcneAnalysisRepository) {
        self.repository = repository
    }

    func execute() async throws -> [AcneAnalysis] {
        try await repository.history()
    }
}
