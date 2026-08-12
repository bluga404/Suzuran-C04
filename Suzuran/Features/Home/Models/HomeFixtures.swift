import Foundation

/// Provides static fixture data for all 6 Home summary states and a detail scan.
/// Used for development, previews, and testing without ML or persistence dependencies.
enum HomeFixtures {

    // MARK: - Shared Fixture Dates

    private static let fixtureDate = Date()
    private static let fixtureUserID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    // MARK: - Shared Recommendations

    private static let niacinamideRecommendation = IngredientRecommendation(
        id: UUID(),
        ingredient: Ingredient(name: "niacinamide", displayName: "Niacinamide"),
        detail: SkincareIngredientRecommendation(
            ingredientName: "Niacinamide",
            alternativesName: nil,
            acneTypes: "Papule, Pustule",
            description: "Helps reduce sebum production and minimizes pore appearance, effective for blackhead-prone skin.",
            concentrationAndUsage: "", application: "", ingredientInteractions: nil, risksAndSafety: "", researchPapers: nil
        ),
        status: .notFound
    )

    private static let salicylicAcidRecommendation = IngredientRecommendation(
        id: UUID(),
        ingredient: Ingredient(name: "salicylic acid", displayName: "Salicylic Acid"),
        detail: SkincareIngredientRecommendation(
            ingredientName: "Salicylic Acid",
            alternativesName: nil,
            acneTypes: "Blackhead, Whitehead",
            description: "A BHA that penetrates pores to dissolve debris and reduce blackhead formation.",
            concentrationAndUsage: "", application: "", ingredientInteractions: nil, risksAndSafety: "", researchPapers: nil
        ),
        status: .found(products: [
            SkincareProduct(name: "Facewash", brand: "Unknown", category: .cleanser)
        ])
    )

    private static let benzoylPeroxideRecommendation = IngredientRecommendation(
        id: UUID(),
        ingredient: Ingredient(name: "benzoyl peroxide", displayName: "Benzoyl Peroxide"),
        detail: SkincareIngredientRecommendation(
            ingredientName: "Benzoyl Peroxide",
            alternativesName: nil,
            acneTypes: "Pustule",
            description: "Kills acne-causing bacteria and helps clear pustules by reducing inflammation.",
            concentrationAndUsage: "", application: "", ingredientInteractions: nil, risksAndSafety: "", researchPapers: nil
        ),
        status: .notFound
    )

    // MARK: - Fixture Scans

    private static let scanScore60 = SkinScan(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000100")!,
        userID: fixtureUserID,
        createdAt: fixtureDate,
        overallScore: 60,
        weightedAcneCount: 24.0,
        gagsScore: 6,
        acneCounts: [.blackhead: 14, .whitehead: 2, .papule: 3],
        regionCounts: [
            .forehead: [.blackhead: 9, .whitehead: 1, .papule: 1],
            .leftCheek: [.blackhead: 2, .papule: 1],
            .rightCheek: [.blackhead: 1, .whitehead: 1],
            .chin: [.blackhead: 2, .papule: 1],
            .nose: [:]
        ],
        regionGagsScores: [
            .forehead: 4,
            .leftCheek: 4,
            .rightCheek: 2,
            .chin: 2,
            .nose: 0
        ],
        imageReference: nil,
        modelVersion: "v1.0",
        scanProtocolVersion: "1.0"
    )

    private static let scanScore83 = SkinScan(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000101")!,
        userID: fixtureUserID,
        createdAt: fixtureDate,
        overallScore: 83,
        weightedAcneCount: 10.0,
        gagsScore: 4,
        acneCounts: [.blackhead: 8, .whitehead: 2],
        regionCounts: [
            .forehead: [.blackhead: 5, .whitehead: 1],
            .leftCheek: [.blackhead: 1],
            .rightCheek: [.blackhead: 1, .whitehead: 1],
            .chin: [.blackhead: 1],
            .nose: [:]
        ],
        regionGagsScores: [
            .forehead: 2,
            .leftCheek: 2,
            .rightCheek: 2,
            .chin: 1,
            .nose: 0
        ],
        imageReference: nil,
        modelVersion: "v1.0",
        scanProtocolVersion: "1.0"
    )

    private static let scanScore40 = SkinScan(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000102")!,
        userID: fixtureUserID,
        createdAt: fixtureDate,
        overallScore: 40,
        weightedAcneCount: 36.0,
        gagsScore: 10,
        acneCounts: [.pustule: 10, .papule: 5, .blackhead: 3],
        regionCounts: [
            .forehead: [.pustule: 4, .papule: 2, .blackhead: 1],
            .leftCheek: [.pustule: 3, .papule: 1],
            .rightCheek: [.pustule: 2, .blackhead: 1],
            .chin: [.pustule: 1, .papule: 2, .blackhead: 1],
            .nose: [:]
        ],
        regionGagsScores: [
            .forehead: 6,
            .leftCheek: 6,
            .rightCheek: 6,
            .chin: 3,
            .nose: 0
        ],
        imageReference: nil,
        modelVersion: "v1.0",
        scanProtocolVersion: "1.0"
    )

