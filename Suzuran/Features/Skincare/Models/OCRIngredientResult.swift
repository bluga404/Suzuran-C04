import Foundation

/// Intermediate model representing the raw output of an OCR scan of an
/// ingredient label, produced by `OCRServicing` and consumed by the
/// Add Skincare flow.
///
/// This value is **transient** and lives only in-memory. It is deliberately
/// **not** `Codable`: only the ingredient candidates that the user explicitly
/// confirms during review are persisted as part of `SkincareProduct`.
///
struct OCRIngredientResult: Equatable {
    /// Raw text extracted from the scanned image by the OCR engine,
    /// prior to any parsing or normalization.
    let rawText: String

    /// Candidate ingredient names produced by `IngredientParser` from
    /// `rawText`. Presented to the user in the review step, still editable
    /// before commit.
    let candidates: [String]

    /// Timestamp of when the OCR result was produced. Useful for logging
    /// and for disambiguating multiple scan attempts in the same session.
    let capturedAt: Date

    init(rawText: String, candidates: [String], capturedAt: Date = Date()) {
        self.rawText = rawText
        self.candidates = candidates
        self.capturedAt = capturedAt
    }
}
