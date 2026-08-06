import SwiftUI

enum FaceScanFactory {
    static func makeView(onDismiss: @escaping () -> Void = {}) -> some View {
        let keyValueStore = UserDefaultsKeyValueStore(userDefaults: .standard)
        let mlDataSource = MLAcneDetectionDataSource()
        let localDataSource = FaceScanLocalDataSource(keyValueStore: keyValueStore)
        let repository = DefaultFaceScanRepository(
            mlDataSource: mlDataSource,
            localDataSource: localDataSource
        )

        let useCase = PerformFaceScanUseCase(repository: repository)
        let mapper = FaceScanPresentationMapper()
        let logger = AppLogger()

        let viewModel = FaceScanViewModel(
            performScanUseCase: useCase,
            mapper: mapper,
            logger: logger
        )

        return FaceScanView(viewModel: viewModel, onDismiss: onDismiss)
    }
}