    // MARK: - Home Summary Fixtures

    /// Empty state: no scan data available.
    static let empty = HomeSummary(
        state: .empty,
        date: fixtureDate,
        latestScan: nil,
        previousScan: nil,
        skinScore: nil,
        dominantAcne: nil,
        recommendations: [],

        hasTrackedSkincare: false
    )

    /// Face-only state: score 60, Blackhead dominant, no ingredient scan.
    static let faceOnly = HomeSummary(
        state: .faceOnly,
        date: fixtureDate,
        latestScan: scanScore60,
        previousScan: nil,
        skinScore: SkinScorePresentation(
            value: 60,
            title: "Good",
            trend: .noPreviousData,
            message: "Scan produk skincaremu untuk rekomendasi bahan!"
        ),
        dominantAcne: .blackhead,
        recommendations: [],

        hasTrackedSkincare: true
    )

    /// Complete state: score 60, Blackhead dominant, with ingredient recommendations.
    static let complete = HomeSummary(
        state: .complete,
        date: fixtureDate,
        latestScan: scanScore60,
        previousScan: nil,
        skinScore: SkinScorePresentation(
            value: 60,
            title: "Good",
            trend: .noPreviousData,
            message: "Scan lagi besok untuk lihat perubahan kondisi kulitmu!"
        ),
        dominantAcne: .blackhead,
        recommendations: [niacinamideRecommendation, salicylicAcidRecommendation],

        hasTrackedSkincare: true
    )

    /// Improvement state: previous 60 → latest 83, Blackhead dominant.
    static let improvement = HomeSummary(
        state: .improvement,
        date: fixtureDate,
        latestScan: scanScore83,
        previousScan: scanScore60,
        skinScore: SkinScorePresentation(
            value: 83,
            title: "Good",
            trend: .improved,
            message: "Yeay! Skormu lebih tinggi dari kemarin!"
        ),
        dominantAcne: .blackhead,
        recommendations: [niacinamideRecommendation, salicylicAcidRecommendation],

        hasTrackedSkincare: true
    )

    /// Degradation state: previous 60 → latest 40, Pustule dominant.
    static let degradation = HomeSummary(
        state: .degradation,
        date: fixtureDate,
        latestScan: scanScore40,
        previousScan: scanScore60,
        skinScore: SkinScorePresentation(
            value: 40,
            title: "Moderate",
            trend: .declined,
            message: "Skormu lebih rendah dari kemarin, jangan khawatir, ini bagian dari proses!"
        ),
        dominantAcne: .pustule,
        recommendations: [niacinamideRecommendation],

        hasTrackedSkincare: true
    )

    /// Unchanged state: previous 60 → latest 60, Blackhead dominant.
    static let unchanged = HomeSummary(
        state: .unchanged,
        date: fixtureDate,
        latestScan: scanScore60,
        previousScan: scanScore60,
        skinScore: SkinScorePresentation(
            value: 60,
            title: "Good",
            trend: .unchanged,
            message: "Skormu tidak berubah dari kemarin."
        ),
        dominantAcne: .blackhead,
        recommendations: [niacinamideRecommendation, salicylicAcidRecommendation],

        hasTrackedSkincare: true
    )

    // MARK: - Detail Fixture

    /// Detail fixture SkinScan with Blackhead region breakdown:
    /// Total blackheads = 14, Forehead = 9, LeftCheek = 2, RightCheek = 1, Chin = 2, Nose = 0
    static let detailScan = SkinScan(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000200")!,
        userID: fixtureUserID,
        createdAt: fixtureDate,
        overallScore: 60,
        weightedAcneCount: 24.0,
        gagsScore: 6,
        acneCounts: [.blackhead: 14, .whitehead: 2, .papule: 3],
        regionCounts: [
            .forehead: [.blackhead: 9, .whitehead: 1, .papule: 1],
            .leftCheek: [.blackhead: 2, .papule: 1],
            .rightCheek: [.blackhead: 1, .whitehead: 1],
            .chin: [.blackhead: 2, .papule: 1],
            .nose: [:]
        ],
        regionGagsScores: [
            .forehead: 4,
            .leftCheek: 4,
            .rightCheek: 2,
            .chin: 2,
            .nose: 0
        ],
        imageReference: nil,
        modelVersion: "v1.0",
        scanProtocolVersion: "1.0"
    )
}
