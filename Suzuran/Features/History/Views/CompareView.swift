import SwiftUI

// MARK: - CompareView
//
// Pushed via NavigationStack from HistoryView — NOT a modal/sheet.
// All presentation logic lives in CompareViewModel; this file only renders UI.

struct CompareView: View {

    @ObservedObject private var viewModel: CompareViewModel

    // MARK: - Init

    init(viewModel: CompareViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                areaFilterChips
                dateSelectors
                faceImages
                if viewModel.selectedArea == nil {
                    skinScoreSection
                }
                insightCard
                totalAcneCard
                acneBreakdownCard
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.sm)
            .padding(.bottom, AppSpacing.xl)
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
        .navigationTitle("Compare")
        .navigationBarTitleDisplayMode(.inline)
        // Date picker for "before" slot
        .confirmationDialog(
            "Select 'Before' Date",
            isPresented: $viewModel.showDatePickerA,
            titleVisibility: .visible
        ) {
            ForEach(viewModel.candidatesForA) { record in
                Button(CompareViewModel.displayDateFormatter.string(from: record.date)) {
                    viewModel.selectRecordA(record)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        // Date picker for "after" slot
        .confirmationDialog(
            "Select 'After' Date",
            isPresented: $viewModel.showDatePickerB,
            titleVisibility: .visible
        ) {
            ForEach(viewModel.candidatesForB) { record in
                Button(CompareViewModel.displayDateFormatter.string(from: record.date)) {
                    viewModel.selectRecordB(record)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Area Filter Chips

    private var areaFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                // "All" chip
                CompareAreaChip(
                    label: "All",
                    isSelected: viewModel.selectedArea == nil
                ) {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        viewModel.selectedArea = nil
                    }
                }
                // Per-area chips
                ForEach(ScanRecord.FaceArea.allCases) { area in
                    CompareAreaChip(
                        label: area.rawValue,
                        isSelected: viewModel.selectedArea == area
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

    // MARK: - Date Selectors

    private var dateSelectors: some View {
        HStack(spacing: AppSpacing.sm) {
            // Tap to switch "before" record
            Button {
                viewModel.showDatePickerA = true
            } label: {
                CompareDateChip(
                    date: viewModel.recordA.date,
                    formatter: CompareViewModel.displayDateFormatter
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Before date: \(CompareViewModel.displayDateFormatter.string(from: viewModel.recordA.date)). Tap to change.")

            // Tap to switch "after" record
            Button {
                viewModel.showDatePickerB = true
            } label: {
                CompareDateChip(
                    date: viewModel.recordB.date,
                    formatter: CompareViewModel.displayDateFormatter
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("After date: \(CompareViewModel.displayDateFormatter.string(from: viewModel.recordB.date)). Tap to change.")
        }
    }

    // MARK: - Face Images

    private var faceImages: some View {
        HStack(spacing: AppSpacing.sm) {
            CompareFaceImage(record: viewModel.recordA)
            CompareFaceImage(record: viewModel.recordB)
        }
    }

    // MARK: - Skin Score Section (All filter only)

    private var skinScoreSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.xxs) {
                Text("Skin Score")
                    .font(.custom("AvenirNext-DemiBold", size: 18, relativeTo: .headline))
                    .foregroundStyle(.primary)
                Image(systemName: "info.circle")
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }

            HStack {
                Text("\(viewModel.recordA.skinScore)")
                    .font(.custom("AvenirNext-Bold", size: 52, relativeTo: .largeTitle))
                    .foregroundStyle(.primary)
                    .monospacedDigit()

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.custom("AvenirNext-DemiBold", size: 20, relativeTo: .title3))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)

                Spacer()

                Text("\(viewModel.recordB.skinScore)")
                    .font(.custom("AvenirNext-Bold", size: 52, relativeTo: .largeTitle))
                    .foregroundStyle(.primary)
                    .monospacedDigit()
            }
            .padding(.vertical, AppSpacing.xs)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Skin score: \(viewModel.recordA.skinScore) before, \(viewModel.recordB.skinScore) after")
        }
    }

    // MARK: - Summary Insight Card

    private var insightCard: some View {
        let diff = viewModel.scoreDiff
        return AppCard {
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("Summary Insight")
                        .font(.custom("AvenirNext-Medium", size: 12, relativeTo: .caption))
                        .foregroundStyle(.secondary)

                    Text(viewModel.insightHeadline)
                        .font(.custom("AvenirNext-Bold", size: 17, relativeTo: .headline))
                        .foregroundStyle(.primary)

                    Text(viewModel.insightBody)
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: AppSpacing.sm)

                // Score delta badge — visible in area-specific modes only
                if viewModel.selectedArea != nil {
                    VStack(spacing: AppSpacing.xxs) {
                        Text("Score")
                            .font(.custom("AvenirNext-Regular", size: 11, relativeTo: .caption2))
                            .foregroundStyle(.secondary)
                        Text("\(diff >= 0 ? "+" : "")\(diff)")
                            .font(.custom("AvenirNext-Bold", size: 22, relativeTo: .title2))
                            .foregroundStyle(diff >= 0 ? AppColor.accentPrimary : AppColor.accentDanger)
                            .monospacedDigit()
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, AppSpacing.xs)
                            .background(
                                RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                                    .fill(diff >= 0
                                          ? AppColor.accentPrimary.opacity(0.12)
                                          : AppColor.accentDanger.opacity(0.12))
                            )
                    }
                    .fixedSize()
                    .accessibilityLabel("Score change: \(diff >= 0 ? "plus" : "")\(diff)")
                }
            }
        }
    }

    // MARK: - Total Acne Card

    private var totalAcneCard: some View {
        let diff = viewModel.filteredAcneDiff
        return AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // Title
                HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xxs) {
                    Text("Total Acne")
                        .font(.custom("AvenirNext-Bold", size: 18, relativeTo: .headline))
                        .foregroundStyle(.primary)
                    if let area = viewModel.selectedArea {
                        Text("· \(area.rawValue)")
                            .font(.custom("AvenirNext-Medium", size: 14, relativeTo: .subheadline))
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(alignment: .center) {
                    Text("\(viewModel.filteredAcneA)")
                        .font(.custom("AvenirNext-Bold", size: 28, relativeTo: .title))
                        .foregroundStyle(.primary)
                        .monospacedDigit()

                    Image(systemName: "arrow.right")
                        .font(.custom("AvenirNext-DemiBold", size: 16, relativeTo: .callout))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, AppSpacing.xs)
                        .accessibilityHidden(true)

                    Text("\(viewModel.filteredAcneB)")
                        .font(.custom("AvenirNext-Bold", size: 28, relativeTo: .title))
                        .foregroundStyle(.primary)
                        .monospacedDigit()

                    Spacer()

                    // Delta badge
                    VStack(spacing: AppSpacing.xxs) {
                        Text("\(diff > 0 ? "+" : "")\(diff)")
                            .font(.custom("AvenirNext-Bold", size: 20, relativeTo: .title3))
                            .foregroundStyle(diff <= 0 ? AppColor.accentPrimary : AppColor.accentDanger)
                            .monospacedDigit()
                        Text("Acne spots")
                            .font(.custom("AvenirNext-Medium", size: 11, relativeTo: .caption2))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                            .fill(AppColor.surfacePrimary)
                    )
                    .accessibilityLabel("\(diff > 0 ? "plus" : "")\(diff) acne spots")
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Total acne: \(viewModel.filteredAcneA) before, \(viewModel.filteredAcneB) after")
            }
        }
    }

    // MARK: - Acne Breakdown Card

    private var acneBreakdownCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // Segmented control
                Picker("Acne breakdown", selection: $viewModel.acneMode) {
                    ForEach(AcneBreakdownMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Divider()

                // Rows driven by current mode
                let rows = viewModel.acneMode == .byType
                    ? viewModel.acneTypeRows
                    : viewModel.acneAreaRows

                ForEach(rows) { row in
                    CompareBreakdownRow(row: row)
                }
            }
        }
    }
}

// MARK: - CompareAreaChip

private struct CompareAreaChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.custom(isSelected ? "AvenirNext-DemiBold" : "AvenirNext-Regular", size: 14, relativeTo: .subheadline))
                .foregroundStyle(isSelected ? Color(uiColor: .systemBackground) : .primary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .background(
                    Capsule().fill(
                        isSelected
                            ? Color.primary
                            : AppColor.surfacePrimary
                    )
                )
                .overlay(
                    Capsule()
                        .stroke(
                            isSelected ? Color.clear : AppColor.borderSubtle,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isSelected ? "\(label), selected" : label)
    }
}

