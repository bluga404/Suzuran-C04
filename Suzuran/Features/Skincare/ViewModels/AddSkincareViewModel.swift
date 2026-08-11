import SwiftUI
import Combine

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

    init(editingProduct: SkincareProduct? = nil) {
        self.editingProduct = editingProduct
        if let product = editingProduct {
            self.name = product.name
            self.brand = product.brand
            self.category = product.category
            self.ingredients = product.ingredients
            self.isUsedCurrently = product.isUsedCurrently
        }
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

    func addIngredient(_ ingredientName: String) {
        let cleanName = ingredientName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }
        
        // Avoid duplicate case-insensitive ingredients
        if !ingredients.contains(where: { $0.normalizedName == cleanName.lowercased() }) {
            ingredients.append(IngredientReference(name: cleanName))
        }
    }

    func removeIngredient(at offsets: IndexSet) {
        ingredients.remove(atOffsets: offsets)
    }

    func removeIngredient(_ ingredient: IngredientReference) {
        ingredients.removeAll { $0.id == ingredient.id }
    }
    
    func clearAllIngredients() {
        ingredients.removeAll()
    }

    func processImageForOCR(_ image: UIImage) async {
        isProcessingOCR = true
        errorMessage = nil
        do {
            let text = try await ocrService.recognizeText(from: image)
            self.scannedIngredients = parser.extractIngredients(from: text)
        } catch {
            self.errorMessage = SkincareError.ocrFailed.localizedDescription
        }
        isProcessingOCR = false
    }

    func commitScannedIngredients() {
        for result in scannedIngredients {
            addIngredient(result.rawText)
        }
        scannedIngredients.removeAll()
    }
}
