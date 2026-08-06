import Foundation
import CoreGraphics

struct FaceScanPresentationMapper {
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    func map(_ session: FaceScanSession) -> FaceScanResultModel {
        var acneTypeCounts: [AcneType: Int] = [:]
        var faceMarkers: [FaceMaskMarkerModel] = []

        let zoneSummaries = session.zoneResults.map { zoneResult in
            let count = zoneResult.detections.count

            // Group detections by type
            var typeCounts: [String: Int] = [:]
            for det in zoneResult.detections {
                typeCounts[det.acneType.displayName, default: 0] += 1
                acneTypeCounts[det.acneType, default: 0] += 1
                faceMarkers.append(
                    FaceMaskMarkerModel(
                        id: det.id,
                        acneType: det.acneType,
                        confidence: det.confidence,
                        normalizedPosition: mapToFaceMask(
                            zone: zoneResult.zone,
                            boundingBox: det.boundingBox
                        )
                    )
                )
            }

            let detailText: String
            if typeCounts.isEmpty {
                detailText = "Tidak ditemukan jerawat"
            } else {
                detailText = typeCounts
                    .sorted { $0.key < $1.key }
                    .map { "\($0.key): \($0.value)" }
                    .joined(separator: ", ")
            }

            return ZoneSummaryModel(
                id: zoneResult.id,
                zoneName: zoneResult.zone.displayName,
                acneCount: count,
                detailText: detailText
            )
        }

        let rawSummaries = acneTypeCounts.map { AcneTypeSummaryModel(acneType: $0.key, count: $0.value) }
        let acneTypeSummaries = rawSummaries.sorted { lhs, rhs in
            if lhs.count == rhs.count {
                return lhs.title < rhs.title
            }
            return lhs.count > rhs.count
        }

        return FaceScanResultModel(
            id: session.id,
            dateText: dateFormatter.string(from: session.capturedAt),
            overallSeverityText: session.overallSeverity.rawValue.capitalized,
            totalAcneCountText: "\(session.totalAcneCount) jerawat terdeteksi",
            zoneSummaries: zoneSummaries,
            acneTypeSummaries: acneTypeSummaries,
            faceMarkers: faceMarkers
        )
    }

    private func mapToFaceMask(zone: FaceZone, boundingBox: CGRect) -> CGPoint {
        let localX = min(max(boundingBox.midX, 0), 1)
        // Vision's normalized coordinate system starts at the lower-left;
        // SwiftUI's drawing space starts at the upper-left.
        let localY = min(max(1 - boundingBox.midY, 0), 1)

        let region: CGRect
        switch zone {
        case .forehead:
            region = CGRect(x: 0.28, y: 0.10, width: 0.44, height: 0.22)
        case .rightCheek:
            region = CGRect(x: 0.10, y: 0.34, width: 0.30, height: 0.34)
        case .leftCheek:
            region = CGRect(x: 0.60, y: 0.34, width: 0.30, height: 0.34)
        case .nose:
            region = CGRect(x: 0.42, y: 0.31, width: 0.16, height: 0.30)
        case .chin:
            region = CGRect(x: 0.32, y: 0.69, width: 0.36, height: 0.16)
        case .jawline:
            region = CGRect(x: 0.18, y: 0.68, width: 0.64, height: 0.18)
        }

        return CGPoint(
            x: region.minX + region.width * localX,
            y: region.minY + region.height * localY
        )
    }
}
