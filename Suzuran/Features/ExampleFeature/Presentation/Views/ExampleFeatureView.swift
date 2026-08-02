import SwiftUI

struct ExampleFeatureView: View {
    @StateObject private var viewModel: ExampleFeatureViewModel

    init(viewModel: ExampleFeatureViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Example Feature: Acne Detection")
                    .font(AppTypography.title)
                    .foregroundStyle(AppColor.textPrimary)

                Text("This view is intentionally not connected to app navigation. It exists as a full architecture reference.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textSecondary)

                AppCard {
                    VStack(spacing: AppSpacing.sm) {
                        PrimaryButton(title: "Run Sample Analysis", action: viewModel.analyzeSampleImage)
                        PrimaryButton(title: "Load History", style: .bordered, action: viewModel.loadHistory)
                        PrimaryButton(title: "Reset", style: .destructive, action: viewModel.reset)
                    }
                }

                contentView
            }
            .padding(AppSpacing.md)
        }
        .appScreenContainer()
    }

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .idle:
            EmptyStateView(
                title: "No Analysis Yet",
                message: "Run sample analysis to see how the full MVVM + Clean Architecture flow works."
            )

        case .analyzing:
            LoadingStateView(
                title: "Analyzing Face",
                subtitle: "Simulating acne detection request and mapping the result."
            )

        case let .analysisResult(model):
            analysisCard(model)

        case let .history(items):
            VStack(spacing: AppSpacing.sm) {
                ForEach(items) { item in
                    analysisCard(item)
                }
            }

        case .emptyHistory:
            EmptyStateView(
                title: "No History",
                message: "No previous analysis results were found in local storage."
            )

        case let .error(message):
            ErrorStateView(
                title: "Analysis Error",
                message: message,
                primaryActionTitle: "Try Again",
                onPrimaryAction: viewModel.analyzeSampleImage
            )
        }
    }

    @ViewBuilder
    private func analysisCard(_ model: AcneAnalysisCardModel) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(model.dateText)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)

                Text("Severity: \(model.severityText)")
                    .font(AppTypography.bodyBold)
                    .foregroundStyle(AppColor.textPrimary)

                Text(model.confidenceText)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textSecondary)

                Text(model.findingsSummary)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textPrimary)

                Text("Recommendation: \(model.recommendation)")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
    }
}

#Preview {
    ExampleFeatureFactory.makeView()
}
