import SwiftUI

/// Modal view displaying information about the skin score levels.
/// Shown when the user taps the info button on the Skin Condition card.
struct AboutSkinScoreView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    headerSection
                    scoreLevelsList
                    footerSection
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.lg)
            }
            .background(AppColor.backgroundPrimary.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close) { dismiss() }
                }
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("About Skin Score")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(AppColor.textPrimary)

            Text("A score that reflects your current acne condition based on the number and severity of detected acne lesions. Higher scores indicate clearer skin.")
                .font(.body)
                .foregroundStyle(AppColor.textSecondary)
        }
    }

    private var scoreLevelsList: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            ForEach(SkinScoreLevelInfo.allCases) { info in
                InfoPillRow(
                    pillColor: info.color,
                    title: info.title,
                    subtitle: info.range,
                    bodyBold: info.summary,
                    bodyRegular: info.description
                )
            }
        }
    }

    private var footerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("IMPORTANT")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(AppColor.textSecondary)

            Text("Descriptions are based on established acne severity assessment criteria. Suzuran is an app-specific estimate and does not provide a medical diagnosis.")
                .font(.caption)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, AppSpacing.lg)
    }
}

// MARK: - Data Models

private enum SkinScoreLevelInfo: String, CaseIterable, Identifiable {
    case veryGood, good, moderate, low, veryLow
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .veryGood: return "Very Good"
        case .good: return "Good"
        case .moderate: return "Moderate"
        case .low: return "Low"
        case .veryLow: return "Very Low"
        }
    }
    
    var range: String {
        switch self {
        case .veryGood: return "100%"
        case .good: return "55% - 99%"
        case .moderate: return "25% - 54%"
        case .low: return "5% - 24%"
        case .veryLow: return "0% - 4%"
        }
    }
    
    var color: Color {
        switch self {
        case .veryGood: return AppColor.scoreVeryGood
        case .good: return AppColor.scoreGood
        case .moderate: return AppColor.scoreModerate
        case .low: return AppColor.scoreLow
        case .veryLow: return AppColor.scoreVeryLow
        }
    }
    
    var summary: String {
        switch self {
        case .veryGood:
            return "Your scan shows very few or no acne lesions detected."
        case .good:
            return "Your scan shows some acne lesions, but the overall findings appear limited."
        case .moderate:
            return "Your scan shows a noticeable number of acne lesions."
        case .low:
            return "Your scan shows more noticeable acne findings, including more significant inflammatory lesions."
        case .veryLow:
            return "Your scan shows a higher level of acne-related findings."
        }
    }
    
    var description: String {
        switch self {
        case .veryGood:
            return "A higher Skin Score indicates fewer or less severe acne findings in the scan."
        case .good:
            return "Keep tracking your skin regularly to see how it changes over time."
        case .moderate:
            return "Regular tracking can help you understand whether your skin condition is improving or changing over time."
        case .low:
            return "Consider monitoring changes closely and consulting a dermatologist if your acne persists or worsens."
        case .veryLow:
            return "If your acne is persistent, painful, or worsening, consider consulting a dermatologist."
        }
    }
}

#Preview {
    AboutSkinScoreView()
}
