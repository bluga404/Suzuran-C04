import SwiftUI
import Charts

struct ReportView: View {
    enum Metric: String, CaseIterable, Identifiable {
        case skinScore = "Skin Score"
        case acneType = "Acne Type"

        var id: String { rawValue }
    }

    enum Range: String, CaseIterable, Identifiable {
        case oneWeek = "1 Week"
        case oneMonth = "1 Month"

        var id: String { rawValue }
    }

    @ObservedObject private var viewModel: ReportViewModel
    @State private var selectedMetric: Metric = .skinScore
    @State private var selectedRange: Range = .oneWeek
    let onDismiss: () -> Void

    init(viewModel: ReportViewModel, onDismiss: @escaping () -> Void = {}) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self.onDismiss = onDismiss
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    Picker("Metric", selection: $selectedMetric) {
                        ForEach(Metric.allCases) { metric in
                            Text(metric.rawValue).tag(metric)
                        }
                    }
                    .pickerStyle(.segmented)

                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        HStack {
                            Text(selectedMetric.rawValue)
                                .font(AppTypography.subtitle)
                                .foregroundStyle(AppColor.textPrimary)

                            Spacer()

                            Menu {
                                Picker("Filter", selection: $selectedRange) {
                                    ForEach(Range.allCases) { range in
                                        Text(range.rawValue).tag(range)
                                    }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Text(selectedRange.rawValue)
                                        .font(.callout.weight(.semibold))
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.footnote.weight(.semibold))
                                        .symbolRenderingMode(.hierarchical)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                                )
                                .foregroundColor(AppColor.textPrimary)
                            }
                        }

                        ReportChartView(data: reportData)
                            .frame(height: 180)
                    }

                    AppCard {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Compared to 28 July")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColor.textSecondary)

                            HStack {
                                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                    Text("Your Skin is Improving!")
                                        .font(AppTypography.bodyBold)
                                        .foregroundStyle(AppColor.textPrimary)

                                    Text("Score")
                                        .font(AppTypography.caption)
                                        .foregroundStyle(AppColor.textSecondary)
                                }

                                Spacer()

                                Text("+10")
                                    .font(AppTypography.bodyBold)
                                    .foregroundStyle(AppColor.accentPrimary)
                                    .padding(.horizontal, AppSpacing.md)
                                    .padding(.vertical, AppSpacing.sm)
                                    .background(AppColor.surfacePrimary)
                                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.md))
                            }
                        }
                    }

                    AppCard {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            HStack {
                                Text("Summary Insight")
                                    .font(AppTypography.subtitle)
                                    .foregroundStyle(AppColor.textPrimary)

                                Spacer()
                                Image(systemName: "sparkles")
                                    .foregroundStyle(AppColor.accentPrimary)
                            }

                            Text("Lorem ipsum dolor sit amet, nulla deserunt tempor elit veniam esse tempor. In et fugiat dolor consequat nulla laboris fugiat in. Qui nulla deserunt deserunt nemo nostrud occaecat ut in nulla ut enim. Ut velit sint dolore veniam ut enim officia irure velit ut. Ut velit mollit ea in reprehenderit id veniam sed.")
                                .font(AppTypography.body)
                                .foregroundStyle(AppColor.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(AppSpacing.md)
            }
            .navigationTitle("Report")
            .navigationBarTitleDisplayMode(.inline)
            .appScreenContainer()
        }
    }

    private var reportData: [ReportPoint] {
        switch (selectedMetric, selectedRange) {
        case (.skinScore, .oneWeek):
            return [
                .init(day: "Mon", score: 22),
                .init(day: "Tue", score: 28),
                .init(day: "Wed", score: 35),
                .init(day: "Thu", score: 32),
                .init(day: "Fri", score: 38),
                .init(day: "Sat", score: 41),
                .init(day: "Sun", score: 45)
            ]
        case (.skinScore, .oneMonth):
            return [
                .init(day: "Week 1", score: 24),
                .init(day: "Week 2", score: 32),
                .init(day: "Week 3", score: 36),
                .init(day: "Week 4", score: 44)
            ]
        case (.acneType, .oneWeek):
            return [
                .init(day: "Mon", score: 18),
                .init(day: "Tue", score: 22),
                .init(day: "Wed", score: 20),
                .init(day: "Thu", score: 24),
                .init(day: "Fri", score: 26),
                .init(day: "Sat", score: 30),
                .init(day: "Sun", score: 34)
            ]
        case (.acneType, .oneMonth):
            return [
                .init(day: "Week 1", score: 20),
                .init(day: "Week 2", score: 25),
                .init(day: "Week 3", score: 28),
                .init(day: "Week 4", score: 33)
            ]
        }
    }
}

private struct ReportPoint: Identifiable {
    let id = UUID()
    let day: String
    let score: Int
}

private struct ReportChartView: View {
    let data: [ReportPoint]

    var body: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Day", point.day),
                y: .value("Score", point.score)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(AppColor.accentPrimary)

            PointMark(
                x: .value("Day", point.day),
                y: .value("Score", point.score)
            )
            .foregroundStyle(AppColor.accentPrimary)
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 7)) { _ in
                AxisValueLabel(centered: true)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: [0, 25, 50, 75, 100]) { value in
                if let score = value.as(Double.self) {
                    if score == 0 {
                        AxisGridLine(
                            stroke: StrokeStyle(lineWidth: 1)
                        )
                    } else {
                        AxisGridLine(
                            stroke: StrokeStyle(lineWidth: 1, dash: [5, 5])
                        )
                    }
                }
                AxisValueLabel()
            }
        }
        .chartPlotStyle { plotArea in
            plotArea
                .cornerRadius(AppCornerRadius.md)
        }
    }
}