// MARK: - CompareDateChip

private struct CompareDateChip: View {
    let date: Date
    let formatter: DateFormatter

    var body: some View {
        HStack(spacing: AppSpacing.xxs) {
            Text(formatter.string(from: date))
                .font(AppTypography.caption)
                .foregroundStyle(.primary)
                .lineLimit(1)
            Image(systemName: "chevron.down")
                .font(.custom("AvenirNext-Regular", size: 10, relativeTo: .caption2))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.xs)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

// MARK: - CompareFaceImage

private struct CompareFaceImage: View {
    let record: ScanRecord

    var body: some View {
        Group {
            if let data = record.frontImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(AppColor.surfacePrimary)
                    .overlay(
                        VStack(spacing: AppSpacing.xs) {
                            Image(systemName: "person.crop.rectangle")
                                .font(.custom("AvenirNext-Regular", size: 36, relativeTo: .largeTitle))
                                .foregroundStyle(.secondary)
                            Text("No Image")
                                .font(.custom("AvenirNext-Regular", size: 11, relativeTo: .caption2))
                                .foregroundStyle(.secondary)
                        }
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(0.75, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.md)
                .stroke(Color(.systemGray4), lineWidth: 0.5)
        )
        .accessibilityLabel(record.frontImageData != nil ? "Face capture" : "No face image available")
    }
}

// MARK: - CompareBreakdownRow

private struct CompareBreakdownRow: View {
    let row: AcneComparisonRow

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Text(row.label)
                .font(AppTypography.body)
                .foregroundStyle(.primary)
                .frame(minWidth: 90, alignment: .leading)

            Spacer()

            Text("\(row.valueA)")
                .font(.custom("AvenirNext-Medium", size: 15, relativeTo: .subheadline))
                .foregroundStyle(.secondary)
                .monospacedDigit()

            Image(systemName: "arrow.right")
                .font(.custom("AvenirNext-Regular", size: 11, relativeTo: .caption2))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text("\(row.valueB)")
                .font(.custom("AvenirNext-Medium", size: 15, relativeTo: .subheadline))
                .foregroundStyle(.primary)
                .monospacedDigit()

            // Delta badge
            let diff = row.delta
            Text("\(diff >= 0 ? "+" : "")\(diff)")
                .font(.custom("AvenirNext-DemiBold", size: 13, relativeTo: .caption))
                .foregroundStyle(diff <= 0 ? AppColor.accentPrimary : AppColor.accentDanger)
                .monospacedDigit()
                .frame(minWidth: 44)
                .padding(.horizontal, AppSpacing.xs)
                .padding(.vertical, AppSpacing.xxs)
                .background(
                    RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                        .fill(AppColor.surfacePrimary)
                )
        }
        .padding(.vertical, AppSpacing.xxs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(row.label): \(row.valueA) before, \(row.valueB) after, difference \(row.delta)")
    }
}
