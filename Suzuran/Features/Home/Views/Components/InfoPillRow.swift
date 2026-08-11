import SwiftUI

/// A reusable row component for informational modals (e.g. About Acne Type, About Skin Score).
/// Displays a colored vertical pill alongside a title and several optional descriptive text blocks.
struct InfoPillRow: View {
    let pillColor: Color
    let title: String
    
    // Used in About Skin Score for the range (e.g. "55% - 99%")
    var subtitle: String? = nil
    
    // Used in About Skin Score for the bold summary description
    var bodyBold: String? = nil
    
    // The regular description text
    let bodyRegular: String

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            // Colored Pill - intrinsic height will match sibling VStack
            Capsule()
                .fill(pillColor)
                .frame(width: 8)
                .padding(.vertical, 2)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppColor.textPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColor.textPrimary)
                }

                if let bodyBold = bodyBold {
                    Text(bodyBold)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(AppColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text(bodyRegular)
                    .font(.subheadline)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview("Standard (Acne Type)") {
    InfoPillRow(
        pillColor: .green,
        title: "Whitehead",
        bodyRegular: "A closed clogged pore that appears as a small white or skin-colored bump."
    )
    .padding()
}

#Preview("Extended (Skin Score)") {
    InfoPillRow(
        pillColor: .purple.opacity(0.3),
        title: "Good",
        subtitle: "55% - 99%",
        bodyBold: "Your scan shows some acne lesions, but the overall findings appear limited.",
        bodyRegular: "Keep tracking your skin regularly to see how it changes over time."
    )
    .padding()
}
