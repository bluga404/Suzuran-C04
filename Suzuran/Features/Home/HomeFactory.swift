import SwiftUI

/// Factory for constructing Home feature views with all dependencies.
/// Uses an in-memory skin scan repository shared with the FaceScan completion flow.
/// Requirement: 10.6, 13.4
enum HomeFactory {

    /// Shared in-memory repository accessible from both Home and FaceScan features.
    /// When FaceScan completes, call `HomeFactory.sharedScanRepository.save(mappedScan)`
    /// to persist the scan so the Home screen picks it up on next load.
    static let sharedScanRepository = InMemorySkinScanRepository()

    @MainActor
    static func makeView() -> some View {
        let skinScanRepo: SkinScanRepository = sharedScanRepository
        let ingredientRepo: IngredientRepository = FixtureIngredientRepository()
        let skincareRepo: SkincareRepository = FixtureSkincareRepository()
        let calculator = SummaryCalculator(scoreCalculator: HomeScoreCalculator())
        let viewModel = HomeSummaryViewModel(
            skinScanRepository: skinScanRepo,
            ingredientRepository: ingredientRepo,
            skincareRepository: skincareRepo,
            calculator: calculator
        )
        return HomeView(viewModel: viewModel)
    }

    @MainActor
    static func makeDetailView(scanID: UUID, historyStore: ScanHistoryStore? = nil) -> some View {
        let repo: SkinScanRepository = sharedScanRepository
        let viewModel = ScanDetailViewModel(scanID: scanID, skinScanRepository: repo, historyStore: historyStore)
        return ScanDetailView(viewModel: viewModel)
    }

    @MainActor
    static func makeViewModel() -> HomeSummaryViewModel {
        let skinScanRepo: SkinScanRepository = sharedScanRepository
        let ingredientRepo: IngredientRepository = FixtureIngredientRepository()
        let skincareRepo: SkincareRepository = FixtureSkincareRepository()
        let calculator = SummaryCalculator(scoreCalculator: HomeScoreCalculator())
        return HomeSummaryViewModel(
            skinScanRepository: skinScanRepo,
            ingredientRepository: ingredientRepo,
            skincareRepository: skincareRepo,
            calculator: calculator
        )
    }
}
