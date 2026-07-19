//
//  DietMode.swift
//  KiDSKiTCHEN
//
//  Created by Claude Fable 5 on 03.07.26.
//  Diät-Modi + Diät-Tauglichkeit je Zutat/Rezept. Grundlage für Jays
//  „Onboarding über Ausschluss": Nutzer sagt, was NICHT geht → Rezepte werden gefiltert.
//

import Foundation

// MARK: - DietMode
enum DietMode: String, CaseIterable, Identifiable, Codable {
    case all = "Alles"
    case vegetarian = "Vegetarisch"
    case vegan = "Vegan"

    var id: Self { self }

    var symbolName: String {
        switch self {
        case .all: "fork.knife"
        case .vegetarian: "leaf"
        case .vegan: "leaf.fill"
        }
    }
}

// MARK: - Zutat: Diät-Tauglichkeit
extension Ingredient {
    /// Namen, die trotz „harmloser" Kategorie nicht vegan sind.
    private static let nonVeganNames: Set<String> = ["ei", "eier", "honig", "gelatine"]

    var isVegetarian: Bool {
        switch category {
        case .redMeat, .poultry, .fish: false
        default: !name.localizedCaseInsensitiveContains("gelatine")
        }
    }

    var isVegan: Bool {
        guard isVegetarian else { return false }
        if category == .dairy { return false }
        let lower = name.lowercased()
        return !Ingredient.nonVeganNames.contains { lower == $0 }
    }

    func fits(_ diet: DietMode) -> Bool {
        switch diet {
        case .all: true
        case .vegetarian: isVegetarian
        case .vegan: isVegan
        }
    }
}

// MARK: - Rezept: Diät- & Ausschluss-Filter
extension Recipe {
    /// Passt das Rezept zum Diät-Modus (alle Zutaten müssen passen)?
    func fits(_ diet: DietMode) -> Bool {
        ingredients.allSatisfy { $0.ingredient.fits(diet) }
    }

    /// Enthält das Rezept eine ausgeschlossene Zutat?
    func containsExcluded(_ excluded: Set<String>) -> Bool {
        guard !excluded.isEmpty else { return false }
        return ingredients.contains { excluded.contains($0.ingredient.name) }
    }
}
