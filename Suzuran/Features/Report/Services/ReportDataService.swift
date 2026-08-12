import Foundation

struct ReportDataSnapshot: Equatable {
    let records: [ScanRecord]
    let skinScoreSeriesByRange: [ReportRange: [ReportPoint]]
    let acneTypeSeriesByRange: [ReportRange: [AcneTypeSeries]]
    let insightSummary: ReportInsightSummary
}

final class ReportDataService {
    private let historyStore: ScanHistoryStore?
    private let summaryService: SummaryServiceProtocol
    private let keyValueStore: KeyValueStore

    private enum CacheKeys {
        static let summary = "suzuran.report.summary.v1"
    }

    private let logger: AppLogging

    init(
        historyStore: ScanHistoryStore? = nil,
        summaryService: SummaryServiceProtocol = LocalSummaryService(),
        keyValueStore: KeyValueStore = UserDefaultsKeyValueStore(userDefaults: .standard),
        logger: AppLogging = AppLogger()
    ) {
        self.historyStore = historyStore
        self.summaryService = summaryService
        self.keyValueStore = keyValueStore
        self.logger = logger
    }

    func loadSnapshot() async -> ReportDataSnapshot {
        let records = (historyStore?.records ?? []).sorted { $0.date < $1.date }

        let skinScoreSeriesByRange = ReportRange.allCases.reduce(into: [ReportRange: [ReportPoint]]()) { result, range in
            result[range] = buildSkinScoreSeries(for: range, from: records)
        }

        let acneTypeSeriesByRange = ReportRange.allCases.reduce(into: [ReportRange: [AcneTypeSeries]]()) { result, range in
            result[range] = buildAcneTypeSeries(for: range, from: records)
        }

        return ReportDataSnapshot(
            records: records,
            skinScoreSeriesByRange: skinScoreSeriesByRange,
            acneTypeSeriesByRange: acneTypeSeriesByRange,
            insightSummary: await buildInsightSummary(from: records)
        )
    }

    // MARK: - Real data builders

    private func buildSkinScoreSeries(for range: ReportRange, from records: [ScanRecord]) -> [ReportPoint] {
        let filtered = filteredRecords(for: range, in: records)
        guard !filtered.isEmpty else { return [] }

        return filtered.enumerated().map { index, record in
            let label = shortLabel(for: record.date, in: range, index: index)
            return ReportPoint(day: label, score: record.skinScore)
        }
    }

    private func buildAcneTypeSeries(for range: ReportRange, from records: [ScanRecord]) -> [AcneTypeSeries] {
        let filtered = filteredRecords(for: range, in: records)
        guard !filtered.isEmpty else { return [] }

        let relevantTypes = AcneType.allCases.filter { $0 != .unknown }
        var series: [AcneTypeSeries] = []

        for acneType in relevantTypes {
            let points = filtered.enumerated().map { index, record in
                let count = record.acneCount(for: acneType)
                let normalizedScore: Int

                if record.totalAcneCount > 0 {
                    normalizedScore = Int((Double(count) / Double(record.totalAcneCount)) * 100.0)
                } else {
                    normalizedScore = 0
                }

                let label = shortLabel(for: record.date, in: range, index: index)
                return ReportPoint(day: label, score: normalizedScore)
            }

            let hasVisibleData = points.contains { $0.score > 0 }
            if hasVisibleData || filtered.count == 1 {
                series.append(AcneTypeSeries(acneType: acneType, points: points))
            }
        }

        return series
    }

