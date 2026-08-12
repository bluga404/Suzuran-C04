import SwiftUI

struct AddSkincareView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var skincareViewModel: SkincareViewModel
    @StateObject private var viewModel: AddSkincareViewModel

    @State private var isShowingSearch = false
    @State private var isShowingScanInstruction = false
    @State private var isShowingScanner = false

    private let ingredientRepository: CosingIngredientRepository
    private let acneRepository: AcneIngredientRepository
    private let isEditing: Bool
    private let isPendingFlow: Bool
    private let onSave: (() -> Void)?

    init(
        skincareViewModel: SkincareViewModel,
        ingredientRepository: CosingIngredientRepository,
        acneRepository: AcneIngredientRepository,
        editingProduct: SkincareProduct? = nil,
        isPendingFlow: Bool = true,
        onSave: (() -> Void)? = nil
    ) {
        self.skincareViewModel = skincareViewModel
        self.ingredientRepository = ingredientRepository
        self.acneRepository = acneRepository
        self.isEditing = editingProduct != nil
        self.isPendingFlow = isPendingFlow
        self.onSave = onSave
        self._viewModel = StateObject(wrappedValue: AddSkincareViewModel(editingProduct: editingProduct))
    }

    var body: some View {
        Form {
            Section("Category") {
                Picker("Kategori", selection: $viewModel.category) {
                    ForEach(SkincareCategory.allCases) { cat in
                        Text(cat.displayName).tag(cat)
                    }
                }
                .pickerStyle(.menu)
                .font(AppTypography.body)
            }
            
            Section("Product Name") {
                TextField("Nama Produk", text: $viewModel.name)
                    .font(AppTypography.body)
            }
            
            Section(header: HStack {
                Text("Ingredients")
                Spacer()
                if !viewModel.ingredients.isEmpty {
                    Button("Clear All") {
                        viewModel.clearAllIngredients()
                    }
                    .textCase(.none)
                    .foregroundStyle(.red)
                }
            }) {
                Button(action: {
                    isShowingScanner = true
                }) {
                    VStack(spacing: AppSpacing.sm) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 32))
                        Text("Scan Ingredients")
                            .font(AppTypography.bodyBold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.lg)
                    .background(AppColor.surfacePrimary)
                    .foregroundStyle(AppColor.accentPrimary)
                    .cornerRadius(AppCornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppCornerRadius.md)
                            .stroke(AppColor.accentPrimary, style: StrokeStyle(lineWidth: 1, dash: [5]))
                    )
                }
                .listRowBackground(Color.clear)
                .padding(.bottom, AppSpacing.xs)
                
                if !viewModel.ingredients.isEmpty {
                    Button(action: {
                        isShowingSearch = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Tambah Manual")
                        }
                        .font(AppTypography.bodyBold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                        .background(AppColor.surfacePrimary)
                        .foregroundStyle(AppColor.accentPrimary)
                        .cornerRadius(AppCornerRadius.md)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .padding(.bottom, AppSpacing.sm)
                }
                
                if viewModel.ingredients.isEmpty {
                    Text("Belum ada bahan ditambahkan.")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textSecondary)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120, maximum: 200), spacing: 8)], spacing: 8) {
                        ForEach(viewModel.ingredients) { ingredient in
                            let rec = acneRepository.getRecommendation(for: ingredient.normalizedName)
                            let isMatched = rec != nil
                            
                            IngredientChip(
                                name: ingredient.name,
                                isMatched: isMatched,
                                onDelete: {
                                    viewModel.removeIngredient(ingredient)
                                }
                            )
                        }
                    }
                    .padding(.vertical, AppSpacing.xs)
                }
            }
            
            Section {
                Button(action: {
                    if isPendingFlow {
                        viewModel.saveToPending(to: skincareViewModel)
                        onSave?()
                    } else {
                        viewModel.saveProduct(to: skincareViewModel)
                        dismiss()
                    }
                }) {
                    Text("Simpan Skincare")
                        .font(AppTypography.bodyBold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .foregroundStyle(.white)
                }
                .listRowBackground(viewModel.isFormValid ? AppColor.accentPrimary : AppColor.textSecondary.opacity(0.5))
                .disabled(!viewModel.isFormValid)
            }
            }
            .background(AppColor.backgroundPrimary)
            .navigationTitle(isEditing ? "Edit Skincare" : "Add Skincare")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Toolbar items removed
            }
            // Sheets
            .sheet(isPresented: $isShowingSearch) {
                IngredientSearchView(repository: ingredientRepository) { name in
                    viewModel.addIngredient(name)
                }
            }
            .sheet(isPresented: $isShowingScanInstruction) {
                ScanInstructionView {
                    isShowingScanner = true
                }
            }
            .fullScreenCover(isPresented: $isShowingScanner) {
                IngredientScanView(viewModel: viewModel, repository: ingredientRepository)
            }
    }
}

#Preview {
    AddSkincareView(
        skincareViewModel: SkincareViewModel(
            skincareRepository: SkincareProductRepository(),
            acneRepository: AcneIngredientRepository(),
            acneProfileProvider: AcneProfileProvider(historyStore: ScanHistoryStore())
        ),
        ingredientRepository: CosingIngredientRepository(),
        acneRepository: AcneIngredientRepository()
    )
}
