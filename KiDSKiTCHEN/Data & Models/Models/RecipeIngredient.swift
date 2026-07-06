//
//  RecipeIngredient.swift
//  KiDSKiTCHEN
//
//  Created by Claude Fable 5 on 02.07.26.
//  Struct (Werttyp) — ViewModel mutiert amount/unit über den Array-Index.
//

import Foundation

// MARK: - RecipeIngredient
struct RecipeIngredient: Identifiable {
    let id: UUID
    var ingredient: Ingredient
    var amount: Double
    var unit: IngredientUnit

    init(
        id: UUID = UUID(),
        ingredient: Ingredient,
        amount: Double,
        unit: IngredientUnit = .gram
    ) {
        self.id = id
        self.ingredient = ingredient
        self.amount = amount
        self.unit = unit
    }

    // MARK: formatted („250 g Vollkornmehl")
    var formatted: String {
        "\(amount.formatted(.number.precision(.fractionLength(0...3)))) \(unit.rawValue) \(ingredient.name)"
    }

    // MARK: - Mocks
    static let example1: [RecipeIngredient] = [
        RecipeIngredient(ingredient: Ingredient(name: "Haferflocken", category: .cereals), amount: 100, unit: .gram),
        RecipeIngredient(ingredient: Ingredient(name: "Milch", category: .dairy), amount: 200, unit: .milliliter),
        RecipeIngredient(ingredient: Ingredient(name: "Apfel", category: .fruit), amount: 1, unit: .piece),
        RecipeIngredient(ingredient: Ingredient(name: "Zimt", category: .spices), amount: 1, unit: .pinch),
    ]
}
