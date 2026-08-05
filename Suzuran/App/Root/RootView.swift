import SwiftUI

struct RootView: View {
    struct Dependencies {
        let makeHomeViewModel: () -> HomeViewModel
    }

    @ObservedObject var viewModel: RootViewModel
    @StateObject private var router: AppRouter
    @StateObject private var homeViewModel: HomeViewModel
    private let dependencies: Dependencies

    init(
        viewModel: RootViewModel,
        dependencies: Dependencies
    ) {
        self.viewModel = viewModel
        self.dependencies = dependencies
        let router = AppRouter()
        _router = StateObject(wrappedValue: router)
        _homeViewModel = StateObject(wrappedValue: dependencies.makeHomeViewModel())
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            switch viewModel.phase {
            case .launching:
                LoadingStateView(
                    title: "Preparing App",
                    subtitle: "Setting up dependencies and local data."
                )
            case .ready:
                HomeView(
                    viewModel: homeViewModel,
                    onNavigateToIngredientOcr: { router.push(.ingredientOcr) }
                )
            case let .failed(error):
                ErrorStateView(
                    title: "Startup Failed",
                    message: error.userMessage,
                    primaryActionTitle: "Retry",
                    onPrimaryAction: viewModel.retry
                )
            }
        }
        .navigationDestination(for: AppRoute.self) { route in
            switch route {
            case .ingredientOcr:
                ImagePickerPOCView()
            }
        }
        .onAppear(perform: viewModel.start)
        .appScreenContainer()
    }
}

#Preview {
    RootView(
        viewModel: RootViewModel(
            bootstrapper: PreviewBootstrapper()
        ),
        dependencies: RootView.Dependencies(
            makeHomeViewModel: {
                HomeViewModel(
                    welcomeText: AppConstants.homeWelcomeTitle,
                    ingredientOcrButtonTitle: AppConstants.homeIngredientOcrButtonTitle
                )
            }
        )
    )
}

private struct PreviewBootstrapper: AppBootstrapping {
    func bootstrap() async throws {}
}
