import SwiftUI

/// History tab — shows all past scans in a grid grouped by month.
/// Supports a compare mode where the user selects exactly 2 scans to compare.
struct HistoryView: View {
    @ObservedObject private var viewModel: HistoryViewModel

    @State private var navigateToCompare = false

    init(viewModel: HistoryViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: AppSpacing.xs), count: 3)

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMMM yyyy"
        f.locale = Locale(identifier: "en_US")
        return f
    }()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.records.isEmpty {
                    ContentUnavailableView(
                        "Belum Ada Riwayat",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Mulai scan wajah untuk melihat riwayat di sini.")
                    )
                } else {
                    scrollContent
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    compareButton
                }
            }
            .navigationDestination(isPresented: $navigateToCompare) {
                // selectedPair is guaranteed when navigateToCompare=true.
                // Use a fallback EmptyView to satisfy type system safely.
                if let (first, second) = viewModel.selectedPair {
                    HistoryFactory.makeCompareView(
                        recordA: first,
                        recordB: second,
                        allRecords: viewModel.records
                    )
                }
            }
        }
    }

    // MARK: - Compare Button

    private var compareButton: some View {
        HStack(spacing: 8) {
            Button {
                if !viewModel.isCompareMode {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        viewModel.toggleCompareMode()
                    }
                } else if viewModel.canCompare {
                    navigateToCompare = true
                }
            } label: {
                if viewModel.isCompareMode {
                    Text("Compare (\(viewModel.selectedCount)/2)")
                        .font(.custom("AvenirNext-DemiBold", size: 14, relativeTo: .subheadline))
                } else {
                    Text("Compare")
                        .font(.custom("AvenirNext-DemiBold", size: 14, relativeTo: .subheadline))
                }
            }
            .tint(AppColor.accentPrimary)
            .disabled(viewModel.isCompareMode && !viewModel.canCompare)
            .buttonStyle(.glassProminent)

            if viewModel.isCompareMode {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        viewModel.toggleCompareMode()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.custom("AvenirNext-Bold", size: 14, relativeTo: .subheadline))
                }
                .tint(Color.primary)
                .buttonStyle(.glassProminent)
                .accessibilityLabel("Cancel comparison selection")
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
    }

    // MARK: - Grid Content

    private var scrollContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppSpacing.lg) {
                ForEach(viewModel.groupedRecords, id: \.key) { section in
                    Section {
                        LazyVGrid(columns: columns, spacing: AppSpacing.xs) {
                            ForEach(section.records) { record in
                                gridItem(record)
                            }
                        }
                    } header: {
                        Text(section.key)
                            .font(.custom("AvenirNext-Bold", size: 22, relativeTo: .title2))
                            .foregroundStyle(.primary)
                            .padding(.top, AppSpacing.xs)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.bottom, AppSpacing.xl)
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
    }

    // MARK: - Grid Item

    private func gridItem(_ record: ScanRecord) -> some View {
        Button {
            if viewModel.isCompareMode {
                viewModel.toggleSelection(record)
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 6) {
                    // Thumbnail
                    Group {
                        if let data = record.frontImageData,
                           let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Rectangle()
                                .fill(Color(.secondarySystemGroupedBackground))
                                .overlay(
                                    Image(systemName: "person.crop.rectangle")
                                        .font(.custom("AvenirNext-Regular", size: 28, relativeTo: .title))
                                        .foregroundStyle(.secondary)
                                )
                        }
                    }
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                            .stroke(
                                viewModel.isSelected(record) ? AppColor.accentPrimary : AppColor.borderSubtle,
                                lineWidth: viewModel.isSelected(record) ? 2.5 : 0.5
                            )
                    )

                    // Date label
                    Text(dateFormatter.string(from: record.date))
                        .font(.custom("AvenirNext-Medium", size: 11, relativeTo: .caption2))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                // Selection checkmark badge (compare mode only)
                if viewModel.isCompareMode {
                    Image(systemName: viewModel.isSelected(record) ? "checkmark.circle.fill" : "circle")
                        .font(.custom("AvenirNext-Regular", size: 20, relativeTo: .title3))
                        .foregroundStyle(viewModel.isSelected(record) ? AppColor.accentPrimary : Color(uiColor: .systemGray3))
                        .background(Circle().fill(Color(uiColor: .systemBackground)).padding(2))
                        .padding(6)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
