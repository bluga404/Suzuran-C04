import SwiftUI
import Combine

@MainActor
final class AddSkincareViewModel: ObservableObject {
    // Form fields
    @Published var name = ""
    @Published var brand = ""
    @Published var category = "Moisturizer"
    @Published var ingredients: [String] = []
    @Published var isUsedCurrently = true

    // OCR scanning fields
    @Published var isProcessingOCR = false
    @Published var errorMessage: String?
    @Published var scannedIngredients: [String] = []

    let categories = ["Cleanser", "Toner", "Serum", "Moisturizer", "Sunscreen", "Face Mask", "Other"]

    private let ocrService = IngredientOCRService()
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
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !brand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func saveProduct(to viewModel: SkincareViewModel) {
        let trimmedIngredients = ingredients.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        if let editingProduct = editingProduct {
            var updated = editingProduct
            updated.name = name
            updated.brand = brand
            updated.category = category
            updated.ingredients = trimmedIngredients
            updated.isUsedCurrently = isUsedCurrently
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
        if !ingredients.contains(where: { $0.caseInsensitiveCompare(cleanName) == .orderedSame }) {
            ingredients.append(cleanName)
        }
    }

    func removeIngredient(at offsets: IndexSet) {
        ingredients.remove(atOffsets: offsets)
    }

    func removeIngredient(_ name: String) {
        ingredients.removeAll { $0.caseInsensitiveCompare(name) == .orderedSame }
    }

    func processImageForOCR(_ image: UIImage) async {
        isProcessingOCR = true
        errorMessage = nil
        do {
            let text = try await ocrService.recognizeText(from: image)
            let parsed = IngredientParser.extractIngredients(from: text)
            
            let cleanParsed = parsed
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0.count > 1 }
                
            self.scannedIngredients = cleanParsed
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isProcessingOCR = false
    }

    func commitScannedIngredients() {
        for ingredient in scannedIngredients {
            addIngredient(ingredient)
        }
        scannedIngredients.removeAll()
    }
}
