import Foundation

struct ReportPoint: Identifiable, Equatable {
    let day: String
    let score: Int

    var id: String { day }
}

struct AcneTypeSeries: Identifiable, Equatable {
    let acneType: AcneType
    let points: [ReportPoint]

    var id: String { acneType.id }

    var latestScore: Int {
        points.last?.score ?? 0
    }
}

struct AcneSeriesPoint: Identifiable {
    let acneType: AcneType
    let day: String
    let score: Int

    var id: String { "\(acneType.id)-\(day)" }
}
