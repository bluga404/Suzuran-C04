import SwiftUI
import Charts

struct ReportSkinScoreChartView: View {
    let data: [ReportPoint]
    private let minChartWidth: CGFloat = 320
    private let widthPerPoint: CGFloat = 56

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
                            if score == 0 {
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                            } else {
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                            }
                        }
                        AxisValueLabel()
                    }
                }
                .chartPlotStyle { plotArea in
                    plotArea.cornerRadius(AppCornerRadius.md)
                }
                .frame(width: chartWidth(availableWidth: proxy.size.width))
            }
        }
    }

    private func chartWidth(availableWidth: CGFloat) -> CGFloat {
        let dataWidth = CGFloat(Swift.max(data.count, 1)) * widthPerPoint
        return Swift.max(availableWidth, Swift.max(minChartWidth, dataWidth))
    }
}
