import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Helper providing dummy scan data for testing purposes (e.g. 9 August 2026 record).
enum DummyScanData {

    /// Generates a test record for 9 August 2026 to enable testing the Compare feature immediately.
    static func createAugust9Record() -> ScanRecord {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2026
        components.month = 8
        components.day = 9
        components.hour = 10
        let date = calendar.date(from: components) ?? Date()

        return ScanRecord(
            id: UUID(uuidString: "99999999-9999-9999-9999-999999999999")!,
            date: date,
            frontImageData: nil,
            skinScore: 62,
            totalAcneCount: 15,
            severity: .moderate,
            acneTypeCounts: [
                ScanRecord.AcneTypeCount(acneType: .papule, count: 6),
                ScanRecord.AcneTypeCount(acneType: .pustule, count: 4),
                ScanRecord.AcneTypeCount(acneType: .blackhead, count: 3),
                ScanRecord.AcneTypeCount(acneType: .whitehead, count: 2)
            ],
            acneAreaCounts: [
                ScanRecord.AcneAreaCount(area: .forehead, count: 7),
                ScanRecord.AcneAreaCount(area: .rightCheek, count: 3),
                ScanRecord.AcneAreaCount(area: .leftCheek, count: 2),
                ScanRecord.AcneAreaCount(area: .nose, count: 2),
                ScanRecord.AcneAreaCount(area: .chin, count: 1)
            ],
            subZoneThumbnails: createDummyThumbnails(),
            areaTypeCounts: [
                .forehead: [
                    ScanRecord.AcneTypeCount(acneType: .whitehead, count: 0),
                    ScanRecord.AcneTypeCount(acneType: .blackhead, count: 1),
                    ScanRecord.AcneTypeCount(acneType: .papule, count: 4),
                    ScanRecord.AcneTypeCount(acneType: .pustule, count: 2),
                    ScanRecord.AcneTypeCount(acneType: .nodule, count: 0),
                    ScanRecord.AcneTypeCount(acneType: .cyst, count: 0)
                ],
                .rightCheek: [
                    ScanRecord.AcneTypeCount(acneType: .whitehead, count: 1),
                    ScanRecord.AcneTypeCount(acneType: .blackhead, count: 0),
                    ScanRecord.AcneTypeCount(acneType: .papule, count: 1),
                    ScanRecord.AcneTypeCount(acneType: .pustule, count: 1),
                    ScanRecord.AcneTypeCount(acneType: .nodule, count: 0),
                    ScanRecord.AcneTypeCount(acneType: .cyst, count: 0)
                ],
                .leftCheek: [
                    ScanRecord.AcneTypeCount(acneType: .whitehead, count: 1),
                    ScanRecord.AcneTypeCount(acneType: .blackhead, count: 1),
                    ScanRecord.AcneTypeCount(acneType: .papule, count: 0),
                    ScanRecord.AcneTypeCount(acneType: .pustule, count: 0),
                    ScanRecord.AcneTypeCount(acneType: .nodule, count: 0),
                    ScanRecord.AcneTypeCount(acneType: .cyst, count: 0)
                ],
                .nose: [
                    ScanRecord.AcneTypeCount(acneType: .whitehead, count: 0),
                    ScanRecord.AcneTypeCount(acneType: .blackhead, count: 1),
                    ScanRecord.AcneTypeCount(acneType: .papule, count: 1),
                    ScanRecord.AcneTypeCount(acneType: .pustule, count: 0),
                    ScanRecord.AcneTypeCount(acneType: .nodule, count: 0),
                    ScanRecord.AcneTypeCount(acneType: .cyst, count: 0)
                ],
                .chin: [
                    ScanRecord.AcneTypeCount(acneType: .whitehead, count: 0),
                    ScanRecord.AcneTypeCount(acneType: .blackhead, count: 0),
                    ScanRecord.AcneTypeCount(acneType: .papule, count: 0),
                    ScanRecord.AcneTypeCount(acneType: .pustule, count: 1),
                    ScanRecord.AcneTypeCount(acneType: .nodule, count: 0),
                    ScanRecord.AcneTypeCount(acneType: .cyst, count: 0)
                ]
            ]
        )
    }

    private static func createDummyThumbnails() -> [ScanRecord.FaceArea: Data]? {
        #if canImport(UIKit)
        var result: [ScanRecord.FaceArea: Data] = [:]
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100))

        let colors: [ScanRecord.FaceArea: UIColor] = [
            .forehead: UIColor(red: 0.95, green: 0.82, blue: 0.75, alpha: 1.0),
            .leftCheek: UIColor(red: 0.92, green: 0.78, blue: 0.72, alpha: 1.0),
            .rightCheek: UIColor(red: 0.92, green: 0.78, blue: 0.72, alpha: 1.0),
            .nose: UIColor(red: 0.90, green: 0.75, blue: 0.70, alpha: 1.0),
            .chin: UIColor(red: 0.93, green: 0.80, blue: 0.74, alpha: 1.0)
        ]

        for area in ScanRecord.FaceArea.allCases {
            let color = colors[area] ?? .systemGray5
            let image = renderer.image { ctx in
                color.setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: 100, height: 100))

                let text = String(area.rawValue.prefix(1)) as NSString
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 32, weight: .bold),
                    .foregroundColor: UIColor.white.withAlphaComponent(0.85)
                ]
                let textSize = text.size(withAttributes: attrs)
                let textRect = CGRect(
                    x: (100 - textSize.width) / 2,
                    y: (100 - textSize.height) / 2,
                    width: textSize.width,
                    height: textSize.height
                )
                text.draw(in: textRect, withAttributes: attrs)
            }
            if let data = image.jpegData(compressionQuality: 0.8) {
                result[area] = data
            }
        }
        return result.isEmpty ? nil : result
        #else
        return nil
        #endif
    }
}
