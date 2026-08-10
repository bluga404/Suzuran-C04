import SwiftUI

/// Displays the user's skin health score with contextual messaging and an action button.
/// Adapts its content based on the current HomeSummaryState.
struct SkinScoreCard: View {
    let score: SkinScorePresentation?
    let state: HomeSummaryState
    var onAction: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Score label title
            HStack(spacing: AppSpacing.xxs) {
                Text(state == .improvement || state == .degradation ? "Skin Score" : "Skin Condition")
                    .font(AppTypography.bodyBold)
                    .foregroundStyle(.primary)
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let score = score {
                // Score title
                Text(score.title)
                    .font(.system(size: 48, weight: .bold, design: .default))
                    .foregroundStyle(.primary)
                    .padding(.bottom, -AppSpacing.xs)

                // Score value
                HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xxs) {
                    Text("\(score.value)")
                        .font(.system(size: 24, weight: .bold, design: .default))
                        .foregroundStyle(.primary)
                    Text("/100")
                        .font(AppTypography.body)
                        .foregroundStyle(.primary)
                }
            } else {
                Text("—")
                    .font(.system(size: 48, weight: .bold, design: .default))
                    .foregroundStyle(.primary)
                    .padding(.bottom, -AppSpacing.xs)

                HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xxs) {
                    Text("—")
                        .font(.system(size: 24, weight: .bold, design: .default))
                        .foregroundStyle(.primary)
                    Text("/100")
                        .font(AppTypography.body)
                        .foregroundStyle(.primary)
                }
            }

            // Contextual message
            Text(messageText)
                .font(AppTypography.body)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .padding(.top, AppSpacing.xxs)
                .padding(.bottom, AppSpacing.xs)

            // Action button
            Button(action: onAction) {
                Text(state == .empty ? "Scan" : "Details")
                    .font(AppTypography.bodyBold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.black)
                    .clipShape(Capsule())
            }
            .accessibilityLabel(state == .empty ? "Mulai scan wajah" : "Lihat detail hasil scan")
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.lg))
    }

    // MARK: - State-specific messages in Bahasa Indonesia

    private var messageText: String {
        switch state {
        case .empty:
            return "Scan your face to see skin condition"
        case .faceOnly:
            return score?.message ?? ""
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
            message: "Scan lagi besok untuk lihat perubahan kondisi kulitmu!"
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
            message: "Yeay! Skormu lebih tinggi dari kemarin!"
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
            message: "Skormu lebih rendah dari kemarin, jangan khawatir, ini bagian dari prosesnya!"
        ),
        state: .degradation,
        onAction: {}
    )
    .padding()
}

