import SwiftUI

struct MatchedResultView: View {
    @ObservedObject var viewModel: SkincareViewModel
    let acneRepository: AcneIngredientRepositoryProtocol
    @Binding var navPath: NavigationPath
    @State private var selectedRecommendation: SkincareIngredientRecommendation?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // Header
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(AppColor.accentPrimary)
                        
                        Text("Skincare Saved!")
                            .font(AppTypography.title)
                            .foregroundStyle(AppColor.textPrimary)
                    }
                    
                    Text("\(viewModel.products.count) skincare products saved successfully.")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.textSecondary)
                }
                .padding(.bottom, AppSpacing.sm)
                
                // Acne Profile
                if !viewModel.activeAcneTypes.isEmpty {
                    AppCard {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            HStack {
                                Image(systemName: "face.dashed")
                                    .foregroundStyle(AppColor.accentPrimary)
                                Text("Your Active Acne Types")
                                    .font(AppTypography.bodyBold)
                                    .foregroundStyle(AppColor.textPrimary)
                            }
                            
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
                        }
                    }
                }
                
                // Matched Ingredients
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Matched Ingredients")
                        .font(AppTypography.bodyBold)
                        .foregroundStyle(AppColor.textPrimary)
                    
                    Text("Ingredients in your skincare that match your acne condition.")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textSecondary)
                    
                    if viewModel.uniqueMatchedRecommendations.isEmpty {
                        AppCard {
                            HStack(spacing: AppSpacing.sm) {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(AppColor.textSecondary)
                                Text("No matching ingredients found. Try adding more products with active ingredients.")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColor.textSecondary)
                            }
                        }
                    } else {
                        ForEach(viewModel.uniqueMatchedRecommendations) { match in
                            RecommendationCard(match: match) {
                                selectedRecommendation = match.recommendation
                            }
                        }
                    }
                }
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.backgroundPrimary)
        .navigationTitle("Match Results")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    navPath = NavigationPath()
                }
                .font(AppTypography.bodyBold)
                .foregroundStyle(AppColor.accentPrimary)
            }
        }
        .sheet(item: $selectedRecommendation) { rec in
            IngredientDetailView(recommendation: rec)
        }
    }
}
