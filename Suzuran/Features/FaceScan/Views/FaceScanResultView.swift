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
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .scrollEdgeEffectStyle(.soft, for: .top)
            .navigationTitle("Result")
            .navigationBarTitleDisplayMode(.large)
            .toolbarRole(.editor)
            .background(Color(.systemBackground))
            .safeAreaInset(edge: .bottom) {
                saveButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
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
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Overall Condition")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.primary)

                HStack(spacing: 4) {
                    Text("Skin-Score \(displayScore)")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(.secondary)
                    Image(systemName: "info.circle")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Text("\(displayScore)%")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                severityHeartsRow
            }

            Spacer(minLength: 0)

            frontSmallThumbnail
        }
        .padding(.top, 8)
    }

    // MARK: - Severity Hearts Row

    private var severityHeartsRow: some View {
        HStack(spacing: 4) {
            ForEach(0..<4, id: \.self) { index in
                Image(systemName: index < filledHearts ? "heart.fill" : "heart")
                    .font(.system(size: 18))
                    .foregroundStyle(severityColor)
            }
            Text(result.overallSeverity.rawValue.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
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

    /// Derives the colour based on overall severity.
    private var severityColor: Color {
        if let healthResult = result.skinHealthResult {
            return healthResult.color
        }
        
        switch result.overallSeverity {
        case .clear: return AppColor.scoreGood
        case .mild: return AppColor.scoreGood
        case .moderate: return AppColor.scoreModerate
        case .severe: return AppColor.scoreLow
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
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(.systemGray4), lineWidth: 0.5)
                    )
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray5))
                    .frame(width: 110, height: 140)
                    .overlay(
                        Image(systemName: "person.crop.rectangle")
                            .font(.system(size: 32))
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
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(.systemGray4), lineWidth: 0.5)
                    )
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray5))
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "person.crop.rectangle")
                                .font(.system(size: 44))
                                .foregroundStyle(.secondary)
                            Text("Foto belum tersedia")
                                .font(.system(size: 13))
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
                    .font(.system(size: 11, weight: .bold))
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
                            .background(Color(.systemGray5))
                            .overlay(
                                FaceMaskScanVisualization(markers: subZone.markers)
                            )
                    } else {
                        Rectangle()
                            .fill(Color(.systemGray4))
                            .aspectRatio(1.0, contentMode: .fit)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundStyle(.secondary)
                            )
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Text("\(subZone.acneCount) Jerawat")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.primary)
            }
            .padding(8)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Acne Type Summary Section

    private var acneTypeSummarySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Type & Number of Acne")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.primary)
                .padding(.bottom, 14)

            VStack(spacing: 0) {
                ForEach(Array(result.acneTypeSummaries.enumerated()), id: \.element.id) { index, summary in
                    HStack(spacing: 10) {
                        // Colour dot matching bounding box colour
                        Circle()
                            .fill(summary.acneType.color)
                            .frame(width: 10, height: 10)

                        Text(summary.acneType.displayName)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(.primary)

                        Spacer()

                        // Count number (not percentage)
                        Text("\(summary.count)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(summary.count > 0 ? summary.acneType.color : .secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(summary.count > 0
                                          ? summary.acneType.color.opacity(0.15)
                                          : Color(.systemGray5))
                            )
                    }
                    .padding(.vertical, 14)

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
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 50)
                        .fill(Color(red: 0.961, green: 0.784, blue: 0.259)) // #F5C842
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
