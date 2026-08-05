import Foundation
import Combine

@MainActor
final class AppContainer: ObservableObject {
    let rootViewModel: RootViewModel

    private init(
        rootViewModel: RootViewModel
    ) {
        self.rootViewModel = rootViewModel
    }

    static func live() -> AppContainer {
        let logger = AppLogger()
        let keyValueStore = UserDefaultsKeyValueStore(userDefaults: .standard)
        let environment = AppEnvironment(logger: logger, keyValueStore: keyValueStore)
        let bootstrapper = AppBootstrapper(environment: environment)
        let rootViewModel = RootViewModel(bootstrapper: bootstrapper)

        return AppContainer(
            rootViewModel: rootViewModel
        )
    }

    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(
            welcomeText: AppConstants.homeWelcomeTitle,
            ingredientOcrButtonTitle: AppConstants.homeIngredientOcrButtonTitle
        )
    }

    func makeRootViewDependencies() -> RootView.Dependencies {
        RootView.Dependencies(makeHomeViewModel: makeHomeViewModel)
    }
}
