import Foundation
import CoreGraphics
struct PerformFaceScanUseCase {
    private let repository: FaceScanRepository

    init(repository: FaceScanRepository) {
        self.repository = repository
    }

    func execute(
        frontFullImageData: Data,
        frontTZoneImageData: Data,
        frontTZoneRect: CGRect,
        leftImageData: Data,
        rightImageData: Data
    ) async throws -> FaceScanSession {
        // Process Front T-Zone
        let tZoneDetections = try await repository.detectAcne(in: frontTZoneImageData)
        
        // Map T-Zone detections back to the full front image
        let mappedFrontDetections = tZoneDetections.map { detection -> AcneDetection in
            let mappedX = frontTZoneRect.minX + (detection.boundingBox.minX * frontTZoneRect.width)
            let mappedY = frontTZoneRect.minY + (detection.boundingBox.minY * frontTZoneRect.height)
            let mappedWidth = detection.boundingBox.width * frontTZoneRect.width
            let mappedHeight = detection.boundingBox.height * frontTZoneRect.height
            
            let mappedBoundingBox = CGRect(x: mappedX, y: mappedY, width: mappedWidth, height: mappedHeight)
            return AcneDetection(
                id: detection.id,
                acneType: detection.acneType,
                confidence: detection.confidence,
                boundingBox: mappedBoundingBox
            )
        }
        
        let frontResult = FaceZoneScanResult(
            zone: .front,
            detections: mappedFrontDetections,
            capturedImageData: frontFullImageData
        )
        
        // Process Left
        let leftDetections = try await repository.detectAcne(in: leftImageData)
        let leftResult = FaceZoneScanResult(
            zone: .leftAngle,
            detections: leftDetections,
            capturedImageData: leftImageData
        )
        
        // Process Right
        let rightDetections = try await repository.detectAcne(in: rightImageData)
        let rightResult = FaceZoneScanResult(
            zone: .rightAngle,
            detections: rightDetections,
            capturedImageData: rightImageData
        )
        
        let zoneResults = [frontResult, leftResult, rightResult]
        let totalAcneCount = mappedFrontDetections.count + leftDetections.count + rightDetections.count
        
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
            overallImageData: frontFullImageData,
            overallDetections: mappedFrontDetections,
            zoneResults: zoneResults,
            totalAcneCount: totalAcneCount,
            overallSeverity: overallSeverity
        )
        
        try await repository.saveScanSession(session)
        return session
    }
}
