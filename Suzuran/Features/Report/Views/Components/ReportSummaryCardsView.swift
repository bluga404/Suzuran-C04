import SwiftUI

struct ReportSummaryCardsView: View {
    let selectedMetric: ReportMetric
    let skinScoreSummary: ReportComparisonSummary
    let acneSummary: ReportComparisonSummary
    let insight: ReportInsightSummary

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            if selectedMetric == .skinScore {
                summaryCard(summary: skinScoreSummary)
            } else {
                summaryCard(summary: acneSummary)
            }

            AppCard(padding: AppSpacing.sm) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack(alignment: .center, spacing: AppSpacing.xs) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppColor.accentPrimary)

                        Text(insight.title)
                            .font(AppTypography.subtitle)
                            .foregroundStyle(AppColor.textPrimary)
                    }

                    Text(insight.body)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func summaryCard(summary: ReportComparisonSummary) -> some View {
        AppCard(padding: AppSpacing.lg) {
            HStack(alignment: .top, spacing: AppSpacing.lg) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(summary.baselineLabel)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textSecondary)

                    Text(summary.headline)
                        .font(AppTypography.title)
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                VStack(alignment: .center, spacing: AppSpacing.xs) {
                    Text(summary.scoreLabel)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textSecondary)
                        .multilineTextAlignment(.center)

                    numberedBadge(summary.deltaText)
                }
                .frame(minWidth: badgeSize, alignment: .center)
            }
        }
    }

    private var badgeSize: CGFloat {
        AppSpacing.lg * 2 + AppSpacing.sm
    }

    private func numberedBadge(_ value: String) -> some View {
        ZStack {
            Circle()
                .fill(AppColor.surfacePrimary)
                .frame(width: badgeSize, height: badgeSize)
                .overlay(
                    Circle()
                        .stroke(AppColor.borderSubtle, lineWidth: 1)
                )

            Text(verbatim: value)
                .font(AppTypography.title)
                .foregroundStyle(AppColor.textPrimary)
        }
        .frame(width: badgeSize, height: badgeSize)
    }
}
