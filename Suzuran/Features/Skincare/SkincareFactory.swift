import SwiftUI

enum SkincareFactory {
    
    // Single shared instance ensures the JSON databases are only decoded once
    private static let ingredientRepository = SkincareIngredientRepository()

    @MainActor
    static func makeView(onDismiss: @escaping () -> Void = {}) -> some View {
        let repository = SkincareProductRepository()
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
