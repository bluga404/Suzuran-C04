import Combine
import Foundation

/// ViewModel for the Home summary screen.
/// Coordinates data fetching from repositories and delegates all domain
/// computation to SummaryCalculator. Publishes results via LoadableState.
@MainActor
final class HomeSummaryViewModel: ObservableObject {
    @Published private(set) var state: LoadableState<HomeSummary> = .idle

    private let skinScanRepository: SkinScanRepository
    private let ingredientRepository: IngredientRepository
    private let skincareRepository: SkincareRepository
    private let calculator: SummaryCalculator

    init(
        skinScanRepository: SkinScanRepository,
        ingredientRepository: IngredientRepository,
        skincareRepository: SkincareRepository,
        calculator: SummaryCalculator
    ) {
        self.skinScanRepository = skinScanRepository
        self.ingredientRepository = ingredientRepository
        self.skincareRepository = skincareRepository
        self.calculator = calculator
    }

    /// Fetches data from all repositories, computes HomeSummary via calculator,
    /// and publishes the result. No domain logic lives here.
    func load() async {
        state = .loading
        do {
            let latestScan = try await skinScanRepository.latestScan()
            let previousScan: SkinScan?
            if let latest = latestScan {
                previousScan = try await skinScanRepository.previousScan(before: latest.createdAt)
            } else {
                previousScan = nil
            }
            let ingredientScan = try await ingredientRepository.latestIngredientScan()
            let products = try await skincareRepository.products()

            let summary = calculator.makeSummary(
                latestScan: latestScan,
                previousScan: previousScan,
                ingredientScan: ingredientScan,
                products: products
            )
            state = .loaded(summary)
        } catch {
            let appError = AppErrorMapper.map(error)
            state = .failed(appError)
        }
    }
}
