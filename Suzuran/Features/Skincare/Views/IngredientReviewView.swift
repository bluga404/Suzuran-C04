import SwiftUI

struct IngredientReviewView: View {
    @ObservedObject var viewModel: AddSkincareViewModel
    let onSave: () -> Void

    @State private var newIngredientName = ""

    var body: some View {
        VStack(spacing: 0) {
            // Instructions
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Tinjau Hasil Pindaian")
                    .font(Font.screenTitle)
                    .foregroundStyle(AppColor.textPrimary)
                
                Text("Berikut adalah bahan-bahan yang berhasil dideteksi. Anda dapat menghapus yang kurang tepat atau menambahkan yang terlewat.")
                    .font(Font.description)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .padding(AppSpacing.md)
            .background(AppColor.surfacePrimary)
            
            // Add Missing Ingredient Inline Bar
            HStack(spacing: AppSpacing.sm) {
                TextField("Tambah kandungan manual...", text: $newIngredientName)
                    .font(Font.description)
                    .padding(AppSpacing.sm)
                    .background(AppColor.backgroundPrimary)
                    .cornerRadius(AppCornerRadius.sm)
                
                Button(action: addScannedIngredient) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .padding(AppSpacing.sm)
                        .background(AppColor.accentPrimary)
                        .foregroundStyle(AppColor.textOnAccent)
                        .cornerRadius(AppCornerRadius.sm)
                }
            }
            .padding(AppSpacing.md)
            .background(AppColor.surfacePrimary)
            
            Divider()

            // List of Scanned Ingredients
            List {
                if viewModel.scannedIngredients.isEmpty {
                    Text("Belum ada kandungan terdeteksi. Silakan tambah manual di atas.")
                        .font(Font.metadata)
                        .foregroundStyle(AppColor.textSecondary)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(viewModel.scannedIngredients, id: \.self) { ingredient in
                        HStack {
                            Text(ingredient)
                                .font(Font.description)
                                .foregroundStyle(AppColor.textPrimary)
                            
                            Spacer()
                            
                            Button(action: {
                                viewModel.removeScannedIngredient(ingredient)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundStyle(AppColor.accentDanger)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .onDelete { offsets in
                        viewModel.removeScannedIngredient(at: offsets)
                    }
                }
            }
            .listStyle(.plain)

            // Save Action
            VStack {
                Button(action: {
                    viewModel.commitReview()
                    onSave()
                }) {
                    Text("Gunakan Kandungan Ini (\(viewModel.scannedIngredients.count))")
                        .font(Font.description)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColor.accentPrimary)
                        .foregroundStyle(AppColor.textOnAccent)
                        .cornerRadius(AppCornerRadius.md)
                }
                .padding(AppSpacing.md)
            }
            .background(AppColor.surfacePrimary)
            .border(AppColor.borderSubtle, width: 0.5)
        }
        .background(AppColor.backgroundPrimary)
        .navigationTitle("Tinjau Bahan")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func addScannedIngredient() {
        viewModel.addScannedIngredient(newIngredientName)
        newIngredientName = ""
    }
}
