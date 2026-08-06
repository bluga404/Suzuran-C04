import Foundation

struct PerformFaceScanUseCase {
    private let repository: FaceScanRepository

    init(repository: FaceScanRepository) {
        self.repository = repository
    }

    func execute(zoneCaptures: [(zone: FaceZone, imageData: Data)]) async throws -> FaceScanSession {
        guard !zoneCaptures.isEmpty else {
            throw FaceScanDomainError.emptyScanData
        }

        var zoneResults: [FaceZoneScanResult] = []
        var totalAcneCount = 0

        for capture in zoneCaptures {
            let detections = try await repository.detectAcne(in: capture.imageData)
            totalAcneCount += detections.count

            let zoneResult = FaceZoneScanResult(
                zone: capture.zone,
                detections: detections,
                capturedImageData: capture.imageData
            )
            zoneResults.append(zoneResult)
        }

        let overallSeverity: AcneSeverity
        switch totalAcneCount {
        case 0:
            overallSeverity = .clear
        case 1...5:
            overallSeverity = .mild
        case 6...15:
            overallSeverity = .moderate
        default:
            overallSeverity = .severe
        }

        let session = FaceScanSession(
            capturedAt: Date(),
            zoneResults: zoneResults,
            totalAcneCount: totalAcneCount,
            overallSeverity: overallSeverity
        )

        try await repository.saveScanSession(session)
        return session
    }
}
