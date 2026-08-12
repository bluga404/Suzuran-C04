import SwiftUI

enum ReportFactory {
    @MainActor
    static func makeView(historyStore: ScanHistoryStore? = nil, onDismiss: @escaping () -> Void = {}) -> some View {
        let summaryService = GeminiSummaryService()
        let dataService = ReportDataService(historyStore: historyStore, summaryService: summaryService)
        let viewModel = ReportViewModel(dataService: dataService)
        return ReportView(viewModel: viewModel, onDismiss: onDismiss)
    }
}
