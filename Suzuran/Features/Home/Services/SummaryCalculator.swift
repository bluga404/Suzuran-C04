import Foundation

/// Pure computation service that orchestrates all Home summary logic.
/// Delegates scoring, trend, state machine, and dominant acne to HomeScoreCalculator,
/// then assembles the final HomeSummary with ingredient recommendations.
/// No I/O, no async — trivially unit-testable.
struct SummaryCalculator {
    let scoreCalculator: HomeScoreCalculator

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
        let changePercent = percentageChange(from: previousScan, to: scan)

        // Build message based on state (English)
        let message: String
        switch state {
        case .empty:
            message = "Scan your face to see skin condition"
        case .faceOnly, .complete:
            message = "Scan again tomorrow to see your skin condition change!"
        case .improvement:
            let percent = changePercent ?? 0
            message = "Yeay! your score is higher than yesterday! improving \(percent)% from yesterday"
        case .degradation:
            let percent = changePercent ?? 0
            message = "Your score is lower \(percent)% than yesterday, don't worry, it's part of the process!"
        case .unchanged:
            message = "No change from yesterday. Keep up your routine!"
        }

        let skinScore = SkinScorePresentation(
            value: scan.overallScore,
            title: label,
            trend: trend,
            message: message
        )

        // Build recommendations only when ingredient scan exists
        let recommendations: [IngredientRecommendation]
        if let ingredientData = ingredientScan, let dominant = dominantAcne {
            recommendations = buildRecommendations(
                dominantAcne: dominant,
                ingredientScan: ingredientData,
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

    // MARK: - Percentage Change

    /// Computes the rounded percentage change between two scans relative to the previous score.
    /// - Parameters:
    ///   - previous: The previous scan, or nil if none exists.
    ///   - latest: The most recent scan.
    /// - Returns: A non-negative rounded percentage, or nil when there is no previous scan or its score is 0.
    func percentageChange(from previous: SkinScan?, to latest: SkinScan) -> Int? {
        guard let previous = previous, previous.overallScore > 0 else { return nil }
        let delta = latest.overallScore - previous.overallScore
        return Int((Double(abs(delta)) / Double(previous.overallScore) * 100).rounded())
    }

    // MARK: - Ingredient Recommendations

    /// Builds ingredient recommendations based on dominant acne type and user's products.
    private func buildRecommendations(
        dominantAcne: AcneType,
        ingredientScan: IngredientScanData,
        products: [SkincareProduct]
    ) -> [IngredientRecommendation] {
        let ingredients = recommendedIngredients(for: dominantAcne)

        return ingredients.prefix(5).map { ingredient in
            let status = ingredientStatus(for: ingredient, in: products)
            return IngredientRecommendation(
                id: UUID(),
                ingredient: ingredient,
                explanation: explanation(for: ingredient, dominantAcne: dominantAcne),
                status: status
            )
        }
    }

    /// Maps dominant acne type to a list of recommended ingredients.
    private func recommendedIngredients(for acneType: AcneType) -> [Ingredient] {
        switch acneType {
        case .blackhead, .whitehead:
            return [
                Ingredient(name: "niacinamide", displayName: "Niacinamide"),
                Ingredient(name: "salicylic acid", displayName: "Salicylic Acid"),
                Ingredient(name: "retinol", displayName: "Retinol")
            ]
        case .papule, .pustule:
            return [
                Ingredient(name: "benzoyl peroxide", displayName: "Benzoyl Peroxide"),
                Ingredient(name: "niacinamide", displayName: "Niacinamide"),
                Ingredient(name: "tea tree oil", displayName: "Tea Tree Oil")
            ]
        case .nodule, .cyst:
            return [
                Ingredient(name: "benzoyl peroxide", displayName: "Benzoyl Peroxide"),
                Ingredient(name: "adapalene", displayName: "Adapalene"),
                Ingredient(name: "azelaic acid", displayName: "Azelaic Acid")
            ]
        case .unknown:
            return []
        }
    }

    /// Checks whether a recommended ingredient is found in the user's tracked products.
    private func ingredientStatus(for ingredient: Ingredient, in products: [SkincareProduct]) -> IngredientStatus {
        for product in products {
            if product.ingredients.contains(where: { $0.lowercased() == ingredient.name.lowercased() }) {
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
