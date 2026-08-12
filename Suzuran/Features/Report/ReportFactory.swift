import SwiftUI

enum ReportFactory {
    @MainActor
    static func makeView(historyStore: ScanHistoryStore? = nil) -> some View {
        let logger = AppLogger()
        let apiKeyProvider = KeychainAPIKeyProvider()
        let summaryService = GeminiSummaryService(apiKeyProvider: apiKeyProvider, logger: logger)
        let dataService = ReportDataService(historyStore: historyStore, summaryService: summaryService, logger: logger)
        let viewModel = ReportViewModel(dataService: dataService, logger: logger)
        return ReportView(viewModel: viewModel)
    }
}
