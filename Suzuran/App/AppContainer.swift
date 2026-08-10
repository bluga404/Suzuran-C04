import Foundation
import Combine

@MainActor
final class AppContainer: ObservableObject {
    let environment: AppEnvironment
    let bootstrapper: AppBootstrapping
    let rootViewModel: RootViewModel
    let scanHistoryStore: ScanHistoryStore

    private init(
        environment: AppEnvironment,
        bootstrapper: AppBootstrapping,
        rootViewModel: RootViewModel,
        scanHistoryStore: ScanHistoryStore
    ) {
        self.environment = environment
        self.bootstrapper = bootstrapper
        self.rootViewModel = rootViewModel
        self.scanHistoryStore = scanHistoryStore
    }

    static func live() -> AppContainer {
        let logger = AppLogger()
        let keyValueStore = UserDefaultsKeyValueStore(userDefaults: .standard)
        let environment = AppEnvironment(logger: logger, keyValueStore: keyValueStore)
        let bootstrapper = AppBootstrapper(environment: environment)
        let scanHistoryStore = ScanHistoryStore()

        let rootViewModel = RootViewModel(
            bootstrapper: bootstrapper,
            scanHistoryStore: scanHistoryStore,
            homeSummaryViewModelFactory: {
                HomeFactory.makeViewModel()
            }
        )

        return AppContainer(
            environment: environment,
            bootstrapper: bootstrapper,
            rootViewModel: rootViewModel,
            scanHistoryStore: scanHistoryStore
        )
    }
}
