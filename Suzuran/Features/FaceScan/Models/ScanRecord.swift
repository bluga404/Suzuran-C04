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

    /// Codable wrapper for acne type + count pair.
    struct AcneTypeCount: Codable, Equatable {
        let acneType: AcneType
        let count: Int
    }
}
