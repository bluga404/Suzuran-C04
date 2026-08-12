import Foundation
import Testing
@testable import Suzuran

@Suite("LocalSummaryService")
struct GeminiSummaryServiceTests {
    @Test("builds a summary for a single scan record")
    func singleRecordSummary() async throws {
        let service = LocalSummaryService()
        let record = ScanRecord(
            date: Date(),
            frontImageData: nil,
            skinScore: 78,
            totalAcneCount: 5,
            severity: .moderate,
            acneTypeCounts: [
                .init(acneType: .papule, count: 2),
                .init(acneType: .blackhead, count: 3)
            ],
            acneAreaCounts: []
        )

        let result = try await service.generateSummary(for: [record])

        #expect(!result.isEmpty)
        #expect(result.localizedCaseInsensitiveContains("jerawat") || result.localizedCaseInsensitiveContains("kulit"))
        #expect(result.localizedCaseInsensitiveContains("skor kulit"))
    }

    @Test("builds a trend summary from first and latest scans")
    func trendSummary() async throws {
        let first = ScanRecord(
            date: Date().addingTimeInterval(-86400 * 7),
            frontImageData: nil,
            skinScore: 60,
            totalAcneCount: 12,
            severity: .moderate,
            acneTypeCounts: [
                .init(acneType: .pustule, count: 4),
                .init(acneType: .whitehead, count: 8)
            ],
            acneAreaCounts: []
        )

        let latest = ScanRecord(
            date: Date(),
            frontImageData: nil,
            skinScore: 68,
            totalAcneCount: 9,
            severity: .mild,
            acneTypeCounts: [
                .init(acneType: .pustule, count: 3),
                .init(acneType: .whitehead, count: 6)
            ],
            acneAreaCounts: []
        )

        let service = LocalSummaryService()
        let result = try await service.generateSummary(for: [first, latest])

        #expect(!result.isEmpty)
        #expect(result.localizedCaseInsensitiveContains("jumlah jerawat") || result.localizedCaseInsensitiveContains("Tipe jerawat"))
        #expect(result.localizedCaseInsensitiveContains("membaik") || result.localizedCaseInsensitiveContains("turun") || result.localizedCaseInsensitiveContains("stabil"))
    }
}
