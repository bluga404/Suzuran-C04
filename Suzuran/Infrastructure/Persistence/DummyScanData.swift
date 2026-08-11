import Foundation

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
            ]
        )
    }
}
