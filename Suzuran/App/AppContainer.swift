import Foundation
import Combine

@MainActor
final class AppContainer: ObservableObject {
    let environment: AppEnvironment
    let bootstrapper: AppBootstrapping
    let rootViewModel: RootViewModel

    private init(
        environment: AppEnvironment,
        bootstrapper: AppBootstrapping,
        rootViewModel: RootViewModel
    ) {
        self.environment = environment
        self.bootstrapper = bootstrapper
        self.rootViewModel = rootViewModel
    }

    static func live() -> AppContainer {
        let logger = AppLogger()
        let keyValueStore = UserDefaultsKeyValueStore(userDefaults: .standard)
        let environment = AppEnvironment(logger: logger, keyValueStore: keyValueStore)
        let bootstrapper = AppBootstrapper(environment: environment)
        let rootViewModel = RootViewModel(
            bootstrapper: bootstrapper,
            homeSummaryViewModelFactory: {
                HomeFactory.makeViewModel()
            }
        )

        return AppContainer(
            environment: environment,
            bootstrapper: bootstrapper,
            rootViewModel: rootViewModel
        )
    }
}
