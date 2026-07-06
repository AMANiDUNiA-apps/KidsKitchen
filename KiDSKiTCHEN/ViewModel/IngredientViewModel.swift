//
//  IngredientViewModel.swift
//  KiDSKiTCHEN
//
//  Created by Joscha Amani Gaber on 18.01.26.
//

import Foundation


@Observable
class IngredientViewModel {
    
    static let shared = IngredientViewModel(ingredient: .longMock)
    
    var ingredient: Ingredient
    var ingredientName: String { ingredient.name }
    var amount: Double?
    var unit: IngredientUnit = .gram
    var recipeIngredient: RecipeIngredient? { viewModel.getRecipeIngredient(ingredient: ingredient)}
    // Abgeleitet vom geteilten Ingredient (Referenztyp), damit die Zeile auch auf
    // Änderungen von außen reagiert (z.B. „ganze Kategorie abwählen")
    var isSelected: Bool { ingredient.isSelected }

    init (ingredient: Ingredient) {
        self.ingredient = ingredient
        checkIsSelected()
    }

    private var viewModel: RecipeEditorViewModel = .shared

    func checkIsSelected() {
        if let recipeIngredient {
            ingredient.isSelected = true
            amount = recipeIngredient.amount
            unit = recipeIngredient.unit
        } else { ingredient.isSelected = false }
    }

    // Add Ingredient
    func addIngredient() {
        viewModel.addRecipeIngredient(
            ingredient: ingredient,
            amount: amount ?? 0,
            ingredientUnit: unit
        )
        ingredient.isSelected = true
    }

    // Delete Ingredient
    func deleteIngredient() {
        viewModel.removeRecipeIngredientByIngredient(ingredient: ingredient)
        ingredient.isSelected = false
    }
    
}
