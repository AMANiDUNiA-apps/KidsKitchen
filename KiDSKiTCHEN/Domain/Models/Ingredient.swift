//
//  Ingredient.swift
//  KiDSKiTCHEN
//
//  Rebuild P2 (Domain): reiner Werttyp — kein `@Observable`, keine `isSelected`
//  im Modell. UI-Auswahlzustand (Picker) lebt jetzt im jeweiligen ViewModel
//  (siehe RecipeEditorViewModel.selectedIngredientIDs), nicht mehr am Datenmodell.
//

import Foundation

// MARK: - Ingredient
struct Ingredient: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var category: IngredientCategory
    var imageURL: String?
    var details: String?
    /// Kanonische Maßeinheit dieser Zutat für Vorrat/Einkauf (g/ml/Stück …).
    /// KEINE Umrechnung — die reale Maßeinheit der Zutat (Milch → ml, Ei → Stück,
    /// Mehl → g). Default `.gram` deckt alle Schütt-/Wiegezutaten ab.
    var unit: IngredientUnit

    init(
        id: UUID = UUID(),
        name: String,
        category: IngredientCategory = .other,
        imageURL: String? = nil,
        details: String? = nil,
        unit: IngredientUnit = .gram
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.imageURL = imageURL
        self.details = details
        self.unit = unit
    }

    // MARK: - Mocks
    static let longMock = Ingredient(
        name: "Vollkornmehl",
        category: .cereals,
        details: "Mehl aus dem vollen Korn — mehr Ballaststoffe als Weißmehl."
    )

    static let mock: [Ingredient] = [
        Ingredient(name: "Apfel", category: .fruit),
        Ingredient(name: "Banane", category: .fruit),
        Ingredient(name: "Karotte", category: .vegetable),
        Ingredient(name: "Kartoffel", category: .vegetable),
        Ingredient(name: "Haferflocken", category: .cereals),
        longMock,
        Ingredient(name: "Milch", category: .dairy),
        Ingredient(name: "Butter", category: .fatsAndOils),
        Ingredient(name: "Ei", category: .other),
        Ingredient(name: "Honig", category: .other),
        Ingredient(name: "Zimt", category: .spices),
        Ingredient(name: "Petersilie", category: .herbs),
    ]
}
