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
    // Abgeleitet aus der zentralen Auswahl im RecipeEditorViewModel (Rebuild P2:
    // Ingredient ist ein Werttyp, kann selbst keine Auswahl mehr tragen), damit
    // die Zeile auch auf Änderungen von außen reagiert (z.B. „ganze Kategorie abwählen").
    var isSelected: Bool { viewModel.isSelected(ingredient) }

    init (ingredient: Ingredient) {
        self.ingredient = ingredient
        checkIsSelected()
    }

    private var viewModel: RecipeEditorViewModel = .shared

    func checkIsSelected() {
        if let recipeIngredient {
            viewModel.selectedIngredientIDs.insert(ingredient.id)
            amount = recipeIngredient.amount
            unit = recipeIngredient.unit
        } else { viewModel.selectedIngredientIDs.remove(ingredient.id) }
    }

    // Add Ingredient
    func addIngredient() {
        viewModel.addRecipeIngredient(
            ingredient: ingredient,
            amount: amount ?? 0,
            ingredientUnit: unit
        )
        viewModel.selectedIngredientIDs.insert(ingredient.id)
    }

    // Delete Ingredient
    func deleteIngredient() {
        viewModel.removeRecipeIngredientByIngredient(ingredient: ingredient)
        viewModel.selectedIngredientIDs.remove(ingredient.id)
    }
    
}
