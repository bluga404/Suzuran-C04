import Foundation

struct AcneAnalysis: Identifiable, Equatable {
    let id: UUID
    let capturedAt: Date
    let overallSeverity: AcneSeverity
    let confidence: Double
    let findings: [AcneFinding]
    let recommendation: String
}

enum AcneSeverity: String, Equatable, Codable {
    case clear
    case mild
    case moderate
    case severe
}

struct AcneFinding: Identifiable, Equatable {
    let id: UUID
    let zone: FaceZone
    let lesionCount: Int
    let inflammationLevel: Double
}
