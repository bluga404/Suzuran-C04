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

    /// Optional provider for the newest ``ScanRecord``. Set once, additively, from
    /// `AppContainer.live()`. When unset, ``AcneProfileProvider`` returns an empty
    /// active-acne list (Req 8.2, 8.6).
    static var scanHistoryStoreProvider: (() -> ScanRecord?)?

    @MainActor
    static func makeView(onDismiss: @escaping () -> Void = {}) -> some View {
        // Shared, decoded-once reference database (Req 6.6).
        let db = IngredientDB.shared

        // Split repositories (Req 6.1, 6.2, 6.3).
        let cosingRepo = CosingIngredientRepository(db: db)
        let acneRepo = AcneIngredientRepository(db: db)

        // Pure matcher (Req 5.4, 7.x).
        let matcher = IngredientMatchingService(acneRepo: acneRepo)

        // Real acne profile, read-only from scan history (Req 8).
        let profile = AcneProfileProvider(
            latestRecordProvider: { scanHistoryStoreProvider?() }
        )

        // Persistence.
        let productRepo = SkincareProductRepository()

        let viewModel = SkincareViewModel(
            productRepo: productRepo,
            matcher: matcher,
            profile: profile
        )

        return SkincareView(
            viewModel: viewModel,
            ingredientRepo: cosingRepo,
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