    private func buildInsightSummary(from records: [ScanRecord]) async -> ReportInsightSummary {
        guard !records.isEmpty else {
            logger.info("No records available for summary; returning empty insight", file: #fileID, line: #line)
            return .init(title: "Summary Insight", body: "Complete your first skin scan to see your progress here.", source: .empty, timestamp: nil)
        }

        do {
            logger.info("Requesting generated summary for \(records.count) records", file: #fileID, line: #line)
            let generated = try await summaryService.generateSummary(for: records)
            if !generated.isEmpty {
                saveCachedSummary(body: generated)
                logger.info("Generated summary cached (\(generated.count) chars)", file: #fileID, line: #line)
                return .init(title: "Summary Insight", body: generated, source: .generated, timestamp: Date())
            }
        } catch {
            logger.error("Summary generation failed: \(error.localizedDescription)", file: #fileID, line: #line)
            if let cached = loadCachedSummary() {
                logger.info("Using cached summary last updated \(formattedDate(cached.timestamp))", file: #fileID, line: #line)
                let bodyWithNote = "(Cached: last updated on \(formattedDate(cached.timestamp)))\n\n\(cached.body)"
                return .init(title: "Summary Insight", body: bodyWithNote, source: .cached, timestamp: cached.timestamp)
            }

            logger.error("No cached summary available; returning error summary", file: #fileID, line: #line)
            return .init(title: "Summary Insight", body: "We could not generate a summary right now. Please check your connection or API configuration.", source: .error, timestamp: nil)
        }

        let staticSummary = buildStaticInsightSummary(from: records)
        saveCachedSummary(body: staticSummary.body)
        logger.info("Using static analysis summary and cached it", file: #fileID, line: #line)
        return .init(title: staticSummary.title, body: staticSummary.body, source: .generated, timestamp: Date())
    }

    // MARK: - Caching

    private struct CachedSummary: Codable {
        let body: String
        let timestamp: Date
    }

    private func saveCachedSummary(body: String) {
        let cached = CachedSummary(body: body, timestamp: Date())
        if let data = try? JSONEncoder().encode(cached) {
            keyValueStore.set(data, forKey: CacheKeys.summary)
        }
    }

    private func loadCachedSummary() -> CachedSummary? {
        guard let data = keyValueStore.data(forKey: CacheKeys.summary) else { return nil }
        return try? JSONDecoder().decode(CachedSummary.self, from: data)
    }

    private func buildStaticInsightSummary(from records: [ScanRecord]) -> ReportInsightSummary {
        let latest = records.last!
        let first = records.first!
        let totalDelta = latest.totalAcneCount - first.totalAcneCount

        if records.count == 1 {
            let dominant = latest.acneTypeCounts.max { $0.count < $1.count }
            let dominantText = dominant?.acneType.displayName ?? "Acne"
            return .init(
                title: "Summary Insight",
                body: "The most common acne type right now is \(dominantText.lowercased()). The latest scan detected \(latest.totalAcneCount) acne occurrences.",
                source: .generated,
                timestamp: Date()
            )
        }

        let dominant = latest.acneTypeCounts.max { $0.count < $1.count }
        let dominantText = dominant?.acneType.displayName ?? "Acne"
        let direction = totalDelta <= 0 ? "fewer" : "more"

        return .init(
            title: "Summary Insight",
            body: "Compared with the first scan, the current acne count is \(direction == "fewer" ? "lower" : "higher") than before. The most common acne type is \(dominantText.lowercased()).",
            source: .generated,
            timestamp: Date()
        )
    }

    // MARK: - Range helpers

    private func filteredRecords(for range: ReportRange, in records: [ScanRecord]) -> [ScanRecord] {
        guard !records.isEmpty else { return [] }

        switch range {
        case .oneWeek:
            return records.filter { $0.date >= Calendar.current.date(byAdding: .day, value: -6, to: Date()) ?? $0.date }
        case .oneMonth:
            return records.filter { $0.date >= Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? $0.date }
        case .oneYear:
            return records.filter { $0.date >= Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? $0.date }
        }
    }

    private func shortLabel(for date: Date, in range: ReportRange, index: Int) -> String {
        switch range {
        case .oneWeek:
            return DateFormatters.dayShort.string(from: date)
        case .oneMonth:
            return DateFormatters.dayAndMonth.string(from: date)
        case .oneYear:
            return DateFormatters.monthShort.string(from: date)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        return DateFormatters.fullDateEN.string(from: date)
    }
}
