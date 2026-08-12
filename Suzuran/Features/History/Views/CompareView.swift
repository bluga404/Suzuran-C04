import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Compare screen — allows side-by-side visual and quantitative comparison
/// of two selected face scan records (recordA = older/before, recordB = newer/after).
struct CompareView: View {
    @ObservedObject var viewModel: CompareViewModel

    struct PhotoDetailPayload: Identifiable, Hashable {
        let id = UUID()
        let imageData: Data?
        let title: String
        let dateText: String

        static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
        func hash(into hasher: inout Hasher) { hasher.combine(id) }
    }

    @State private var activeDetailPayload: PhotoDetailPayload? = nil
    @State private var showAboutSkinScore = false

    // MARK: - Color & Style Tokens

    private let primaryPurple = Color(red: 91/255, green: 67/255, blue: 177/255)  // #5B43B1
    private let cardBorder    = Color(red: 206/255, green: 202/255, blue: 232/255) // #CECAE8
    private let cardFill      = Color(red: 206/255, green: 202/255, blue: 232/255).opacity(0.28) // #CECAE8 28%

    // MARK: - Init

    init(viewModel: CompareViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                areaFilterChips
                faceImages
                    .padding(.top, 0)
                skinScoreAndInsightCard
                totalAcneSection
                acneBreakdownSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
        .navigationTitle("Compare")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .navigationDestination(item: $activeDetailPayload) { payload in
            FullPhotoDetailView(
                imageData: payload.imageData,
                title: payload.title,
                dateText: payload.dateText
            )
        }
        .sheet(isPresented: $showAboutSkinScore) {
            NavigationStack {
                AboutSkinScoreView()
            }
        }
    }

    // MARK: - Area Filter Chips

