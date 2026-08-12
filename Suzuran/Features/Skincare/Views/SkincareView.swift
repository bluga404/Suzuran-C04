import SwiftUI

struct SkincareView: View {
    @ObservedObject var viewModel: SkincareViewModel
    let ingredientRepo: IngredientRepositoryProtocol
    /// Retained for `SkincareFactory.makeView(onDismiss:)` source compatibility.
    let onDismiss: () -> Void

    @State private var isShowingAdd = false
    @State private var isShowingMatchedList = false
    @State private var isShowingSkincareList = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.products.isEmpty {
                    EmptySkincareView(onAdd: { isShowingAdd = true })
                } else {
                    productContent
                }
            }
            .background(AppColor.backgroundPrimary)
            .navigationTitle("Skincare")
            .toolbarTitleDisplayMode(.inlineLarge)
            .navigationDestination(isPresented: $isShowingAdd) {
                AddSkincareView(
                    skincareViewModel: viewModel,
                    ingredientRepo: ingredientRepo,
                    makeViewModel: { SkincareFactory.makeAddSkincareViewModel(editing: nil) }
                )
            }
            .navigationDestination(isPresented: $isShowingMatchedList) {
                MatchedIngredientListView(matched: viewModel.matchedIngredients)
            }
            .navigationDestination(isPresented: $isShowingSkincareList) {
                SkincareListView(viewModel: viewModel, ingredientRepo: ingredientRepo)
            }
            .alert(item: $viewModel.alert, content: makeAlert)
            .alert(
                "Terjadi Kesalahan",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .onAppear { viewModel.loadData() }
        }
    }

    // MARK: - Content

    private var productContent: some View {
        List {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                matchPreview
                
                HStack {
                    Text("Skincare Saat Ini")
                        .font(AppTypography.bodyBold)
                        .foregroundStyle(AppColor.textPrimary)
                        .accessibilityAddTraits(.isHeader)

                    Spacer()

                    Button("See Detail") {
                        isShowingSkincareList = true
                    }
                    .font(AppTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColor.accentPrimary)
                    .frame(minHeight: 44)
                    .buttonStyle(.plain)
                }
            }
            .listRowInsets(EdgeInsets(top: AppSpacing.md, leading: AppSpacing.md, bottom: AppSpacing.sm, trailing: AppSpacing.md))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            let previewProducts = viewModel.products.prefix(3)
            ForEach(previewProducts) { product in
                SkincareCard(
                    product: product,
                    recommendationsCount: 0,
                    onEdit: nil
                )
                .listRowInsets(EdgeInsets(top: AppSpacing.xs, leading: AppSpacing.md, bottom: AppSpacing.xs, trailing: AppSpacing.md))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    @ViewBuilder
    private var matchPreview: some View {
        if !viewModel.activeAcneTypes.isEmpty {
            if viewModel.matchedIngredients.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Ingredient yang Cocok")
                        .font(AppTypography.bodyBold)
                        .foregroundStyle(AppColor.textPrimary)
                    MatchedIngredientEmptyState()
                }
            } else {
                MatchedIngredientSection(
                    matched: viewModel.matchedIngredients,
                    onShowAll: { isShowingMatchedList = true }
                )
            }
        }
    }



    // MARK: - Delete confirmation

    private func makeAlert(_ alert: SkincareAlert) -> Alert {
        switch alert {
        case .deleteProduct(let product):
            Alert(
                title: Text("Hapus Produk"),
                message: Text("Hapus \"\(product.name)\" dari catatan skincare Anda?"),
                primaryButton: .destructive(Text("Hapus")) { viewModel.confirmDelete(product) },
                secondaryButton: .cancel(Text("Batal"))
            )
        case .deleteLastProduct(let product):
            Alert(
                title: Text("Hapus Produk Terakhir"),
                message: Text("\"\(product.name)\" adalah produk terakhir. Menghapusnya akan mengembalikan halaman ke kondisi kosong."),
                primaryButton: .destructive(Text("Hapus")) { viewModel.confirmDelete(product) },
                secondaryButton: .cancel(Text("Batal"))
            )
        case .saveEmpty:
            Alert(title: Text(""))
        }
    }
}

#Preview {
    SkincareFactory.makeView()
}
