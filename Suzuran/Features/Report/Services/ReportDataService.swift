import Foundation

struct ReportDataSnapshot {
    let records: [ScanRecord]
    let skinScoreSeriesByRange: [ReportRange: [ReportPoint]]
    let acneTypeSeriesByRange: [ReportRange: [AcneTypeSeries]]
    let insightSummary: ReportInsightSummary
}

final class ReportDataService {
    private let historyStore: ScanHistoryStore?
    private let summaryService: GeminiSummaryService

    init(
        historyStore: ScanHistoryStore? = nil,
        summaryService: GeminiSummaryService = GeminiSummaryService()
    ) {
        self.historyStore = historyStore
        self.summaryService = summaryService
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
            return .init(
                title: "Ringkasan",
                body: "Simpan scan wajah pertama untuk melihat tren perkembangan kulitmu di sini."
            )
        }

        do {
            let generated = try await summaryService.generateSummary(for: records)
            if !generated.isEmpty {
                return .init(title: "Ringkasan", body: generated)
            }
        } catch {
            // Fall back to a static summary if Gemini is unavailable, misconfigured, or returns invalid content.
        }

        return buildStaticInsightSummary(from: records)
    }

    private func buildStaticInsightSummary(from records: [ScanRecord]) -> ReportInsightSummary {
        let latest = records.last!
        let first = records.first!
        let totalDelta = latest.totalAcneCount - first.totalAcneCount

        if records.count == 1 {
            let dominant = latest.acneTypeCounts.max { $0.count < $1.count }
            let dominantText = dominant?.acneType.displayName ?? "Acne"
            return .init(
                title: "Ringkasan",
                body: "Jenis jerawat yang paling sering muncul saat ini adalah \(dominantText.lowercased()). Total jerawat yang terdeteksi pada scan terakhir adalah \(latest.totalAcneCount)."
            )
        }

        let dominant = latest.acneTypeCounts.max { $0.count < $1.count }
        let dominantText = dominant?.acneType.displayName ?? "Acne"
        let direction = totalDelta <= 0 ? "fewer" : "more"

        return .init(
            title: "Ringkasan",
            body: "Dibandingkan scan awal, jumlah jerawat yang terdeteksi saat ini \(direction == "fewer" ? "lebih sedikit" : "lebih banyak") dari sebelumnya. Jenis jerawat yang paling sering muncul adalah \(dominantText.lowercased())."
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
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US")
            formatter.dateFormat = "EEE"
            return formatter.string(from: date)
        case .oneMonth:
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US")
            formatter.dateFormat = "d MMM"
            return formatter.string(from: date)
        case .oneYear:
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US")
            formatter.dateFormat = "MMM"
            return formatter.string(from: date)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }
}
