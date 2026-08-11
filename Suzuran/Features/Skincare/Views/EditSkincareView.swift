import SwiftUI

struct EditSkincareView: View {
    @ObservedObject var skincareViewModel: SkincareViewModel
    let ingredientRepository: IngredientRepository
    let product: SkincareProduct

    var body: some View {
        AddSkincareView(
            skincareViewModel: skincareViewModel,
            ingredientRepository: ingredientRepository,
            editingProduct: product
        )
    }
}
