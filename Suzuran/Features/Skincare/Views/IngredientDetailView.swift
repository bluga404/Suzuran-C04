import SwiftUI

struct IngredientDetailView: View {
    let recommendation: IngredientRecommendation
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    
                    // Header Section
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(recommendation.ingredientName)
                            .font(AppTypography.title)
                            .foregroundStyle(AppColor.textPrimary)
                        
                        if let alternatives = recommendation.alternativesName {
                            Text("Alias: \(alternatives)")
                                .font(AppTypography.body)
                                .foregroundStyle(AppColor.textSecondary)
                        }
                    }
                    .padding(.top, AppSpacing.sm)
                    
                    // Acne Types Treated
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Label("Target Tipe Jerawat", systemImage: "sparkles")
                            .font(AppTypography.bodyBold)
                            .foregroundStyle(AppColor.accentPrimary)
                        
                        Text(recommendation.acneTypes)
                            .font(AppTypography.body)
                            .foregroundStyle(AppColor.textPrimary)
                            .padding(AppSpacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColor.accentPrimary.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.md))
                    }
                    
                    Divider()
                    
                    // Description
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Deskripsi")
                            .font(AppTypography.bodyBold)
                            .foregroundStyle(AppColor.textPrimary)
                        
                        Text(recommendation.description)
                            .font(AppTypography.body)
                            .foregroundStyle(AppColor.textSecondary)
                            .lineSpacing(4)
                    }
                    
                    Divider()
                    
                    // Concentration & Usage
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Label("Konsentrasi & Penggunaan", systemImage: "slider.horizontal.3")
                            .font(AppTypography.bodyBold)
                            .foregroundStyle(AppColor.textPrimary)
                        
                        Text(recommendation.concentrationAndUsage)
                            .font(AppTypography.body)
                            .foregroundStyle(AppColor.textSecondary)
                            .lineSpacing(4)
                    }
                    
                    Divider()
                    
                    // Application
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Label("Metode Aplikasi", systemImage: "hand.tap")
                            .font(AppTypography.bodyBold)
                            .foregroundStyle(AppColor.textPrimary)
                        
                        Text(recommendation.application)
                            .font(AppTypography.body)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    
                    Divider()
                    
                    // Risks & Safety
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Label("Risiko & Keamanan", systemImage: "exclamationmark.triangle")
                            .font(AppTypography.bodyBold)
                            .foregroundStyle(AppColor.accentDanger)
                        
                        Text(recommendation.risksAndSafety)
                            .font(AppTypography.body)
                            .foregroundStyle(AppColor.textSecondary)
                            .lineSpacing(4)
                            .padding(AppSpacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColor.accentDanger.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppCornerRadius.md)
                                    .stroke(AppColor.accentDanger.opacity(0.2), lineWidth: 1)
                            )
                    }
                    
                    // Research Papers if present
                    if let papers = recommendation.researchPapers, !papers.isEmpty {
                        Divider()
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Label("Referensi Jurnal", systemImage: "doc.text")
                                .font(AppTypography.bodyBold)
                                .foregroundStyle(AppColor.textPrimary)
                            
                            Text(papers)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColor.accentPrimary)
                                .underline()
                        }
                    }
                }
                .padding(AppSpacing.md)
            }
            .background(AppColor.backgroundPrimary)
            .navigationTitle("Detail Kandungan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Tutup") {
                        dismiss()
                    }
                    .font(AppTypography.bodyBold)
                    .foregroundStyle(AppColor.accentPrimary)
                }
            }
        }
    }
}
