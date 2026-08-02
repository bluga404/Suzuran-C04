import Foundation

struct FaceScanCaptureArtifact: Identifiable {
    let id = UUID()
    let area: FaceScanArea
    let imageData: Data
    let capturedAt: Date
}