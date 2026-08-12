import SwiftUI

/// Evidence-oriented ingredient detail screen adopting the layout from
/// feature/integrate-ingredients with added "Found in your product" section.
struct IngredientDetailView: View {
    let recommendation: SkincareIngredientRecommendation
    /// `true` when rendered in a sheet; `false` when pushed from the match list.
    var showsCloseButton = true
    @Environment(\.dismiss) private var dismiss

    @State private var isConcentrationExpanded = false
    @State private var isApplicationExpanded = false
    @State private var isInteractionsExpanded = false

    var body: some View {
        Group {
            if showsCloseButton {
                NavigationStack {
                    detailContent
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Tutup") { dismiss() }
                                    .font(Font.description)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(AppColor.accentPrimary)
                                    .frame(minHeight: 44)
                            }
                        }
                }
            } else {
                detailContent
            }
        }
    }

    // MARK: - Detail Content

    private var detailContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {

                // Header
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(recommendation.ingredientName)
                        .font(Font.screenTitle)
                        .foregroundStyle(AppColor.textPrimary)

                    if let alternatives = recommendation.alternativesName, !alternatives.isEmpty {
                        Text("Alias: \(alternatives)")
                            .font(Font.description)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
                .padding(.top, AppSpacing.sm)

                // Acne Types Treated
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Label("Target Tipe Jerawat", systemImage: "sparkles")
                        .font(Font.description)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColor.accentPrimary)

                    Text(recommendation.acneTypes)
                        .font(Font.description)
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
                        .font(Font.description)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColor.textPrimary)

                    Text(recommendation.description)
                        .font(Font.description)
                        .foregroundStyle(AppColor.textSecondary)
                        .lineSpacing(4)
                }

                Divider()

                // Concentration & Usage
                DisclosureGroup(
                    isExpanded: $isConcentrationExpanded,
                    content: {
                        Text(recommendation.concentrationAndUsage)
                            .font(Font.description)
                            .foregroundStyle(AppColor.textSecondary)
                            .lineSpacing(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, AppSpacing.xs)
                    },
                    label: {
                        Label("Konsentrasi & Penggunaan", systemImage: "slider.horizontal.3")
                            .font(Font.description)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColor.textPrimary)
                    }
                )
                .tint(AppColor.textSecondary)

                Divider()

                // Application
                DisclosureGroup(
                    isExpanded: $isApplicationExpanded,
                    content: {
                        Text(recommendation.application)
                            .font(Font.description)
                            .foregroundStyle(AppColor.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, AppSpacing.xs)
                    },
                    label: {
                        Label("Metode Aplikasi", systemImage: "hand.tap")
                            .font(Font.description)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColor.textPrimary)
                    }
                )
                .tint(AppColor.textSecondary)

                if let interactions = recommendation.ingredientInteractions, !interactions.isEmpty {
                    Divider()

                    // Ingredient Interactions
                    DisclosureGroup(
                        isExpanded: $isInteractionsExpanded,
                        content: {
                            VStack(alignment: .leading, spacing: AppSpacing.md) {
                                ForEach(interactions, id: \.ingredient) { interaction in
                                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                                        HStack {
                                            Text(interaction.ingredient)
                                                .font(Font.metadata)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(AppColor.textPrimary)
                                            Spacer()
                                            Text(interaction.status)
                                                .font(Font.metadata)
                                                .fontWeight(.medium)
                                                .foregroundStyle(interaction.status.contains("Separately") || interaction.status.contains("Carefully") ? AppColor.accentDanger : AppColor.accentPrimary)
                                        }
                                        Text(interaction.description)
                                            .font(Font.metadata)
                                            .foregroundStyle(AppColor.textSecondary)
                                            .lineSpacing(2)
                                    }
                                }
                            }
                            .padding(.top, AppSpacing.xs)
                        },
                        label: {
                            Label("Interaksi Kandungan", systemImage: "arrow.triangle.2.circlepath")
                                .font(Font.description)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppColor.textPrimary)
                        }
                    )
                    .tint(AppColor.textSecondary)
                }

                Divider()

                // Risks & Safety
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Label("Risiko & Keamanan", systemImage: "exclamationmark.triangle")
                        .font(Font.description)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColor.accentDanger)

                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        if let common = recommendation.risksAndSafety.common, !common.isEmpty {
                            Text("**Umum:** \(common)")
                        }
                        if let serious = recommendation.risksAndSafety.serious, !serious.isEmpty {
                            Text("**Serius:** \(serious)")
                        }
                        if let rare = recommendation.risksAndSafety.rare, !rare.isEmpty {
                            Text("**Jarang:** \(rare)")
                        }
                    }
                    .font(Font.description)
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



                // Research Papers
                if let papers = recommendation.researchPapers, !papers.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Label("Referensi Jurnal", systemImage: "doc.text")
                            .font(Font.description)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColor.textPrimary)

                        Text(papers)
                            .font(Font.metadata)
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
    }

}
