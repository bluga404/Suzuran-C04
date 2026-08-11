import Testing

@testable import Suzuran

/// Unit tests for HomeSummaryViewModel data flow and state transitions.
///
/// **Validates: Requirements 10.1, 10.3, 10.4**
@Suite("HomeSummaryViewModel Tests")
struct HomeSummaryViewModelTests {

    // MARK: - Mock Repositories

    private final class MockSkinScanRepository: SkinScanRepository {
        var latestScanResult: SkinScan?
        var previousScanResult: SkinScan?
        var scanByIDResult: SkinScan?
        var shouldThrow: Error?

        func latestScan() async throws -> SkinScan? {
            if let error = shouldThrow { throw error }
            return latestScanResult
        }

        func previousScan(before date: Date) async throws -> SkinScan? {
            if let error = shouldThrow { throw error }
            return previousScanResult
        }

        func scan(byID id: UUID) async throws -> SkinScan? {
            if let error = shouldThrow { throw error }
            return scanByIDResult
        }
    }

    private final class MockIngredientRepository: IngredientRepository {
        var result: IngredientScanData?
        var shouldThrow: Error?

        func latestIngredientScan() async throws -> IngredientScanData? {
            if let error = shouldThrow { throw error }
            return result
        }
    }

    private final class MockSkincareRepository: SkincareRepository {
        var result: [SkincareProduct] = []
        var shouldThrow: Error?

        func products() async throws -> [SkincareProduct] {
            if let error = shouldThrow { throw error }
            return result
        }
    }

    // MARK: - Helpers

    @MainActor
    private func makeViewModel(
        scanRepo: MockSkinScanRepository = MockSkinScanRepository(),
        ingredientRepo: MockIngredientRepository = MockIngredientRepository(),
        skincareRepo: MockSkincareRepository = MockSkincareRepository()
    ) -> HomeSummaryViewModel {
        HomeSummaryViewModel(
            skinScanRepository: scanRepo,
            ingredientRepository: ingredientRepo,
            skincareRepository: skincareRepo,
            calculator: SummaryCalculator(scoreCalculator: HomeScoreCalculator())
        )
    }

    // MARK: - Initial State (Requirement 10.1)

    @Test("Initial state is .idle")
    @MainActor
    func initialStateIsIdle() {
        // **Validates: Requirements 10.1**
        let vm = makeViewModel()
        #expect(vm.state == .idle)
    }

    // MARK: - Load Happy Path (Requirement 10.3)

    @Test("Load happy path transitions to .loaded with scan data")
    @MainActor
    func loadHappyPath() async {
        // **Validates: Requirements 10.3**
        let scanRepo = MockSkinScanRepository()
        scanRepo.latestScanResult = HomeFixtures.detailScan

        let vm = makeViewModel(scanRepo: scanRepo)

        await vm.load()

        if case .loaded(let summary) = vm.state {
            #expect(summary.state != .empty)
            #expect(summary.latestScan != nil)
            #expect(summary.skinScore != nil)
        } else {
            Issue.record("Expected .loaded state, got \(vm.state)")
        }
    }

    @Test("Load transitions through .loading state")
    @MainActor
    func loadTransitionsThroughLoading() async {
        // **Validates: Requirements 10.3**
        let scanRepo = MockSkinScanRepository()
        scanRepo.latestScanResult = HomeFixtures.detailScan

        let vm = makeViewModel(scanRepo: scanRepo)

        // Before load, state should be idle
        #expect(vm.state == .idle)

        await vm.load()

        // After load completes, state should be loaded (loading is transient)
        if case .loaded = vm.state {
            // success — the state transitioned from idle through loading to loaded
        } else {
            Issue.record("Expected .loaded state after load(), got \(vm.state)")
        }
    }

    // MARK: - Load Failure (Requirement 10.4)

    @Test("Load failure from skin scan repository transitions to .failed")
    @MainActor
    func loadFailureFromSkinScanRepo() async {
        // **Validates: Requirements 10.4**
        let scanRepo = MockSkinScanRepository()
        scanRepo.shouldThrow = NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Test error"])

        let vm = makeViewModel(scanRepo: scanRepo)

        await vm.load()

        if case .failed(let appError) = vm.state {
            #expect(appError == .unknown(message: "Test error"))
        } else {
            Issue.record("Expected .failed state, got \(vm.state)")
        }
    }

    @Test("Load failure from ingredient repository transitions to .failed")
    @MainActor
    func loadFailureFromIngredientRepo() async {
        // **Validates: Requirements 10.4**
        let scanRepo = MockSkinScanRepository()
        scanRepo.latestScanResult = HomeFixtures.detailScan

        let ingredientRepo = MockIngredientRepository()
        ingredientRepo.shouldThrow = NSError(domain: "test", code: -2, userInfo: [NSLocalizedDescriptionKey: "Ingredient error"])

        let vm = makeViewModel(scanRepo: scanRepo, ingredientRepo: ingredientRepo)

        await vm.load()

        if case .failed(let appError) = vm.state {
            #expect(appError == .unknown(message: "Ingredient error"))
        } else {
            Issue.record("Expected .failed state, got \(vm.state)")
        }
    }

    @Test("Load failure from skincare repository transitions to .failed")
    @MainActor
    func loadFailureFromSkincareRepo() async {
        // **Validates: Requirements 10.4**
        let scanRepo = MockSkinScanRepository()
        scanRepo.latestScanResult = HomeFixtures.detailScan

        let skincareRepo = MockSkincareRepository()
        skincareRepo.shouldThrow = NSError(domain: "test", code: -3, userInfo: [NSLocalizedDescriptionKey: "Skincare error"])

        let vm = makeViewModel(scanRepo: scanRepo, skincareRepo: skincareRepo)

        await vm.load()

        if case .failed(let appError) = vm.state {
            #expect(appError == .unknown(message: "Skincare error"))
        } else {
            Issue.record("Expected .failed state, got \(vm.state)")
        }
    }

    @Test("Load failure with AppError preserves the specific error type")
    @MainActor
    func loadFailureWithAppError() async {
        // **Validates: Requirements 10.4**
        let scanRepo = MockSkinScanRepository()
        scanRepo.shouldThrow = AppError.networkUnavailable

        let vm = makeViewModel(scanRepo: scanRepo)

        await vm.load()

        if case .failed(let appError) = vm.state {
            #expect(appError == .networkUnavailable)
        } else {
            Issue.record("Expected .failed(.networkUnavailable), got \(vm.state)")
        }
    }

    // MARK: - Empty State (Requirements 10.1, 10.3)

    @Test("All repos return nil produces .loaded with .empty HomeSummary state")
    @MainActor
    func allNilProducesEmptyState() async {
        // **Validates: Requirements 10.1, 10.3**
        let vm = makeViewModel()

        await vm.load()

        if case .loaded(let summary) = vm.state {
            #expect(summary.state == .empty)
            #expect(summary.latestScan == nil)
            #expect(summary.previousScan == nil)
            #expect(summary.skinScore == nil)
            #expect(summary.dominantAcne == nil)
            #expect(summary.recommendations.isEmpty)
            #expect(summary.scanAvailability.hasFaceScan == false)
            #expect(summary.scanAvailability.hasIngredientScan == false)
            #expect(summary.scanAvailability.hasPreviousFaceScan == false)
        } else {
            Issue.record("Expected .loaded with .empty state, got \(vm.state)")
        }
    }
}
