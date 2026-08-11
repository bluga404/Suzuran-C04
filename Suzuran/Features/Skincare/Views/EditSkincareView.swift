import SwiftUI

struct EditSkincareView: View {
    @ObservedObject var skincareViewModel: SkincareViewModel
    let ingredientRepository: CosingIngredientRepository
    let acneRepository: AcneIngredientRepository
    let product: SkincareProduct

    var body: some View {
        AddSkincareView(
            skincareViewModel: skincareViewModel,
            ingredientRepository: ingredientRepository,
            acneRepository: acneRepository,
            editingProduct: product
        )
    }
}
