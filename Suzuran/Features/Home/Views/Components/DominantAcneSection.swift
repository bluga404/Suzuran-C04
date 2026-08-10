import SwiftUI

struct DominantAcneSection: View {
    let acneType: AcneType?

    var body: some View {
        if let type = acneType {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack(spacing: AppSpacing.xxs) {
                    Text("Most Detected Acne Type")
                        .font(AppTypography.bodyBold)
                        .foregroundStyle(.primary)
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(type.displayName)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, AppSpacing.md)
        }
    }
}
