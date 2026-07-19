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

    // Rebuild P2: Ingredient ist ein reiner Werttyp ohne `isSelected` — die
    // Auswahl lebt jetzt hier zentral, statt auf den geteilten Model-Instanzen.
    var selectedIngredientIDs: Set<Ingredient.ID> = []

    func isSelected(_ ingredient: Ingredient) -> Bool {
        selectedIngredientIDs.contains(ingredient.id)
    }

    var sortedIngredients: [Ingredient] {
        if !ingredientSearchText.isEmpty {
            return ingredients.filter { isSelected($0) || $0.name.localizedCaseInsensitiveContains(ingredientSearchText) }
        }
        return ingredients.sorted { isSelected($0) && !isSelected($1) }
    }

    // MARK: - pickerSections (Kategorie-Sektionen für den IngredientPicker)
    var pickerSections: [(category: IngredientCategory, items: [Ingredient])] {
        let visible = ingredientSearchText.isEmpty
            ? ingredients
            : ingredients.filter { isSelected($0) || $0.name.localizedStandardContains(ingredientSearchText) }
        return IngredientCategory.allCases.compactMap { category in
            let items = visible
                .filter { $0.category == category }
                .sorted {
                    if isSelected($0) != isSelected($1) { return isSelected($0) }
                    return $0.name.localizedStandardCompare($1.name) == .orderedAscending
                }
            return items.isEmpty ? nil : (category, items)
        }
    }

    // MARK: - deselectCategory (ganze Kategorie abwählen)
    func deselectCategory(_ category: IngredientCategory) {
        recipeIngredients.removeAll { $0.ingredient.category == category }
        for ingredient in ingredients where ingredient.category == category {
            selectedIngredientIDs.remove(ingredient.id)
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
    /// Setzt die Auswahl zurück. Muss nach jedem Abbruch/Speichern des
    /// Rezept-Editors aufgerufen werden, damit der Picker beim nächsten
    /// Öffnen sauber startet.
    func resetAllSelected() {
        selectedIngredientIDs.removeAll()
    }

    func resetEditorSession() {
        recipeIngredients = []
        recipeInstructions = []
        recipeIngredient = nil
        recipeInstruction = nil
        ingredientSearchText = ""
        instructionsTextField = ""
        isEditingInstruction = false
        isShowingIngredients = false
        resetAllSelected()
    }

    // MARK: - removeAllRecipeIngredients
    func removeAllRecipeIngredients() {
        recipeIngredients.removeAll()
        resetAllSelected()
        isShowingIngredients = false
    }

    func checkStatus() {
        let selected = Set(recipeIngredients.map { $0.ingredient.name })
        selectedIngredientIDs = Set(ingredients.filter { selected.contains($0.name) }.map(\.id))
    }

    // MARK: - checkIngredientStatus
    func checkIngredientStatus(ingredient: Ingredient) {
        if recipeIngredients.contains(where: { $0.ingredient.name == ingredient.name }) {
            selectedIngredientIDs.insert(ingredient.id)
        } else {
            selectedIngredientIDs.remove(ingredient.id)
        }
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
