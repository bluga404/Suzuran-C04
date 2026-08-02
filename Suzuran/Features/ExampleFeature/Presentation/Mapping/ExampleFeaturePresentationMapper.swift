import Foundation

struct ExampleFeaturePresentationMapper {
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    func map(_ analysis: AcneAnalysis) -> AcneAnalysisCardModel {
        let sortedFindings = analysis.findings.sorted { lhs, rhs in
            lhs.lesionCount > rhs.lesionCount
        }

        let findingsSummary = sortedFindings
            .map { finding in
                "\(finding.zone.rawValue): \(finding.lesionCount) lesions"
            }
            .joined(separator: ", ")

        return AcneAnalysisCardModel(
            id: analysis.id,
            dateText: dateFormatter.string(from: analysis.capturedAt),
            severityText: analysis.overallSeverity.rawValue.capitalized,
            confidenceText: "\(Int(analysis.confidence * 100))% confidence",
            findingsSummary: findingsSummary,
            recommendation: analysis.recommendation
        )
    }
}
