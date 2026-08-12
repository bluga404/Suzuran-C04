import Foundation
import Testing

@testable import Suzuran

/// Verifies that `SkincareProduct` can decode the three payload shapes that may
/// exist in `UserDefaults` under the persistence key `suzuran.skincare.products`:
///
/// 1. **Legacy v0** — the shape written by the app before the redesign:
///    `category` is a free-form `String` (e.g. `"Cleanser"`, `"Face Mask"`,
///    `"Other"`), `ingredients` is `[String]`, and `isUsedCurrently` is absent.
/// 2. **Mixed valid + corrupt** — one entry is valid legacy shape, another is
///    missing required fields. The valid entry decodes; the corrupt entry throws.
///    This is exactly the boundary the repository layer relies on for its
///    skip-and-continue behavior (Task 17.1, Req 21.5).
/// 3. **New format** — `category` as `SkincareCategory.rawValue`, `ingredients`
///    as `[IngredientReference]`, and `isUsedCurrently` present.
///
/// This test is the automated stand-in for Task 11.2 ("baca payload `UserDefaults`
/// legacy di simulator; pastikan `SkincareProduct` legacy tetap terdecode via
/// tolerant decoder"). Running it under the `SuzuranTests` target exercises the
/// exact same `SkincareProduct.init(from:)` code path a device running against
/// legacy `UserDefaults` data would exercise, without needing an interactive
/// LLDB session on the simulator.
///
/// **Validates: Requirements 21.2, 21.3, 21.5**
@Suite("SkincareProduct - Legacy Payload Decode")
struct SkincareProductLegacyDecodeTests {

    // MARK: - Helpers

    private func decode(_ json: String) throws -> SkincareProduct {
        let data = Data(json.utf8)
        return try JSONDecoder().decode(SkincareProduct.self, from: data)
    }

    private func decodeArray(_ json: String) throws -> [SkincareProduct] {
        let data = Data(json.utf8)
        return try JSONDecoder().decode([SkincareProduct].self, from: data)
    }

    // MARK: - Case 1: Legacy v0 payload (Req 21.2, 21.3)

    @Test("Legacy v0 payload decodes: category string, ingredients [String], no isUsedCurrently")
    func decodesLegacyV0_capitalizedCategory() throws {
        // **Validates: Requirements 21.2, 21.3**
        //
        // Simulates a payload written by an older app version:
        //   - `category`: free-form capitalized label from the old picker
        //   - `ingredients`: array of raw strings
        //   - `isUsedCurrently`: field missing entirely
        let json = """
        {
            "id": "11111111-1111-1111-1111-111111111111",
            "name": "Gentle Foaming Wash",
            "brand": "Acme",
            "category": "Cleanser",
            "ingredients": ["Niacinamide", "Salicylic Acid"]
        }
        """

        let product = try decode(json)

        #expect(product.id == UUID(uuidString: "11111111-1111-1111-1111-111111111111"))
        #expect(product.name == "Gentle Foaming Wash")
        #expect(product.brand == "Acme")
        // Free-form "Cleanser" → SkincareCategory.cleanser via fromLegacy mapping.
        #expect(product.category == .cleanser)
        // [String] ingredients promoted to [IngredientReference] with canonical IDs.
        #expect(product.ingredients.count == 2)
        #expect(product.ingredients[0].name == "Niacinamide")
        #expect(product.ingredients[0].id == "niacinamide")
        #expect(product.ingredients[0].normalizedName == "niacinamide")
        #expect(product.ingredients[1].name == "Salicylic Acid")
        #expect(product.ingredients[1].id == "salicylic acid")
        // Missing `isUsedCurrently` defaults to true (Req 21.3 preserves semantic).
        #expect(product.isUsedCurrently == true)
    }

    @Test("Legacy v0 payload with 'Face Mask' maps to treatment category")
    func decodesLegacyV0_faceMaskCategory() throws {
        // **Validates: Requirements 21.3**
        //
        // "Face Mask" is a legacy label from the old `AddSkincareViewModel.categories`
        // list. It must map to `.treatment` per `SkincareCategory.fromLegacy`.
        let json = """
        {
            "id": "22222222-2222-2222-2222-222222222222",
            "name": "Clay Mask",
            "brand": "OldBrand",
            "category": "Face Mask",
            "ingredients": ["Kaolin", "Zinc Oxide"]
        }
        """

        let product = try decode(json)

        #expect(product.category == .treatment)
        #expect(product.ingredients.map(\.name) == ["Kaolin", "Zinc Oxide"])
        #expect(product.isUsedCurrently == true)
    }

