import SwiftUI

/// Preview section for the user's aggregate, canonical-ID-deduplicated matched
/// ingredients. The home screen renders a compact preview; `onShowAll` opens the
/// full match list that corresponds to mockup `09_SeeDetails.png`.
struct MatchedIngredientSection: View {
    let matched: [MatchedIngredient]
    let onSelect: (MatchedIngredient) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Matched Ingredients")
                    .font(Font.description)
                    .foregroundStyle(AppColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
            }

            LazyVStack(spacing: AppSpacing.sm) {
                ForEach(matched) { item in
                    Button { onSelect(item) } label: {
                        RecommendationCard(matched: item)
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(Text(accessibilityLabel(for: item)))
                    .accessibilityHint(Text("Tap to view ingredient detail"))
                }
            }
        }
    }

    private func accessibilityLabel(for item: MatchedIngredient) -> String {
        let acneTypeNames = item.matchedAcneTypes.map(\.displayName).joined(separator: ", ")
        guard !acneTypeNames.isEmpty else {
            return "\(item.recommendation.ingredientName), matches your acne condition"
        }
        return "\(item.recommendation.ingredientName), matches \(acneTypeNames)"
    }
}

/// Empty-state view rendered when the acne profile exists but none of the user's
/// products contain an ingredient matched to that profile.
struct MatchedIngredientEmptyState: View {
    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("No matched ingredients yet")
                    .font(Font.description)
                    .foregroundStyle(AppColor.textPrimary)

                Text("Your saved skincare doesn't contain ingredients that match your current acne condition. Try adding other products to get recommendations.")
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
                Text("Discover Skincare Compatibility")
                    .font(Font.description)
                    .foregroundStyle(AppColor.textPrimary)

                Text("Scan your face from the main menu to see if your saved skincare matches your current acne condition.")
                    .font(Font.metadata)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
