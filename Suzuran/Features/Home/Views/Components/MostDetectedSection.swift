import SwiftUI

/// Displays the most detected acne type from the latest scan as a highlighted card.
/// Shown only when a face scan exists and a dominant type was detected.
struct MostDetectedSection: View {
    let acneType: AcneType?
    let count: Int?
    var onInfoTap: () -> Void = {}

    var body: some View {
        if let type = acneType {
            AppCard(backgroundColor: AppColor.surfacePurple, borderColor: .clear) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack {
                        Text("Most Detected")
                            .font(Font.metadata)
                            .tracking(1.2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button(action: onInfoTap) {
                            Image(systemName: "info.circle")
                                .font(Font.metadata)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityLabel("Most detected information")
                    }

                    Text(type.displayName)
                        .font(Font.pageTitle)
                        .foregroundStyle(.primary)

                    Text(countText)
                        .font(Font.metadata)
                        .foregroundStyle(.secondary)
                }
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
