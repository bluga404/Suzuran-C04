import SwiftUI

/// Grid of category cards yang menggantikan `Picker` bawaan SwiftUI untuk memilih
/// `SkincareCategory` pada `AddSkincareView`.
///
/// Mengikuti mockup `DevFeature/Mid-Fid SkincarePage/02_SelectCategory.png`:
/// setiap case `SkincareCategory` dirender sebagai kartu berikon dengan label
/// Bahasa Indonesia. Border 2pt `AppColor.accentPrimary` menandai kartu terpilih.
///
struct CategorySelector: View {

    // MARK: - Input

    @Binding var selected: SkincareCategory

    // MARK: - Layout

    /// Adaptive grid dengan minimum 96pt per kolom, mengikuti design.md § CategorySelector.
    /// Memakai `AppSpacing.sm` untuk jarak antar kartu.
    private let columns = [
        GridItem(.adaptive(minimum: 96), spacing: AppSpacing.sm, alignment: .top)
    ]

    // MARK: - Body

    var body: some View {
        LazyVGrid(columns: columns, spacing: AppSpacing.sm) {
            ForEach(SkincareCategory.allCases) { category in
                CategoryCard(
                    category: category,
                    isSelected: selected == category,
                    onTap: {
                        // Animate transisi border/warna kartu ≤ 500 ms (Req 10.2 + design.md).
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selected = category
                        }
                    }
                )
            }
        }
    }
}

// MARK: - CategoryCard

/// Kartu individual yang merepresentasikan satu `SkincareCategory`.
///
/// - Icon: SF Symbol dari `category.iconSystemName`.
/// - Label: Bahasa Indonesia dari `category.displayName`.
/// - State terpilih: border 2pt `AppColor.accentPrimary` + background aksen tipis.
struct CategoryCard: View {

    let category: SkincareCategory
    let isSelected: Bool
    let onTap: () -> Void

    private let cardMinHeight = AppSpacing.xl * 2 + AppSpacing.lg

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: AppSpacing.xs) {
                Image(systemName: category.iconSystemName)
                    .font(AppTypography.body)
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(iconColor)
                    .accessibilityHidden(true)

                Text(category.displayName)
                    .font(AppTypography.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(labelColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity, minHeight: cardMinHeight)
            .padding(.vertical, AppSpacing.sm)
            .padding(.horizontal, AppSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.md, style: .continuous)
                    .fill(backgroundFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.md, style: .continuous)
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: AppCornerRadius.md, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(category.displayName))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - Styling

    private var iconColor: Color {
        isSelected ? AppColor.accentPrimary : AppColor.textPrimary
    }

    private var labelColor: Color {
        isSelected ? AppColor.accentPrimary : AppColor.textPrimary
    }

    private var backgroundFill: Color {
        isSelected ? AppColor.accentPrimary.opacity(0.08) : AppColor.surfacePrimary
    }

    private var borderColor: Color {
        isSelected ? AppColor.accentPrimary : AppColor.borderSubtle
    }
}

// MARK: - Previews

#Preview("CategorySelector — Serum selected") {
    StatefulPreviewWrapper(SkincareCategory.serum) { binding in
        CategorySelector(selected: binding)
            .padding(AppSpacing.md)
            .background(AppColor.backgroundPrimary)
    }
}

#Preview("CategorySelector — Sunscreen selected") {
    StatefulPreviewWrapper(SkincareCategory.sunscreen) { binding in
        CategorySelector(selected: binding)
            .padding(AppSpacing.md)
            .background(AppColor.backgroundPrimary)
    }
}

/// Helper untuk meng-host `@Binding` di preview `CategorySelector`.
private struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State private var value: Value
    private let content: (Binding<Value>) -> Content

    init(_ initial: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: initial)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}
