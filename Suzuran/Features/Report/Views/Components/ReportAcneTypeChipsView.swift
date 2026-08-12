import SwiftUI

struct ReportAcneTypeChipsView: View {
    let series: [AcneTypeSeries]
    let isActive: (String) -> Bool
    let scoresByAcneTypeID: [String: Int]
    let onToggle: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(series) { item in
                    let active = isActive(item.id)

                    Button {
                        onToggle(item.id)
                    } label: {
                        HStack(spacing: AppSpacing.xs) {
                            Circle()
                                .fill(item.acneType.color)
                                .frame(width: 8, height: 8)

                            Text(item.acneType.displayName)
                                .font(Font.metadata)

                            Text("\(scoresByAcneTypeID[item.id] ?? item.latestScore)")
                                .font(Font.metadata.weight(.semibold))
                        }
                        .foregroundStyle(active ? AppColor.textPrimary : AppColor.textSecondary)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                        .background(active ? AppColor.surfacePrimary : AppColor.surfacePrimary.opacity(0.45))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(active ? item.acneType.color.opacity(0.5) : AppColor.textSecondary.opacity(0.25), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, AppSpacing.sm)
        }
    }
}