    @Test("Legacy v0 payload with unknown 'Other' category falls back to moisturizer")
    func decodesLegacyV0_otherCategoryFallback() throws {
        // **Validates: Requirements 21.3**
        //
        // "Other" is not in the canonical mapping table; the tolerant decoder must
        // still succeed (never throw) and fall through to `.moisturizer` via
        // `SkincareCategory.fromLegacy`'s default branch.
        let json = """
        {
            "id": "33333333-3333-3333-3333-333333333333",
            "name": "Mystery Product",
            "brand": "Legacy",
            "category": "Other",
            "ingredients": ["Water"]
        }
        """

        let product = try decode(json)

        #expect(product.category == .moisturizer)
        #expect(product.ingredients.count == 1)
        #expect(product.ingredients[0].id == "water")
    }

    @Test("Legacy v0 empty ingredients array decodes to empty [IngredientReference]")
    func decodesLegacyV0_emptyIngredients() throws {
        // **Validates: Requirements 21.2, 21.3**
        let json = """
        {
            "id": "44444444-4444-4444-4444-444444444444",
            "name": "Bare Product",
            "brand": "None",
            "category": "Toner",
            "ingredients": []
        }
        """

        let product = try decode(json)

        #expect(product.category == .toner)
        #expect(product.ingredients.isEmpty)
        #expect(product.isUsedCurrently == true)
    }

    @Test("Legacy v0 array-of-products payload decodes cleanly")
    func decodesLegacyV0_topLevelArray() throws {
        // **Validates: Requirements 21.2, 21.3**
        //
        // Repository serializes/deserializes as `[SkincareProduct]`. Confirm the
        // whole-array decode path works for a purely-legacy payload.
        let json = """
        [
            {
                "id": "55555555-5555-5555-5555-555555555555",
                "name": "Serum A",
                "brand": "BrandA",
                "category": "Serum",
                "ingredients": ["Retinol"]
            },
            {
                "id": "66666666-6666-6666-6666-666666666666",
                "name": "Sunscreen B",
                "brand": "BrandB",
                "category": "Sunscreen",
                "ingredients": ["Zinc Oxide", "Titanium Dioxide"]
            }
        ]
        """

        let products = try decodeArray(json)

        #expect(products.count == 2)
        #expect(products[0].category == .serum)
        #expect(products[0].ingredients.map(\.id) == ["retinol"])
        #expect(products[1].category == .sunscreen)
        #expect(products[1].ingredients.map(\.id) == ["zinc oxide", "titanium dioxide"])
        // All entries default `isUsedCurrently` to true when field is absent.
        #expect(products.allSatisfy { $0.isUsedCurrently })
    }

    // MARK: - Case 2: Mixed valid + corrupt (Req 21.5 — model-level boundary)

    @Test("Mixed payload: valid entry decodes standalone")
    func mixedPayload_validEntryDecodes() throws {
        // **Validates: Requirements 21.2, 21.3**
        //
        // The repository (Task 17.1) will decode per-entry and skip entries that
        // throw. Here we confirm the "valid half" of a mixed payload decodes when
        // presented on its own.
        let validJSON = """
        {
            "id": "77777777-7777-7777-7777-777777777777",
            "name": "Good Cream",
            "brand": "Good",
            "category": "Moisturizer",
            "ingredients": ["Ceramide"]
        }
        """

        let product = try decode(validJSON)

        #expect(product.category == .moisturizer)
        #expect(product.ingredients.map(\.id) == ["ceramide"])
    }

