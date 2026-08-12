import SwiftUI

struct ManageSkincareListView: View {
    @ObservedObject var viewModel: SkincareViewModel
    let ingredientRepository: CosingIngredientRepository
    let acneRepository: AcneIngredientRepository
    @Binding var navPath: NavigationPath
    
    var body: some View {
        VStack(spacing: 0) {
            let activeProducts = viewModel.products.filter { $0.isUsedCurrently }
            
            if activeProducts.isEmpty {
                Spacer()
                Text("Tidak ada skincare yang sedang digunakan.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textSecondary)
                Spacer()
            } else {
                List {
                    ForEach(Array(activeProducts.enumerated()), id: \.element.id) { index, product in
                        Section {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(product.name)
                                        .font(AppTypography.bodyBold)
                                        .foregroundStyle(AppColor.textPrimary)
                                    
                                    Text(product.category.displayName)
                                        .font(AppTypography.caption)
                                        .foregroundStyle(AppColor.textSecondary)
                                    
                                    Text("\(product.ingredients.count) ingredients")
                                        .font(AppTypography.caption)
                                        .foregroundStyle(AppColor.textSecondary)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    navPath.append(SkincareRoute.edit(product))
                                }) {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 16))
                                        .foregroundStyle(AppColor.accentPrimary)
                                        .padding(8)
                                        .background(AppColor.accentPrimary.opacity(0.08))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 4)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation {
                                        viewModel.deleteProduct(id: product.id)
                                    }
                                } label: {
                                    Label("Hapus", systemImage: "trash")
                                }
                            }
                        } header: {
                            if index == 0 {
                                Text("Sedang Digunakan (\(activeProducts.count))")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(AppColor.backgroundPrimary)
            }
        }
        .navigationTitle("Manage Skincare")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    navPath.removeLast()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                }
            }
        }
    }
}
