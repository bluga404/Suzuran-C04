import SwiftUI
import PhotosUI

struct AcneScannerView: View {
    @StateObject private var viewModel = AcneScannerViewModel()
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                imageSection
                analyzeButton
                resultsSection
            }
            .padding(AppSpacing.md)
        }
        .navigationTitle("ML Model Test")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if viewModel.state == .result {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Reset") {
                        selectedItem = nil
                        viewModel.reset()
                    }
                }
            }
        }
        .appScreenContainer()
        .onChange(of: selectedItem) { _, newItem in
            loadImage(from: newItem)
        }
    }

    // MARK: - Image Section

    @ViewBuilder
    private var imageSection: some View {
        AppCard {
            VStack(spacing: AppSpacing.md) {
                if let image = viewModel.displayImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
                        .overlay {
                            if viewModel.state == .result {
                                detectionOverlay
                            }
                        }
                } else {
                    VStack(spacing: AppSpacing.sm) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 48))
                            .foregroundStyle(AppColor.textSecondary)
                        Text("Select a photo to analyze")
                            .font(AppTypography.body)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                }

                let hasImage = viewModel.displayImage != nil
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label(
                        hasImage ? "Change Photo" : "Select Photo",
                        systemImage: "photo.badge.plus"
                    )
                    .font(AppTypography.bodyBold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm)
                    .background(AppColor.accentPrimary.opacity(0.1))
                    .foregroundStyle(AppColor.accentPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.md))
                }
            }
        }
    }

    // MARK: - Detection Overlay

    @ViewBuilder
    private var detectionOverlay: some View {
        GeometryReader { geometry in
            let imageSize = viewModel.displayImage?.size ?? .zero
            ForEach(viewModel.detections) { detection in
                let rect = visionToView(detection.boundingBox, in: geometry.size, imageSize: imageSize)

                Rectangle()
                    .stroke(detection.acneType.color, lineWidth: 2)
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)

                Text(String(format: "%@ (%.0f%%)", detection.acneType.displayName, detection.confidence * 100))
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(detection.acneType.color.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                    .position(x: rect.midX, y: max(rect.minY - 8, 6))
            }
        }
    }

    // MARK: - Analyze Button

    @ViewBuilder
    private var analyzeButton: some View {
        if viewModel.displayImage != nil {
            switch viewModel.state {
            case .idle, .failed:
                PrimaryButton(title: "Analyze") {
                    viewModel.analyze()
                }
            case .analyzing:
                PrimaryButton(title: "Analyzing...", isLoading: true) {}
            case .result:
                EmptyView()
            }
        }
    }

    // MARK: - Results Section

    @ViewBuilder
    private var resultsSection: some View {
        switch viewModel.state {
        case .result:
            if let score = viewModel.scoreResult {
                scoreCard(score)
                breakdownCard(score)
                detectionsListCard
            }
        case .failed(let message):
            AppCard {
                VStack(spacing: AppSpacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(AppColor.accentDanger)
                    Text(message)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
        default:
            EmptyView()
        }
    }

    // MARK: - Score Card

    private func scoreCard(_ score: SkinHealthResult) -> some View {
        AppCard {
            VStack(spacing: AppSpacing.md) {
                Text("Skin Health Score")
                    .font(AppTypography.subtitle)
                    .foregroundStyle(AppColor.textSecondary)

                ZStack {
                    Circle()
                        .stroke(AppColor.borderSubtle, lineWidth: 12)
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
                            .foregroundStyle(AppColor.textPrimary)
                        Text("/ 100")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }

                Text(score.label)
                    .font(AppTypography.bodyBold)
                    .foregroundStyle(score.color)

                Text("Weighted Count: \(formatWeight(score.weightedCount)) / 60")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Breakdown Card

    private func breakdownCard(_ score: SkinHealthResult) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Acne Breakdown")
                    .font(AppTypography.subtitle)
                    .foregroundStyle(AppColor.textPrimary)

                Divider()

                ForEach(AcneType.allCases, id: \.self) { type in
                    let count = score.breakdown[type] ?? 0
                    HStack {
                        Circle()
                            .fill(type.color)
                            .frame(width: 10, height: 10)

                        Text(type.displayName)
                            .font(AppTypography.body)
                            .foregroundStyle(AppColor.textPrimary)

                        Spacer()

                        Text("\(count)")
                            .font(AppTypography.bodyBold)
                            .foregroundStyle(AppColor.textPrimary)

                        Text("×\(formatWeight(type.severityWeight)) = \(formatWeight(Float(count) * type.severityWeight))")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColor.textSecondary)
                            .frame(width: 72, alignment: .trailing)
                    }
                }

                Divider()

                HStack {
                    Text("Total Detections")
                        .font(AppTypography.bodyBold)
                        .foregroundStyle(AppColor.textPrimary)
                    Spacer()
                    Text("\(viewModel.detections.count)")
                        .font(AppTypography.bodyBold)
                        .foregroundStyle(AppColor.accentPrimary)
                }
            }
        }
    }

    // MARK: - Detections List Card

    @ViewBuilder
    private var detectionsListCard: some View {
        if !viewModel.detections.isEmpty {
            AppCard {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Detailed Detections")
                        .font(AppTypography.subtitle)
                        .foregroundStyle(AppColor.textPrimary)

                    Divider()

                    ForEach(Array(viewModel.detections.enumerated()), id: \.element.id) { index, detection in
                        HStack {
                            Text("#\(index + 1)")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColor.textSecondary)
                                .frame(width: 32, alignment: .leading)

                            Circle()
                                .fill(detection.acneType.color)
                                .frame(width: 8, height: 8)

                            Text(detection.acneType.displayName)
                                .font(AppTypography.bodyBold)
                                .foregroundStyle(AppColor.textPrimary)

                            Spacer()

                            Text(String(format: "%.1f%% Conf", detection.confidence * 100))
                                .font(AppTypography.body)
                                .foregroundStyle(AppColor.accentPrimary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    /// Converts Vision normalized coordinates (origin bottom-left, 0–1)
    /// to view coordinates (origin top-left, pixel values), accounting for aspect ratio scaling (scaledToFit).
    private func visionToView(_ box: CGRect, in viewSize: CGSize, imageSize: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0, viewSize.width > 0, viewSize.height > 0 else {
            let x = box.origin.x * viewSize.width
            let y = (1.0 - box.origin.y - box.height) * viewSize.height
            let width = box.width * viewSize.width
            let height = box.height * viewSize.height
            return CGRect(x: x, y: y, width: width, height: height)
        }

        let imageAspect = imageSize.width / imageSize.height
        let viewAspect = viewSize.width / viewSize.height

        let scale: CGFloat
        let offsetX: CGFloat
        let offsetY: CGFloat

        if imageAspect > viewAspect {
            // Image is wider than container view -> letterboxed top & bottom
            scale = viewSize.width / imageSize.width
            offsetX = 0
            offsetY = (viewSize.height - imageSize.height * scale) / 2.0
        } else {
            // Image is taller than container view -> pillarboxed left & right
            scale = viewSize.height / imageSize.height
            offsetX = (viewSize.width - imageSize.width * scale) / 2.0
            offsetY = 0
        }

        let width = box.width * imageSize.width * scale
        let height = box.height * imageSize.height * scale
        let x = offsetX + box.origin.x * imageSize.width * scale
        let y = offsetY + (1.0 - box.origin.y - box.height) * imageSize.height * scale

        return CGRect(x: x, y: y, width: width, height: height)
    }

    private func formatWeight(_ value: Float) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func loadImage(from item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                viewModel.loadImage(data: data)
            }
        }
    }
}

#Preview {
    NavigationStack {
        AcneScannerView()
    }
}
