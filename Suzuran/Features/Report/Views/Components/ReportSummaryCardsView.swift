import SwiftUI

struct ReportSummaryCardsView: View {
    let comparison: ReportComparisonSummary
    let insight: ReportInsightSummary

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            AppCard {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(comparison.baselineLabel)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textSecondary)

                    HStack {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text(comparison.headline)
                                .font(AppTypography.bodyBold)
                                .foregroundStyle(AppColor.textPrimary)

                            Text(comparison.scoreLabel)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColor.textSecondary)
                        }

                        Spacer()

                        Text(comparison.deltaText)
                            .font(AppTypography.bodyBold)
                            .foregroundStyle(AppColor.accentPrimary)
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.sm)
                            .background(AppColor.surfacePrimary)
                            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.md))
                    }
                }
            }

            AppCard {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack {
                        Text(insight.title)
                            .font(AppTypography.subtitle)
                            .foregroundStyle(AppColor.textPrimary)

                        Spacer()

                        Image(systemName: "sparkles")
                            .foregroundStyle(AppColor.accentPrimary)
                    }

                    Text(insight.body)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
