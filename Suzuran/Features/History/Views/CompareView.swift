import SwiftUI

/// Compare view — side-by-side comparison of two scan records.
/// Shows photos, dates, skin scores, total acne comparison, and insight summary.
struct CompareView: View {
    let recordA: ScanRecord   // Older scan (before)
    let recordB: ScanRecord   // Newer scan (after)
    let onDismiss: () -> Void

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMMM yyyy"
        f.locale = Locale(identifier: "en_US")
        return f
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Date selectors (visual-only chips matching UI)
                    HStack(spacing: AppSpacing.sm) {
                        dateChip(recordA.date)
                        dateChip(recordB.date)
                    }

                    // Side-by-side photos
                    HStack(spacing: AppSpacing.sm) {
                        photoCard(recordA)
                        photoCard(recordB)
                    }

                    // Skin Score comparison section
                    skinScoreSection

                    // Summary insight card
                    insightCard

                    // Total Acne comparison card
                    totalAcneCard
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, 80) // Leave space for floating bar if present
            }
            .scrollEdgeEffectStyle(.soft, for: .top)
            .navigationTitle("Compare")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
    }

    // MARK: - Components

    private func dateChip(_ date: Date) -> some View {
        HStack(spacing: 4) {
            Text(dateFormatter.string(from: date))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
            Image(systemName: "chevron.down")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .frame(maxWidth: .infinity)
    }

    private func photoCard(_ record: ScanRecord) -> some View {
        Group {
            if let data = record.frontImageData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.md))
            } else {
                RoundedRectangle(cornerRadius: AppCornerRadius.md)
                    .fill(Color(.systemGray5))
                    .frame(height: 200)
                    .overlay(
                        Image(systemName: "person.crop.rectangle")
                            .font(.system(size: 36))
                            .foregroundStyle(.secondary)
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.md)
                .stroke(Color(.systemGray4), lineWidth: 0.5)
        )
    }

    // MARK: - Skin Score Section

    private var skinScoreSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: 4) {
                Text("Skin Score")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.primary)
                Image(systemName: "info.circle")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("\(recordA.skinScore)")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(recordB.skinScore)")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(.primary)
            }
        }
    }

    // MARK: - Insight Card

    private var insightCard: some View {
        let scoreDiff = recordB.skinScore - recordA.skinScore
        let acneDiff  = recordB.totalAcneCount - recordA.totalAcneCount
        let isImproving = scoreDiff > 0

        return AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Summary Insight")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(isImproving ? "Your Skin is Improving!" : (scoreDiff == 0 ? "Skin Condition Stable" : "Skin Needs Attention"))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.primary)

                        Text("Compared to \(dateFormatter.string(from: recordA.date)), \(abs(acneDiff)) \(acneDiff <= 0 ? "fewer" : "more") acne detected")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Text("Score")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)

                        Text("\(scoreDiff > 0 ? "+" : "")\(scoreDiff)")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(scoreDiff >= 0 ? .green : .red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                                    .fill(scoreDiff >= 0 ? Color.green.opacity(0.12) : Color.red.opacity(0.12))
                            )
                    }
                }
            }
        }
    }

    // MARK: - Total Acne Card

    private var totalAcneCard: some View {
        let acneDiff = recordB.totalAcneCount - recordA.totalAcneCount

        return AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Total Acne")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.primary)

                HStack {
                    Text("\(recordA.totalAcneCount)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "arrow.right")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(recordB.totalAcneCount)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Text("\(acneDiff > 0 ? "+" : "")\(acneDiff) Acne spots")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(acneDiff <= 0 ? .green : .red)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                                .fill(Color(.systemGray5))
                        )
                }

                Divider()

                HStack {
                    Spacer()
                    Text("View Acne Breakdown")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
    }
}
