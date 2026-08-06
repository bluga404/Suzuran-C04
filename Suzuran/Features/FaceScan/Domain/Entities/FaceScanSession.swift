import Foundation

struct FaceScanSession: Identifiable, Equatable, Codable {
    let id: UUID
    let capturedAt: Date
    let overallImageData: Data
    let overallDetections: [AcneDetection]
    let zoneResults: [FaceZoneScanResult]
    let totalAcneCount: Int
    let overallSeverity: AcneSeverity

    init(
        id: UUID = UUID(),
        capturedAt: Date = Date(),
        overallImageData: Data,
        overallDetections: [AcneDetection],
        zoneResults: [FaceZoneScanResult],
        totalAcneCount: Int,
        overallSeverity: AcneSeverity
    ) {
        self.id = id
        self.capturedAt = capturedAt
        self.overallImageData = overallImageData
        self.overallDetections = overallDetections
        self.zoneResults = zoneResults
        self.totalAcneCount = totalAcneCount
        self.overallSeverity = overallSeverity
    }

    // Custom Codable: backwards-compatible with old saved sessions
    // that lack overallImageData and overallDetections.
    enum CodingKeys: String, CodingKey {
        case id, capturedAt, overallImageData, overallDetections
        case zoneResults, totalAcneCount, overallSeverity
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        capturedAt = try container.decode(Date.self, forKey: .capturedAt)
        overallImageData = try container.decodeIfPresent(Data.self, forKey: .overallImageData) ?? Data()
        overallDetections = try container.decodeIfPresent([AcneDetection].self, forKey: .overallDetections) ?? []
        zoneResults = try container.decode([FaceZoneScanResult].self, forKey: .zoneResults)
        totalAcneCount = try container.decode(Int.self, forKey: .totalAcneCount)
        overallSeverity = try container.decode(AcneSeverity.self, forKey: .overallSeverity)
    }
}

