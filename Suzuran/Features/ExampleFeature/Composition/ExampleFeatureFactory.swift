import SwiftUI

enum ExampleFeatureFactory {
    static func makeViewModel() -> ExampleFeatureViewModel {
        let repository = DefaultAcneAnalysisRepository(
            remoteDataSource: MockAcneDetectionRemoteDataSource(),
            localDataSource: InMemoryAcneHistoryLocalDataSource()
        )

        return ExampleFeatureViewModel(
            analyzeUseCase: AnalyzeAcneFromImageUseCase(repository: repository),
            historyUseCase: GetAcneAnalysisHistoryUseCase(repository: repository),
            mapper: ExampleFeaturePresentationMapper(),
            logger: AppLogger()
        )
    }

    static func makeView() -> some View {
        ExampleFeatureView(viewModel: makeViewModel())
    }
}
