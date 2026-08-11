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
                    .font(AppTypography.title)
                    .foregroundStyle(AppColor.textPrimary)
                
                Text("Berikut adalah bahan-bahan yang berhasil dideteksi. Anda dapat menghapus yang kurang tepat atau menambahkan yang terlewat.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .padding(AppSpacing.md)
            .background(AppColor.surfacePrimary)
            
            // Add Missing Ingredient Inline Bar
            HStack(spacing: AppSpacing.sm) {
                TextField("Tambah kandungan manual...", text: $newIngredientName)
                    .font(AppTypography.body)
                    .padding(AppSpacing.sm)
                    .background(AppColor.backgroundPrimary)
                    .cornerRadius(AppCornerRadius.sm)
                
                Button(action: addScannedIngredient) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .padding(AppSpacing.sm)
                        .background(AppColor.accentPrimary)
                        .foregroundStyle(.white)
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
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textSecondary)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(viewModel.scannedIngredients, id: \.self) { ingredient in
                        HStack {
                            Text(ingredient.rawText)
                                .font(AppTypography.body)
                                .foregroundStyle(AppColor.textPrimary)
                            
                            Spacer()
                            
                            Button(action: {
                                viewModel.scannedIngredients.removeAll { $0 == ingredient }
                            }) {
                                Image(systemName: "trash")
                                    .foregroundStyle(AppColor.accentDanger)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .onDelete { offsets in
                        viewModel.scannedIngredients.remove(atOffsets: offsets)
                    }
                }
            }
            .listStyle(.plain)

            // Save Action
            VStack {
                Button(action: {
                    viewModel.commitScannedIngredients()
                    onSave()
                }) {
                    Text("Gunakan Kandungan Ini (\(viewModel.scannedIngredients.count))")
                        .font(AppTypography.bodyBold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColor.accentPrimary)
                        .foregroundStyle(.white)
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
        let trimmed = newIngredientName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if !viewModel.scannedIngredients.contains(where: { $0.rawText.lowercased() == trimmed.lowercased() }) {
            viewModel.scannedIngredients.append(OCRIngredientResult(rawText: trimmed))
        }
        newIngredientName = ""
    }
}
