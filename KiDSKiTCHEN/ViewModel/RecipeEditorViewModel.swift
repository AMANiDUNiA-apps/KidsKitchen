//
//  RecipeEditorViewModel.swift
//  KiDSKiTCHEN
//
//  Autoren-Seite: der Flow zum Erstellen eines Rezepts (NewRecipe) samt Zutaten-Picker
//  (IngredientPicker/IngredientRow) und Zubereitungs-Editor. Picker und Editor teilen sich
//  dieselbe `recipeIngredients`-Sammlung, deshalb liegen sie bewusst in EINEM VM.
//  Aus dem früheren God-ViewModel herausgelöst.
//

import Foundation
import Observation

@Observable
class RecipeEditorViewModel {
    // MARK: - .shared
    static let shared = RecipeEditorViewModel()

    private init() {}

    // MARK: - Zutaten-Auswahlliste (Picker)
    var ingredients: [Ingredient] = Ingredient.seed

    var sortedIngredients: [Ingredient] {
        if !ingredientSearchText.isEmpty {
            return ingredients.filter { $0.isSelected || (!$0.isSelected && $0.name.localizedCaseInsensitiveContains(ingredientSearchText)) }
        }
        return ingredients.sorted { $0.isSelected && !$1.isSelected }
    }

    // MARK: - pickerSections (Kategorie-Sektionen für den IngredientPicker)
    var pickerSections: [(category: IngredientCategory, items: [Ingredient])] {
        let visible = ingredientSearchText.isEmpty
            ? ingredients
            : ingredients.filter { $0.isSelected || $0.name.localizedStandardContains(ingredientSearchText) }
        return IngredientCategory.allCases.compactMap { category in
            let items = visible
                .filter { $0.category == category }
                .sorted {
                    if $0.isSelected != $1.isSelected { return $0.isSelected }
                    return $0.name.localizedStandardCompare($1.name) == .orderedAscending
                }
            return items.isEmpty ? nil : (category, items)
        }
    }

    // MARK: - deselectCategory (ganze Kategorie abwählen)
    func deselectCategory(_ category: IngredientCategory) {
        recipeIngredients.removeAll { $0.ingredient.category == category }
        for ingredient in ingredients where ingredient.category == category {
            ingredient.isSelected = false
        }
    }

    // MARK: - Zutaten des aktuell bearbeiteten Rezepts
    var recipeIngredients: [RecipeIngredient] = RecipeIngredient.example1

    // MARK: - einzelne
    var newRecipe: Recipe?
    var ingredient: Ingredient?
    var recipeIngredient: RecipeIngredient?
    var recipeInstruction: RecipeInstruction?
    var recipeInstructions: [RecipeInstruction] = RecipeInstruction.mock

    // MARK: - Bool
    var isShowingIngredients: Bool = false
    var isEditingInstruction: Bool = false

    // MARK: - Eingabefelder
    var ingredientSearchText: String = ""
    var instructionsTextField: String = ""

    // MARK: - NumberFormatter
    let numberFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 3
        return f
    }()

    func clearInstructionTextField() {
        instructionsTextField = ""
        isEditingInstruction = false
    }

    func editRecipeInstruction(instruction: RecipeInstruction) {
        // TextField bearbeiten
        instructionsTextField = instruction.text

        // zur Sicherheit speichern
        recipeInstruction = instruction
        isEditingInstruction = true
    }

    // - Methods
    // TODO: umbennen, da es nicht mehr nur noch add ist.
    func addRecipeInstruction() {
        if !isEditingInstruction {
            let recipeInstruction = RecipeInstruction(text: instructionsTextField)
            recipeInstructions.append(recipeInstruction)
        }
        else if let current = recipeInstruction,
                let index = recipeInstructions.firstIndex(where: { $0.id == current.id }) {
            recipeInstructions[index] = RecipeInstruction(text: instructionsTextField)
        }
        clearInstructionTextField()
    }

    // MARK: - removeRecipeInstruction
    func removeRecipeInstruction() {
        recipeInstructions.removeAll() { $0.id == recipeInstruction?.id }
        recipeInstruction = nil
        clearInstructionTextField()
    }

    // MARK: - showIngredients
    func showRecipeIngredients() {
        isShowingIngredients = true
    }

    // MARK: - addRecipeIngredients
    func closeRecipeIngredients() {
        isShowingIngredients = false
    }

    // MARK: - resetAllSelected
    /// Setzt alle isSelected-Flags auf den globalen Ingredient-Instanzen zurück.
    /// Muss nach jedem Abbruch/Speichern des Rezept-Editors aufgerufen werden,
    /// damit der Picker beim nächsten Öffnen sauber startet.
    func resetAllSelected() {
        for ingredient in ingredients { ingredient.isSelected = false }
    }

    // MARK: - removeAllRecipeIngredients
    func removeAllRecipeIngredients() {
        recipeIngredients.removeAll()
        resetAllSelected()
        isShowingIngredients = false
    }

    func checkStatus() {
        let selected = Set(recipeIngredients.map { $0.ingredient.name })
        for ingredient in ingredients {
            ingredient.isSelected = selected.contains(ingredient.name)
        }
    }

    // MARK: - checkIngredientStatus
    func checkIngredientStatus(ingredient: Ingredient) {
        ingredient.isSelected = recipeIngredients.contains(where: { $0.ingredient.name == ingredient.name })
    }

    // MARK: - getRecipeIngredient
    func getRecipeIngredient(ingredient: Ingredient) -> RecipeIngredient? {
        checkIngredientStatus(ingredient: ingredient)
        if let existingIndex = recipeIngredients.firstIndex(where: { $0.ingredient.name == ingredient.name }) {
            return recipeIngredients[existingIndex]
        } else {
            return nil
        }
    }

    // MARK: addRecipeIngredient
    func addRecipeIngredient(ingredient: Ingredient, amount: Double, ingredientUnit: IngredientUnit) {
        let recipeIngredient: RecipeIngredient = RecipeIngredient(
            ingredient: ingredient,
            amount: amount,
            unit: ingredientUnit
        )
        if let existingIndex = self.recipeIngredients.firstIndex(where: { $0.ingredient.name == recipeIngredient.ingredient.name }) {
            // Update existing entry: adjust amount and unit
            self.recipeIngredients[existingIndex].amount = (amount)
            self.recipeIngredients[existingIndex].unit = ingredientUnit
        } else {
            self.recipeIngredients.append(recipeIngredient)
        }
    }

    // MARK: removeRecipeIngredientByIngredient
    func removeRecipeIngredientByIngredient(ingredient: Ingredient) {
        if let existingIndex = self.recipeIngredients.firstIndex(where: { $0.ingredient.name == ingredient.name }) {
            self.recipeIngredients.remove(at: existingIndex)
        }
    }

    // MARK: removeRecipeIngredient
    func removeRecipeIngredient(recipeIngredient: RecipeIngredient) {
        recipeIngredients.removeAll(where: { $0.id == recipeIngredient.id })
    }
}
