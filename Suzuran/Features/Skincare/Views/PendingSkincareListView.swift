import SwiftUI

struct PendingSkincareListView: View {
    @ObservedObject var viewModel: SkincareViewModel
    let ingredientRepository: CosingIngredientRepository
    let acneRepository: AcneIngredientRepository
    @Binding var navPath: NavigationPath
    @State private var showingBackAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            List {
                ForEach(Array(viewModel.pendingProducts.enumerated()), id: \.element.id) { index, product in
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
                                    viewModel.deletePendingProduct(id: product.id)
                                }
                            } label: {
                                Label("Hapus", systemImage: "trash")
                            }
                        }
                    } header: {
                        if index == 0 {
                            Text("Skincare List (\(viewModel.pendingProducts.count))")
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppColor.backgroundPrimary)
            
            // Bottom Action Buttons
            VStack(spacing: AppSpacing.sm) {
                Button(action: {
                    navPath.append(SkincareRoute.add)
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Another Skincare")
                    }
                    .font(AppTypography.bodyBold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm)
                    .background(AppColor.surfacePrimary)
                    .foregroundStyle(AppColor.accentPrimary)
                    .cornerRadius(AppCornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppCornerRadius.md)
                            .stroke(AppColor.accentPrimary, lineWidth: 1)
                    )
                }
                
                Button(action: {
                    viewModel.saveAllPending()
                    navPath = NavigationPath()
                }) {
                    Text("Save All Skincare")
                        .font(AppTypography.bodyBold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                        .background(AppColor.accentPrimary)
                        .foregroundStyle(.white)
                        .cornerRadius(AppCornerRadius.md)
                }
            }
            .padding(AppSpacing.md)
            .background(AppColor.backgroundPrimary)
        }
        .navigationTitle("Your Skincare")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    showingBackAlert = true
                }) {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                }
            }
        }
        .alert("Batalkan Penyimpanan?", isPresented: $showingBackAlert) {
            Button("Kembali Edit", role: .cancel) { }
            Button("Hapus Semua", role: .destructive) {
                viewModel.pendingProducts.removeAll()
                navPath = NavigationPath()
            }
        } message: {
            Text("Semua produk yang sudah ditambahkan akan dihapus.")
        }
    }
    
    
    // deletePending is no longer needed since we use swipeActions directly
}
