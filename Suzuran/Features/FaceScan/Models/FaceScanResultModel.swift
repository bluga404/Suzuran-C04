import CoreGraphics
import Foundation

// MARK: - FaceScanResultModel

struct FaceScanResultModel: Identifiable, Equatable {
    let id: UUID
    let dateText: String
    /// Typed severity enum — used for hearts display and badge.
    let overallSeverity: AcneSeverity
    /// Raw acne count — used for skin-score calculation.
    let totalAcneCount: Int
    /// Convenience text for backwards-compatible display.
    var overallSeverityText: String { overallSeverity.rawValue.capitalized }
    var totalAcneCountText: String { "\(totalAcneCount) jerawat" }
    /// Skin score 0–100. Formula: max(0, 100 - totalAcneCount * 3)
    var skinScore: Int { max(0, 100 - totalAcneCount * 3) }
    /// Full-face zone summaries (front / leftAngle / rightAngle) — kept for marker overlay.
    let zoneSummaries: [ZoneSummaryModel]
    /// Sub-zone summaries — the 5 cropped thumbnails shown in the result grid.
    let subZoneSummaries: [SubZoneSummaryModel]
    /// Acne type breakdown sorted descending by count.
    let acneTypeSummaries: [AcneTypeSummaryModel]
    /// Optional skin health result score.
    let skinHealthResult: SkinHealthResult?

    init(
        id: UUID,
        dateText: String,
        overallSeverity: AcneSeverity,
        totalAcneCount: Int,
        zoneSummaries: [ZoneSummaryModel],
        subZoneSummaries: [SubZoneSummaryModel],
        acneTypeSummaries: [AcneTypeSummaryModel],
        skinHealthResult: SkinHealthResult? = nil
    ) {
        self.id = id
        self.dateText = dateText
        self.overallSeverity = overallSeverity
        self.totalAcneCount = totalAcneCount
        self.zoneSummaries = zoneSummaries
        self.subZoneSummaries = subZoneSummaries
        self.acneTypeSummaries = acneTypeSummaries
        self.skinHealthResult = skinHealthResult
    }
}

// MARK: - ZoneSummaryModel

struct ZoneSummaryModel: Identifiable, Equatable {
    let id: UUID
    let zone: FaceZone
    let zoneName: String
    let acneCount: Int
    let detailText: String
    let imageData: Data?
    let markers: [MarkerModel]

    init(
        id: UUID = UUID(),
        zone: FaceZone = .front,
        zoneName: String,
        acneCount: Int,
        detailText: String,
        imageData: Data?,
        markers: [MarkerModel]
    ) {
        self.id = id
        self.zone = zone
        self.zoneName = zoneName
        self.acneCount = acneCount
        self.detailText = detailText
        self.imageData = imageData
        self.markers = markers
    }
}

// MARK: - SubZoneSummaryModel

/// Represents one of the 5 cropped face sub-zones shown in the result grid:
/// Forehead, Nose, Chin (cropped from front scan) and Left/Right Cheek (from side scans).
struct SubZoneSummaryModel: Identifiable, Equatable {
    let id: UUID
    let label: String          // Display name shown above the thumbnail
    let imageData: Data?       // Cropped JPEG for thumbnail
    let acneCount: Int         // Attributed acne count for this sub-zone
    let markers: [MarkerModel] // Attributed markers (for potential overlay)
}

// MARK: - MarkerModel

struct MarkerModel: Identifiable, Equatable {
    let id: UUID
    let acneType: AcneType
    let confidence: Double
    /// Full YOLO bounding box in 0–1 space (top-left origin, width, height).
    let normalizedBoundingBox: CGRect

    /// Centre of the bounding box — convenience accessor.
    var normalizedPosition: CGPoint {
        CGPoint(x: normalizedBoundingBox.midX, y: normalizedBoundingBox.midY)
    }

    init(
        id: UUID = UUID(),
        acneType: AcneType,
        confidence: Double,
        normalizedBoundingBox: CGRect
    ) {
        self.id = id
        self.acneType = acneType
        self.confidence = confidence
        self.normalizedBoundingBox = normalizedBoundingBox
    }

    init(
        id: UUID = UUID(),
        acneType: AcneType,
        confidence: Double,
        normalizedPosition: CGPoint
    ) {
        self.id = id
        self.acneType = acneType
        self.confidence = confidence
        self.normalizedBoundingBox = CGRect(
            x: max(0, normalizedPosition.x - 0.05),
            y: max(0, normalizedPosition.y - 0.05),
            width: 0.1,
            height: 0.1
        )
    }
}

// MARK: - AcneTypeSummaryModel

struct AcneTypeSummaryModel: Identifiable, Equatable {
    let acneType: AcneType
    let count: Int

    var id: String { acneType.rawValue }
    var title: String { acneType.displayName }
}