    private var areaFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" chip
                CompareAreaChip(
                    label: "All",
                    isSelected: viewModel.selectedArea == nil,
                    activeColor: primaryPurple
                ) {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        viewModel.selectedArea = nil
                    }
                }
                // Per-area chips
                ForEach(ScanRecord.FaceArea.allCases) { area in
                    CompareAreaChip(
                        label: area.rawValue,
                        isSelected: viewModel.selectedArea == area,
                        activeColor: primaryPurple
                    ) {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            viewModel.selectedArea = area
                        }
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: - Face Images (181 x 213 with margin 8)

    private var faceImages: some View {
        HStack(spacing: 8) {
            CompareFaceImage(
                record: viewModel.recordA,
                selectedArea: viewModel.selectedArea,
                borderColor: cardBorder
            ) { imageData, title, dateText in
                activeDetailPayload = PhotoDetailPayload(imageData: imageData, title: title, dateText: dateText)
            }

            CompareFaceImage(
                record: viewModel.recordB,
                selectedArea: viewModel.selectedArea,
                borderColor: cardBorder
            ) { imageData, title, dateText in
                activeDetailPayload = PhotoDetailPayload(imageData: imageData, title: title, dateText: dateText)
            }
        }
    }

    // MARK: - Combined Skin Score & Summary Insight Card

    private var skinScoreAndInsightCard: some View {
        let diff = viewModel.scoreDiff
        return VStack(alignment: .leading, spacing: 14) {
            if viewModel.selectedArea == nil {
                // Skin Score Top Section (All mode only)
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 4) {
                        Text("Skin Score")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.primary)
                        Button {
                            showAboutSkinScore = true
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.system(size: 14))
                                .foregroundStyle(.primary)
                        }
                        .accessibilityLabel("About Skin Score")
                    }

                    HStack {
                        Text("\(viewModel.recordA.skinScore)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.primary)
                            .monospacedDigit()

                        Spacer()

                        Image(systemName: "arrow.right")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.primary)
                            .accessibilityHidden(true)

                        Spacer()

                        Text("\(viewModel.recordB.skinScore)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.primary)
                            .monospacedDigit()
                    }
                }

                Divider()
                    .overlay(cardBorder.opacity(0.6))
            }

            // Summary Insight Section
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Summary Insight")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(.secondaryLabel))

                    Text(viewModel.insightHeadline)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(primaryPurple)

                    Text(viewModel.insightBody)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.primary)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if viewModel.selectedArea != nil {
                    Spacer(minLength: 8)

                    // Score Delta Circle Badge (visible in region-specific chip modes)
                    VStack(spacing: 2) {
                        Text("Score")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(primaryPurple)

                        Text("\(diff >= 0 ? "+" : "")\(diff)")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(primaryPurple)
                            .monospacedDigit()
                    }
                    .frame(width: 68, height: 68)
                    .background(primaryPurple.opacity(0.14))
                    .clipShape(Circle())
                }
            }
        }
        .padding(16)
        .background(cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Total Acne Section

    private var totalAcneSection: some View {
        let diff = viewModel.filteredAcneDiff
        return VStack(alignment: .leading, spacing: 12) {
            Text("Total Acne")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.primary)

            HStack(alignment: .center) {
                Text("\(viewModel.filteredAcneA)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.primary)
                    .monospacedDigit()

                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .accessibilityHidden(true)

                Text("\(viewModel.filteredAcneB)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.primary)
                    .monospacedDigit()

                Spacer()

                // Delta Badge
                VStack(spacing: 2) {
                    Text("\(diff > 0 ? "+" : "")\(diff)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(primaryPurple)
                    Text("Acne spots")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(primaryPurple)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(cardFill)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    // MARK: - Acne Breakdown Section

    private var acneBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if viewModel.selectedArea == nil {
                // All Mode: Native Segmented Control
                Picker("Acne breakdown mode", selection: $viewModel.acneMode) {
                    ForEach(AcneBreakdownMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                let rows = viewModel.acneMode == .byType
                    ? viewModel.acneTypeRows
                    : viewModel.acneAreaRows

                VStack(spacing: 12) {
                    ForEach(rows) { row in
                        CompareBreakdownRow(row: row, cardFill: cardFill, primaryPurple: primaryPurple)
                    }
                }
            } else {
                // Region Chip Mode: "Acne Type (i)" title (NO segmented button)
                HStack(spacing: 4) {
                    Text("Acne Type")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.primary)

                    Button {
                        showAboutSkinScore = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("About Acne Type")
                }

                VStack(spacing: 12) {
                    ForEach(viewModel.acneTypeRows) { row in
                        CompareBreakdownRow(row: row, cardFill: cardFill, primaryPurple: primaryPurple)
                    }
                }
            }
        }
    }
}

// MARK: - CompareAreaChip

private struct CompareAreaChip: View {
    let label: String
    let isSelected: Bool
    let activeColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(
                        isSelected
                            ? activeColor
                            : Color(.systemBackground)
                    )
                )
                .overlay(
                    Capsule()
                        .stroke(
                            isSelected ? Color.clear : Color(.systemGray4),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isSelected ? "\(label), selected" : label)
    }
}



// MARK: - CompareFaceImage

private struct CompareFaceImage: View {
    let record: ScanRecord
    let selectedArea: ScanRecord.FaceArea?
    let borderColor: Color
    let onTap: (Data?, String, String) -> Void

    private static let subZoneCrops: [ScanRecord.FaceArea: CGRect] = [
        .forehead:   CGRect(x: 0.15, y: 0.08, width: 0.70, height: 0.32),
        .nose:       CGRect(x: 0.25, y: 0.35, width: 0.50, height: 0.30),
        .chin:       CGRect(x: 0.25, y: 0.62, width: 0.50, height: 0.28),
        .rightCheek: CGRect(x: 0.45, y: 0.25, width: 0.45, height: 0.45),
        .leftCheek:  CGRect(x: 0.10, y: 0.25, width: 0.45, height: 0.45)
    ]

    static func cropImageData(_ data: Data?, area: ScanRecord.FaceArea) -> Data? {
        guard let data = data, !data.isEmpty else { return nil }
        #if canImport(UIKit)
        guard let cropRect = subZoneCrops[area],
              let sourceImage = UIImage(data: data) else { return nil }

        let originalSize = sourceImage.size
        guard originalSize.width > 0, originalSize.height > 0 else { return nil }

        let cropWidth = originalSize.width * cropRect.width
        let cropHeight = originalSize.height * cropRect.height
        let targetSize = CGSize(width: cropWidth, height: cropHeight)

        let drawX = -cropRect.origin.x * originalSize.width
        let drawY = -cropRect.origin.y * originalSize.height

        let format = UIGraphicsImageRendererFormat()
        format.scale = sourceImage.scale
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)

        let croppedImage = renderer.image { _ in
            sourceImage.draw(in: CGRect(
                x: drawX,
                y: drawY,
                width: originalSize.width,
                height: originalSize.height
            ))
        }

        return croppedImage.jpegData(compressionQuality: 0.85)
        #else
        return nil
        #endif
    }

    static func drawMarkersOnImage(imageData: Data?, markers: [MarkerModel]) -> Data? {
        guard let imageData = imageData, !imageData.isEmpty,
              let uiImage = UIImage(data: imageData) else { return imageData }
        guard !markers.isEmpty else { return imageData }

        #if canImport(UIKit)
        let size = uiImage.size
        guard size.width > 0, size.height > 0 else { return imageData }

        let format = UIGraphicsImageRendererFormat()
        format.scale = uiImage.scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        let renderedImage = renderer.image { _ in
            uiImage.draw(in: CGRect(origin: .zero, size: size))

            let strokeWidth = max(3.0, size.width / 200.0)

            for marker in markers {
                let box = marker.normalizedBoundingBox
                let rect = CGRect(
                    x: box.minX * size.width,
                    y: box.minY * size.height,
                    width: box.width * size.width,
                    height: box.height * size.height
                )

                let color = uiMarkerColor(for: marker.acneType)
                color.setStroke()

                let path = UIBezierPath(roundedRect: rect, cornerRadius: max(3.0, strokeWidth / 2))
                path.lineWidth = strokeWidth
                path.stroke()
            }
        }

        return renderedImage.jpegData(compressionQuality: 0.85) ?? imageData
        #else
        return imageData
        #endif
    }

    private static func uiMarkerColor(for type: AcneType) -> UIColor {
        switch type {
        case .blackhead:  return .brown
        case .cyst:       return .red
        case .nodule:     return .purple
        case .papule:     return .orange
        case .pustule:    return .yellow
        case .whitehead:  return .white
        case .unknown:    return .gray
        }
    }

    private var renderedImageData: Data? {
        let rawData: Data?
        let activeMarkers: [MarkerModel]

        if let area = selectedArea {
            rawData = record.subZoneThumbnails?[area]
                ?? Self.cropImageData(record.frontImageData, area: area)
                ?? record.frontImageData
            activeMarkers = record.areaMarkers?[area] ?? []
        } else {
            rawData = record.frontImageData
            activeMarkers = record.frontMarkers ?? []
        }

        return Self.drawMarkersOnImage(imageData: rawData, markers: activeMarkers)
    }

    private var photoTitle: String {
        selectedArea?.rawValue ?? "Face Capture"
    }

    var body: some View {
        let displayImageData = renderedImageData
        let displayTitle = photoTitle
        let dateStr = CompareViewModel.displayDateFormatter.string(from: record.date)

        Button {
            onTap(displayImageData, displayTitle, dateStr)
        } label: {
            ZStack(alignment: .bottom) {
                Group {
                    if let data = displayImageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .id(selectedArea?.rawValue ?? "All")
                            .transition(.opacity)
                    } else {
                        Rectangle()
                            .fill(Color(.systemBackground))
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "person.crop.rectangle")
                                        .font(.system(size: 36))
                                        .foregroundStyle(.secondary)
                                    Text("No Image")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                }
                            )
                    }
                }
                .frame(width: 181, height: 213)
                .clipped()

                // Date banner overlay at bottom of photo frame (matching History page layout)
                HStack {
                    Spacer()
                    Text(dateStr)
                        .font(Font.metadata)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.50))
            }
            .animation(.easeInOut(duration: 0.25), value: selectedArea)
            .frame(width: 181, height: 213)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(record.frontImageData != nil ? "\(displayTitle), tap to view full photo" : "No face image available")
    }
}


