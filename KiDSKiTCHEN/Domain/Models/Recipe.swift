//
//  Recipe.swift
//  KiDSKiTCHEN
//
//  Created by Claude Fable 5 on 02.07.26.
//  Felder abgeleitet aus Recipes/Meal.swift (Oktober 25) + ViewModel-Nutzung.
//

import Foundation

// MARK: - Recipe
struct Recipe: Identifiable, Codable {
    let id: UUID
    var name: String
    var details: String
    var imageURL: String?
    var category: RecipeCategory?
    var seasons: [Season]
    var level: String?
    var ingredients: [RecipeIngredient]
    var instructions: [RecipeInstruction]
    var nutrition: Nutrition
    var servings: Int
    var prepTime: Int   // Minuten
    var cookTime: Int
    var restTime: Int

    var totalTime: Int { prepTime + cookTime + restTime }

    init(
        id: UUID = UUID(),
        name: String = "",
        details: String = "",
        imageURL: String? = nil,
        category: RecipeCategory? = nil,
        seasons: [Season] = [.allYear],
        level: String? = nil,
        ingredients: [RecipeIngredient] = [],
        instructions: [RecipeInstruction] = [],
        nutrition: Nutrition = .empty,
        servings: Int = 2,
        prepTime: Int = 0,
        cookTime: Int = 0,
        restTime: Int = 0
    ) {
        self.id = id
        self.name = name
        self.details = details
        self.imageURL = imageURL
        self.category = category
        self.seasons = seasons
        self.level = level
        self.ingredients = ingredients
        self.instructions = instructions
        self.nutrition = nutrition
        self.servings = servings
        self.prepTime = prepTime
        self.cookTime = cookTime
        self.restTime = restTime
    }

    // MARK: - Mocks
    /// Leeres Rezept für den „Neues Rezept"-Flow (RecipeEditorViewModel.newRecipe)
    static let emptyMock = Recipe()

    static let mock = Recipe(
        name: "Apfel-Zimt-Porridge",
        details: "Ein warmes Frühstück, das nach Herbst schmeckt — und in 10 Minuten fertig ist.",
        category: .breakfast,
        seasons: [.autumn, .winter],
        level: "leicht",
        ingredients: RecipeIngredient.example1,
        instructions: RecipeInstruction.mock,
        nutrition: Nutrition(kcal: 320, protein: 11, carbs: 52, fat: 7, fiber: 8),
        prepTime: 5,
        cookTime: 5,
        restTime: 0
    )
}
