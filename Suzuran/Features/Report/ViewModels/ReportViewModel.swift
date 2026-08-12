import Combine
import Foundation

@MainActor
final class ReportViewModel: ObservableObject {
    @Published private(set) var selectedMetric: ReportMetric = .skinScore
    @Published private(set) var selectedRange: ReportRange = .oneWeek
    @Published private(set) var selectedAcnePointDay: String?
    @Published private(set) var hiddenAcneTypeIDs: Set<String> = []
    @Published private(set) var state: LoadableState<ReportDataSnapshot> = .idle

    private let logger: AppLogging
    private let dataService: ReportDataService
    private var snapshot: ReportDataSnapshot?
    private var isRefreshingSummary = false

    init(dataService: ReportDataService, logger: AppLogging = AppLogger()) {
        self.dataService = dataService
        self.logger = logger
    }

    func loadIfNeeded(forceRefresh: Bool = false) async {
        if case .loading = state {
            return
        }

        if !forceRefresh, case .loaded = state {
            return
        }

        isRefreshingSummary = true
        state = .loading

        logger.info("Loading report snapshot", file: #fileID, line: #line)
        let loadedSnapshot = await dataService.loadSnapshot()
        snapshot = loadedSnapshot

        if loadedSnapshot.records.isEmpty {
            state = .empty(
                title: "No scan history yet",
                message: "Complete your first skin scan to see your progress here."
            )
        } else {
            selectedAcnePointDay = acneDayLabels(for: loadedSnapshot).last
            state = .loaded(loadedSnapshot)
            logger.info("Report snapshot loaded; records=\(loadedSnapshot.records.count)", file: #fileID, line: #line)
        }

        isRefreshingSummary = false
    }

    func refreshSummary() async {
        guard !isRefreshingSummary else { return }
        logger.info("Refreshing report summary", file: #fileID, line: #line)
        await loadIfNeeded(forceRefresh: true)
    }

    func setMetric(_ metric: ReportMetric) {
        selectedMetric = metric
    }

    func setRange(_ range: ReportRange) {
        selectedRange = range
        selectedAcnePointDay = acneDayLabels.last

        if let snapshot {
            let activeIDs = Set(snapshot.acneTypeSeriesByRange[range, default: []].map(\.id))
            hiddenAcneTypeIDs = hiddenAcneTypeIDs.intersection(activeIDs)
        }
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

    var hasAnyData: Bool {
        guard let snapshot else { return false }
        return ReportRange.allCases.contains { range in
            !snapshot.skinScoreSeriesByRange[range, default: []].isEmpty
        }
    }

    var skinScoreData: [ReportPoint] {
        snapshot?.skinScoreSeriesByRange[selectedRange] ?? []
    }

    var acneTypeSeriesData: [AcneTypeSeries] {
        snapshot?.acneTypeSeriesByRange[selectedRange] ?? []
    }

    var acneDayLabels: [String] {
        acneDayLabels(for: snapshot)
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

    var skinScoreSummary: ReportComparisonSummary {
        let records = skinScoreData
        if records.isEmpty {
            return .init(
                baselineLabel: "Your result in the last \(selectedRangeLabel)",
                headline: "No data yet",
                scoreLabel: "Total",
                deltaText: "--"
            )
        }

        let firstScore = records.first?.score ?? 0
        let latestScore = records.last?.score ?? 0
        let delta = latestScore - firstScore

        let headline: String
        switch delta {
        case let value where value > 0:
            headline = "Your skin is improving"
        case let value where value < 0:
            headline = "Your skin is declining"
        default:
            headline = "Your skin is stable"
        }

        return .init(
            baselineLabel: "Your result in the last \(selectedRangeLabel)",
            headline: headline,
            scoreLabel: "Total",
            deltaText: "\(latestScore)"
        )
    }

    var mostDetectedAcneSummary: ReportComparisonSummary {
        let series = acneTypeSeriesData
        if series.isEmpty {
            return .init(
                baselineLabel: "Most detected acne",
                headline: "No data yet",
                scoreLabel: "Total",
                deltaText: "--"
            )
        }

        guard let topSeries = series.max(by: { lhs, rhs in
            (lhs.points.max(by: { $0.score < $1.score })?.score ?? lhs.latestScore) <
            (rhs.points.max(by: { $0.score < $1.score })?.score ?? rhs.latestScore)
        }) else {
            return .init(
                baselineLabel: "Most detected acne",
                headline: "No data yet",
                scoreLabel: "Total",
                deltaText: "--"
            )
        }

        let value = topSeries.points.max(by: { $0.score < $1.score })?.score ?? topSeries.latestScore

        return .init(
            baselineLabel: "Most detected acne",
            headline: topSeries.acneType.displayName,
            scoreLabel: "Total",
            deltaText: "\(value)"
        )
    }

    var insightSummary: ReportInsightSummary {
        snapshot?.insightSummary ?? .init(
            title: "Summary Insight",
            body: "Complete your first skin scan to see your progress here.",
            source: .empty,
            timestamp: nil
        )
    }

    private func acneDayLabels(for snapshot: ReportDataSnapshot?) -> [String] {
        guard let series = snapshot?.acneTypeSeriesByRange[selectedRange]?.first else { return [] }
        return series.points.map(\.day)
    }

    private var selectedRangeLabel: String {
        switch selectedRange {
        case .oneWeek:
            return "week"
        case .oneMonth:
            return "month"
        case .oneYear:
            return "year"
        }
    }
}
