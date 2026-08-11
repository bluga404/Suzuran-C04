import SwiftUI

struct SkincareView: View {
    @ObservedObject var viewModel: SkincareViewModel
    let ingredientRepository: IngredientRepository
    let onDismiss: () -> Void

    @State private var isShowingAdd = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    
                    // User Active Acne Profile Information
                    AppCard {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            HStack {
                                Image(systemName: "face.dashed")
                                    .foregroundStyle(AppColor.accentPrimary)
                                Text("Tipe Jerawat Aktif Anda")
                                    .font(AppTypography.bodyBold)
                                    .foregroundStyle(AppColor.textPrimary)
                            }
                            
                            if viewModel.activeAcneTypes.isEmpty {
                                Text("Tidak ada jerawat aktif terdeteksi.")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColor.textSecondary)
                            } else {
                                HStack(spacing: AppSpacing.xs) {
                                    ForEach(viewModel.activeAcneTypes) { type in
                                        Text(type.displayName)
                                            .font(.system(size: 11, weight: .bold))
                                            .padding(.horizontal, AppSpacing.sm)
                                            .padding(.vertical, 4)
                                            .background(AppColor.accentPrimary.opacity(0.08))
                                            .foregroundStyle(AppColor.accentPrimary)
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(.top, 4)
                            }
                            
                            Text("Berdasarkan hasil pemindaian wajah terakhir. Kandungan skincare Anda akan disesuaikan dengan tipe jerawat di atas.")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColor.textSecondary)
                                .padding(.top, 4)
                        }
                    }
                    
                    // Skincare List Section
                    if viewModel.products.isEmpty {
                        VStack(spacing: AppSpacing.md) {
                            Spacer(minLength: 40)
                            
                            ZStack {
                                Circle()
                                    .fill(AppColor.accentPrimary.opacity(0.05))
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "bubbles.and.sparkles")
                                    .font(.system(size: 40))
                                    .foregroundStyle(AppColor.accentPrimary)
                            }
                            
                            Text("Belum Ada Catatan Skincare")
                                .font(AppTypography.subtitle)
                                .foregroundStyle(AppColor.textPrimary)
                            
                            Text("Catat produk skincare yang Anda gunakan saat ini untuk menganalisis kesesuaian bahan aktifnya dengan kondisi jerawat Anda.")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColor.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, AppSpacing.lg)
                            
                            Button(action: {
                                isShowingAdd = true
                            }) {
                                Text("Catat Skincare Pertama")
                                    .font(AppTypography.bodyBold)
                                    .padding(.horizontal, AppSpacing.lg)
                                    .padding(.vertical, AppSpacing.sm)
                                    .background(AppColor.accentPrimary)
                                    .foregroundStyle(.white)
                                    .cornerRadius(AppCornerRadius.md)
                            }
                            .padding(.top, AppSpacing.sm)
                            
                            Spacer(minLength: 40)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.xl)
                    } else {
                        let activeProducts = viewModel.products.filter { $0.isUsedCurrently }
                        let inactiveProducts = viewModel.products.filter { !$0.isUsedCurrently }
                        
                        if !activeProducts.isEmpty {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text("Sedang Digunakan (\(activeProducts.count))")
                                    .font(AppTypography.bodyBold)
                                    .foregroundStyle(AppColor.textPrimary)
                                
                                ForEach(activeProducts) { product in
                                    NavigationLink(
                                        destination: SkincareDetailView(
                                            skincareViewModel: viewModel,
                                            ingredientRepository: ingredientRepository,
                                            product: product
                                        )
                                    ) {
                                        SkincareCard(
                                            product: product,
                                            recommendationsCount: viewModel.getRecommendations(for: product).count,
                                            onTap: {}
                                        )
                                    }
                                }
                            }
                        }
                        
                        if !inactiveProducts.isEmpty {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text("Riwayat Produk Lain (\(inactiveProducts.count))")
                                    .font(AppTypography.bodyBold)
                                    .foregroundStyle(AppColor.textSecondary)
                                
                                ForEach(inactiveProducts) { product in
                                    NavigationLink(
                                        destination: SkincareDetailView(
                                            skincareViewModel: viewModel,
                                            ingredientRepository: ingredientRepository,
                                            product: product
                                        )
                                    ) {
                                        SkincareCard(
                                            product: product,
                                            recommendationsCount: viewModel.getRecommendations(for: product).count,
                                            onTap: {}
                                        )
                                    }
                                }
                            }
                            .padding(.top, AppSpacing.sm)
                        }
                    }
                }
                .padding(AppSpacing.md)
            }
            .background(AppColor.backgroundPrimary)
            .navigationTitle("Catatan Skincare")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onDismiss) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Kembali")
                        }
                        .font(AppTypography.bodyBold)
                        .foregroundStyle(AppColor.accentPrimary)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        isShowingAdd = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(AppColor.accentPrimary)
                    }
                }
            }
            .sheet(isPresented: $isShowingAdd) {
                AddSkincareView(
                    skincareViewModel: viewModel,
                    ingredientRepository: ingredientRepository
                )
            }
            .onAppear {
                viewModel.loadData()
            }
        }
    }
}
