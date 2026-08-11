import SwiftUI
import Charts

struct ReportAcneTypeChartView: View {
    let points: [AcneSeriesPoint]
    let dayLabels: [String]
    let selectedDay: String?
    let onSelectDay: (String) -> Void
    private let minChartWidth: CGFloat = 320
    private let widthPerPoint: CGFloat = 56

    private var colorScale: KeyValuePairs<String, Color> {
        [
            AcneType.whitehead.displayName: AcneType.whitehead.color,
            AcneType.blackhead.displayName: AcneType.blackhead.color,
            AcneType.papule.displayName: AcneType.papule.color,
            AcneType.pustule.displayName: AcneType.pustule.color,
            AcneType.nodule.displayName: AcneType.nodule.color,
            AcneType.cyst.displayName: AcneType.cyst.color
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            GeometryReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    ZStack(alignment: .topLeading) {
                        Chart {
                            ForEach(points) { point in
                                LineMark(
                                    x: .value("Day", point.day),
                                    y: .value("Score", point.score),
                                    series: .value("Acne Type", point.acneType.displayName)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(by: .value("Acne Type", point.acneType.displayName))

                                PointMark(
                                    x: .value("Day", point.day),
                                    y: .value("Score", point.score)
                                )
                                .symbolSize(selectedDay == point.day ? 140 : 70)
                                .foregroundStyle(by: .value("Acne Type", point.acneType.displayName))
                                .opacity(selectedDay == point.day ? 1 : 0.75)
                            }

                            if let selectedDay {
                                RuleMark(x: .value("Selected Day", selectedDay))
                                    .foregroundStyle(AppColor.textSecondary.opacity(0.45))
                                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            }
                        }
                        .chartForegroundStyleScale(colorScale)
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
                        .chartLegend(.hidden)
                        .chartPlotStyle { plotArea in
                            plotArea.cornerRadius(AppCornerRadius.md)
                        }
                        .frame(width: chartWidth(availableWidth: proxy.size.width))

                        HStack(spacing: 0) {
                            ForEach(dayLabels, id: \ .self) { day in
                                Color.clear
                                    .contentShape(Rectangle())
                                    .frame(width: widthPerPoint)
                                    .onTapGesture {
                                        onSelectDay(day)
                                    }
                            }
                        }
                        .frame(width: chartWidth(availableWidth: proxy.size.width), height: proxy.size.height)
                    }
                }
            }
        }
    }

    private func chartWidth(availableWidth: CGFloat) -> CGFloat {
        let uniqueDaysCount = Set(points.map(\ .day)).count
        let dataWidth = CGFloat(Swift.max(uniqueDaysCount, 1)) * widthPerPoint
        return Swift.max(availableWidth, Swift.max(minChartWidth, dataWidth))
    }
}
