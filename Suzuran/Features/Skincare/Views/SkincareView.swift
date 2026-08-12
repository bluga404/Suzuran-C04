import SwiftUI

struct SkincareView: View {
    @ObservedObject var viewModel: SkincareViewModel
    let ingredientRepo: IngredientRepositoryProtocol
    /// Retained for `SkincareFactory.makeView(onDismiss:)` source compatibility.
    let onDismiss: () -> Void

    @State private var isShowingAdd = false
    @State private var productToEdit: SkincareProduct?
    @State private var isShowingMatchedList = false
    @State private var selectedMatched: MatchedIngredient?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.products.isEmpty {
                    EmptySkincareView(onAdd: { isShowingAdd = true })
                } else {
                    productContent
                }
            }
            .navigationTitle(ScreenTitle.skincare.title)
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                if !viewModel.products.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { isShowingAdd = true }) {
                            Image(systemName: "plus")
                                .font(Font.description)
                                .foregroundStyle(AppColor.accentPrimary)
                                .frame(minWidth: 44, minHeight: 44)
                        }
                        .accessibilityLabel(Text(SkincareStrings.addSkincare))
                    }
                }
            }
            .sheet(isPresented: $isShowingAdd) {
                AddSkincareView(
                    skincareViewModel: viewModel,
                    ingredientRepo: ingredientRepo,
                    makeViewModel: { SkincareFactory.makeAddSkincareViewModel(editing: nil) }
                )
            }
            .sheet(item: $productToEdit) { product in
                AddSkincareView(
                    skincareViewModel: viewModel,
                    ingredientRepo: ingredientRepo,
                    makeViewModel: { SkincareFactory.makeAddSkincareViewModel(editing: product) }
                )
            }
            .navigationDestination(isPresented: $isShowingMatchedList) {
                MatchedIngredientListView(matched: viewModel.matchedIngredients)
            }
            .sheet(item: $selectedMatched) { matched in
                IngredientDetailView(recommendation: matched.recommendation)
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
                
                Text(SkincareStrings.currentSkincare)
                    .font(Font.description)
                    .foregroundStyle(AppColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
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
                Text(SkincareStrings.savedProducts)
                    .font(Font.metadata)
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
                Label(SkincareStrings.addNewSkincare, systemImage: "plus")
                    .font(Font.description)
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
    }

    @ViewBuilder
    private var matchPreview: some View {
        if !viewModel.activeAcneTypes.isEmpty {
            if viewModel.matchedIngredients.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Ingredient yang Cocok")
                        .font(Font.description)
                        .foregroundStyle(AppColor.textPrimary)
                    MatchedIngredientEmptyState()
                }
            } else {
                MatchedIngredientSection(
                    matched: viewModel.matchedIngredients,
                    onSelect: { selectedMatched = $0 },
                    onShowAll: { isShowingMatchedList = true }
                )
            }
        }
    }

    private func productRow(_ product: SkincareProduct) -> some View {
        ZStack {
            SkincareCard(
                product: product,
                recommendationsCount: viewModel.matchedIngredients(in: product).count,
                onEdit: { productToEdit = product }
            )
            NavigationLink(destination: SkincareDetailView(
                skincareViewModel: viewModel,
                ingredientRepo: ingredientRepo,
                product: product
            )) {
                EmptyView()
            }
            .opacity(0)
        }
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
