import Foundation

struct MockAcneDetectionRemoteDataSource: AcneDetectionRemoteDataSource {
    func analyze(imageData: Data, capturedAt: Date) async throws -> AcneAnalysisResponseDTO {
        let hash = imageData.reduce(0) { partialResult, byte in
            (partialResult + Int(byte)) % 10_000
        }

        let severity: String
        switch hash % 4 {
        case 0:
            severity = "clear"
        case 1:
            severity = "mild"
        case 2:
            severity = "moderate"
        default:
            severity = "severe"
        }

        let confidence = Double((hash % 35) + 60) / 100
        let inflammationBase = Double((hash % 40) + 35) / 100

        return AcneAnalysisResponseDTO(
            id: UUID(),
            capturedAt: capturedAt,
            confidence: confidence,
            severity: severity,
            findings: [
                AcneFindingDTO(
                    id: UUID(),
                    zone: "forehead",
                    lesionCount: (hash % 7) + 1,
                    inflammationLevel: min(0.95, inflammationBase)
                ),
                AcneFindingDTO(
                    id: UUID(),
                    zone: "leftCheek",
                    lesionCount: (hash % 5) + 1,
                    inflammationLevel: min(0.95, inflammationBase - 0.05)
                ),
                AcneFindingDTO(
                    id: UUID(),
                    zone: "rightCheek",
                    lesionCount: (hash % 6) + 1,
                    inflammationLevel: min(0.95, inflammationBase - 0.03)
                )
            ],
            recommendation: "Keep cleansing twice daily, avoid pore-clogging cosmetics, and monitor progress for 2 weeks."
        )
    }
}
