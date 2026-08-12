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
        #if DEBUG
        if let envKey = developerGeminiAPIKey() {
            let saved = KeychainHelper.shared.save(envKey, service: "com.suzuran.gemini", account: AppConstants.geminiApiKeyInfoPlistKey)
            logger.info("Debug: stored Gemini API key to Keychain (saved=\(saved))", file: #fileID, line: #line)
        } else {
            logger.info("Debug: no Gemini API key configured in environment (expected GEMINI_API_KEY)", file: #fileID, line: #line)
        }
        #endif
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

    private static func developerGeminiAPIKey() -> String? {
        let environment = ProcessInfo.processInfo.environment
        let keyName = "GEMINI_API_KEY"

        if let value = environment[keyName], !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return value
        }

        return nil
    }
}
