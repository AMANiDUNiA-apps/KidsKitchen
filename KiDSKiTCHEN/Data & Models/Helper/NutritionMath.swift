//
//  NutritionMath.swift
//  KiDSKiTCHEN
//
//  Created by Claude Fable 5 on 03.07.26.
//  In-App-Entsprechung der Nährwert-Berechnung (pipelines/nutrition-calc.sql):
//  Zutat → Gramm → NutritionFacts × g/100 → summieren → ÷ Portionen.
//

import Foundation

extension IngredientUnit {
    /// Gramm je 1 Einheit (Näherung; „Stück" = 100 g als Default).
    var gramFactor: Double {
        switch self {
        case .gram: 1
        case .kilogram: 1000
        case .milliliter: 1
        case .liter: 1000
        case .tablespoon: 15
        case .teaspoon: 5
        case .pinch: 0.5
        case .bunch: 25
        case .piece: 100
        }
    }
}

extension RecipeIngredient {
    var grams: Double { amount * unit.gramFactor }
}

extension Recipe {
    /// Aus den Zutaten berechnete Nährwerte PRO PORTION (nutzt NutritionFacts.blsSeed).
    /// Zutaten ohne hinterlegte Werte werden übersprungen.
    var computedNutrition: Nutrition {
        var kcal = 0.0, protein = 0.0, carbs = 0.0, fat = 0.0, fiber = 0.0
        for item in ingredients {
            guard let facts = NutritionFacts.bls(for: item.ingredient.name) else { continue }
            let factor = item.grams / 100
            kcal += (facts.kcal ?? 0) * factor
            protein += (facts.protein ?? 0) * factor
            carbs += (facts.carbs ?? 0) * factor
            fat += (facts.fat ?? 0) * factor
            fiber += (facts.fiber ?? 0) * factor
        }
        let portions = Double(max(servings, 1))
        return Nutrition(
            kcal: kcal / portions, protein: protein / portions,
            carbs: carbs / portions, fat: fat / portions, fiber: fiber / portions
        )
    }

    /// Nährwerte für die Anzeige: explizit hinterlegte gewinnen; sonst die aus
    /// BLS-Fakten berechneten, aber NUR bei ausreichender Zutaten-Abdeckung
    /// (Schwelle wie in der Pipeline: ≥ 80 %). Sonst nil = Sektion ausblenden,
    /// statt zu niedrige Werte als Fakt zu zeigen.
    var displayNutrition: Nutrition? {
        if !nutrition.isEmpty { return nutrition }
        guard nutritionCoverage >= 0.8 else { return nil }
        let computed = computedNutrition
        return computed.isEmpty ? nil : computed
    }

    /// Anteil der Zutaten mit hinterlegten Nährwerten (0…1) — Vertrauensmaß.
    var nutritionCoverage: Double {
        guard !ingredients.isEmpty else { return 0 }
        let known = ingredients.filter { NutritionFacts.bls(for: $0.ingredient.name) != nil }.count
        return Double(known) / Double(ingredients.count)
    }
}
