import Foundation

struct AcneAnalysisCardModel: Identifiable, Equatable {
    let id: UUID
    let dateText: String
    let severityText: String
    let confidenceText: String
    let findingsSummary: String
    let recommendation: String
}

enum ExampleFeatureViewState: Equatable {
    case idle
    case analyzing
    case analysisResult(AcneAnalysisCardModel)
    case history([AcneAnalysisCardModel])
    case emptyHistory
    case error(message: String)
}
