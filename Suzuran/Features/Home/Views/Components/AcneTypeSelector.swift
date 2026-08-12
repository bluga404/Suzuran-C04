import SwiftUI

/// A horizontal scrollable row of pill-shaped buttons for selecting an acne type.
/// Shows only the acne types detected in the scan, with the highest-count type pre-selected.
struct AcneTypeSelector: View {
    let types: [AcneType]
    @Binding var selected: AcneType

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                ForEach(types, id: \.self) { type in
                    Button {
                        selected = type
                    } label: {
                        Text(type.displayName)
                            .font(Font.metadata)
                            .foregroundStyle(selected == type ? AppColor.surfacePrimary : AppColor.textPrimary)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, AppSpacing.xs)
                            .background(selected == type ? AppColor.accentPrimary : AppColor.borderSubtle.opacity(0.5))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, AppSpacing.md)
        }
    }
}
