import SwiftUI

/// Result screen matching the clinical scan result design.
///
/// Layout (top → bottom):
///   1. Header row: "Overall Condition" info left, front-scan thumbnail right
///   2. Full-width front-scan photo with YOLO bounding boxes
///   3. Sub-zone grid: Forehead · Nose · Chin (row 1), Right/Left Cheek centred (row 2)
///      — each card is tappable → opens ZoneDetailView full-screen
///   4. "Type & Number of Acne" — all 6 classes, counts, colour-coded dots
///   5. Yellow "Save" button (floating safe-area inset)
struct FaceScanResultView: View {

    let result: FaceScanResultModel
    let onDone: () -> Void

    /// Sub-zone selected for full-screen display (nil = none shown).
    @State private var selectedSubZone: SubZoneSummaryModel? = nil

    /// The authoritative skin health score, computed using HomeScoreCalculator (Double precision,
    /// PRD-approved weighted formula). Falls back to skinHealthResult if available.
    private var displayScore: Int {
        if let healthResult = result.skinHealthResult {
            return healthResult.score
        }
        // Fallback: recalculate using HomeScoreCalculator from breakdown
        let calculator = HomeScoreCalculator()
        let counts = result.acneTypeSummaries.reduce(into: [AcneType: Int]()) { dict, summary in
            dict[summary.acneType] = summary.count
        }
        let weighted = calculator.calculateWeightedAcneCount(counts: counts)
        return calculator.calculateSkinHealthScore(weightedCount: weighted)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    fullFacePhotoSection
                    zoneGridSection
                    acneTypeSummarySection
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)
            }
            .scrollEdgeEffectStyle(.soft, for: .top)
            .navigationTitle("Result")
            .navigationBarTitleDisplayMode(.large)
            .toolbarRole(.editor)
            .background(Color(.systemBackground))
            .safeAreaInset(edge: .bottom) {
                saveButton
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.md)
                    .background(Color(.systemBackground))
            }
            // Full-screen zone detail
            .fullScreenCover(item: $selectedSubZone) { subZone in
                ZoneDetailView(subZone: subZone) {
                    selectedSubZone = nil
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Overall Condition")
                    .font(.custom("AvenirNext-Bold", size: 22, relativeTo: .title2))
                    .foregroundStyle(.primary)

                HStack(spacing: AppSpacing.xxs) {
                    Text("Skin-Score \(displayScore)")
                        .font(AppTypography.body)
                        .foregroundStyle(.secondary)
                    Image(systemName: "info.circle")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }

                Text("\(displayScore)%")
                    .font(.custom("AvenirNext-Bold", size: 56, relativeTo: .largeTitle))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                severityHeartsRow
            }

            Spacer(minLength: 0)

            frontSmallThumbnail
        }
        .padding(.top, AppSpacing.xs)
    }

    // MARK: - Severity Hearts Row

    private var severityHeartsRow: some View {
        HStack(spacing: AppSpacing.xxs) {
            ForEach(0..<4, id: \.self) { index in
                Image(systemName: index < filledHearts ? "heart.fill" : "heart")
                    .font(.custom("AvenirNext-Regular", size: 18, relativeTo: .headline))
                    .foregroundStyle(severityColor)
            }
            Text(result.overallSeverity.rawValue.uppercased())
                .font(.custom("AvenirNext-Bold", size: 11, relativeTo: .caption2))
                .foregroundStyle(.white)
                .padding(.horizontal, AppSpacing.xs)
                .padding(.vertical, 3)
                .background(Capsule().fill(severityColor))
        }
    }

    private var filledHearts: Int {
        switch result.overallSeverity {
        case .clear:    return 0
        case .mild:     return 1
        case .moderate: return 2
        case .severe:   return 4
        }
    }

    private var severityColor: Color {
        switch result.overallSeverity {
        case .clear:    return AppColor.scoreVeryGood
        case .mild:     return AppColor.scoreGood
        case .moderate: return AppColor.scoreModerate
        case .severe:   return AppColor.scoreVeryLow
        }
    }

    // MARK: - Small Thumbnail (header right corner)

    private var frontSmallThumbnail: some View {
        Group {
            if let frontZone = result.zoneSummaries.first(where: { $0.zone == .front }),
               let imageData = frontZone.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 110, height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.lg))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppCornerRadius.lg)
                            .stroke(AppColor.borderSubtle, lineWidth: 0.5)
                    )
            } else {
                RoundedRectangle(cornerRadius: AppCornerRadius.lg)
                    .fill(AppColor.surfacePrimary)
                    .frame(width: 110, height: 140)
                    .overlay(
                        Image(systemName: "person.crop.rectangle")
                            .font(.custom("AvenirNext-Regular", size: 32, relativeTo: .largeTitle))
                            .foregroundStyle(.secondary)
                    )
            }
        }
    }

    // MARK: - Full-Width Front Photo

    private var fullFacePhotoSection: some View {
        Group {
            if let frontZone = result.zoneSummaries.first(where: { $0.zone == .front }),
               let imageData = frontZone.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .overlay(
                        FaceMaskScanVisualization(markers: frontZone.markers)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.lg))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppCornerRadius.lg)
                            .stroke(AppColor.borderSubtle, lineWidth: 0.5)
                    )
            } else {
                RoundedRectangle(cornerRadius: AppCornerRadius.lg)
                    .fill(AppColor.surfacePrimary)
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .overlay(
                        VStack(spacing: AppSpacing.xs) {
                            Image(systemName: "person.crop.rectangle")
                                .font(.custom("AvenirNext-Regular", size: 44, relativeTo: .largeTitle))
                                .foregroundStyle(.secondary)
                            Text("Foto belum tersedia")
                                .font(AppTypography.caption)
                                .foregroundStyle(.secondary)
                        }
                    )
            }
        }
    }

    // MARK: - Zone Grid

    private var zoneGridSection: some View {
        VStack(spacing: 10) {
            // Row 1: Forehead / Nose / Chin
            let topRow    = Array(result.subZoneSummaries.prefix(3))
            // Row 2: Right Cheek / Left Cheek (centred)
            let bottomRow = Array(result.subZoneSummaries.dropFirst(3).prefix(2))

            HStack(spacing: 10) {
                ForEach(topRow) { subZone in
                    zoneThumbnailCard(subZone)
                }
            }

            // Centre the two cheek cards so they align with the top row cards
            GeometryReader { geo in
                let cardW = (geo.size.width - 20) / 3
                HStack(spacing: 10) {
                    Spacer(minLength: 0)
                    ForEach(bottomRow) { subZone in
                        zoneThumbnailCard(subZone)
                            .frame(width: cardW)
                    }
                    Spacer(minLength: 0)
                }
            }
            .frame(height: 150)
        }
    }

    /// Tappable zone thumbnail card.
    private func zoneThumbnailCard(_ subZone: SubZoneSummaryModel) -> some View {
        Button {
            selectedSubZone = subZone
        } label: {
            VStack(spacing: 5) {
                Text(subZone.label)
                    .font(.custom("AvenirNext-Bold", size: 11, relativeTo: .caption2))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Group {
                    if let imageData = subZone.imageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .background(AppColor.surfacePrimary)
                            .overlay(
                                FaceMaskScanVisualization(markers: subZone.markers)
                            )
                    } else {
                        Rectangle()
                            .fill(AppColor.surfacePrimary)
                            .aspectRatio(1.0, contentMode: .fit)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundStyle(.secondary)
                            )
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))

                Text("\(subZone.acneCount) Jerawat")
                    .font(.custom("AvenirNext-Regular", size: 11, relativeTo: .caption2))
                    .foregroundStyle(.primary)
            }
            .padding(AppSpacing.xs)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.md))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Acne Type Summary Section

    private var acneTypeSummarySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Type & Number of Acne")
                .font(.custom("AvenirNext-DemiBold", size: 20, relativeTo: .title3))
                .foregroundStyle(.primary)
                .padding(.bottom, AppSpacing.md)

            VStack(spacing: 0) {
                ForEach(Array(result.acneTypeSummaries.enumerated()), id: \.element.id) { index, summary in
                    HStack(spacing: AppSpacing.sm) {
                        // Colour dot matching bounding box colour
                        Circle()
                            .fill(summary.acneType.color)
                            .frame(width: 10, height: 10)

                        Text(summary.acneType.displayName)
                            .font(.custom("AvenirNext-Regular", size: 12, relativeTo: .caption))
                            .foregroundStyle(.primary)

                        Spacer()

                        // Count number (not percentage)
                        Text("\(summary.count)")
                            .font(.custom("AvenirNext-DemiBold", size: 13, relativeTo: .caption))
                            .foregroundStyle(summary.count > 0 ? summary.acneType.color : .secondary)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, AppSpacing.xxs)
                            .background(
                                RoundedRectangle(cornerRadius: AppCornerRadius.lg)
                                    .fill(summary.count > 0
                                          ? summary.acneType.color.opacity(0.15)
                                          : AppColor.surfacePrimary)
                            )
                    }
                    .padding(.vertical, AppSpacing.sm)

                    if index < result.acneTypeSummaries.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button(action: onDone) {
            Text("Save")
                .font(.custom("AvenirNext-Bold", size: 17, relativeTo: .headline))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.vertical, AppSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppCornerRadius.lg)
                        .fill(AppColor.accentPrimary)
                )
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleSubZones: [SubZoneSummaryModel] = [
        SubZoneSummaryModel(id: UUID(), label: "Forehead",    imageData: nil, acneCount: 2, markers: []),
        SubZoneSummaryModel(id: UUID(), label: "Nose",        imageData: nil, acneCount: 0, markers: []),
        SubZoneSummaryModel(id: UUID(), label: "Chin",        imageData: nil, acneCount: 1, markers: []),
        SubZoneSummaryModel(id: UUID(), label: "Right Cheek", imageData: nil, acneCount: 1, markers: []),
        SubZoneSummaryModel(id: UUID(), label: "Left Cheek",  imageData: nil, acneCount: 1, markers: []),
    ]

    let sampleResult = FaceScanResultModel(
        id: UUID(),
        dateText: "25 Juni 2025",
        overallSeverity: .mild,
        totalAcneCount: 5,
        zoneSummaries: [
            ZoneSummaryModel(id: UUID(), zone: .front,      zoneName: "Depan", acneCount: 3, detailText: "", imageData: nil, markers: []),
            ZoneSummaryModel(id: UUID(), zone: .leftAngle,  zoneName: "Kiri",  acneCount: 1, detailText: "", imageData: nil, markers: []),
            ZoneSummaryModel(id: UUID(), zone: .rightAngle, zoneName: "Kanan", acneCount: 1, detailText: "", imageData: nil, markers: []),
        ],
        subZoneSummaries: sampleSubZones,
        acneTypeSummaries: [
            AcneTypeSummaryModel(acneType: .papule,    count: 2),
            AcneTypeSummaryModel(acneType: .pustule,   count: 1),
            AcneTypeSummaryModel(acneType: .whitehead, count: 1),
            AcneTypeSummaryModel(acneType: .blackhead, count: 1),
            AcneTypeSummaryModel(acneType: .nodule,    count: 0),
            AcneTypeSummaryModel(acneType: .cyst,      count: 0),
        ]
    )

    FaceScanResultView(result: sampleResult, onDone: {})
}
