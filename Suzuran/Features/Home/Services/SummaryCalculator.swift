import Foundation

/// Pure computation service that orchestrates all Home summary logic.
/// Delegates scoring, trend, state machine, and dominant acne to HomeScoreCalculator,
/// then assembles the final HomeSummary with ingredient recommendations.
/// No I/O, no async — trivially unit-testable.
struct SummaryCalculator {
    let scoreCalculator: HomeScoreCalculator
    private let acneIngredientRepo: AcneIngredientRepositoryProtocol
    
    init(scoreCalculator: HomeScoreCalculator, acneIngredientRepo: AcneIngredientRepositoryProtocol = AcneIngredientRepository(db: IngredientDB.shared)) {
        self.scoreCalculator = scoreCalculator
        self.acneIngredientRepo = acneIngredientRepo
    }

    /// Computes a complete HomeSummary from repository data.
    /// - Parameters:
    ///   - latestScan: The most recent face scan, or nil if none exists.
    ///   - previousScan: The previous face scan, or nil if none exists.
    ///   - ingredientScan: The most recent ingredient scan data, or nil if none exists.
    ///   - products: The user's tracked skincare products.
    /// - Returns: A fully assembled HomeSummary ready for the ViewModel to publish.
    func makeSummary(
        latestScan: SkinScan?,
        previousScan: SkinScan?,
        ingredientScan: IngredientScanData?,
        products: [SkincareProduct]
    ) -> HomeSummary {
        let hasIngredientScan = ingredientScan != nil
        let state = scoreCalculator.determineHomeState(
            latestScan: latestScan,
            previousScan: previousScan,
            hasIngredientScan: hasIngredientScan
        )

        // If empty, return minimal summary
        guard let scan = latestScan else {
            return HomeSummary(
                state: .empty,
                date: Date(),
                latestScan: nil,
                previousScan: nil,
                skinScore: nil,
                dominantAcne: nil,
                recommendations: [],
                scanAvailability: ScanAvailability(
                    hasFaceScan: false,
                    hasIngredientScan: false,
                    hasPreviousFaceScan: false
                )
            )
        }

        let trend = scoreCalculator.calculateTrend(latest: latestScan, previous: previousScan)
        let label = scoreCalculator.scoreLabel(for: scan.overallScore)
        let dominantAcne = scoreCalculator.dominantAcneType(from: scan.acneCounts)

        // Build message based on state (Bahasa Indonesia)
        let message: String
        switch state {
        case .empty:
            message = "Scan wajahmu untuk lihat kondisi kulit"
        case .faceOnly:
            message = "Scan produk skincarenya juga yuk!"
        case .complete:
            message = "Scan lagi besok untuk lihat perubahan kondisi kulitmu!"
        case .improvement:
            message = "Yeay! skormu lebih tinggi dari kemarin!"
        case .degradation:
            message = "Skormu lebih rendah dari kemarin, jangan khawatir, ini bagian dari prosesnya!"
        case .unchanged:
            message = "Skormu tidak berubah sejak scan terakhir"
        }

        let skinScore = SkinScorePresentation(
            value: scan.overallScore,
            title: label,
            trend: trend,
            message: message
        )

        // Build recommendations based on dominant acne
        let recommendations: [IngredientRecommendation]
        if let dominant = dominantAcne {
            recommendations = buildRecommendations(
                dominantAcne: dominant,
                products: products
            )
        } else {
            recommendations = []
        }

        let scanAvailability = ScanAvailability(
            hasFaceScan: true,
            hasIngredientScan: hasIngredientScan,
            hasPreviousFaceScan: previousScan != nil
        )

        return HomeSummary(
            state: state,
            date: Date(),
            latestScan: latestScan,
            previousScan: previousScan,
            skinScore: skinScore,
            dominantAcne: dominantAcne,
            recommendations: recommendations,
            scanAvailability: scanAvailability
        )
    }

    // MARK: - Ingredient Recommendations

    private func buildRecommendations(
        dominantAcne: AcneType,
        products: [SkincareProduct]
    ) -> [IngredientRecommendation] {
        let recommendations = acneIngredientRepo.recommendations(for: [dominantAcne])

        return recommendations.prefix(5).map { rec in
            let ingredient = Ingredient(name: rec.ingredientName.lowercased(), displayName: rec.ingredientName)
            let status = ingredientStatus(for: ingredient, in: products)
            return IngredientRecommendation(
                id: UUID(),
                ingredient: ingredient,
                explanation: explanation(for: ingredient, dominantAcne: dominantAcne),
                status: status
            )
        }
    }

    /// Checks whether a recommended ingredient is found in the user's tracked products.
    private func ingredientStatus(for ingredient: Ingredient, in products: [SkincareProduct]) -> IngredientStatus {
        for product in products {
            // Phase 1 adapter (Task 11.1 in skincare-tabview-redesign spec):
            // `SkincareProduct.ingredients` is now `[IngredientReference]`. Compare
            // against the reference's display `.name` to preserve the existing
            // case-insensitive substring semantics. This one-line touch is the
            // only cross-feature caller broken by the Phase 1 model change.
            if product.ingredients.contains(where: { $0.name.lowercased() == ingredient.name.lowercased() }) {
                return .found(productName: product.name)
            }
        }
        return .notFound
    }

    /// Returns a short explanation (Bahasa Indonesia) for why an ingredient is recommended.
    private func explanation(for ingredient: Ingredient, dominantAcne: AcneType) -> String {
        switch ingredient.name {
        case "niacinamide":
            return "Membantu mengontrol produksi sebum dan mengurangi peradangan"
        case "salicylic acid":
            return "Membersihkan pori-pori tersumbat dan mengangkat sel kulit mati"
        case "benzoyl peroxide":
            return "Membunuh bakteri penyebab jerawat dan mengurangi peradangan"
        case "retinol":
            return "Mempercepat regenerasi sel kulit dan mencegah pori tersumbat"
        case "tea tree oil":
            return "Antibakteri alami yang membantu mengurangi peradangan jerawat"
        case "adapalene":
            return "Retinoid yang membantu mencegah dan mengobati jerawat parah"
        case "azelaic acid":
            return "Mengurangi peradangan dan membantu membunuh bakteri jerawat"
        default:
            return "Bahan yang direkomendasikan untuk jenis jerawatmu"
        }
    }
}
