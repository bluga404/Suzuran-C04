import SwiftUI

/// Displays the user's skin health score with contextual messaging and an action button.
/// Adapts its content based on the current HomeSummaryState.
/// Layout hierarchy: "SKIN CONDITION" header with an info icon, the score category,
/// the score value, an English state-specific insight message, and an action button.
struct SkinScoreCard: View {
    let score: SkinScorePresentation?
    let state: HomeSummaryState
    var onAction: () -> Void = {}
    var onInfoTap: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Header: title with an info button beside it
            HStack {
                Text("SKIN CONDITION")
                    .font(AppTypography.caption)
                    .tracking(1.2)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(action: onInfoTap) {
                    Image(systemName: "info.circle")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Skin condition information")
            }

            // Score category (e.g. "Good", "Moderate") — larger than the score value
            if let title = score?.title, !title.isEmpty {
                Text(title)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(scoreColor)
            }

            // Score value
            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xxs) {
                Text(score != nil ? "\(score!.value)" : "—")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(scoreColor)
                Text("/100")
                    .font(AppTypography.subtitle)
                    .foregroundStyle(.secondary)
            }

            // Contextual insight message
            Text(messageText)
                .font(AppTypography.body)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            // Action button
            Button(action: onAction) {
                Text(state == .empty ? "Check My Skin" : "Details")
                    .font(AppTypography.bodyBold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm)
                    .background(AppColor.accentPrimary)
                    .clipShape(Capsule())
            }
            .accessibilityLabel(state == .empty ? "Start face scan" : "View scan details")
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.lg))
    }

    // MARK: - Score color based on severity

    private var scoreColor: Color {
        guard let score = score else { return AppColor.textSecondary }
        switch score.value {
        case 100: return AppColor.scoreVeryGood
        case 55...99: return AppColor.scoreGood
        case 25...54: return AppColor.scoreModerate
        case 5...24: return AppColor.scoreLow
        default: return AppColor.scoreVeryLow
        }
    }

    // MARK: - State-specific messages in English

    private var messageText: String {
        if let message = score?.message, !message.isEmpty {
            return message
        }
        switch state {
        case .empty:
            return "Scan your face to see skin condition"
        case .faceOnly, .complete:
            return "Scan again tomorrow to see your skin condition change!"
        case .improvement:
            return "Yeay! your score is higher than yesterday!"
        case .degradation:
            return "Your score is lower than yesterday, don't worry, it's part of the process!"
        case .unchanged:
            return "No change from yesterday. Keep up your routine!"
        }
    }
}

#Preview("Empty State") {
    SkinScoreCard(
        score: nil,
        state: .empty,
        onAction: {}
    )
    .padding()
}

#Preview("Complete State") {
    SkinScoreCard(
        score: SkinScorePresentation(
            value: 60,
            title: "Good",
            trend: .noPreviousData,
            message: "Scan again tomorrow to see your skin condition change!"
        ),
        state: .complete,
        onAction: {}
    )
    .padding()
}

#Preview("Improvement State") {
    SkinScoreCard(
        score: SkinScorePresentation(
            value: 83,
            title: "Good",
            trend: .improved,
            message: "Yeay! your score is higher than yesterday! improving 38% from yesterday"
        ),
        state: .improvement,
        onAction: {}
    )
    .padding()
}

#Preview("Degradation State") {
    SkinScoreCard(
        score: SkinScorePresentation(
            value: 40,
            title: "Moderate",
            trend: .declined,
            message: "Your score is lower 33% than yesterday, don't worry, it's part of the process!"
        ),
        state: .degradation,
        onAction: {}
    )
    .padding()
}
