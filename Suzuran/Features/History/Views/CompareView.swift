import SwiftUI

// MARK: - CompareView
//
// Pushed via NavigationStack from HistoryView — NOT a modal/sheet.
// All presentation logic lives in CompareViewModel; this file only renders UI.

struct CompareView: View {

    @StateObject private var viewModel: CompareViewModel

    // MARK: - Init

    init(recordA: ScanRecord, recordB: ScanRecord, allRecords: [ScanRecord]) {
        _viewModel = StateObject(
            wrappedValue: CompareViewModel(
                recordA: recordA,
                recordB: recordB,
                allRecords: allRecords
            )
        )
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
            HStack(spacing: 4) {
                Text("Skin Score")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.primary)
                Image(systemName: "info.circle")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }

            HStack {
                Text("\(viewModel.recordA.skinScore)")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .monospacedDigit()

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)

                Spacer()

                Text("\(viewModel.recordB.skinScore)")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
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
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)

                    Text(viewModel.insightHeadline)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.primary)

                    Text(viewModel.insightBody)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: AppSpacing.sm)

                // Score delta badge — visible in area-specific modes only
                if viewModel.selectedArea != nil {
                    VStack(spacing: 2) {
                        Text("Score")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Text("\(diff >= 0 ? "+" : "")\(diff)")
                            .font(.system(size: 22, weight: .bold))
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
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.primary)
                    if let area = viewModel.selectedArea {
                        Text("· \(area.rawValue)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(alignment: .center) {
                    Text("\(viewModel.filteredAcneA)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .monospacedDigit()

                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, AppSpacing.xs)
                        .accessibilityHidden(true)

                    Text("\(viewModel.filteredAcneB)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .monospacedDigit()

                    Spacer()

                    // Delta badge
                    VStack(spacing: 2) {
                        Text("\(diff > 0 ? "+" : "")\(diff)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(diff <= 0 ? AppColor.accentPrimary : AppColor.accentDanger)
                            .monospacedDigit()
                        Text("Acne spots")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                            .fill(Color(.systemGray5))
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
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(
                        isSelected
                            ? Color(.systemGray)
                            : Color(.secondarySystemGroupedBackground)
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

// MARK: - CompareDateChip

private struct CompareDateChip: View {
    let date: Date
    let formatter: DateFormatter

    var body: some View {
        HStack(spacing: 4) {
            Text(formatter.string(from: date))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
            Image(systemName: "chevron.down")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
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
                    .fill(Color(.systemGray5))
                    .overlay(
                        VStack(spacing: AppSpacing.xs) {
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
                .font(.system(size: 15))
                .foregroundStyle(.primary)
                .frame(minWidth: 90, alignment: .leading)

            Spacer()

            Text("\(row.valueA)")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
                .monospacedDigit()

            Image(systemName: "arrow.right")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text("\(row.valueB)")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.primary)
                .monospacedDigit()

            // Delta badge
            let diff = row.delta
            Text("\(diff >= 0 ? "+" : "")\(diff)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(diff <= 0 ? AppColor.accentPrimary : AppColor.accentDanger)
                .monospacedDigit()
                .frame(minWidth: 44)
                .padding(.horizontal, AppSpacing.xs)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                        .fill(Color(.systemGray5))
                )
        }
        .padding(.vertical, 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(row.label): \(row.valueA) before, \(row.valueB) after, difference \(row.delta)")
    }
}
