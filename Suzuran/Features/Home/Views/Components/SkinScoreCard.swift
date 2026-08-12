import SwiftUI

/// Displays the user's skin health score with contextual messaging and an action button.
/// Adapts its content based on the current HomeSummaryState.
struct SkinScoreCard: View {
    let score: SkinScorePresentation?
    let state: HomeSummaryState
    var onAction: () -> Void = {}
    var onInfoAction: () -> Void = {}

    var body: some View {
        AppCard(backgroundColor: AppColor.surfacePurple, borderColor: .clear) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                // Score label title
            HStack {
                Text(state == .improvement || state == .degradation ? "Skin Score" : "Skin Condition")
                    .font(Font.metadata)
                    .tracking(1.2)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(action: onInfoAction) {
                    Image(systemName: "info.circle")
                        .font(Font.metadata)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Skin condition information")
            }

            if let score = score {
                // Score title
                Text(score.title)
                    .font(Font.system(size: 48, weight: .bold))
                    .foregroundStyle(.primary)
                    .padding(.bottom, -AppSpacing.xs)

                // Score value
                HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xxs) {
                    Text("\(score.value)")
                        .font(Font.system(size: 24, weight: .bold))
                        .foregroundStyle(.primary)
                    Text("/100")
                        .font(Font.description)
                        .foregroundStyle(.primary)
                }
            } else {
                Text("—")
                    .font(Font.system(size: 48, weight: .bold))
                    .foregroundStyle(.primary)
                    .padding(.bottom, -AppSpacing.xs)

                HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xxs) {
                    Text("—")
                        .font(Font.system(size: 24, weight: .bold))
                        .foregroundStyle(.primary)
                    Text("/100")
                        .font(Font.description)
                        .foregroundStyle(.primary)
                }
            }

            // Contextual message
            Text(messageText)
                .font(Font.description)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .padding(.top, AppSpacing.xxs)
                .padding(.bottom, AppSpacing.xs)

            // Action button
            Button(action: onAction) {
                Text(state == .empty ? "Check my skin" : "Details")
                    .font(Font.description)
                    .foregroundStyle(Color(uiColor: .systemBackground))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(AppColor.buttonPrimaryPurple)
                    .clipShape(Capsule())
            }
            .accessibilityLabel(state == .empty ? "Mulai scan wajah" : "Lihat detail hasil scan")
        }
        }
    }

    // MARK: - State-specific messages in Bahasa Indonesia

    private var messageText: String {
        switch state {
        case .empty:
            return "Scan your face to see skin condition"
        case .faceOnly:
            return "Scan your skincare products to get recommendations!"
        case .complete:
            return "Scan again tomorrow to see your skin condition change!"
        case .improvement:
            return "Yeay! your score is higher than yesterday!"
        case .degradation:
            return "Your score is lower than yesterday, don't worry, it's part of the process!"
        case .unchanged:
            return "Your score hasn't changed since the last scan"
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
            message: "Yeay! your score is higher than yesterday!"
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
            message: "Your score is lower than yesterday, don't worry, it's part of the process!"
        ),
        state: .degradation,
        onAction: {}
    )
    .padding()
}

