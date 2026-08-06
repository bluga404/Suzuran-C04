import Foundation

enum FaceScanMapper {
    static func map(_ result: AcneDetectionResult) -> AcneDetection {
        let type = AcneType(rawLabel: result.label)
        return AcneDetection(
            acneType: type,
            confidence: Double(result.confidence),
            boundingBox: result.boundingBox
        )
    }
}
