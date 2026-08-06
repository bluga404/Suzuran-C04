import Foundation

struct PerformFaceScanUseCase {
    private let repository: FaceScanRepository

    init(repository: FaceScanRepository) {
        self.repository = repository
    }

    func execute(fullFaceImageData: Data, zoneCaptures: [(zone: FaceZone, imageData: Data)]) async throws -> FaceScanSession {
        guard !zoneCaptures.isEmpty else {
            throw FaceScanDomainError.emptyScanData
        }
        
        // Detect acne on the overall face
        let overallDetections = try await repository.detectAcne(in: fullFaceImageData)
        let totalAcneCount = overallDetections.count

        // Process zones
        var zoneResults: [FaceZoneScanResult] = []

        for capture in zoneCaptures {
            let detections = try await repository.detectAcne(in: capture.imageData)

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
            overallImageData: fullFaceImageData,
            overallDetections: overallDetections,
            zoneResults: zoneResults,
            totalAcneCount: totalAcneCount,
            overallSeverity: overallSeverity
        )

        try await repository.saveScanSession(session)
        return session
    }
}
