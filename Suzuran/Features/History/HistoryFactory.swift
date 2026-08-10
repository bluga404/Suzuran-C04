import SwiftUI

enum HistoryFactory {
    @MainActor
    static func makeView(historyStore: ScanHistoryStore) -> some View {
        let viewModel = HistoryViewModel(historyStore: historyStore)
        return HistoryView(viewModel: viewModel)
    }
}
