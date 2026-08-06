import Foundation

enum FaceScanDomainError: Error, Equatable {
    case cameraPermissionDenied
    case noFaceDetected
    case modelLoadingFailed
    case scanIncomplete(missingZones: [FaceZone])
    case insufficientLighting
    case emptyScanData
}
