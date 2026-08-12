import SwiftUI

/// Factory for constructing Home feature views with all dependencies.
/// Uses `ScanHistoryStoreSkinScanRepository` backed by disk-persisted JSON as the primary
/// read source so the Summary screen survives app restarts.
/// Requirement: 10.6, 13.4
enum HomeFactory {

    /// In-memory store still used to save the scan during the current session
    /// (before AppContainer persists it via ScanHistoryStore).
    /// This ensures the Home screen refreshes immediately after a scan without
    /// needing to re-read from disk on save. Reading uses ScanHistoryStore instead.
    static let sharedScanRepository = InMemorySkinScanRepository()

    @MainActor
    static func makeView(historyStore: ScanHistoryStore) -> some View {
        let viewModel = makeViewModel(historyStore: historyStore)
        return HomeView(viewModel: viewModel)
    }

    @MainActor
    static func makeDetailView(scanID: UUID, historyStore: ScanHistoryStore? = nil) -> some View {
        // For detail view, prefer the disk-backed repo when historyStore is available
        let repo: SkinScanRepository
        if let store = historyStore {
            repo = ScanHistoryStoreSkinScanRepository(store: store)
        } else {
            repo = sharedScanRepository
        }
        let viewModel = ScanDetailViewModel(scanID: scanID, skinScanRepository: repo, historyStore: historyStore)
        return ScanDetailView(viewModel: viewModel)
    }

    @MainActor
    static func makeViewModel(historyStore: ScanHistoryStore) -> HomeSummaryViewModel {
        // Use disk-backed repository so Summary survives app restarts
        let skinScanRepo: SkinScanRepository = ScanHistoryStoreSkinScanRepository(store: historyStore)
        let ingredientRepo: IngredientRepository = FixtureIngredientRepository()
        let skincareRepo: SkincareRepository = SkincareProductRepository()
        let calculator = SummaryCalculator(scoreCalculator: HomeScoreCalculator())
        return HomeSummaryViewModel(
            skinScanRepository: skinScanRepo,
            ingredientRepository: ingredientRepo,
            skincareRepository: skincareRepo,
            calculator: calculator
        )
    }
}