// MARK: - CompareBreakdownRow

private struct CompareBreakdownRow: View {
    let row: AcneComparisonRow
    let cardFill: Color
    let primaryPurple: Color

    var body: some View {
        HStack(spacing: 8) {
            Text(row.label)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.primary)
                .frame(minWidth: 100, alignment: .leading)

            Spacer()

            Text("\(row.valueA)")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)
                .monospacedDigit()

            Image(systemName: "arrow.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text("\(row.valueB)")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)
                .monospacedDigit()

            // Delta Badge
            let diff = row.delta
            Text("\(diff >= 0 ? "+" : "")\(diff)")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(primaryPurple)
                .monospacedDigit()
                .frame(width: 42)
                .padding(.vertical, 6)
                .background(cardFill)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(row.label): \(row.valueA) before, \(row.valueB) after, difference \(row.delta)")
    }
}

// MARK: - FullPhotoDetailView

private struct FullPhotoDetailView: View {
    let imageData: Data?
    let title: String
    let dateText: String

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                if let data = imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 4)
                        .padding(.horizontal, 16)
                } else {
                    ContentUnavailableView(
                        "No Image Available",
                        systemImage: "person.crop.rectangle",
                        description: Text("No photo data found for this scan record.")
                    )
                }

                Spacer()

                // Date & Area Badge
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text("·")
                        .foregroundStyle(.secondary)

                    Text(dateText)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .padding(.bottom, 24)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
}
