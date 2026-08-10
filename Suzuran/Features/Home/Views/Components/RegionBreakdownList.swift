import SwiftUI

/// Displays a per-region count table for the selected acne type.
/// Shows all five facial regions in display order with their respective counts including zero values.
struct RegionBreakdownList: View {
    let regionCounts: [(region: FaceRegion, count: Int)]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Per Wilayah Wajah")
                .font(AppTypography.bodyBold)
                .foregroundStyle(AppColor.textPrimary)
                .padding(.horizontal, AppSpacing.md)

            ForEach(regionCounts, id: \.region) { item in
                HStack {
                    Text(item.region.displayName)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.textSecondary)
                    Spacer()
                    Text("\(item.count)")
                        .font(AppTypography.bodyBold)
                        .foregroundStyle(AppColor.textPrimary)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xxs)
            }
        }
    }
}
