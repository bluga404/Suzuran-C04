import Foundation

final class LocalSummaryService: SummaryServiceProtocol {
    private let logger: AppLogging

    init(logger: AppLogging = AppLogger()) {
        self.logger = logger
    }

    func generateSummary(for records: [ScanRecord]) async throws -> String {
        guard !records.isEmpty else { return "" }

        let summary = buildSummary(from: records)
        logger.info("Built local summary (\(summary.count) chars)", file: #fileID, line: #line)
        return summary
    }

    private func buildSummary(from records: [ScanRecord]) -> String {
        let sorted = records.sorted { $0.date < $1.date }

        if sorted.count == 1 {
            return buildSingleRecordSummary(sorted[0])
        }

        return buildTrendSummary(first: sorted.first!, latest: sorted.last!, records: sorted)
    }

    private func buildSingleRecordSummary(_ record: ScanRecord) -> String {
        let dominantType = record.acneTypeCounts
            .max(by: { $0.count < $1.count })?.acneType.displayName ?? "Acne"

        let paragraph1 = "Your latest scan shows a skin score of \(record.skinScore) and a total acne count of \(record.totalAcneCount)."

        let paragraph2: String
        if record.totalAcneCount == 0 {
            paragraph2 = "No acne was detected in the most recent scan — skin appears clear in the captured image."
        } else {
            paragraph2 = "The most common lesion type detected was \(dominantType.lowercased()), which accounted for the largest share of occurrences in this scan."
        }

        return [paragraph1, paragraph2].joined(separator: "\n\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func buildTrendSummary(first: ScanRecord, latest: ScanRecord, records: [ScanRecord]) -> String {
        let acneDelta = latest.totalAcneCount - first.totalAcneCount
        let scoreDelta = latest.skinScore - first.skinScore

        let headline: String
        if scoreDelta > 5 {
            headline = "Skin score has improved over the recorded period by approximately \(scoreDelta) points."
        } else if scoreDelta < -5 {
            headline = "Skin score has declined over the recorded period by approximately \(abs(scoreDelta)) points."
        } else {
            headline = "Skin score has remained relatively stable over the recorded period."
        }

        let dominantType = latest.acneTypeCounts
            .max(by: { $0.count < $1.count })?.acneType.displayName ?? "Acne"

        let trendDetail = "Across the range of saved scans, the average skin score is \(Int(records.map { $0.skinScore }.reduce(0, +)) / max(1, records.count)). The latest scan shows \(latest.totalAcneCount) acne occurrences, with \(dominantType.lowercased()) as the most frequently detected type."

        let interpretation: String
        if acneDelta < 0 {
            interpretation = "Overall acne counts have decreased compared with the earliest saved scan, suggesting an improving trend in lesion frequency."
        } else if acneDelta > 0 {
            interpretation = "Overall acne counts have increased compared with the earliest saved scan, indicating a rise in lesion frequency that may need attention."
        } else {
            interpretation = "Overall acne counts show little net change across the period; consider monitoring for short-term spikes."
        }

        let closing = "Continue regular scans to track whether recent trends persist; this summary reflects detected counts and averaged scores across saved scans."

        return [headline, trendDetail, interpretation, closing].joined(separator: "\n\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
