import CoreGraphics
import Foundation

// MARK: - FaceScanResultModel

struct FaceScanResultModel: Identifiable, Equatable {
    let id: UUID
    let dateText: String
    let overallSeverityText: String
    let totalAcneCountText: String
    let zoneSummaries: [ZoneSummaryModel]
    let acneTypeSummaries: [AcneTypeSummaryModel] // Sorted descending by count
}

// MARK: - ZoneSummaryModel

struct ZoneSummaryModel: Identifiable, Equatable {
    let id: UUID
    let zoneName: String
    let acneCount: Int
    let detailText: String
    let imageData: Data?
    let markers: [MarkerModel]
}

// MARK: - MarkerModel

struct MarkerModel: Identifiable, Equatable {
    let id: UUID
    let acneType: AcneType
    let confidence: Double
    let normalizedPosition: CGPoint // 0–1, top-left origin
}

// MARK: - AcneTypeSummaryModel

struct AcneTypeSummaryModel: Identifiable, Equatable {
    let acneType: AcneType
    let count: Int

    var id: String { acneType.rawValue }
    var title: String { acneType.displayName }
}
