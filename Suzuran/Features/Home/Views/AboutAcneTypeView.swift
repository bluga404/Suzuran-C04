import SwiftUI

/// Modal view displaying information about different acne types and their severities.
/// Shown when the user taps the info button on the Most Detected card.
struct AboutAcneTypeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isSourcesExpanded = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    headerSection
                    acneTypesList
                    sourcesSection
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.lg)
            }
            .background(AppColor.backgroundPrimary.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close) { dismiss() }
                }
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("About Acne Type")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(AppColor.textPrimary)

            Text("Acne type show different forms of breakouts. Each has a different level of severity.")
                .font(.body)
                .foregroundStyle(AppColor.textSecondary)
        }
    }

    private var acneTypesList: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            ForEach(AcneTypeInfo.allCases) { info in
                InfoPillRow(
                    pillColor: info.type.color,
                    title: info.type.displayName,
                    bodyRegular: info.description
                )
            }
        }
    }

    private var sourcesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Button(action: {
                withAnimation(.easeInOut) {
                    isSourcesExpanded.toggle()
                }
            }) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sources")
                            .font(.headline)
                            .foregroundStyle(AppColor.textPrimary)
                        Text("Our acne type definition are based on dermatology research")
                            .font(.caption)
                            .foregroundStyle(AppColor.textSecondary)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text(isSourcesExpanded ? "See Less" : "See Detail")
                            .font(.subheadline)
                            .foregroundStyle(AppColor.textPrimary)
                        
                        Image(systemName: isSourcesExpanded ? "chevron.up" : "chevron.down")
                            .font(.subheadline)
                            .foregroundStyle(AppColor.textPrimary)
                    }
                    .padding(.top, 4)
                }
            }

            if isSourcesExpanded {
                VStack(spacing: AppSpacing.sm) {
                    SourceCard(
                        title: "A systematic review to evaluate the efficacy of azelaic acid in the management of acne, rosacea, melasma and skin aging.",
                        date: "October 6, 2023"
                    )
                    
                    SourceCard(
                        title: "A systematic review to evaluate the efficacy of azelaic acid in the management of acne, rosacea, melasma and skin aging.",
                        date: "October 6, 2023"
                    )
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.bottom, AppSpacing.xl)
    }
}

// MARK: - Supporting Views

private struct SourceCard: View {
    let title: String
    let date: String

    var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.md) {
            Image(systemName: "link")
                .font(.title2)
                .foregroundStyle(AppColor.textPrimary)
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .italic()
                    .foregroundStyle(AppColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text("Published: \(date)")
                    .font(.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.md)
                .stroke(AppColor.borderSubtle, lineWidth: 1)
        )
    }
}

// MARK: - Data Models

private enum AcneTypeInfo: String, CaseIterable, Identifiable {
    case whitehead, blackhead, papule, pustule, nodule, cyst
    
    var id: String { rawValue }
    
    var type: AcneType {
        switch self {
        case .whitehead: return .whitehead
        case .blackhead: return .blackhead
        case .papule: return .papule
        case .pustule: return .pustule
        case .nodule: return .nodule
        case .cyst: return .cyst
        }
    }
    
    var description: String {
        switch self {
        case .whitehead:
            return "A closed clogged pore that appears as a small white or skin-colored bump."
        case .blackhead:
            return "An open clogged pore that looks black due to contact with air, not dirt."
        case .papule:
            return "A small red, inflamed bump without pus."
        case .pustule:
            return "An inflamed pimple with a visible white or yellow pus-filled center."
        case .nodule:
            return "A deep, hard, painful acne lesion beneath the skin."
        case .cyst:
            return "A deep, painful, pus-filled acne lesion with a high risk of scarring."
        }
    }
}

#Preview {
    AboutAcneTypeView()
}
