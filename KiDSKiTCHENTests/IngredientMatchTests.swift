//
//  IngredientMatchTests.swift
//  KiDSKiTCHENTests
//
//  Rebuild P2: Swift-Testing-Target — deckt die Matching-Stufen
//  (exakt/alias/enthalten/fuzzy) deterministisch ab.
//

import Testing
@testable import KiDSKiTCHEN

struct IngredientMatchTests {

    @Test func exactMatchHitsCatalog() {
        let result = IngredientMatch.resolve("Apfel")
        #expect(result.tier == .exact)
        #expect(result.assetKey == "apfel")
    }

    @Test func pluralResolvesViaAlias() {
        let result = IngredientMatch.resolve("Kartoffeln")
        #expect(result.tier == .alias)
        #expect(result.assetKey == "kartoffel")
    }

    @Test func rawStringWithAmountAndUnitNormalizes() {
        let result = IngredientMatch.resolve("600 g Kartoffeln")
        #expect(result.assetKey == "kartoffel")
    }

    @Test func unresolvableNameReturnsNoneOrUncertain() {
        let result = IngredientMatch.resolve("Xyzzy Quatschzutat 42")
        #expect(result.assetKey == nil)
    }

    @Test func normalizeHandlesUmlautsAndSharpS() {
        #expect(Ingredient.imageAssetKey(for: "Süßkartoffel") == "suesskartoffel")
    }
}
