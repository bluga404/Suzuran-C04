import SwiftUI
import Combine

/// ViewModel for the Add / Edit Skincare form.
///
/// Owns an isolated ``SkincareDraft`` so that nothing touches the persisted
/// product list until the user taps Save (Req 15.1–15.4). All collaborators are
/// injected via protocol so the ViewModel is testable and constructed by
/// ``SkincareFactory`` (Req 5.5, 25.1).
///
/// Key behaviors:
/// - **Draft isolation**: mutations edit `draft` only; the repository is written
///   exactly once on a successful save (Req 15.2).
/// - **Save-empty confirmation**: saving a draft with no ingredients raises
///   `SkincareAlert.saveEmpty` instead of committing (Req 16.1).
/// - **Clear all**: `confirmClearAll()` empties only `draft.ingredients` and is
///   idempotent (Req 18.3, 18.4).
/// - **Granular loading**: `isScanning`, `isSearchingIngredient`, `isSaving`
///   reflect the active async operation (Req 19.3, 19.4).
///
@MainActor
final class AddSkincareViewModel: ObservableObject {
    // Form fields
    @Published var name = ""
    @Published var brand = ""
    @Published var category: SkincareCategory = .moisturizer
    @Published var ingredients: [IngredientReference] = []
    @Published var isUsedCurrently = true

    // OCR scanning fields
    @Published var isProcessingOCR = false
    @Published var isSearchingIngredient = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var scannedIngredients: [OCRIngredientResult] = []

    private let ocrService = IngredientOCRService()
    private let parser = IngredientParser()
    private let editingProduct: SkincareProduct?

    // MARK: - Alert & error

    /// Localized error surfaced to the user in Bahasa Indonesia (Req 19.5).
    @Published var errorMessage: String?

    /// Save-empty confirmation (Req 16.1). Owned by this ViewModel.
    @Published var alert: SkincareAlert?

    /// Set to `true` after a successful commit so the View can dismiss itself.
    @Published private(set) var didSave = false

    // MARK: - Dependencies (protocol-based, Req 5.5, 25.1)

    private let ocr: OCRServicing
    private let ingredientRepo: IngredientRepositoryProtocol
    private let acneRepo: AcneIngredientRepositoryProtocol
    private let productRepo: SkincareProductRepositoryProtocol
    private let logger: AppLogging

    private let editingProductID: UUID?
    let isEditing: Bool

    // MARK: - Init

    init(
        editingProduct: SkincareProduct? = nil,
        ocr: OCRServicing,
        ingredientRepo: IngredientRepositoryProtocol,
        acneRepo: AcneIngredientRepositoryProtocol,
        productRepo: SkincareProductRepositoryProtocol,
        logger: AppLogging
    ) {
        self.ocr = ocr
        self.ingredientRepo = ingredientRepo
        self.acneRepo = acneRepo
        self.productRepo = productRepo
        self.logger = logger
        self.editingProductID = editingProduct?.id
        self.isEditing = editingProduct != nil
        self.draft = SkincareDraft(from: editingProduct)
    }

    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func saveProduct(to viewModel: SkincareViewModel) {
        isSaving = true
        defer { isSaving = false }
        
        let trimmedIngredients = ingredients
        if let editingProduct = editingProduct {
            var updated = editingProduct
            updated.name = name
            updated.brand = brand
            updated.category = category
            updated.ingredients = trimmedIngredients
            updated.isUsedCurrently = isUsedCurrently
            updated.updatedAt = Date()
            viewModel.updateProduct(updated)
        } else {
            let newProduct = SkincareProduct(
                name: name,
                brand: brand,
                category: category,
                ingredients: trimmedIngredients,
                isUsedCurrently: isUsedCurrently
            )
            viewModel.addProduct(newProduct)
        }
    }

    func saveToPending(to viewModel: SkincareViewModel) {
        isSaving = true
        defer { isSaving = false }

        let trimmedIngredients = ingredients
        if let editingProduct = editingProduct {
            var updated = editingProduct
            updated.name = name
            updated.brand = brand
            updated.category = category
            updated.ingredients = trimmedIngredients
            updated.isUsedCurrently = isUsedCurrently
            updated.updatedAt = Date()
            viewModel.updatePendingProduct(updated)
        } else {
            let newProduct = SkincareProduct(
                name: name,
                brand: brand,
                category: category,
                ingredients: trimmedIngredients,
                isUsedCurrently: isUsedCurrently
            )
            viewModel.addPendingProduct(newProduct)
        }
    }

    func addIngredient(_ ingredientName: String) {
        let cleanName = ingredientName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }
        
        // Avoid duplicate case-insensitive ingredients
        if !ingredients.contains(where: { $0.normalizedName == cleanName.lowercased() }) {
            ingredients.append(IngredientReference(name: cleanName))
        }
    }

    func removeIngredient(at offsets: IndexSet) {
        draft.ingredients.remove(atOffsets: offsets)
    }

    func removeIngredient(_ ingredient: IngredientReference) {
        ingredients.removeAll { $0.id == ingredient.id }
    }
    
    func clearAllIngredients() {
        ingredients.removeAll()
    }

    // MARK: - OCR (Req 19.3, 19.4, 19.5)

    /// Runs OCR + parsing on the captured image, populating `scannedIngredients`
    /// for review. Failures surface a localized ``SkincareError/ocrFailed`` message.
    func processImage(_ image: UIImage) async {
        isScanning = true
        errorMessage = nil
        defer { isScanning = false }
        do {
            let text = try await ocrService.recognizeText(from: image)
            self.scannedIngredients = parser.extractIngredients(from: text)
        } catch {
            self.errorMessage = SkincareError.ocrFailed.localizedDescription
        }
    }

    func commitScannedIngredients() {
        for result in scannedIngredients {
            addIngredient(result.rawText)
        }
        scannedIngredients.removeAll()
    }

    // MARK: - Save (Req 15.4, 16.1, 16.3)

    /// Validates the draft and either raises the save-empty alert (empty ingredient
    /// list) or commits the product to the parent ViewModel.
    func save(into parent: SkincareViewModel) {
        guard draft.isValid else {
            errorMessage = SkincareError.validationFailed.errorDescription
            return
        }
        if draft.ingredients.isEmpty {
            alert = .saveEmpty(draft)      // Req 16.1
            return
        }
        commitSave(into: parent)
    }

    /// Called from the "Simpan Tetap" action of the save-empty alert (Req 16.3).
    func confirmSaveEmpty(into parent: SkincareViewModel) {
        commitSave(into: parent)
    }

    /// Single write-through to the repository (via the parent ViewModel), which
    /// reloads and recomputes matches. Sets `didSave` so the View can dismiss.
    private func commitSave(into parent: SkincareViewModel) {
        isSaving = true
        defer { isSaving = false }
        let product = draft.toProduct(existingID: editingProductID)
        if isEditing {
            parent.updateProduct(product)
        } else {
            parent.addProduct(product)
        }
        didSave = true
    }
}
