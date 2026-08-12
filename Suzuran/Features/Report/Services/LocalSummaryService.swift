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
        let sortedRecords = records.sorted { $0.date < $1.date }

        if sortedRecords.count == 1 {
            return buildSingleRecordSummary(sortedRecords[0])
        }

        return buildTrendSummary(first: sortedRecords.first!, latest: sortedRecords.last!, records: sortedRecords)
    }

    private func buildSingleRecordSummary(_ record: ScanRecord) -> String {
        let dominantType = record.acneTypeCounts
            .max(by: { lhs, rhs in lhs.count < rhs.count })?
            .acneType.displayName
            .lowercased() ?? "acne"

        let acneDescription = record.totalAcneCount == 0
            ? "kulit kamu terlihat sangat bersih dengan tidak ada jerawat yang terdeteksi"
            : "terdapat \(record.totalAcneCount) jerawat dengan tipe yang paling umum adalah \(dominantType)"

        return "Scan terbaru menunjukkan bahwa \(acneDescription). Skor kulit kamu saat ini adalah \(record.skinScore), yang menggambarkan kondisi kulit saat ini.".trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func buildTrendSummary(first: ScanRecord, latest: ScanRecord, records: [ScanRecord]) -> String {
        let acneDelta = latest.totalAcneCount - first.totalAcneCount
        let scoreDelta = latest.skinScore - first.skinScore

        let acneTrend: String
        switch acneDelta {
        case ..<0:
            acneTrend = "menurun"
        case 1...:
            acneTrend = "meningkat"
        default:
            acneTrend = "stabil"
        }

        let scoreTrend: String
        switch scoreDelta {
        case let value where value > 0:
            scoreTrend = "membaik"
        case let value where value < 0:
            scoreTrend = "turun"
        default:
            scoreTrend = "tetap stabil"
        }

        let dominantType = latest.acneTypeCounts
            .max(by: { lhs, rhs in lhs.count < rhs.count })?
            .acneType.displayName
            .lowercased() ?? "acne"

        let firstDate = DateFormatters.fullDateID.string(from: first.date)
        let latestDate = DateFormatters.fullDateID.string(from: latest.date)

        let deltaDescription: String
        switch acneDelta {
        case ..<0:
            deltaDescription = "lebih sedikit" 
        case 1...:
            deltaDescription = "lebih banyak"
        default:
            deltaDescription = "jumlah yang sama"
        }

        let comparisonSentence = "Dari scan pertama pada \(firstDate) hingga scan terakhir pada \(latestDate), jumlah jerawat \(acneTrend) menjadi \(deltaDescription) dan skor kulit \(scoreTrend)."
        let dominantSentence = "Tipe jerawat yang paling umum sekarang adalah \(dominantType)."

        return [comparisonSentence, dominantSentence]
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
