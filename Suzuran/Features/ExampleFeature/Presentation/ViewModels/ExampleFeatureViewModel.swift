import Foundation
import Combine

@MainActor
final class ExampleFeatureViewModel: ObservableObject {
    @Published private(set) var state: ExampleFeatureViewState = .idle

    private let analyzeUseCase: AnalyzeAcneFromImageUseCase
    private let historyUseCase: GetAcneAnalysisHistoryUseCase
    private let mapper: ExampleFeaturePresentationMapper
    private let logger: AppLogging

    init(
        analyzeUseCase: AnalyzeAcneFromImageUseCase,
        historyUseCase: GetAcneAnalysisHistoryUseCase,
        mapper: ExampleFeaturePresentationMapper,
        logger: AppLogging
    ) {
        self.analyzeUseCase = analyzeUseCase
        self.historyUseCase = historyUseCase
        self.mapper = mapper
        self.logger = logger
    }

    func analyzeSampleImage() {
        state = .analyzing

        Task {
            do {
                let result = try await analyzeUseCase.execute(
                    .init(imageData: Data("sample-face-image".utf8), capturedAt: Date())
                )
                state = .analysisResult(mapper.map(result))
            } catch {
                logger.error("Example feature analysis failed: \(error.localizedDescription)")
                state = .error(message: ExampleFeatureErrorTextMapper.message(for: error))
            }
        }
    }

    func loadHistory() {
        Task {
            do {
                let history = try await historyUseCase.execute()

                if history.isEmpty {
                    state = .emptyHistory
                    return
                }

                state = .history(history.map(mapper.map))
            } catch {
                logger.error("Example feature history failed: \(error.localizedDescription)")
                state = .error(message: ExampleFeatureErrorTextMapper.message(for: error))
            }
        }
    }

    func reset() {
        state = .idle
    }
}
