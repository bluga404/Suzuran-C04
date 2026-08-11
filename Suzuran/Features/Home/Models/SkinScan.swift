import Foundation

/// Domain model representing a single skin scan session with all acne detection data,
/// computed scores, and metadata.
struct SkinScan: Identifiable, Equatable {
    /// Unique identifier for this scan.
    let id: UUID

    /// The user who performed the scan.
    let userID: UUID

    /// Timestamp when the scan was created.
    let createdAt: Date

    /// Overall skin health score (0-100, higher is better).
    let overallScore: Int

    /// Sum of (count × severityWeight) for all detected acne types (≥ 0).
    let weightedAcneCount: Double

    /// Global Acne Grading System score (≥ 0).
    let gagsScore: Int

    /// Count of each acne type detected across all regions.
    let acneCounts: [AcneType: Int]

    /// Per-region breakdown of acne type counts.
    let regionCounts: [FaceRegion: [AcneType: Int]]

    /// Per-region GAGS scores.
    let regionGagsScores: [FaceRegion: Int]

    /// Optional reference to the scan image (e.g., file path or asset identifier).
    let imageReference: String?

    /// Optional ML model version used for detection.
    let modelVersion: String?

    /// Optional protocol version describing the scan workflow.
    let scanProtocolVersion: String?
}
