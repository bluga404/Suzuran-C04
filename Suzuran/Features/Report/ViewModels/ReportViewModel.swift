import Combine
import Foundation

@MainActor
final class ReportViewModel: ObservableObject {
    @Published private(set) var selectedMetric: ReportMetric = .skinScore
    @Published private(set) var selectedRange: ReportRange = .oneWeek
    @Published private(set) var selectedAcnePointDay: String?
    @Published private(set) var hiddenAcneTypeIDs: Set<String> = []
    @Published private(set) var isLoaded = false

    private let dataService: ReportDataService
    private var snapshot: ReportDataSnapshot?

    init(dataService: ReportDataService) {
        self.dataService = dataService
    }

    func loadIfNeeded() {
        guard !isLoaded else { return }
        snapshot = dataService.loadSnapshot()
        selectedAcnePointDay = acneDayLabels.last
        isLoaded = true
    }

    func setMetric(_ metric: ReportMetric) {
        selectedMetric = metric
    }

    func setRange(_ range: ReportRange) {
        selectedRange = range
        selectedAcnePointDay = acneDayLabels.last
        let activeIDs = Set(acneTypeSeriesData.map(\ .id))
        hiddenAcneTypeIDs = hiddenAcneTypeIDs.intersection(activeIDs)
    }

    func selectAcnePointDay(_ day: String) {
        guard acneDayLabels.contains(day) else { return }
        selectedAcnePointDay = day
    }

    func toggleAcneTypeVisibility(_ acneTypeID: String) {
        if hiddenAcneTypeIDs.contains(acneTypeID) {
            hiddenAcneTypeIDs.remove(acneTypeID)
        } else {
            hiddenAcneTypeIDs.insert(acneTypeID)
        }
    }

    func isAcneTypeActive(_ acneTypeID: String) -> Bool {
        !hiddenAcneTypeIDs.contains(acneTypeID)
    }

    var skinScoreData: [ReportPoint] {
        snapshot?.skinScoreSeriesByRange[selectedRange] ?? []
    }

    var acneTypeSeriesData: [AcneTypeSeries] {
        snapshot?.acneTypeSeriesByRange[selectedRange] ?? []
    }

    var acneDayLabels: [String] {
        guard let first = acneTypeSeriesData.first else { return [] }
        return first.points.map(\ .day)
    }

    var visibleAcneChartPoints: [AcneSeriesPoint] {
        acneTypeSeriesData
            .filter { !hiddenAcneTypeIDs.contains($0.id) }
            .flatMap { entry in
                entry.points.map { point in
                    AcneSeriesPoint(acneType: entry.acneType, day: point.day, score: point.score)
                }
            }
    }

    func acneTypeScore(for acneTypeID: String) -> Int {
        guard let series = acneTypeSeriesData.first(where: { $0.id == acneTypeID }) else {
            return 0
        }

        guard let selectedDay = selectedAcnePointDay else {
            return series.latestScore
        }

        return series.points.first(where: { $0.day == selectedDay })?.score ?? series.latestScore
    }

    var acneTypeScoresByID: [String: Int] {
        Dictionary(uniqueKeysWithValues: acneTypeSeriesData.map { series in
            (series.id, acneTypeScore(for: series.id))
        })
    }

    var comparisonSummary: ReportComparisonSummary {
        snapshot?.comparisonSummary ?? .init(
            baselineLabel: "Compared to -",
            headline: "-",
            scoreLabel: "Score",
            deltaText: "0"
        )
    }

    var insightSummary: ReportInsightSummary {
        snapshot?.insightSummary ?? .init(title: "Summary Insight", body: "-")
    }
}
