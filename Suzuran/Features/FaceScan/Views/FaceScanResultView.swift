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

    /// Payload for full-screen photo detail view.
    @State private var activeDetailPayload: PhotoDetailPayload? = nil

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMMM yyyy"
        f.locale = Locale(identifier: "en_US")
        return f
    }()

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
                    zoneGridSection
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)
            }
            .scrollEdgeEffectStyle(.soft, for: .top)
            .navigationTitle("Scan Result")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onDone) {
                        Label("Back", systemImage: "chevron.left")
                            .labelStyle(.iconOnly)
                    }
                }
            }
            .background(Color(.systemBackground))
            .safeAreaInset(edge: .bottom) {
                saveButton
                    .padding(.horizontal, AppSpacing.lg)
            }
            .navigationDestination(item: $activeDetailPayload) { payload in
                FullPhotoDetailView(payload: payload)
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            // Left Column
            VStack(alignment: .leading, spacing: 0) {
                Text("Skin Score")
                    .font(Font.description)
                    .foregroundStyle(.primary)
                    .padding(.bottom, 4)
                
                Text(HomeScoreCalculator().scoreLabel(for: displayScore))
                    .font(Font.system(size: 42, weight: .bold))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("\(displayScore)")
                        .font(Font.bodyLarge)
                        .foregroundStyle(.primary)
                    Text(" /100")
.font(Font.label)
                        .foregroundStyle(.secondary)
                }
                
                Spacer().frame(height: 32)
                
                Text("Most Detected Acne Type")
                    .font(Font.label)
                    .foregroundStyle(.primary)
                    .padding(.bottom, 4)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(mostDetectedAcneType)
                    .font(Font.system(size: 24, weight: .bold))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Right Column (Photo)
            Group {
                if let frontZone = result.zoneSummaries.first(where: { $0.zone == .front }),
                   let imageData = frontZone.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Button {
                        let dateStr = dateFormatter.string(from: Date())
                        let rendered = CompareFaceImage.drawMarkersOnImage(imageData: frontZone.imageData, markers: frontZone.markers)
                        activeDetailPayload = PhotoDetailPayload(
                            imageData: rendered,
                            uiImage: UIImage(data: frontZone.imageData ?? Data()),
                            title: "Front Scan",
                            dateText: dateStr
                        )
                    } label: {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 160, height: 240)
                            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.lg))
                            .overlay(
                                FaceMaskScanVisualization(markers: frontZone.markers)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: AppCornerRadius.lg)
                                    .stroke(Color.primary, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                } else {
                    RoundedRectangle(cornerRadius: AppCornerRadius.lg)
                        .fill(AppColor.surfacePrimary)
                        .frame(width: 160, height: 240)
                        .overlay(
                            Image(systemName: "person.crop.rectangle")
                                .font(Font.system(size: 32, weight: .regular))
                                .foregroundStyle(.secondary)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppCornerRadius.lg)
                                .stroke(Color.primary, lineWidth: 1)
                        )
                }
            }
        }
        .padding(.top, AppSpacing.sm)
    }

    // (Removed severityText since we use HomeScoreCalculator now)

    private var mostDetectedAcneType: String {
        if let highest = result.acneTypeSummaries.max(by: { $0.count < $1.count }), highest.count > 0 {
            return highest.acneType.displayName
        }
        return "None"
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
            let dateStr = dateFormatter.string(from: Date())
            let rendered = CompareFaceImage.drawMarkersOnImage(imageData: subZone.imageData, markers: subZone.markers)
            activeDetailPayload = PhotoDetailPayload(
                imageData: rendered,
                uiImage: UIImage(data: subZone.imageData ?? Data()),
                title: subZone.label,
                dateText: dateStr
            )
        } label: {
            VStack(spacing: 5) {
                Text(subZone.label)
                    .font(Font.helperText)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Group {
                    if let imageData = subZone.imageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .aspectRatio(1.0, contentMode: .fill)
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .clipped()
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

                Text("\(subZone.acneCount) Acne")
                    .font(Font.helperText)
                    .foregroundStyle(.primary)
            }
            .padding(AppSpacing.xs)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.md))
        }
        .buttonStyle(.plain)
    }


    // MARK: - Save Button

    private var saveButton: some View {
        Button(action: onDone) {
            Text("Save Scan Result")
                .font(Font.bodyLarge)
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(AppColor.buttonPrimaryPurple)
                .clipShape(Capsule())
                .shadow(color: AppColor.buttonPrimaryPurple.opacity(0.3), radius: 8, x: 0, y: 4)
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
