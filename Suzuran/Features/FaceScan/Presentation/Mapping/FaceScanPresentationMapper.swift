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

        // Map overall detections to markers and counts
        for det in session.overallDetections {
            acneTypeCounts[det.acneType, default: 0] += 1
            
            // Vision coordinates are bottom-left origin, UI is top-left
            let normalizedX = min(max(det.boundingBox.midX, 0), 1)
            let normalizedY = min(max(1 - det.boundingBox.midY, 0), 1)
            
            faceMarkers.append(
                FaceMaskMarkerModel(
                    id: det.id,
                    acneType: det.acneType,
                    confidence: det.confidence,
                    normalizedPosition: CGPoint(x: normalizedX, y: normalizedY)
                )
            )
        }

        let zoneSummaries = session.zoneResults.map { zoneResult in
            let count = zoneResult.detections.count

            var typeCounts: [String: Int] = [:]
            var zoneMarkers: [FaceMaskMarkerModel] = []
            
            for det in zoneResult.detections {
                typeCounts[det.acneType.displayName, default: 0] += 1
                
                let normalizedX = min(max(det.boundingBox.midX, 0), 1)
                let normalizedY = min(max(1 - det.boundingBox.midY, 0), 1)
                zoneMarkers.append(
                    FaceMaskMarkerModel(
                        id: det.id,
                        acneType: det.acneType,
                        confidence: det.confidence,
                        normalizedPosition: CGPoint(x: normalizedX, y: normalizedY)
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
                detailText: detailText,
                imageData: zoneResult.capturedImageData,
                markers: zoneMarkers
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
            overallImageData: session.overallImageData,
            overallSeverityText: session.overallSeverity.rawValue.capitalized,
            totalAcneCountText: "\(session.totalAcneCount) jerawat terdeteksi",
            zoneSummaries: zoneSummaries,
            acneTypeSummaries: acneTypeSummaries,
            faceMarkers: faceMarkers
        )
    }
}
