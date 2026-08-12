import Foundation

struct ReportComparisonSummary: Equatable {
    let baselineLabel: String
    let headline: String
    let scoreLabel: String
    let deltaText: String
}

struct ReportInsightSummary: Equatable {
    enum Source: String, Codable, Equatable {
        case generated
        case cached
        case error
        case empty
    }

    let title: String
    let body: String
    let source: Source
    let timestamp: Date?
}
