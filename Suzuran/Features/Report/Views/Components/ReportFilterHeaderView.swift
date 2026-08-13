import SwiftUI

struct ReportFilterHeaderView: View {
    let selectedMetric: ReportMetric
    let selectedRange: ReportRange
    let onMetricChanged: (ReportMetric) -> Void
    let onRangeChanged: (ReportRange) -> Void

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Picker("Metric", selection: Binding(get: {
                selectedMetric
            }, set: { newValue in
                onMetricChanged(newValue)
            })) {
                ForEach(ReportMetric.allCases) { metric in
                    Text(metric.rawValue).tag(metric)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                Text(selectedMetric.rawValue)
                    .font(Font.bodyParagraph)
                    .foregroundStyle(AppColor.textPrimary)

                Spacer()

                Menu {
                    Picker("Filter", selection: Binding(get: {
                        selectedRange
                    }, set: { newValue in
                        onRangeChanged(newValue)
                    })) {
                        ForEach(ReportRange.allCases) { range in
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
        }
    }
}
