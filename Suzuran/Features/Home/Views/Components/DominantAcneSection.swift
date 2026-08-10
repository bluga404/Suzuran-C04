import SwiftUI

struct DominantAcneSection: View {
    let acneType: AcneType?

    var body: some View {
        if let type = acneType {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Jenis Jerawat Dominan")
                    .font(AppTypography.bodyBold)
                    .foregroundStyle(.primary)
                Text(type.displayName)
                    .font(AppTypography.body)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, AppSpacing.md)
        }
    }
}
