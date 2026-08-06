import Foundation

struct FaceScanSession: Identifiable, Equatable, Codable {
    let id: UUID
    let capturedAt: Date
    let zoneResults: [FaceZoneScanResult]
    let totalAcneCount: Int
    let overallSeverity: AcneSeverity

    init(
        id: UUID = UUID(),
        capturedAt: Date = Date(),
        zoneResults: [FaceZoneScanResult],
        totalAcneCount: Int,
        overallSeverity: AcneSeverity
    ) {
        self.id = id
        self.capturedAt = capturedAt
        self.zoneResults = zoneResults
        self.totalAcneCount = totalAcneCount
        self.overallSeverity = overallSeverity
    }
}
