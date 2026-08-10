import SwiftUI

/// Displays the most detected acne type from the latest scan as a highlighted card.
/// Shown only when a face scan exists and a dominant type was detected.
struct MostDetectedSection: View {
    let acneType: AcneType?
    let count: Int?
    var onInfoTap: () -> Void = {}

    var body: some View {
        if let type = acneType {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack {
                        Text("MOST DETECTED")
                            .font(AppTypography.caption)
                            .tracking(1.2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button(action: onInfoTap) {
                            Image(systemName: "info.circle")
                                .font(AppTypography.caption)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityLabel("Most detected information")
                    }

                    Text(type.displayName)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text(countText)
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(AppSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.lg))
            }
            .padding(.horizontal, AppSpacing.md)
        }
    }

    private var countText: String {
        guard let count = count else { return "Most detected on your face" }
        return "\(count) detected on your face"
    }
}

#Preview("With Count") {
    MostDetectedSection(acneType: .blackhead, count: 14)
}

#Preview("Without Count") {
    MostDetectedSection(acneType: .papule, count: nil)
}
