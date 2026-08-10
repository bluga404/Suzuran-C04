import SwiftUI

enum HistoryFactory {
    @MainActor
    static func makeView(historyStore: ScanHistoryStore) -> some View {
        let viewModel = HistoryViewModel(historyStore: historyStore)
        return HistoryView(viewModel: viewModel)
    }
    
    @MainActor
    static func makeCompareView(recordA: ScanRecord, recordB: ScanRecord, allRecords: [ScanRecord]) -> some View {
        let viewModel = CompareViewModel(recordA: recordA, recordB: recordB, allRecords: allRecords)
        return CompareView(viewModel: viewModel)
    }
}
