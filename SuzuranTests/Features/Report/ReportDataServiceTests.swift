import Testing
@testable import Suzuran

@Suite("ReportDataService")
struct ReportDataServiceTests {
    @Test("Report uses the real scan history as its data source")
    @MainActor
    func reportUsesRealScanHistory() async {
        let store = ScanHistoryStore()

        let now = Date()
        let earlier = Calendar.current.date(byAdding: .day, value: -3, to: now) ?? now

        let earlierResult = FaceScanResultModel(
            id: UUID(),
            dateText: "Earlier",
            overallSeverity: .moderate,
            totalAcneCount: 12,
            zoneSummaries: [],
            subZoneSummaries: [],
            acneTypeSummaries: [
                .init(acneType: .papule, count: 5),
                .init(acneType: .pustule, count: 4),
                .init(acneType: .blackhead, count: 3)
            ],
            skinHealthResult: nil
        )

        let latestResult = FaceScanResultModel(
            id: UUID(),
            dateText: "Latest",
            overallSeverity: .mild,
            totalAcneCount: 7,
            zoneSummaries: [],
            subZoneSummaries: [],
            acneTypeSummaries: [
                .init(acneType: .papule, count: 3),
                .init(acneType: .blackhead, count: 2),
                .init(acneType: .whitehead, count: 2)
            ],
            skinHealthResult: nil
        )

        store.save(earlierResult)
        store.save(latestResult)

        let service = ReportDataService(historyStore: store)
        let snapshot = await service.loadSnapshot()

        #expect(!snapshot.skinScoreSeriesByRange[.oneWeek, default: []].isEmpty)
        #expect(!snapshot.acneTypeSeriesByRange[.oneWeek, default: []].isEmpty)
        #expect(!snapshot.insightSummary.body.isEmpty)
        #expect(snapshot.insightSummary.body.localizedCaseInsensitiveContains("jerawat") || snapshot.insightSummary.body.localizedCaseInsensitiveContains("kulit"))
    }
}
