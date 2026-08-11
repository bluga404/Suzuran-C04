import Foundation

struct ReportDataSnapshot {
    let skinScoreSeriesByRange: [ReportRange: [ReportPoint]]
    let acneTypeSeriesByRange: [ReportRange: [AcneTypeSeries]]
    let comparisonSummary: ReportComparisonSummary
    let insightSummary: ReportInsightSummary
}

final class ReportDataService {
    func loadSnapshot() -> ReportDataSnapshot {
        ReportDataSnapshot(
            skinScoreSeriesByRange: [
                .oneWeek: [
                    .init(day: "Mon", score: 22),
                    .init(day: "Tue", score: 28),
                    .init(day: "Wed", score: 35),
                    .init(day: "Thu", score: 32),
                    .init(day: "Fri", score: 38),
                    .init(day: "Sat", score: 41),
                    .init(day: "Sun", score: 45)
                ],
                .oneMonth: [
                    .init(day: "Week 1", score: 24),
                    .init(day: "Week 2", score: 32),
                    .init(day: "Week 3", score: 36),
                    .init(day: "Week 4", score: 44)
                ],
                .oneYear: [
                    .init(day: "Jan", score: 18),
                    .init(day: "Feb", score: 21),
                    .init(day: "Mar", score: 25),
                    .init(day: "Apr", score: 28),
                    .init(day: "May", score: 31),
                    .init(day: "Jun", score: 33),
                    .init(day: "Jul", score: 37),
                    .init(day: "Aug", score: 39),
                    .init(day: "Sep", score: 41),
                    .init(day: "Oct", score: 42),
                    .init(day: "Nov", score: 44),
                    .init(day: "Dec", score: 46)
                ]
            ],
            acneTypeSeriesByRange: [
                .oneWeek: [
                    .init(acneType: .whitehead, points: [
                        .init(day: "Mon", score: 78), .init(day: "Tue", score: 80), .init(day: "Wed", score: 79),
                        .init(day: "Thu", score: 83), .init(day: "Fri", score: 85), .init(day: "Sat", score: 87), .init(day: "Sun", score: 90)
                    ]),
                    .init(acneType: .blackhead, points: [
                        .init(day: "Mon", score: 66), .init(day: "Tue", score: 68), .init(day: "Wed", score: 67),
                        .init(day: "Thu", score: 70), .init(day: "Fri", score: 73), .init(day: "Sat", score: 74), .init(day: "Sun", score: 76)
                    ]),
                    .init(acneType: .papule, points: [
                        .init(day: "Mon", score: 58), .init(day: "Tue", score: 60), .init(day: "Wed", score: 64),
                        .init(day: "Thu", score: 62), .init(day: "Fri", score: 65), .init(day: "Sat", score: 67), .init(day: "Sun", score: 69)
                    ]),
                    .init(acneType: .pustule, points: [
                        .init(day: "Mon", score: 72), .init(day: "Tue", score: 71), .init(day: "Wed", score: 73),
                        .init(day: "Thu", score: 75), .init(day: "Fri", score: 74), .init(day: "Sat", score: 77), .init(day: "Sun", score: 79)
                    ]),
                    .init(acneType: .nodule, points: [
                        .init(day: "Mon", score: 52), .init(day: "Tue", score: 54), .init(day: "Wed", score: 53),
                        .init(day: "Thu", score: 56), .init(day: "Fri", score: 58), .init(day: "Sat", score: 57), .init(day: "Sun", score: 60)
                    ]),
                    .init(acneType: .cyst, points: [
                        .init(day: "Mon", score: 62), .init(day: "Tue", score: 63), .init(day: "Wed", score: 65),
                        .init(day: "Thu", score: 67), .init(day: "Fri", score: 68), .init(day: "Sat", score: 70), .init(day: "Sun", score: 72)
                    ])
                ],
                .oneMonth: [
                    .init(acneType: .whitehead, points: [
                        .init(day: "Week 1", score: 79), .init(day: "Week 2", score: 83), .init(day: "Week 3", score: 87), .init(day: "Week 4", score: 91)
                    ]),
                    .init(acneType: .blackhead, points: [
                        .init(day: "Week 1", score: 64), .init(day: "Week 2", score: 68), .init(day: "Week 3", score: 73), .init(day: "Week 4", score: 77)
                    ]),
                    .init(acneType: .papule, points: [
                        .init(day: "Week 1", score: 56), .init(day: "Week 2", score: 61), .init(day: "Week 3", score: 65), .init(day: "Week 4", score: 70)
                    ]),
                    .init(acneType: .pustule, points: [
                        .init(day: "Week 1", score: 70), .init(day: "Week 2", score: 72), .init(day: "Week 3", score: 76), .init(day: "Week 4", score: 80)
                    ]),
                    .init(acneType: .nodule, points: [
                        .init(day: "Week 1", score: 51), .init(day: "Week 2", score: 55), .init(day: "Week 3", score: 58), .init(day: "Week 4", score: 62)
                    ]),
                    .init(acneType: .cyst, points: [
                        .init(day: "Week 1", score: 60), .init(day: "Week 2", score: 64), .init(day: "Week 3", score: 69), .init(day: "Week 4", score: 73)
                    ])
                ],
                .oneYear: [
                    .init(acneType: .whitehead, points: [
                        .init(day: "Jan", score: 74), .init(day: "Feb", score: 75), .init(day: "Mar", score: 77),
                        .init(day: "Apr", score: 79), .init(day: "May", score: 81), .init(day: "Jun", score: 82),
                        .init(day: "Jul", score: 84), .init(day: "Aug", score: 85), .init(day: "Sep", score: 87),
                        .init(day: "Oct", score: 88), .init(day: "Nov", score: 90), .init(day: "Dec", score: 92)
                    ]),
                    .init(acneType: .blackhead, points: [
                        .init(day: "Jan", score: 59), .init(day: "Feb", score: 60), .init(day: "Mar", score: 62),
                        .init(day: "Apr", score: 64), .init(day: "May", score: 65), .init(day: "Jun", score: 67),
                        .init(day: "Jul", score: 69), .init(day: "Aug", score: 70), .init(day: "Sep", score: 72),
                        .init(day: "Oct", score: 73), .init(day: "Nov", score: 74), .init(day: "Dec", score: 76)
                    ]),
                    .init(acneType: .papule, points: [
                        .init(day: "Jan", score: 49), .init(day: "Feb", score: 51), .init(day: "Mar", score: 52),
                        .init(day: "Apr", score: 54), .init(day: "May", score: 56), .init(day: "Jun", score: 57),
                        .init(day: "Jul", score: 59), .init(day: "Aug", score: 60), .init(day: "Sep", score: 62),
                        .init(day: "Oct", score: 63), .init(day: "Nov", score: 65), .init(day: "Dec", score: 67)
                    ]),
                    .init(acneType: .pustule, points: [
                        .init(day: "Jan", score: 66), .init(day: "Feb", score: 67), .init(day: "Mar", score: 68),
                        .init(day: "Apr", score: 70), .init(day: "May", score: 71), .init(day: "Jun", score: 72),
                        .init(day: "Jul", score: 73), .init(day: "Aug", score: 75), .init(day: "Sep", score: 76),
                        .init(day: "Oct", score: 77), .init(day: "Nov", score: 79), .init(day: "Dec", score: 80)
                    ]),
                    .init(acneType: .nodule, points: [
                        .init(day: "Jan", score: 44), .init(day: "Feb", score: 45), .init(day: "Mar", score: 46),
                        .init(day: "Apr", score: 48), .init(day: "May", score: 49), .init(day: "Jun", score: 50),
                        .init(day: "Jul", score: 52), .init(day: "Aug", score: 53), .init(day: "Sep", score: 55),
                        .init(day: "Oct", score: 56), .init(day: "Nov", score: 57), .init(day: "Dec", score: 59)
                    ]),
                    .init(acneType: .cyst, points: [
                        .init(day: "Jan", score: 53), .init(day: "Feb", score: 54), .init(day: "Mar", score: 56),
                        .init(day: "Apr", score: 57), .init(day: "May", score: 59), .init(day: "Jun", score: 60),
                        .init(day: "Jul", score: 61), .init(day: "Aug", score: 63), .init(day: "Sep", score: 64),
                        .init(day: "Oct", score: 66), .init(day: "Nov", score: 67), .init(day: "Dec", score: 69)
                    ])
                ]
            ],
            comparisonSummary: .init(
                baselineLabel: "Compared to 28 July",
                headline: "Your Skin is Improving!",
                scoreLabel: "Score",
                deltaText: "+10"
            ),
            insightSummary: .init(
                title: "Summary Insight",
                body: "Lorem ipsum dolor sit amet, nulla deserunt tempor elit veniam esse tempor. In et fugiat dolor consequat nulla laboris fugiat in. Qui nulla deserunt deserunt nemo nostrud occaecat ut in nulla ut enim. Ut velit sint dolore veniam ut enim officia irure velit ut. Ut velit mollit ea in reprehenderit id veniam sed."
            )
        )
    }
}
