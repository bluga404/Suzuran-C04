import SwiftUI

enum ReportFactory {
    @MainActor
    static func makeView(onDismiss: @escaping () -> Void = {}) -> some View {
        let dataService = ReportDataService()
        let viewModel = ReportViewModel(dataService: dataService)
        return ReportView(viewModel: viewModel, onDismiss: onDismiss)
    }
}
