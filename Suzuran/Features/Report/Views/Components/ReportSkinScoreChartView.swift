import SwiftUI
import Charts

struct ReportSkinScoreChartView: View {
    let data: [ReportPoint]
    private let minChartWidth: CGFloat = 320
    private let widthPerPoint: CGFloat = 56
    private let chartPadding: CGFloat = 16

    var body: some View {
        GeometryReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
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
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: score == 0 ? [] : [5, 5]))
                        }
                        AxisValueLabel()
                    }
                }
                .chartPlotStyle { plotArea in
                    plotArea.cornerRadius(AppCornerRadius.md)
                }
                .chartYScale(domain: 0...100)
                .frame(width: chartWidth(availableWidth: proxy.size.width), height: 240)
                .padding(.top, 8)
                .padding(.bottom, 8)
            }
            .padding(.bottom, 4)
        }
        .frame(minHeight: 240)
    }

    private func chartWidth(availableWidth: CGFloat) -> CGFloat {
        let dataWidth = CGFloat(Swift.max(data.count, 1)) * widthPerPoint
        return Swift.max(availableWidth + (chartPadding * 2), Swift.max(minChartWidth, dataWidth + (chartPadding * 2)))
    }
}
