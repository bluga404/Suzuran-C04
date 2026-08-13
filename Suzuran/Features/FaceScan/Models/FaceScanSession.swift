import Foundation

struct FaceScanSession: Identifiable, Equatable, Codable {
    let id: UUID
    let capturedAt: Date
    let overallImageData: Data
    let zoneResults: [FaceZoneScanResult]
    let totalAcneCount: Int
    let overallSeverity: AcneSeverity

    init(
        id: UUID = UUID(),
        capturedAt: Date = Date(),
        overallImageData: Data,
        zoneResults: [FaceZoneScanResult],
        totalAcneCount: Int,
        overallSeverity: AcneSeverity
    ) {
        self.id = id
        self.capturedAt = capturedAt
        self.overallImageData = overallImageData
        self.zoneResults = zoneResults
        self.totalAcneCount = totalAcneCount
        self.overallSeverity = overallSeverity
    }
}
