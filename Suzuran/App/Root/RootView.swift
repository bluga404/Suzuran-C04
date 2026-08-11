import SwiftUI
import Combine

struct RootView: View {
    @ObservedObject var viewModel: RootViewModel

    var body: some View {
        Group {
            switch viewModel.phase {
            case .onboarding:
                OnboardingView(viewModel: viewModel.makeOnboardingViewModel())
            case .home:
                MainTabView(viewModel: viewModel)
            case let .failed(error):
                ErrorStateView(
                    title: "Startup Failed",
                    message: error.userMessage,
                    primaryActionTitle: "Retry",
                    onPrimaryAction: viewModel.retry
                )
            }
        }
        .onAppear(perform: viewModel.start)
    }
}

#Preview {
    RootView(
        viewModel: RootViewModel(
            bootstrapper: PreviewBootstrapper(),
            scanHistoryStore: ScanHistoryStore(),
            homeSummaryViewModelFactory: { HomeFactory.makeViewModel() }
        )
    )
}

private struct PreviewBootstrapper: AppBootstrapping {
    func bootstrap() async throws {}
}