    @Test("Mixed payload: corrupt entry (missing required field) throws")
    func mixedPayload_corruptEntryThrows() {
        // **Validates: Requirements 21.5**
        //
        // A payload missing a required field (e.g. `brand`) must throw at the
        // model layer. The repository's skip-and-continue logic (Task 17.1) then
        // catches this throw and drops the entry without aborting the batch.
        let corruptJSON = """
        {
            "id": "88888888-8888-8888-8888-888888888888",
            "name": "Missing Fields",
            "category": "Cleanser",
            "ingredients": []
        }
        """

        #expect(throws: (any Error).self) {
            try self.decode(corruptJSON)
        }
    }

    @Test("Mixed payload: corrupt entry (malformed id) throws")
    func mixedPayload_malformedIDThrows() {
        // **Validates: Requirements 21.5**
        let corruptJSON = """
        {
            "id": "not-a-uuid",
            "name": "Bad UUID",
            "brand": "Bad",
            "category": "Toner",
            "ingredients": []
        }
        """

        #expect(throws: (any Error).self) {
            try self.decode(corruptJSON)
        }
    }

    @Test("Mixed payload: top-level array decode aborts on any corrupt entry")
    func mixedPayload_topLevelArrayAbortsOnCorrupt() {
        // **Validates: Requirements 21.5**
        //
        // This documents the *current* stdlib behavior: `JSONDecoder.decode([T])`
        // is all-or-nothing. Precisely because of this behavior, Task 17.1 will
        // switch the repository to per-entry decode. This test protects that
        // rationale: if the stdlib ever changed, we would want to know.
        let mixedJSON = """
        [
            {
                "id": "99999999-9999-9999-9999-999999999999",
                "name": "Valid",
                "brand": "OK",
                "category": "Cleanser",
                "ingredients": []
            },
            {
                "id": "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA",
                "name": "Missing Brand",
                "category": "Toner",
                "ingredients": []
            }
        ]
        """

        #expect(throws: (any Error).self) {
            try self.decodeArray(mixedJSON)
        }
    }

    // MARK: - Case 3: New format (Req 21.4 lazy-migration output)

    @Test("New format payload decodes cleanly: rawValue category + [IngredientReference]")
    func decodesNewFormat_fullShape() throws {
        // **Validates: Requirements 21.2, 21.3, 21.4**
        //
        // Payload as written by the new `encode(to:)`: `category` as rawValue
        // ("cleanser"), `ingredients` as `[IngredientReference]` objects, and
        // `isUsedCurrently` present.
        let json = """
        {
            "id": "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB",
            "name": "New Format Cleanser",
            "brand": "Modern",
            "category": "cleanser",
            "ingredients": [
                {
                    "id": "niacinamide",
                    "name": "Niacinamide",
                    "normalizedName": "niacinamide"
                },
                {
                    "id": "salicylic acid",
                    "name": "Salicylic Acid",
                    "normalizedName": "salicylic acid"
                }
            ],
            "isUsedCurrently": false
        }
        """

        let product = try decode(json)

        #expect(product.category == .cleanser)
        #expect(product.ingredients.count == 2)
        #expect(product.ingredients[0].id == "niacinamide")
        #expect(product.ingredients[0].name == "Niacinamide")
        #expect(product.ingredients[0].normalizedName == "niacinamide")
        #expect(product.ingredients[1].id == "salicylic acid")
        // `isUsedCurrently` is decoded when present (not always overridden to true).
        #expect(product.isUsedCurrently == false)
    }

    @Test("Round-trip: legacy payload decode → encode produces new format")
    func roundTrip_legacyToNewFormat() throws {
        // **Validates: Requirements 21.3, 21.4**
        //
        // Lazy migration: a legacy payload can be decoded and re-encoded, and the
        // re-encoded form is the new format. This is what happens implicitly on
        // the next `saveProducts` call.
        let legacyJSON = """
        {
            "id": "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC",
            "name": "Legacy Toner",
            "brand": "Old",
            "category": "Toner",
            "ingredients": ["Witch Hazel"]
        }
        """

        let decoded = try decode(legacyJSON)
        let reEncoded = try JSONEncoder().encode(decoded)
        let reDecoded = try JSONDecoder().decode(SkincareProduct.self, from: reEncoded)

        // Round-trip preserves semantic content.
        #expect(reDecoded.id == decoded.id)
        #expect(reDecoded.name == decoded.name)
        #expect(reDecoded.brand == decoded.brand)
        #expect(reDecoded.category == decoded.category)
        #expect(reDecoded.ingredients == decoded.ingredients)
        #expect(reDecoded.isUsedCurrently == decoded.isUsedCurrently)

        // And the re-encoded JSON is the new format (category as rawValue string,
        // ingredients as objects — not raw strings).
        let obj = try JSONSerialization.jsonObject(with: reEncoded) as? [String: Any]
        #expect(obj?["category"] as? String == "toner")
        let ingredientsAny = obj?["ingredients"] as? [Any]
        #expect(ingredientsAny?.count == 1)
        #expect(ingredientsAny?.first is [String: Any])
    }
}
