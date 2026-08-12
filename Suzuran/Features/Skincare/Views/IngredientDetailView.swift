import SwiftUI

/// Evidence-oriented ingredient detail screen. It retains the current reference
/// data contract while presenting it in the expandable, sectioned hierarchy from
/// the mid-fidelity ingredient-detail mockup.
struct IngredientDetailView: View {
    let recommendation: SkincareIngredientRecommendation
    /// `true` when rendered in a sheet; `false` when pushed from the match list.
    var showsCloseButton = true
    @Environment(\.dismiss) private var dismiss
    @State private var isDescriptionExpanded = false
    @State private var isInteractionExpanded = false
    @State private var isSourceExpanded = false

    var body: some View {
        Group {
            if showsCloseButton {
                NavigationStack {
                    detailContent
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Tutup") { dismiss() }
                                    .font(AppTypography.bodyBold)
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

    private var detailContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                header
                acneTargetSection
                descriptionSection
                interactionSection
                usageSection
                safetySection
                sourceSection
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.backgroundPrimary)
        .navigationTitle("Detail Ingredient")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(recommendation.ingredientName)
                .font(AppTypography.title)
                .foregroundStyle(AppColor.textPrimary)

            if let alternatives = recommendation.alternativesName, !alternatives.isEmpty {
                Text("Nama lain: \(alternatives)")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
    }

    private var acneTargetSection: some View {
        detailCard(title: "Target Tipe Jerawat", symbol: "sparkles", tint: AppColor.accentPrimary) {
            Text(recommendation.acneTypes)
                .font(AppTypography.body)
                .foregroundStyle(AppColor.textPrimary)
        }
    }

    private var descriptionSection: some View {
        detailCard(title: "Deskripsi", symbol: "text.alignleft", tint: AppColor.textPrimary) {
            Text(recommendation.description)
                .font(AppTypography.body)
                .foregroundStyle(AppColor.textSecondary)
                .lineLimit(isDescriptionExpanded ? nil : 4)

            Button(isDescriptionExpanded ? "Tampilkan Lebih Sedikit" : "Lihat Selengkapnya") {
                withAnimation(.easeInOut) { isDescriptionExpanded.toggle() }
            }
            .font(AppTypography.caption)
            .fontWeight(.semibold)
            .foregroundStyle(AppColor.accentPrimary)
            .frame(minHeight: 44)
        }
    }

    @ViewBuilder
    private var interactionSection: some View {
        if let interactions = recommendation.ingredientInteractions, !interactions.isEmpty {
            detailCard(title: "Interaksi Ingredient", symbol: "arrow.triangle.2.circlepath", tint: AppColor.textPrimary) {
                Button {
                    withAnimation(.easeInOut) { isInteractionExpanded.toggle() }
                } label: {
                    HStack {
                        Text("Lihat interaksi dan kombinasi penggunaan")
                            .font(AppTypography.body)
                            .foregroundStyle(AppColor.textPrimary)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        Image(systemName: isInteractionExpanded ? "chevron.up" : "chevron.down")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    .frame(minHeight: 44)
                }
                .buttonStyle(.plain)

                if isInteractionExpanded {
                    Text(interactions)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
        }
    }

    private var usageSection: some View {
        VStack(spacing: AppSpacing.sm) {
            detailCard(title: "Konsentrasi & Penggunaan", symbol: "slider.horizontal.3", tint: AppColor.textPrimary) {
                Text(recommendation.concentrationAndUsage)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textSecondary)
            }

            detailCard(title: "Cara Aplikasi", symbol: "hand.tap", tint: AppColor.textPrimary) {
                Text(recommendation.application)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
    }

    private var safetySection: some View {
        detailCard(title: "Risiko & Keamanan", symbol: "exclamationmark.triangle", tint: AppColor.accentDanger) {
            Text(recommendation.risksAndSafety)
                .font(AppTypography.body)
                .foregroundStyle(AppColor.textSecondary)
        }
    }

    @ViewBuilder
    private var sourceSection: some View {
        if let papers = recommendation.researchPapers, !papers.isEmpty {
            detailCard(title: "Sumber Referensi", symbol: "doc.text", tint: AppColor.textPrimary) {
                Button {
                    withAnimation(.easeInOut) { isSourceExpanded.toggle() }
                } label: {
                    HStack {
                        Text("Lihat referensi penelitian")
                            .font(AppTypography.body)
                            .foregroundStyle(AppColor.textPrimary)
                        Spacer()
                        Image(systemName: isSourceExpanded ? "chevron.up" : "chevron.down")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    .frame(minHeight: 44)
                }
                .buttonStyle(.plain)

                if isSourceExpanded {
                    Text(papers)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textSecondary)
                        .textSelection(.enabled)
                }
            }
        }
    }

    private func detailCard<Content: View>(
        title: String,
        symbol: String,
        tint: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Label(title, systemImage: symbol)
                    .font(AppTypography.bodyBold)
                    .foregroundStyle(tint)
                content()
            }
        }
    }
}
