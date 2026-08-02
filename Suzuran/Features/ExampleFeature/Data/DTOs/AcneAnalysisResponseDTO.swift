import Foundation

struct AcneAnalysisResponseDTO: Equatable {
    let id: UUID
    let capturedAt: Date
    let confidence: Double
    let severity: String
    let findings: [AcneFindingDTO]
    let recommendation: String
}

struct AcneFindingDTO: Equatable {
    let id: UUID
    let zone: String
    let lesionCount: Int
    let inflammationLevel: Double
}
