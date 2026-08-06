import Foundation

struct GetFaceScanHistoryUseCase {
    private let repository: FaceScanRepository

    init(repository: FaceScanRepository) {
        self.repository = repository
    }

    func execute() async throws -> [FaceScanSession] {
        try await repository.scanHistory()
    }
}
