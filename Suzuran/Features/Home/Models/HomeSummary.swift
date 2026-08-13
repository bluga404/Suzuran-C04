import Foundation

/// Aggregate presentation model consumed by HomeView.
/// Contains the current home state, scan data, score presentation,
/// dominant acne type, ingredient recommendations, and scan availability.
struct HomeSummary: Equatable {
    /// The current UI state of the home screen.
    let state: HomeSummaryState
    /// The date this summary was generated.
    let date: Date
    /// The most recent skin scan, if available.
    let latestScan: SkinScan?
    /// The previous skin scan (before the latest), if available.
    let previousScan: SkinScan?
    /// The score presentation data (value, label, trend, message), nil when no scan exists.
    let skinScore: SkinScorePresentation?
    /// The most frequently detected acne type, nil when no detections exist.
    let dominantAcne: AcneType?
    /// Ingredient recommendations based on dominant acne type. Empty when no ingredient scan exists.
    let recommendations: [IngredientRecommendation]
    /// Indicates if the user has any skincare products tracked. Used by the UI.
    let hasTrackedSkincare: Bool
}
