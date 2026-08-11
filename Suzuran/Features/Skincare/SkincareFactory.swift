import SwiftUI

enum SkincareFactory {
    
    // Single shared instance ensures the JSON databases are only decoded once
    private static let cosingRepository = CosingIngredientRepository()
    private static let acneRepository = AcneIngredientRepository()

    @MainActor
    static func makeView(historyStore: ScanHistoryStore, onDismiss: @escaping () -> Void = {}) -> some View {
        let repository = SkincareProductRepository()
        let provider = AcneProfileProvider(historyStore: historyStore)
        let viewModel = SkincareViewModel(
            skincareRepository: repository,
            acneRepository: acneRepository,
            acneProfileProvider: provider
        )
        return SkincareView(
            viewModel: viewModel,
            ingredientRepository: cosingRepository,
            acneRepository: acneRepository,
            onDismiss: onDismiss
        )
    }
}
