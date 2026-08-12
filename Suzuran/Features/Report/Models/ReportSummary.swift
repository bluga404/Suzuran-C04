import Foundation

struct ReportComparisonSummary: Equatable {
    let baselineLabel: String
    let headline: String
    let scoreLabel: String
    let deltaText: String
}

struct ReportInsightSummary: Equatable {
    let title: String
    let body: String
}
