import Foundation

protocol SummaryServiceProtocol {
    func generateSummary(for records: [ScanRecord]) async throws -> String
}
