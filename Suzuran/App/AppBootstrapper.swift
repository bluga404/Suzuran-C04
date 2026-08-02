import Foundation

protocol AppBootstrapping {
    func bootstrap() async throws
}

struct AppBootstrapper: AppBootstrapping {
    private let environment: AppEnvironment

    init(environment: AppEnvironment) {
        self.environment = environment
    }

    func bootstrap() async throws {
        environment.logger.info("App bootstrap started")

        let hasLaunchedBefore = environment.keyValueStore.bool(forKey: AppConstants.hasLaunchedBeforeKey)
        if !hasLaunchedBefore {
            environment.keyValueStore.set(true, forKey: AppConstants.hasLaunchedBeforeKey)
            environment.logger.info("First launch setup completed")
        }

        environment.logger.info("App bootstrap finished")
    }
}
