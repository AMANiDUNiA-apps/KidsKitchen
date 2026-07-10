//
//  Ingredient.swift
//  KiDSKiTCHEN
//
//  Created by Claude Fable 5 on 02.07.26.
//  Klasse (Referenztyp!) — ViewModel.checkIngredientStatus mutiert isSelected
//  über die Referenz. Felder abgeleitet aus Recipes/Meal.swift (Oktober 25).
//

import Foundation
import Observation

// MARK: - Ingredient
@Observable
class Ingredient: Identifiable, Hashable {
    let id: UUID
    var name: String
    var category: IngredientCategory
    var imageURL: String?
    var details: String?
    var isSelected: Bool
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
        isSelected: Bool = false,
        unit: IngredientUnit = .gram
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.imageURL = imageURL
        self.details = details
        self.isSelected = isSelected
        self.unit = unit
    }

    // MARK: - Hashable
    static func == (lhs: Ingredient, rhs: Ingredient) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

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
