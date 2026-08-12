import SwiftUI

struct SkincareListView: View {
    @ObservedObject var viewModel: SkincareViewModel
    let ingredientRepo: IngredientRepositoryProtocol

    @State private var isShowingAdd = false
    @State private var productToEdit: SkincareProduct?

    var body: some View {
        List {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Your Current Skincare")
                    .font(AppTypography.bodyBold)
                    .foregroundStyle(AppColor.textPrimary)
                Text("You can edit or remove your current skincare product")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .listRowInsets(EdgeInsets(top: AppSpacing.md, leading: AppSpacing.md, bottom: AppSpacing.sm, trailing: AppSpacing.md))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            let activeProducts = viewModel.products.filter(\.isUsedCurrently)
            ForEach(activeProducts) { product in
                productRow(product)
            }

            let inactiveProducts = viewModel.products.filter { !$0.isUsedCurrently }
            if !inactiveProducts.isEmpty {
                Text("Produk Tersimpan")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .padding(.top, AppSpacing.xs)
                    .listRowInsets(EdgeInsets(top: AppSpacing.md, leading: AppSpacing.md, bottom: AppSpacing.xs, trailing: AppSpacing.md))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                ForEach(inactiveProducts) { product in
                    productRow(product)
                }
            }

            Button {
                isShowingAdd = true
            } label: {
                Label("Add New Skincare", systemImage: "plus")
                    .font(AppTypography.bodyBold)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)
            .tint(AppColor.accentPrimary)
            .listRowInsets(EdgeInsets(top: AppSpacing.md, leading: AppSpacing.md, bottom: AppSpacing.xl, trailing: AppSpacing.md))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppColor.backgroundPrimary)
        .navigationTitle("Skincare List")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $isShowingAdd) {
            AddSkincareView(
                skincareViewModel: viewModel,
                ingredientRepo: ingredientRepo,
                makeViewModel: { SkincareFactory.makeAddSkincareViewModel(editing: nil) }
            )
        }
        .navigationDestination(item: $productToEdit) { product in
            AddSkincareView(
                skincareViewModel: viewModel,
                ingredientRepo: ingredientRepo,
                makeViewModel: { SkincareFactory.makeAddSkincareViewModel(editing: product) }
            )
        }
    }

    private func productRow(_ product: SkincareProduct) -> some View {
        SkincareCard(
            product: product,
            recommendationsCount: viewModel.matchedIngredients(in: product).count,
            onEdit: { productToEdit = product }
        )
        .listRowInsets(EdgeInsets(top: AppSpacing.xs, leading: AppSpacing.md, bottom: AppSpacing.xs, trailing: AppSpacing.md))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                viewModel.requestDelete(product)
            } label: {
                Label("Hapus", systemImage: "trash")
            }
        }
    }
}
