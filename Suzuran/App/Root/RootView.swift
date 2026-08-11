import SwiftUI
import Combine

struct RootView: View {
    @ObservedObject var viewModel: RootViewModel

    var body: some View {
        Group {
            switch viewModel.phase {
<<<<<<< HEAD
            case .report:
                ReportFactory.makeView()
=======
            case .onboarding:
                OnboardingView(viewModel: viewModel.makeOnboardingViewModel())
            case .home:
                MainTabView(viewModel: viewModel)
>>>>>>> a10bb3936580a6da0237730f7d536607f842fb57
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
<<<<<<< HEAD
            bootstrapper: PreviewBootstrapper()
=======
            bootstrapper: PreviewBootstrapper(),
            scanHistoryStore: ScanHistoryStore(),
            homeSummaryViewModelFactory: { HomeFactory.makeViewModel() }
>>>>>>> a10bb3936580a6da0237730f7d536607f842fb57
        )
    )
}

private struct PreviewBootstrapper: AppBootstrapping {
    func bootstrap() async throws {}
}
