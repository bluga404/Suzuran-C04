import SwiftUI

struct IngredientSearchView: View {
    @Environment(\.dismiss) private var dismiss
    let repository: IngredientRepositoryProtocol
    let onSelect: (String) -> Void
    
    @State private var query = ""
    @State private var results: [String] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AppColor.textSecondary)
                    
                    TextField("Cari kandungan (contoh: Niacinamide)", text: $query)
                        .font(Font.description)
                        .textFieldStyle(.plain)
                        .onChange(of: query) { _, newQuery in
                            performSearch(query: newQuery)
                        }
                    
                    if !query.isEmpty {
                        Button(action: { query = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(AppColor.textSecondary)
                        }
                    }
                }
                .padding(AppSpacing.sm)
                .background(AppColor.surfacePrimary)
                .cornerRadius(AppCornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.md)
                        .stroke(AppColor.borderSubtle, lineWidth: 1)
                )
                .padding(AppSpacing.md)
                
                // Search Results
                if !query.isEmpty {
                    List {
                        if !results.contains(where: { $0.caseInsensitiveCompare(query) == .orderedSame }) {
                            Button(action: {
                                onSelect(query)
                                dismiss()
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(AppColor.accentPrimary)
                                    Text("Tambah \"\(query)\"")
                                        .font(Font.description)
                                        .foregroundStyle(AppColor.accentPrimary)
                                }
                            }
                        }
                        
                        if results.isEmpty {
                            Text("Tidak ada hasil ditemukan")
                                .font(Font.metadata)
                                .foregroundStyle(AppColor.textSecondary)
                        } else {
                            ForEach(results, id: \.self) { ingredient in
                                Button(action: {
                                    onSelect(ingredient)
                                    dismiss()
                                }) {
                                    HStack {
                                        Text(ingredient)
                                            .font(Font.description)
                                            .foregroundStyle(AppColor.textPrimary)
                                        Spacer()
                                        Image(systemName: "plus")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(AppColor.accentPrimary)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                } else {
                    Spacer()
                }
            }
            .background(AppColor.backgroundPrimary)
            .navigationTitle("Cari Kandungan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Batal") {
                        dismiss()
                    }
                    .font(Font.description)
                    .foregroundStyle(AppColor.accentPrimary)
                }
            }
        }
    }

    private func performSearch(query: String) {
        results = repository.search(query: query).map { $0.name }
    }
}
