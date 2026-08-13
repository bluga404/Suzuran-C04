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

    // MARK: - Draft (isolated form state, Req 15)

    @Published var draft: SkincareDraft

    /// OCR review buffer. Holds candidate names that are NOT yet committed to the
    /// draft (Req 4.3, 12.2). Committed to `draft.ingredients` via ``commitReview()``.
    @Published var scannedIngredients: [String] = []

    // MARK: - Granular loading flags (Req 19.3)

    @Published var isScanning = false
    @Published var isSearchingIngredient = false
    @Published var isSaving = false

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
    private let profile: AcneProfileProviding
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
        profile: AcneProfileProviding,
        logger: AppLogging
    ) {
        self.ocr = ocr
        self.ingredientRepo = ingredientRepo
        self.acneRepo = acneRepo
        self.productRepo = productRepo
        self.profile = profile
        self.logger = logger
        self.editingProductID = editingProduct?.id
        self.isEditing = editingProduct != nil
        self.draft = SkincareDraft(from: editingProduct)
    }

    // MARK: - Validation

    var isFormValid: Bool { draft.isValid }

    /// Whether the ingredient matches the user's active acne profile.
    func isMatched(_ reference: IngredientReference) -> Bool {
        let activeTypes = profile.getActiveAcneTypes()
        guard !activeTypes.isEmpty else { return false }
        let matchedTypes = acneRepo.matchedAcneTypes(for: reference.id, activeTypes: activeTypes)
        return !matchedTypes.isEmpty
    }

    // MARK: - Ingredient management (operates on draft only, Req 15.2)

    /// Adds an ingredient by raw name. Resolves to a canonical ``IngredientReference``
    /// via the cosing repository, falling back to a locally-derived reference when the
    /// name is not in the reference DB (Req 25.1). Deduplicates by Canonical_ID.
    func addIngredient(_ rawName: String) {
        let clean = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        let reference = ingredientRepo.find(byRawName: clean) ?? IngredientReference(fromRawName: clean)
        guard !draft.ingredients.contains(where: { $0.id == reference.id }) else { return }
        draft.ingredients.append(reference)
    }

    func removeIngredient(_ reference: IngredientReference) {
        draft.ingredients.removeAll { $0.id == reference.id }
    }

    func removeIngredient(at offsets: IndexSet) {
        draft.ingredients.remove(atOffsets: offsets)
    }

    // MARK: - Clear All (Req 18)

    /// Empties only the ingredient list, preserving name/brand/category
    /// (Req 18.3). Idempotent: calling it on an already-empty draft is a no-op
    /// (Req 18.4).
    func confirmClearAll() {
        guard !draft.ingredients.isEmpty else { return }
        draft.ingredients.removeAll()
    }

    // MARK: - OCR (Req 19.3, 19.4, 19.5)

    /// Runs OCR + parsing on the captured image, populating `scannedIngredients`
    /// for review. Failures surface a localized ``SkincareError/ocrFailed`` message.
    func processImage(_ image: UIImage) async {
        isScanning = true
        errorMessage = nil
        defer { isScanning = false }
        do {
            let text = try await ocr.recognizeText(from: image)
            let parsed = IngredientParser.extractIngredients(from: text)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0.count > 1 }
            scannedIngredients = parsed
        } catch {
            errorMessage = SkincareError.ocrFailed.errorDescription
            logger.error("[Skincare] OCR failed: \(error)")
        }
    }

    /// Adds a manually-typed candidate to the review buffer (case-insensitive dedupe).
    func addScannedIngredient(_ rawName: String) {
        let clean = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        guard !scannedIngredients.contains(where: { $0.caseInsensitiveCompare(clean) == .orderedSame }) else { return }
        scannedIngredients.append(clean)
    }

    func removeScannedIngredient(_ name: String) {
        scannedIngredients.removeAll { $0 == name }
    }

    func removeScannedIngredient(at offsets: IndexSet) {
        scannedIngredients.remove(atOffsets: offsets)
    }

    /// Commits the reviewed candidates into the draft, then clears the buffer.
    func commitReview() {
        for name in scannedIngredients {
            addIngredient(name)
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
