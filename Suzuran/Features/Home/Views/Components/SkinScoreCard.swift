import SwiftUI

/// Displays the user's skin health score with contextual messaging and an action button.
/// Adapts its content based on the current HomeSummaryState.
struct SkinScoreCard: View {
    let score: SkinScorePresentation?
    let state: HomeSummaryState
    var onAction: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Score label title (only shown when score exists)
            if let score = score {
                Text(score.title)
                    .font(AppTypography.bodyBold)
                    .foregroundStyle(.primary)
            }

            // Score value
            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xxs) {
                Text(score != nil ? "\(score!.value)" : "—")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(scoreColor)
                Text(score != nil ? "/100" : "—/100")
                    .font(AppTypography.subtitle)
                    .foregroundStyle(.secondary)
            }

            // Contextual message
            Text(messageText)
                .font(AppTypography.body)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            // Action button
            Button(action: onAction) {
                Text(state == .empty ? "Scan" : "Details")
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

    // MARK: - State-specific messages in Bahasa Indonesia

    private var messageText: String {
        switch state {
        case .empty:
            return "Scan wajahmu untuk lihat kondisi kulit"
        case .faceOnly:
            return score?.message ?? ""
        case .complete:
            return "Scan lagi besok untuk lihat perubahan kondisi kulitmu!"
        case .improvement:
            return "Yeay! Skormu lebih tinggi dari kemarin!"
        case .degradation:
            return "Skormu lebih rendah dari kemarin, jangan khawatir, ini bagian dari prosesnya!"
        case .unchanged:
            return "Skormu tidak berubah sejak scan terakhir"
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

