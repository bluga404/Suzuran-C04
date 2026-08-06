import Foundation
import CoreGraphics

struct FaceScanResultModel: Identifiable, Equatable {
    let id: UUID
    let dateText: String
    let overallImageData: Data?
    let overallSeverityText: String
    let totalAcneCountText: String
    let zoneSummaries: [ZoneSummaryModel]
    let acneTypeSummaries: [AcneTypeSummaryModel]
    let faceMarkers: [FaceMaskMarkerModel]
}

struct ZoneSummaryModel: Identifiable, Equatable {
    let id: UUID
    let zoneName: String
    let acneCount: Int
    let detailText: String
    let imageData: Data?
    let markers: [FaceMaskMarkerModel]
}

struct AcneTypeSummaryModel: Identifiable, Equatable {
    let acneType: AcneType
    let count: Int

    var id: AcneType { acneType }
    var title: String { acneType.displayName }
}

struct FaceMaskMarkerModel: Identifiable, Equatable {
    let id: UUID
    let acneType: AcneType
    let confidence: Double
    /// Canonical point in the front-facing mask, normalized to 0...1.
    let normalizedPosition: CGPoint
}
