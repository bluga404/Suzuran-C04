import SwiftUI

enum SkincareFactory {
    
    // Single shared instance ensures the JSON databases are only decoded once
    private static let ingredientRepository = IngredientRepository()

    @MainActor
    static func makeView(onDismiss: @escaping () -> Void = {}) -> some View {
        let repository = SkincareRepository()
        let provider = AcneProfileProvider()
        let viewModel = SkincareViewModel(
            skincareRepository: repository,
            ingredientRepository: ingredientRepository,
            acneProfileProvider: provider
        )
        return SkincareView(
            viewModel: viewModel,
            ingredientRepository: ingredientRepository,
            onDismiss: onDismiss
        )
    }
}
