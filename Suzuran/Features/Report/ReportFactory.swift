import SwiftUI

enum ReportFactory {
    @MainActor
    static func makeView(onDismiss: @escaping () -> Void = {}) -> some View {
        let viewModel = ReportViewModel()
        return ReportView(viewModel: viewModel, onDismiss: onDismiss)
    }
}
