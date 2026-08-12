import SwiftUI

struct IngredientDetailView: View {
    let recommendation: SkincareIngredientRecommendation
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
                    
                    // Ingredient Interactions
                    if let interactions = recommendation.ingredientInteractions, !interactions.isEmpty {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Label("Interaksi Kandungan", systemImage: "arrow.triangle.2.circlepath")
                                .font(AppTypography.bodyBold)
                                .foregroundStyle(AppColor.accentPrimary)
                            
                            VStack(spacing: AppSpacing.sm) {
                                ForEach(interactions, id: \.ingredient) { interaction in
                                    interactionCard(for: interaction)
                                }
                            }
                        }
                        
                        Divider()
                    }
                    
                    // Risks & Safety
                    if let risks = recommendation.risksAndSafety {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Label("Risiko & Keamanan", systemImage: "exclamationmark.triangle")
                                .font(AppTypography.bodyBold)
                                .foregroundStyle(AppColor.accentDanger)
                            
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                if let common = risks.common, !common.isEmpty {
                                    riskSection(title: "Umum (Common)", description: common, color: AppColor.accentPrimary)
                                }
                                
                                if let serious = risks.serious, !serious.isEmpty {
                                    riskSection(title: "Serius (Serious)", description: serious, color: AppColor.accentDanger)
                                }
                                
                                if let rare = risks.rare, !rare.isEmpty {
                                    riskSection(title: "Langka (Rare)", description: rare, color: AppColor.textSecondary)
                                }
                            }
                            .padding(AppSpacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColor.accentDanger.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppCornerRadius.md)
                                    .stroke(AppColor.accentDanger.opacity(0.2), lineWidth: 1)
                            )
                        }
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
//                    .font(AppTypography.bodyBold)
//                    .foregroundStyle(AppColor.accentPrimary)
                }
            }
        }
    }
    
    private func riskSection(title: String, description: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundStyle(color)
            
            Text(description)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textPrimary)
                .lineSpacing(2)
        }
    }
    
    private func interactionColor(for status: String) -> Color {
        let lower = status.lowercased()
        if lower.contains("excellent") || lower.contains("well") {
            return AppColor.accentPrimary
        } else if lower.contains("carefully") {
            return .orange
        } else if lower.contains("separately") || lower.contains("avoid") {
            return AppColor.accentDanger
        }
        return AppColor.textSecondary
    }
    
    private func interactionCard(for interaction: SkincareIngredientRecommendation.IngredientInteraction) -> some View {
        let color = interactionColor(for: interaction.status)
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(interaction.ingredient)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textPrimary)
                Spacer()
                Text(interaction.status)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.1))
                    .foregroundStyle(color)
                    .clipShape(Capsule())
            }
            
            Text(interaction.description)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
                .lineSpacing(2)
        }
        .padding(AppSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.md)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }
}
