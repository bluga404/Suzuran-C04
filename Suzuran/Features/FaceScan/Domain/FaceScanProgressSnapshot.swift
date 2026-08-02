import Foundation

enum FaceScanSessionStatus: Equatable {
    case idle
    case preparing
    case scanning
    case capturing(FaceScanArea)
    case completed
    case unavailable
    case permissionDenied
    case failed(String)
}

struct FaceScanProgressSnapshot {
    let status: FaceScanSessionStatus
    let currentTarget: FaceScanArea?
    let capturedAreas: [FaceScanArea]
    let isFaceDetected: Bool
    let stabilityProgress: Double
    let hint: String
}
