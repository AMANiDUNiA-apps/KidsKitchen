//
//  NutritionMathTests.swift
//  KiDSKiTCHENTests
//
//  Rebuild P2: deckt das vereinheitlichte Nutrition-Modell ab — explizit
//  hinterlegte Werte gewinnen, sonst BLS-Berechnung ab 80 % Abdeckung.
//

import Testing
@testable import KiDSKiTCHEN

struct NutritionMathTests {

    @Test func explicitNutritionWinsOverComputed() {
        let recipe = Recipe(
            name: "Test",
            ingredients: [RecipeIngredient(ingredient: Ingredient(name: "Apfel", category: .fruit), amount: 100, unit: .gram)],
            nutrition: Nutrition(kcal: 999, protein: 1, carbs: 1, fat: 1, fiber: 1),
            servings: 1
        )
        #expect(recipe.displayNutrition?.kcal == 999)
    }

    @Test func fullCoverageComputesFromBLS() {
        // Haferflocken/Milch/Apfel haben alle hinterlegte BLS-Werte (Zimt nicht — bewusst weggelassen).
        let recipe = Recipe(
            name: "Porridge",
            ingredients: [
                RecipeIngredient(ingredient: Ingredient(name: "Haferflocken", category: .cereals), amount: 100, unit: .gram),
                RecipeIngredient(ingredient: Ingredient(name: "Milch", category: .dairy), amount: 200, unit: .milliliter),
                RecipeIngredient(ingredient: Ingredient(name: "Apfel", category: .fruit), amount: 1, unit: .piece),
            ],
            servings: 1
        )
        #expect(recipe.nutritionCoverage == 1.0)
        #expect(recipe.computedNutrition.kcal ?? 0 > 0)
    }

    @Test func lowCoverageHidesComputedNutrition() {
        let recipe = Recipe(
            name: "Unbekannt",
            ingredients: [RecipeIngredient(ingredient: Ingredient(name: "Nichtimbls", category: .other), amount: 100, unit: .gram)],
            servings: 1
        )
        #expect(recipe.nutritionCoverage == 0)
        #expect(recipe.displayNutrition == nil)
    }

    @Test func gramFactorsAreStable() {
        #expect(IngredientUnit.piece.gramFactor == 100)
        #expect(IngredientUnit.pinch.gramFactor == 0.5)
    }
}
