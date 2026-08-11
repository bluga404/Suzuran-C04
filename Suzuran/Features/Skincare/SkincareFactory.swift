import SwiftUI

/// Composition root for the Skincare tab.
///
/// Constructs the protocol-based service graph and injects it into the
/// ViewModels (Req 20.1). The public `makeView(onDismiss:)` signature is
/// preserved so `MainTabView` keeps compiling unchanged (Req 20.2, 22.4).
///
/// Reference JSON (`cosing.json`, `AcneIngredients.json`) is decoded exactly once
/// via the shared ``IngredientDB`` singleton, regardless of how many times
/// `makeView()` is invoked (Req 6.6).
///
/// Scan-history access is injected additively via ``scanHistoryStoreProvider``
/// (design.md Opsi A) so the module never holds a strong reference to app-level
/// state and `AppContainer`'s public API is untouched apart from one additive
/// line (Req 20.3, 20.5).
enum SkincareFactory {
    
    // Single shared instance ensures the JSON databases are only decoded once
    private static let ingredientRepository = SkincareIngredientRepository()

    @MainActor
    static func makeView(onDismiss: @escaping () -> Void = {}) -> some View {
        let repository = SkincareProductRepository()
        let provider = AcneProfileProvider()
        let viewModel = SkincareViewModel(
            skincareRepository: repository,
            acneRepository: acneRepository,
            acneProfileProvider: provider
        )

        return SkincareView(
            viewModel: viewModel,
            ingredientRepository: ingredientRepository,
            onDismiss: onDismiss
        )
    }

    /// Builds an ``AddSkincareViewModel`` for the Add/Edit form (Req 5.5, 25.1).
    ///
    /// Called directly by ``SkincareView`` and ``SkincareDetailView`` when presenting
    /// the form, avoiding a threaded closure. All collaborators are thin adapters over
    /// the shared ``IngredientDB/shared`` singleton, so no JSON is re-decoded.
    @MainActor
    static func makeAddSkincareViewModel(editing: SkincareProduct?) -> AddSkincareViewModel {
        let sharedDB = IngredientDB.shared
        return AddSkincareViewModel(
            editingProduct: editing,
            ocr: IngredientOCRService(),
            ingredientRepo: CosingIngredientRepository(db: sharedDB),
            acneRepo: AcneIngredientRepository(db: sharedDB),
            productRepo: SkincareProductRepository(),
            logger: AppLogger()
        )
    }
}
