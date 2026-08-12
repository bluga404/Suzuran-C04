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
            insightSummary: .init(title: "Summary Insight", body: "", source: .empty, timestamp: nil)
        )
    }

    // MARK: - Real data builders

    private func buildSkinScoreSeries(for range: ReportRange, from records: [ScanRecord]) -> [ReportPoint] {
        let groups = groupedRecords(for: range, in: records).filter { !$0.records.isEmpty }
        guard !groups.isEmpty else { return [] }

        return groups.map { group in
            let count = group.records.count
            let averageScore = count > 0
                ? Int(round(Double(group.records.map(\.skinScore).reduce(0, +)) / Double(count)))
                : 0
            return ReportPoint(day: group.label, score: averageScore)
        }
    }

    private func buildAcneTypeSeries(for range: ReportRange, from records: [ScanRecord]) -> [AcneTypeSeries] {
        let groups = groupedRecords(for: range, in: records).filter { !$0.records.isEmpty }
        guard !groups.isEmpty else { return [] }

        let relevantTypes = AcneType.allCases.filter { $0 != .unknown }
        var series: [AcneTypeSeries] = []

        for acneType in relevantTypes {
            let points = groups.map { group -> ReportPoint in
                let totalCount = group.records.reduce(0) { partialResult, record in
                    partialResult + record.acneCount(for: acneType)
                }
                let averageCount = group.records.isEmpty
                    ? 0
                    : Int(round(Double(totalCount) / Double(group.records.count)))
                return ReportPoint(day: group.label, score: averageCount)
            }

            // Always include series for defined acne types (keeps report stable and predictable).
            series.append(AcneTypeSeries(acneType: acneType, points: points))
        }

        return series
    }

    private func groupedRecords(for range: ReportRange, in records: [ScanRecord]) -> [(label: String, records: [ScanRecord])] {
        let filtered = filteredRecords(for: range, in: records)
        guard !filtered.isEmpty else { return [] }

        switch range {
        case .oneWeek:
            return filtered.map { record in
                (
                    label: DateFormatters.dayShort.string(from: record.date),
                    records: [record]
                )
            }
        case .oneMonth:
            return monthlyWeekBuckets(for: filtered)
        case .oneYear:
            return monthlyBuckets(for: filtered)
        }
    }

    /// Groups records into calendar-month weekly buckets (Week 1: days 1-7, Week 2: 8-14, ...)
    private func monthlyWeekBuckets(for records: [ScanRecord]) -> [(label: String, records: [ScanRecord])] {
        let calendar = Calendar.current

        // Use the current month as the reporting span
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) else {
            return []
        }

        let daysRange = calendar.range(of: .day, in: .month, for: startOfMonth) ?? 1..<31
        let daysInMonth = daysRange.count
        let numberOfWeeks = Int(ceil(Double(daysInMonth) / 7.0))

        var buckets: [[ScanRecord]] = Array(repeating: [], count: numberOfWeeks)

        for record in records {
            let comps = calendar.dateComponents([.year, .month, .day], from: record.date)
            guard let day = comps.day else { continue }
            let bucketIndex = max(0, min(numberOfWeeks - 1, (day - 1) / 7))
            buckets[bucketIndex].append(record)
        }

        return (0..<numberOfWeeks).map { idx in
            let bucketRecords = buckets[idx].sorted { $0.date < $1.date }
            return (label: "Week \(idx + 1)", records: bucketRecords)
        }
    }

    private func weeklyBuckets(for records: [ScanRecord], spanDays: Int) -> [(label: String, records: [ScanRecord])] {
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -(spanDays - 1), to: endDate) else {
            return []
        }

        let bucketCount = Int(ceil(Double(spanDays) / 7.0))
        var buckets: [Int: [ScanRecord]] = [:]

        for record in records {
            let dayOffset = calendar.dateComponents([.day], from: startDate, to: calendar.startOfDay(for: record.date)).day ?? 0
            let bucketIndex = max(0, min(bucketCount - 1, dayOffset / 7))
            buckets[bucketIndex, default: []].append(record)
        }

        return (0..<bucketCount).map { index in
            let bucketRecords = (buckets[index] ?? []).sorted { $0.date < $1.date }
            return (label: "Week \(index + 1)", records: bucketRecords)
        }
    }

    private func monthlyBuckets(for records: [ScanRecord]) -> [(label: String, records: [ScanRecord])] {
        let calendar = Calendar.current

        struct YearMonth: Hashable {
            let year: Int
            let month: Int
        }

        let grouped = Dictionary(grouping: records) { record in
            let components = calendar.dateComponents([.year, .month], from: record.date)
            return YearMonth(year: components.year ?? 0, month: components.month ?? 0)
        }

        return grouped.keys.sorted { lhs, rhs in
            if lhs.year == rhs.year { return lhs.month < rhs.month }
            return lhs.year < rhs.year
        }.map { key in
            let date = calendar.date(from: DateComponents(year: key.year, month: key.month)) ?? Date()
            let records = grouped[key]!.sorted { $0.date < $1.date }
            return (label: DateFormatters.monthShort.string(from: date), records: records)
        }
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

    // MARK: - Adaptive insight (rule-based)

    /// Builds an adaptive, human-friendly insight summary based on the supplied records and
    /// the currently active report selection. The output is plain English and designed to be
    /// concise (max 4 paragraphs). This is a rule-based generator (no external LLM) and aims
    /// to give actionable, contextual insights for both `skinScore` and `acneType` metrics.
    func buildAdaptiveInsight(
        from records: [ScanRecord],
        metric: ReportMetric,
        range: ReportRange,
        visibleAcneTypes: [AcneType],
        selectedDay: String?
    ) async -> ReportInsightSummary {
        guard !records.isEmpty else {
            return .init(title: "Summary Insight", body: "No scan history available for the selected range.", source: .empty, timestamp: nil)
        }

        // Build data-aligned, affirmation-style insight that strictly reflects the supplied data
        let groups = groupedRecords(for: range, in: records).filter { !$0.records.isEmpty }

        switch metric {
        case .skinScore:
            let points: [Int] = groups.map { grp in
                let cnt = grp.records.count
                return cnt > 0 ? Int(round(Double(grp.records.map(\.skinScore).reduce(0, +)) / Double(cnt))) : 0
            }

            if points.isEmpty {
                return .init(title: "Skin Score Insight", body: "No skin score data available for the selected range.", source: .generated, timestamp: Date())
            }

            if points.count == 1 {
                let val = points[0]
                let dominant = groups.first?.records.first?.acneTypeCounts.max(by: { $0.count < $1.count })?.acneType.displayName ?? "Acne"
                let p1 = "Latest scan shows a skin score of \(val) with a total acne count of \(groups.first?.records.first?.totalAcneCount ?? 0)."
                let p2 = "The most commonly detected lesion in that scan was \(dominant.lowercased())."
                let p3: String
                if val >= 80 {
                    p3 = "This score indicates a strong skin condition relative to the recorded scale."
                } else if val <= 40 {
                    p3 = "This score indicates room for improvement in overall skin health; consider reviewing recent product changes or treatments."
                } else {
                    p3 = "This single measurement does not yet establish a trend; future scans will reveal whether this is persistent."
                }
                let body = [p1, p2, p3].joined(separator: "\n\n").trimmingCharacters(in: .whitespacesAndNewlines)
                return .init(title: "Skin Score Insight", body: body, source: .generated, timestamp: Date())
            }

            let first = points.first ?? 0
            let last = points.last ?? 0
            let delta = last - first
            let mean = Int(round(points.map(Double.init).reduce(0, +) / Double(points.count)))
            let variance = points.map { Double($0 - mean) * Double($0 - mean) }.reduce(0, +) / Double(max(1, points.count))
            let stddev = Int(round(sqrt(variance)))

            // Build paragraphs
            var paragraphs: [String] = []

            // Headline (affirmation style)
            if delta > 5 {
                paragraphs.append("Your skin score shows a clear upward trend across the selected period, improving by about \(delta) points.")
            } else if delta < -5 {
                paragraphs.append("Your skin score shows a downward trend across the selected period, decreasing by about \(abs(delta)) points.")
            } else {
                paragraphs.append("Your skin score has remained relatively steady across the selected period with modest fluctuations.")
            }

            // Data specifics
            paragraphs.append("Average skin score over the period is \(mean); the most recent value is \(last). Observed variability (std. dev) is \(stddev), indicating \(stddev > 8 ? "notable" : "moderate to low") short-term swings.")

            // Interpretation linking acne counts if possible
            let totalFirst = groups.first?.records.map(\.totalAcneCount).reduce(0, +) ?? 0
            let totalLast = groups.last?.records.map(\.totalAcneCount).reduce(0, +) ?? 0
            let acneDelta = totalLast - totalFirst
            if (delta > 0 && acneDelta < 0) || (delta < 0 && acneDelta > 0) {
                paragraphs.append("The change in skin score appears inversely associated with overall acne counts in the same period, suggesting the score movement aligns with changes in lesion frequency.")
            } else {
                paragraphs.append("Score changes do not show a clear inverse relationship with total acne counts across the same buckets.")
            }

            // Conditional suggestion only when data supports
            if abs(delta) >= 8 || stddev > 10 || abs(acneDelta) >= 3 {
                paragraphs.append("This pattern merits attention: review the recent weeks with notable deviations and consider following targeted recommendations if specific lesion types are rising.")
            }

            let body = paragraphs.prefix(4).joined(separator: "\n\n")
            return .init(title: "Skin Score Insight", body: body, source: .generated, timestamp: Date())

        case .acneType:
            let relevant = visibleAcneTypes.isEmpty ? AcneType.allCases.filter({ $0 != .unknown }) : visibleAcneTypes
            var typeAverages: [AcneType: [Int]] = [:]
            for t in relevant { typeAverages[t] = [] }

            for grp in groups {
                for t in relevant {
                    let total = grp.records.reduce(0) { $0 + $1.acneCount(for: t) }
                    let avg = grp.records.isEmpty ? 0 : Int(round(Double(total) / Double(grp.records.count)))
                    typeAverages[t]?.append(avg)
                }
            }

            struct TypeTrend { let type: AcneType; let first: Int; let last: Int; var delta: Int { last - first } }
            var trends: [TypeTrend] = []
            for (t, arr) in typeAverages {
                let f = arr.first ?? 0
                let l = arr.last ?? 0
                trends.append(TypeTrend(type: t, first: f, last: l))
            }

            if trends.isEmpty {
                return .init(title: "Acne Type Insight", body: "No acne type data available for the selected range.", source: .generated, timestamp: Date())
            }

            let inc = trends.filter { $0.delta > 0 }.sorted { $0.delta > $1.delta }
            let dec = trends.filter { $0.delta < 0 }.sorted { $0.delta < $1.delta }
            let stable = trends.filter { $0.delta == 0 }

            var paragraphs: [String] = []

            // Headline
            if !inc.isEmpty {
                let top = inc.first!
                paragraphs.append("Some lesion types are increasing in average frequency; the largest rise is \(top.type.displayName) with an average increase of \(top.delta) in the selected buckets.")
            } else if !dec.isEmpty {
                let top = dec.first!
                paragraphs.append("Some lesion types are showing declines; the largest decrease is \(top.type.displayName) with an average drop of \(abs(top.delta)).")
            } else {
                paragraphs.append("Average counts for tracked lesion types are stable across the selected period.")
            }

            // Detail examples
            var exampleParts: [String] = []
            if !inc.isEmpty { exampleParts += inc.prefix(2).map { "\($0.type.displayName) (+\($0.delta))" } }
            if !dec.isEmpty { exampleParts += dec.prefix(2).map { "\($0.type.displayName) (\($0.delta))" } }
            if !exampleParts.isEmpty {
                paragraphs.append("Examples: \(exampleParts.joined(separator: ", ")). These are average counts per bucket in the selected range.")
            }

            // Interpretation linking to overall counts
            let totalFirst = groups.first?.records.map(\.totalAcneCount).reduce(0, +) ?? 0
            let totalLast = groups.last?.records.map(\.totalAcneCount).reduce(0, +) ?? 0
            if totalLast < totalFirst {
                paragraphs.append("Overall lesion frequency decreased across the selected period, consistent with reductions in some lesion types.")
            } else if totalLast > totalFirst {
                paragraphs.append("Overall lesion frequency increased across the selected period, which is reflected in rising averages for some lesion types.")
            }

            let body = paragraphs.prefix(4).joined(separator: "\n\n")
            return .init(title: "Acne Type Insight", body: body, source: .generated, timestamp: Date())
        }
    }

    // MARK: - Range helpers

    private func filteredRecords(for range: ReportRange, in records: [ScanRecord]) -> [ScanRecord] {
        guard !records.isEmpty else { return [] }
        switch range {
        case .oneWeek:
            return records.filter { $0.date >= Calendar.current.date(byAdding: .day, value: -6, to: Date()) ?? $0.date }
        case .oneMonth:
            // Filter to current calendar month
            let calendar = Calendar.current
            guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())),
                  let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else {
                return []
            }
            return records.filter { $0.date >= startOfMonth && $0.date < startOfNextMonth }
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
