import SwiftUI
import Combine

struct RootView: View {
    @ObservedObject var viewModel: RootViewModel

    var body: some View {
        Group {
            switch viewModel.phase {
            case .home:
                HomeView(viewModel: viewModel.makeHomeViewModel())
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
        .appScreenContainer()
    }
}

#Preview {
    RootView(
        viewModel: RootViewModel(
            bootstrapper: PreviewBootstrapper(),
            homeViewModelFactory: { HomeViewModel(welcomeText: AppConstants.homeWelcomeTitle) }
        )
    )
}

private struct PreviewBootstrapper: AppBootstrapping {
    func bootstrap() async throws {}
}
