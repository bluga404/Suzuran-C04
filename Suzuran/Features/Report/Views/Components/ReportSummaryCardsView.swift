import SwiftUI

struct ReportSummaryCardsView: View {
    let selectedMetric: ReportMetric
    let skinScoreSummary: ReportComparisonSummary
    let acneSummary: ReportComparisonSummary
    let insight: ReportInsightSummary
    var onRetry: (() -> Void)?

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
                        let (iconName, iconColor): (String, Color) = {
                            switch insight.source {
                            case .generated: return ("sparkles", AppColor.accentPrimary)
                            case .cached: return ("clock", AppColor.textSecondary)
                            case .error: return ("exclamationmark.triangle.fill", .red)
                            case .empty: return ("info.circle", AppColor.textSecondary)
                            }
                        }()

                        Image(systemName: iconName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(iconColor)

                        Text(insight.title)
                            .font(Font.bodyParagraph)
                            .foregroundStyle(AppColor.textPrimary)
                    }

                    Text(insight.body)
                        .font(Font.bodyParagraph)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let ts = insight.timestamp, insight.source == .cached {
                        Text("Last updated: \(DateFormatters.fullDateEN.string(from: ts))")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColor.textSecondary)
                    }

                    if insight.source == .error {
                        HStack(spacing: AppSpacing.sm) {
                            if let onRetry {
                                Button(action: onRetry) {
                                    Text("Try again")
                                }
                                .buttonStyle(.borderedProminent)
                            }

                            Text("There was an error generating the summary. Please check your connection or API configuration.")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColor.textSecondary)
                        }
                    }
                }
            }
        }
    }

    private func summaryCard(summary: ReportComparisonSummary) -> some View {
        AppCard(padding: AppSpacing.lg) {
            HStack(alignment: .top, spacing: AppSpacing.lg) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(summary.baselineLabel)
                        .font(Font.metadata)
                        .foregroundStyle(AppColor.textSecondary)

                    Text(summary.headline)
                        .font(Font.screenTitle)
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                VStack(alignment: .center, spacing: AppSpacing.xs) {
                    Text(summary.scoreLabel)
                        .font(Font.metadata)
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
                .font(Font.screenTitle)
                .foregroundStyle(AppColor.textPrimary)
        }
        .frame(width: badgeSize, height: badgeSize)
    }
}
