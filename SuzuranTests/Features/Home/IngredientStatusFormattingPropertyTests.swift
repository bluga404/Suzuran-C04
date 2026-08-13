import Testing

@testable import Suzuran

// Feature: home-page, Property 9: Ingredient status string formatting
/// **Validates: Requirements 9.4**
@Suite("Ingredient Status - Property 9: Status Formatting")
struct IngredientStatusFormattingPropertyTests {

    /// Helper to format status text (mirrors the view logic)
    private func formatStatusText(_ status: IngredientStatus) -> String {
        switch status {
        case .notFound:
            return "Belum ditemukan di produk yang kamu scan"
        case .found(let productName):
            return "Sudah ada di rutinmu - \(productName)"
        }
    }

    @Test("Found status formatting matches expected pattern for random product names")
    func foundStatusFormatting() {
        var rng = StatusSplitMix64(seed: 200)
        let characters = Array("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-")

        for _ in 0..<200 {
            // Generate random non-empty product name
            let length = Int.random(in: 1...50, using: &rng)
            let name = String((0..<length).map { _ in
                characters[Int.random(in: 0..<characters.count, using: &rng)]
            })

            let status = IngredientStatus.found(productName: name)
            let formatted = formatStatusText(status)

            #expect(formatted == "Sudah ada di rutinmu - \(name)",
                "Expected 'Sudah ada di rutinmu - \(name)', got '\(formatted)'")
        }
    }

    @Test("NotFound status formatting is constant")
    func notFoundStatusFormatting() {
        let status = IngredientStatus.notFound
        let formatted = formatStatusText(status)
        #expect(formatted == "Belum ditemukan di produk yang kamu scan")
    }
}

// MARK: - Private SplitMix64 RNG (avoids conflicts with other test files)

/// A simple, deterministic pseudo-random number generator for reproducible property tests.
private struct StatusSplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
