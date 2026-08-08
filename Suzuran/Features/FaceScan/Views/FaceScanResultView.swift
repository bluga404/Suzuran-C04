import SwiftUI

/// Displays the complete acne detection results with Liquid Glass cards.
///
/// Renders an overall severity summary, front-angle image with marker overlay,
/// per-zone detail cards, acne type summary list, and a "Selesai" dismiss button.
/// All cards use the Liquid Glass material for iOS 26 design language.
struct FaceScanResultView: View {
    let result: FaceScanResultModel
    let onDone: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    overallSummaryCard
                    if let skinHealthResult = result.skinHealthResult {
                        scoreCard(skinHealthResult)
                    }
                    frontImageSection
                    perZoneSection
                    acneTypeSummarySection
                    doneButton
                }
                .padding(AppSpacing.md)
            }
            .navigationTitle("Hasil Scan Wajah")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Selesai", action: onDone)
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }

    // MARK: - Overall Summary

    private var overallSummaryCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Text("Ringkasan")
                        .font(AppTypography.subtitle)
                        .foregroundStyle(.primary)

                    Spacer()

                    severityBadge
                }

                Divider()

                HStack {
                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        Text("Total Jerawat")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                        Text(result.totalAcneCountText)
                            .font(AppTypography.bodyBold)
                            .foregroundStyle(.primary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: AppSpacing.xxs) {
                        Text("Tanggal")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                        Text(result.dateText)
                            .font(AppTypography.body)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Score Card

    private func scoreCard(_ score: SkinHealthResult) -> some View {
        GlassCard {
            VStack(spacing: AppSpacing.md) {
                Text("Skin Health Score")
                    .font(AppTypography.subtitle)
                    .foregroundStyle(.secondary)

                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                        .frame(width: 120, height: 120)

                    Circle()
                        .trim(from: 0, to: CGFloat(score.score) / 100.0)
                        .stroke(
                            score.color,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(score.score)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        Text("/ 100")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(score.label)
                    .font(AppTypography.bodyBold)
                    .foregroundStyle(score.color)

                Text("Weighted Count: \(formatWeight(score.weightedCount)) / 60")
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func formatWeight(_ value: Float) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    // MARK: - Severity Badge

    private var severityBadge: some View {
        Text(result.overallSeverityText)
            .font(AppTypography.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, AppSpacing.xs)
            .padding(.vertical, AppSpacing.xxs)
            .background(
                Capsule()
                    .fill(severityColor.opacity(0.2))
            )
            .foregroundStyle(severityColor)
    }

    // MARK: - Front Image Section

    private var frontImageSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Peta Jerawat")
                .font(AppTypography.subtitle)
                .foregroundStyle(.primary)

            if let frontZone = result.zoneSummaries.first(where: { $0.zoneName == FaceZone.front.displayName }),
               let imageData = frontZone.imageData,
               let uiImage = UIImage(data: imageData) {
                GlassCard {
                    imageWithMarkers(uiImage: uiImage, markers: frontZone.markers)
                }
            }
        }
    }

    // MARK: - Per-Zone Section

    private var perZoneSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Detail Per Area Wajah")
                .font(AppTypography.subtitle)
                .foregroundStyle(.primary)

            ForEach(result.zoneSummaries) { zone in
                zoneCard(zone)
            }
        }
    }

    private func zoneCard(_ zone: ZoneSummaryModel) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                // Zone header with count badge
                HStack {
                    Text(zone.zoneName)
                        .font(AppTypography.bodyBold)
                        .foregroundStyle(.primary)

                    Spacer()

                    countBadge(zone.acneCount)
                }

                // Zone image with markers
                if let imageData = zone.imageData,
                   let uiImage = UIImage(data: imageData) {
                    imageWithMarkers(uiImage: uiImage, markers: zone.markers)
                }

                // Acne type breakdown text
                if !zone.detailText.isEmpty {
                    Text(zone.detailText)
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Acne Type Summary

    private var acneTypeSummarySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Jenis Jerawat")
                .font(AppTypography.subtitle)
                .foregroundStyle(.primary)

            if result.acneTypeSummaries.isEmpty {
                GlassCard {
                    Text("Tidak ada jerawat yang terdeteksi.")
                        .font(AppTypography.body)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                GlassCard {
                    VStack(spacing: AppSpacing.xs) {
                        ForEach(result.acneTypeSummaries) { summary in
                            HStack {
                                Text(summary.title)
                                    .font(AppTypography.body)
                                    .foregroundStyle(.primary)

                                Spacer()

                                Text("\(summary.count)")
                                    .font(AppTypography.bodyBold)
                                    .foregroundStyle(.primary)
                            }

                            if summary.id != result.acneTypeSummaries.last?.id {
                                Divider()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    // MARK: - Done Button

    private var doneButton: some View {
        Button(action: onDone) {
            Text("Selesai")
                .font(AppTypography.bodyBold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.sm)
                .background(AppColor.accentPrimary)
                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.md))
        }
        .padding(.top, AppSpacing.sm)
    }

    // MARK: - Shared Components

    /// Renders an image with acne marker overlay using FaceMaskScanVisualization.
    private func imageWithMarkers(uiImage: UIImage, markers: [MarkerModel]) -> some View {
        Image(uiImage: uiImage)
            .resizable()
            .scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
            .overlay {
                FaceMaskScanVisualization(markers: markers)
            }
            .frame(maxWidth: .infinity)
    }

    /// Badge showing acne count for a zone.
    private func countBadge(_ count: Int) -> some View {
        Text("\(count) jerawat")
            .font(AppTypography.caption)
            .fontWeight(.medium)
            .padding(.horizontal, AppSpacing.xs)
            .padding(.vertical, AppSpacing.xxs)
            .background(
                Capsule()
                    .fill(count > 0 ? Color.red.opacity(0.15) : Color.green.opacity(0.15))
            )
            .foregroundStyle(count > 0 ? Color.red : Color.green)
    }

    // MARK: - Severity Color

    /// Maps severity text to a color for visual indication.
    private var severityColor: Color {
        let severity = result.overallSeverityText.lowercased()
        switch severity {
        case "clear":
            return .green
        case "mild":
            return .yellow
        case "moderate":
            return .orange
        case "severe":
            return .red
        default:
            return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleMarkers: [MarkerModel] = [
        MarkerModel(
            id: UUID(),
            acneType: .papule,
            confidence: 0.85,
            normalizedPosition: CGPoint(x: 0.3, y: 0.4)
        ),
        MarkerModel(
            id: UUID(),
            acneType: .cyst,
            confidence: 0.72,
            normalizedPosition: CGPoint(x: 0.6, y: 0.5)
        ),
    ]

    let sampleResult = FaceScanResultModel(
        id: UUID(),
        dateText: "25 Juni 2025",
        overallSeverityText: "Moderate",
        totalAcneCountText: "8",
        zoneSummaries: [
            ZoneSummaryModel(
                id: UUID(),
                zoneName: "Depan",
                acneCount: 4,
                detailText: "Papule: 2, Cyst: 2",
                imageData: nil,
                markers: sampleMarkers
            ),
            ZoneSummaryModel(
                id: UUID(),
                zoneName: "Kiri",
                acneCount: 2,
                detailText: "Pustule: 1, Blackhead: 1",
                imageData: nil,
                markers: []
            ),
            ZoneSummaryModel(
                id: UUID(),
                zoneName: "Kanan",
                acneCount: 2,
                detailText: "Whitehead: 2",
                imageData: nil,
                markers: []
            ),
        ],
        acneTypeSummaries: [
            AcneTypeSummaryModel(acneType: .papule, count: 3),
            AcneTypeSummaryModel(acneType: .cyst, count: 2),
            AcneTypeSummaryModel(acneType: .pustule, count: 2),
            AcneTypeSummaryModel(acneType: .blackhead, count: 1),
        ],
        skinHealthResult: SkinHealthResult(score: 79, weightedCount: 12.5, label: "Good", color: Color(red: 0.6, green: 0.8, blue: 0.2), breakdown: [.papule: 3, .cyst: 2, .pustule: 2, .blackhead: 1])
    )

    FaceScanResultView(result: sampleResult, onDone: {})
}
