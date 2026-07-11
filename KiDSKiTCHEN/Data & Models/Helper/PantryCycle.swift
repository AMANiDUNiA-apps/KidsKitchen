//
//  PantryCycle.swift
//  KiDSKiTCHEN
//
//  Weiterbau 8 — der Vorrats-Kreislauf: planen → Bedarf rechnen → einkaufen →
//  kochen → Vorrat aktuell. Reine, deterministische Logik (KEIN LLM), sie sitzt
//  auf den vorhandenen Daten auf (Wochenplan, Vorrats-Mengen, Rezept-Zutaten).
//
//  Grundregel wie im ganzen Projekt: KEINE Umrechnung zwischen Einheiten. Gerechnet
//  wird nur, wenn die Rezept-Einheit der Zutat der KANONISCHEN Einheit der Zutat
//  entspricht (Ingredient.seed). Passt sie nicht, fällt die Logik ehrlich auf reine
//  Vorhandensein-Prüfung zurück (da/nicht-da), statt falsche Zahlen zu erfinden.
//

import Foundation

// MARK: - Kanonische Einheit einer Zutat (nach Name)
extension Ingredient {
    /// Die für Vorrat/Einkauf gültige Einheit einer Zutat, anhand des Namens aus
    /// dem kuratierten Seed. Unbekannt → `.gram` (Schütt-/Wiege-Default), wie im Modell.
    static func canonicalUnit(for name: String) -> IngredientUnit {
        seed.first { $0.name == name }?.unit ?? .gram
    }

    /// Kategorie einer Zutat nach Name (für Einkaufs-Vorschläge). Unbekannt → `.other`.
    static func category(for name: String) -> IngredientCategory {
        seed.first { $0.name == name }?.category ?? .other
    }
}

// MARK: - PantryShortfall (Teil A: was fehlt für den Wochenplan)
/// Ergebnis der Bedarf-Rechnung für EINE Zutat über den ganzen Wochenplan.
/// `numeric == false` heißt: Einheit passt nicht zur kanonischen → nur Vorhandensein
/// geprüft, keine Mengen-Zahl (ehrlich statt geraten).
struct PantryShortfall: Identifiable {
    let ingredientName: String
    let category: IngredientCategory
    let unit: IngredientUnit
    let needed: Int
    let have: Int
    let numeric: Bool
    /// Woher der Bedarf kommt, z. B. ["Mittwoch: Bananen-Pfannkuchen"].
    let origins: [String]

    var id: String { ingredientName }

    /// Fehlmenge (nur sinnvoll bei `numeric`). Bei reiner Vorhandensein-Prüfung 0.
    var missing: Int { numeric ? max(0, needed - have) : 0 }

    /// Ist überhaupt etwas nachzukaufen? (numerisch: Fehlmenge > 0 · sonst: gar nicht da)
    var isShort: Bool { numeric ? missing > 0 : have == 0 }

    /// Kurzer Herkunfts-Text für die Einkaufsliste („für Mittwoch: Pfannkuchen").
    var originText: String {
        let unique = origins.reduced()
        guard let first = unique.first else { return "" }
        if unique.count == 1 { return "für \(first)" }
        return "für \(first) +\(unique.count - 1) weitere"
    }

    /// Anzeige-Text des Einkaufs-Postens („120 g Haferflocken" bzw. nur der Name).
    var shoppingText: String {
        numeric ? "\(missing) \(unit.rawValue) \(ingredientName)" : ingredientName
    }
}

private extension Array where Element == String {
    /// Reihenfolge-erhaltende Duplikat-Entfernung.
    func reduced() -> [String] {
        var seen = Set<String>()
        return filter { seen.insert($0).inserted }
    }
}

// MARK: - CookableMatch (Teil C: „Was kann ich kochen?")
/// Ein Rezept mit der Liste der dafür fehlenden Zutaten (reines Set-Matching über
/// Namen gegen den Vorrat — deterministisch, offline).
struct CookableMatch: Identifiable {
    let recipe: Recipe
    let missing: [RecipeIngredient]
    var id: UUID { recipe.id }
    var missingCount: Int { missing.count }
    var missingNames: [String] { missing.map(\.ingredient.name) }
}
