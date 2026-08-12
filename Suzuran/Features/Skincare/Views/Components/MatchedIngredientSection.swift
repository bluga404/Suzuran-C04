import SwiftUI

/// Preview section for the user's aggregate, canonical-ID-deduplicated matched
/// ingredients. The home screen renders a compact preview; `onShowAll` opens the
/// full match list that corresponds to mockup `09_SeeDetails.png`.
struct MatchedIngredientSection: View {
    let matched: [MatchedIngredient]
    let onSelect: (MatchedIngredient) -> Void
    var onShowAll: (() -> Void)? = nil
    var previewLimit: Int = 2

    private var previewItems: ArraySlice<MatchedIngredient> {
        matched.prefix(previewLimit)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Ingredient yang Cocok")
                    .font(Font.description)
                    .foregroundStyle(AppColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                if let onShowAll {
                    Button("Lihat Semua", action: onShowAll)
                        .font(Font.metadata)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColor.accentPrimary)
                        .frame(minHeight: 44)
                        .accessibilityHint("Buka semua ingredient yang cocok")
                }
            }

            LazyVStack(spacing: AppSpacing.sm) {
                ForEach(previewItems) { item in
                    Button { onSelect(item) } label: {
                        RecommendationCard(matched: item)
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(Text(accessibilityLabel(for: item)))
                    .accessibilityHint(Text("Ketuk untuk melihat detail ingredient"))
                }
            }
        }
    }

    private func accessibilityLabel(for item: MatchedIngredient) -> String {
        let acneTypeNames = item.matchedAcneTypes.map(\.displayName).joined(separator: ", ")
        guard !acneTypeNames.isEmpty else {
            return "\(item.recommendation.ingredientName), cocok untuk kondisi acne kamu"
        }
        return "\(item.recommendation.ingredientName), cocok untuk \(acneTypeNames)"
    }
}

/// Empty-state view rendered when the acne profile exists but none of the user's
/// products contain an ingredient matched to that profile.
struct MatchedIngredientEmptyState: View {
    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Belum ada ingredient yang cocok")
                    .font(Font.description)
                    .foregroundStyle(AppColor.textPrimary)

                Text("Skincare yang kamu simpan belum mengandung ingredient yang cocok untuk kondisi acne kamu saat ini. Coba tambahkan produk lain untuk mendapatkan rekomendasi.")
                    .font(Font.metadata)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct MatchedIngredientNeedsScanState: View {
    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Ketahui Kecocokan Skincare")
                    .font(Font.description)
                    .foregroundStyle(AppColor.textPrimary)

                Text("Lakukan scan wajah pada menu utama untuk mengetahui apakah skincare yang kamu simpan cocok dengan kondisi acne kamu saat ini.")
                    .font(Font.metadata)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
