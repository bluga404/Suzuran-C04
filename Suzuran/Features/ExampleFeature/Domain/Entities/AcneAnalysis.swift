import Foundation

struct AcneAnalysis: Identifiable, Equatable {
    let id: UUID
    let capturedAt: Date
    let overallSeverity: AcneSeverity
    let confidence: Double
    let findings: [AcneFinding]
    let recommendation: String
}

enum AcneSeverity: String, Equatable {
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

enum FaceZone: String, Equatable {
    case forehead
    case leftCheek
    case rightCheek
    case nose
    case chin
    case jawline
}
