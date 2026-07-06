//
//  SavedRecipe.swift
//  KiDSKiTCHEN
//
//  SwiftData-Modell für offline gespeicherte Rezepte. Das Bild wird beim Speichern einmal
//  heruntergeladen und als `externalStorage`-Blob abgelegt (SwiftData legt große Daten als
//  separate Datei ab, hält die DB schlank) — so ist das Rezept mitsamt Bild offline verfügbar.
//

import Foundation
import SwiftData

@Model
final class SavedRecipe {
    @Attribute(.unique) var recipeName: String
    var details: String
    var imageURL: String?
    @Attribute(.externalStorage) var imageData: Data?
    var kcal: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double
    var servings: Int
    var prepTime: Int
    var cookTime: Int
    var steps: [String]
    var savedAt: Date

    init(from recipe: Recipe, imageData: Data? = nil) {
        self.recipeName = recipe.name
        self.details = recipe.details
        self.imageURL = recipe.imageURL
        self.imageData = imageData
        self.kcal = recipe.nutrition.kcal
        self.protein = recipe.nutrition.protein
        self.carbs = recipe.nutrition.carbs
        self.fat = recipe.nutrition.fat
        self.fiber = recipe.nutrition.fiber
        self.servings = recipe.servings
        self.prepTime = recipe.prepTime
        self.cookTime = recipe.cookTime
        self.steps = recipe.instructions.map(\.text)
        self.savedAt = .now
    }
}
