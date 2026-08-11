import Foundation

/// Lightweight, Codable representation of a completed face scan for storage in history.
/// Stores only the data needed for the history grid and compare view — not the full
/// detection/marker details (those are transient and only live in FaceScanResultModel).
struct ScanRecord: Identifiable, Codable, Equatable {
    let id: UUID
    /// Date of the scan — only one record per calendar day.
    let date: Date
    /// JPEG data of the front-facing capture — used for thumbnail in history grid.
    let frontImageData: Data?
    /// Skin score 0–100
    let skinScore: Int
    /// Total acne count across all zones
    let totalAcneCount: Int
    /// Severity classification
    let severity: AcneSeverity
    /// Per-type acne counts (Codable-friendly version of AcneTypeSummaryModel)
    let acneTypeCounts: [AcneTypeCount]
    /// Per-area acne counts. Stored alongside type counts for Compare view.
    let acneAreaCounts: [AcneAreaCount]
    /// Cropped thumbnails for each specific facial sub-zone (Forehead, Nose, Chin, Left Cheek, Right Cheek)
    let subZoneThumbnails: [FaceArea: Data]?

    /// Codable wrapper for acne type + count pair.
    struct AcneTypeCount: Codable, Equatable {
        let acneType: AcneType
        let count: Int
    }

    /// Codable wrapper for facial area + count pair.
    struct AcneAreaCount: Codable, Equatable {
        let area: FaceArea
        let count: Int
    }

    /// Facial areas tracked per scan.
    enum FaceArea: String, Codable, CaseIterable, Identifiable {
        case forehead   = "Forehead"
        case rightCheek = "Right Cheek"
        case leftCheek  = "Left Cheek"
        case nose       = "Nose"
        case chin       = "Chin"

        var id: String { rawValue }
    }

    // MARK: - Convenience

    /// Returns the count for a given facial area (0 if not recorded).
    func acneCount(for area: FaceArea) -> Int {
        acneAreaCounts.first { $0.area == area }?.count ?? 0
    }

    /// Returns the count for a given acne type (0 if not recorded).
    func acneCount(for type: AcneType) -> Int {
        acneTypeCounts.first { $0.acneType == type }?.count ?? 0
    }

    // MARK: - Initializer (backward-compatible with existing callers)

    init(
        id: UUID = UUID(),
        date: Date,
        frontImageData: Data?,
        skinScore: Int,
        totalAcneCount: Int,
        severity: AcneSeverity,
        acneTypeCounts: [AcneTypeCount],
        acneAreaCounts: [AcneAreaCount] = [],
        subZoneThumbnails: [FaceArea: Data]? = nil
    ) {
        self.id = id
        self.date = date
        self.frontImageData = frontImageData
        self.skinScore = skinScore
        self.totalAcneCount = totalAcneCount
        self.severity = severity
        self.acneTypeCounts = acneTypeCounts
        self.acneAreaCounts = acneAreaCounts
        self.subZoneThumbnails = subZoneThumbnails
    }
}
