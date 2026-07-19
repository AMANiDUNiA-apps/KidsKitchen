//
//  PantryCycleTests.swift
//  KiDSKiTCHENTests
//
//  Rebuild P2: PantryShortfall/CookableMatch — ehrliche Vorhandensein-Prüfung
//  statt geratener Zahlen, wenn die Einheit nicht zur kanonischen passt.
//

import Testing
@testable import KiDSKiTCHEN

struct PantryCycleTests {

    @Test func numericShortfallComputesMissing() {
        let shortfall = PantryShortfall(
            ingredientName: "Haferflocken", category: .cereals, unit: .gram,
            needed: 300, have: 100, numeric: true, origins: ["Mittwoch: Porridge"]
        )
        #expect(shortfall.missing == 200)
        #expect(shortfall.isShort == true)
        #expect(shortfall.shoppingText == "200 g Haferflocken")
    }

    @Test func nonNumericShortfallFallsBackToPresence() {
        let shortfall = PantryShortfall(
            ingredientName: "Zimt", category: .spices, unit: .gram,
            needed: 0, have: 0, numeric: false, origins: []
        )
        #expect(shortfall.missing == 0)
        #expect(shortfall.isShort == true)
        #expect(shortfall.shoppingText == "Zimt")
    }

    @Test func originTextSummarizesMultipleSources() {
        let shortfall = PantryShortfall(
            ingredientName: "Milch", category: .dairy, unit: .milliliter,
            needed: 500, have: 0, numeric: true,
            origins: ["Montag: Porridge", "Montag: Porridge", "Mittwoch: Pfannkuchen"]
        )
        #expect(shortfall.originText == "für Montag: Porridge +1 weitere")
    }

    @Test func cookableMatchReportsMissingIngredients() {
        let missing = [RecipeIngredient(ingredient: Ingredient(name: "Milch", category: .dairy), amount: 200, unit: .milliliter)]
        let match = CookableMatch(recipe: .mock, missing: missing)
        #expect(match.missingCount == 1)
        #expect(match.missingNames == ["Milch"])
    }

    @Test func canonicalUnitAndCategoryFallBackForUnknownNames() {
        #expect(Ingredient.canonicalUnit(for: "Unbekannte Zutat") == .gram)
        #expect(Ingredient.category(for: "Unbekannte Zutat") == .other)
        #expect(Ingredient.canonicalUnit(for: "Apfel") == .piece)
    }
}
