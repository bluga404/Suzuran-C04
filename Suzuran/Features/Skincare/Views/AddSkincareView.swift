import SwiftUI

struct AddSkincareView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var skincareViewModel: SkincareViewModel
    @StateObject private var viewModel: AddSkincareViewModel

    @State private var isShowingSearch = false
    @State private var isShowingScanner = false

    private let ingredientRepository: SkincareIngredientRepository
    private let isEditing: Bool

    init(
        skincareViewModel: SkincareViewModel,
        ingredientRepository: SkincareIngredientRepository,
        editingProduct: SkincareProduct? = nil
    ) {
        self.skincareViewModel = skincareViewModel
        self.ingredientRepository = ingredientRepository
        self._viewModel = StateObject(wrappedValue: AddSkincareViewModel(editingProduct: editingProduct))
        self.isEditing = editingProduct != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Informasi Produk") {
                    TextField("Nama Produk (misal: Moisturizing Cream)", text: $viewModel.name)
                        .font(AppTypography.body)
                    
                    TextField("Merek / Brand (misal: CeraVe)", text: $viewModel.brand)
                        .font(AppTypography.body)
                    
                    Picker("Kategori", selection: $viewModel.category) {
                        ForEach(viewModel.categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    .font(AppTypography.body)
                    
                    Toggle("Sedang Digunakan saat Ini", isOn: $viewModel.isUsedCurrently)
                        .font(AppTypography.body)
                        .tint(AppColor.accentPrimary)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        HStack {
                            Text("Bahan Kandungan")
                                .font(AppTypography.bodyBold)
                                .foregroundStyle(AppColor.textPrimary)
                            
                            Spacer()
                            
                            Text("\(viewModel.ingredients.count) item")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColor.textSecondary)
                        }
                        
                        HStack(spacing: AppSpacing.sm) {
                            // Add via Search
                            Button(action: {
                                isShowingSearch = true
                            }) {
                                Label("Cari", systemImage: "magnifyingglass")
                                    .font(AppTypography.caption)
                                    .fontWeight(.bold)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(AppColor.surfacePrimary)
                                    .foregroundStyle(AppColor.accentPrimary)
                                    .cornerRadius(AppCornerRadius.sm)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                                            .stroke(AppColor.accentPrimary, lineWidth: 1)
                                    )
                            }
                            
                            // Add via Scanner
                            Button(action: {
                                isShowingScanner = true
                            }) {
                                Label("Pindai Label", systemImage: "doc.text.viewfinder")
                                    .font(AppTypography.caption)
                                    .fontWeight(.bold)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(AppColor.accentPrimary)
                                    .foregroundStyle(.white)
                                    .cornerRadius(AppCornerRadius.sm)
                            }
                        }
                        .padding(.vertical, 4)
                        
                        if viewModel.ingredients.isEmpty {
                            Text("Belum ada bahan ditambahkan. Klik Cari atau Pindai untuk mengisi.")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColor.textSecondary)
                                .padding(.vertical, AppSpacing.sm)
                        } else {
                            // Adaptive Grid of chips
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120, maximum: 200), spacing: 8)], spacing: 8) {
                                ForEach(viewModel.ingredients, id: \.self) { ingredient in
                                    let isMatched = ingredientRepository.getRecommendation(for: ingredient) != nil
                                    
                                    IngredientChip(name: ingredient, isMatched: isMatched) {
                                        viewModel.removeIngredient(ingredient)
                                    }
                                }
                            }
                            .padding(.vertical, AppSpacing.xs)
                        }
                    }
                }
            }
            .background(AppColor.backgroundPrimary)
            .navigationTitle(isEditing ? "Edit Skincare" : "Tambah Skincare")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Batal") {
                        dismiss()
                    }
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.accentPrimary)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Simpan") {
                        viewModel.saveProduct(to: skincareViewModel)
                        dismiss()
                    }
                    .font(AppTypography.bodyBold)
                    .foregroundStyle(AppColor.accentPrimary)
                    .disabled(!viewModel.isFormValid)
                }
            }
            // Sheets
            .sheet(isPresented: $isShowingSearch) {
                IngredientSearchView(repository: ingredientRepository) { name in
                    viewModel.addIngredient(name)
                }
            }
            .sheet(isPresented: $isShowingScanner) {
                IngredientScanView(viewModel: viewModel)
            }
        }
    }
}
