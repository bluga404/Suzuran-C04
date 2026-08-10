import Foundation
import CoreGraphics

/// Maps FaceScan domain objects (produced by the FaceScan feature) into the Home feature's
/// `SkinScan` model, bridging the gap between `FaceZone` capture angles and `FaceRegion` facial zones.
struct FaceScanToSkinScanMapper {

    private let scoreCalculator = HomeScoreCalculator()

    // MARK: - Public API

    /// Converts a `FaceScanSession` (and optional `FaceScanResultModel`) into a `SkinScan`.
    /// - Parameters:
    ///   - session: The captured face scan session with zone results and detections.
    ///   - resultModel: Optional result model containing sub-zone summaries (unused for scoring but available for future use).
    ///   - userID: The user identifier to associate with the scan.
    /// - Returns: A fully populated `SkinScan` ready to be persisted.
    func map(session: FaceScanSession, resultModel: FaceScanResultModel? = nil, userID: UUID = UUID()) -> SkinScan {
        // 1. Collect all detections across zones
        let allDetections = session.zoneResults.flatMap { $0.detections }

        // 2. Build acneCounts: [AcneType: Int]
        let acneCounts = buildAcneCounts(from: allDetections)

        // 3. Build regionCounts: [FaceRegion: [AcneType: Int]]
        let regionCounts = buildRegionCounts(from: session.zoneResults)

        // 4. Compute overall score
        let weightedCount = scoreCalculator.calculateWeightedAcneCount(counts: acneCounts)
        let overallScore = scoreCalculator.calculateSkinHealthScore(weightedCount: weightedCount)

        // 5. Compute GAGS
        let gagsResult = scoreCalculator.calculateGAGS(regionCounts: regionCounts)

        return SkinScan(
            id: session.id,
            userID: userID,
            createdAt: session.capturedAt,
            overallScore: overallScore,
            weightedAcneCount: weightedCount,
            gagsScore: gagsResult.total,
            acneCounts: acneCounts,
            regionCounts: regionCounts,
            regionGagsScores: gagsResult.zoneScores,
            imageReference: nil,
            modelVersion: nil,
            scanProtocolVersion: nil
        )
    }

    // MARK: - Private Helpers

    /// Aggregates detection counts by acne type across all detections.
    private func buildAcneCounts(from detections: [AcneDetection]) -> [AcneType: Int] {
        var counts: [AcneType: Int] = [:]
        for type in AcneType.allCases {
            counts[type] = 0
        }
        for detection in detections {
            counts[detection.acneType, default: 0] += 1
        }
        return counts
    }

    /// Maps zone-level detections to face regions based on the zone-to-region mapping:
    /// - Front zone: split into forehead/nose/chin based on bounding box Y position
    ///   (top 1/3 = forehead, middle 1/3 = nose, bottom 1/3 = chin)
    /// - Left angle zone → leftCheek
    /// - Right angle zone → rightCheek
    private func buildRegionCounts(from zoneResults: [FaceZoneScanResult]) -> [FaceRegion: [AcneType: Int]] {
        var regionCounts: [FaceRegion: [AcneType: Int]] = [:]
        for region in FaceRegion.allCases {
            regionCounts[region] = [:]
            for type in AcneType.allCases {
                regionCounts[region]?[type] = 0
            }
        }

        for zoneResult in zoneResults {
            switch zoneResult.zone {
            case .front:
                for detection in zoneResult.detections {
                    let region = frontRegion(for: detection.normalizedBoundingBox)
                    regionCounts[region]?[detection.acneType, default: 0] += 1
                }
            case .leftAngle:
                for detection in zoneResult.detections {
                    regionCounts[.leftCheek]?[detection.acneType, default: 0] += 1
                }
            case .rightAngle:
                for detection in zoneResult.detections {
                    regionCounts[.rightCheek]?[detection.acneType, default: 0] += 1
                }
            }
        }

        return regionCounts
    }

    /// Determines which front-face region a detection belongs to based on its
    /// normalized bounding box Y center position (top-left origin, 0–1 space):
    /// - Top 1/3 (Y center < 0.333): forehead
    /// - Middle 1/3 (0.333 ≤ Y center < 0.667): nose
    /// - Bottom 1/3 (Y center ≥ 0.667): chin
    private func frontRegion(for boundingBox: CGRect) -> FaceRegion {
        let yCenter = boundingBox.midY
        if yCenter < 1.0 / 3.0 {
            return .forehead
        } else if yCenter < 2.0 / 3.0 {
            return .nose
        } else {
            return .chin
        }
    }
}
