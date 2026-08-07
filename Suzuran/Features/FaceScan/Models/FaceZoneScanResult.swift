import Foundation

struct FaceZoneScanResult: Identifiable, Equatable, Codable {
    let id: UUID
    let zone: FaceZone
    let detections: [AcneDetection]
    let capturedImageData: Data

    init(
        id: UUID = UUID(),
        zone: FaceZone,
        detections: [AcneDetection],
        capturedImageData: Data
    ) {
        self.id = id
        self.zone = zone
        self.detections = detections
        self.capturedImageData = capturedImageData
    }
}
