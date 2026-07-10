//
//  Preferences.swift
//  KiDSKiTCHEN
//
//  Created by Claude Fable 5 on 03.07.26.
//  Persistente Nutzer-Einstellungen (UserDefaults): Diät, ausgeschlossene Zutaten,
//  Favoriten, Einkaufsliste. Bewusst leichtgewichtig (kein SwiftData) — die große
//  Speicher-Entscheidung (Supabase/Vapor) bleibt davon unberührt.
//

import Foundation
import Observation

// MARK: - ShoppingItem
struct ShoppingItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var text: String
    var done: Bool = false
    /// Kategorie der Zutat (seit Teil C). Optional: Alt-Posten aus früheren
    /// Versionen haben den Schlüssel nicht → nil, dann per `resolvedCategory`
    /// aus dem Text abgeleitet.
    var category: IngredientCategory?

    /// Echte Kategorie für Filter/Anzeige — leitet fehlende Werte aus dem Text ab.
    var resolvedCategory: IngredientCategory {
        if let category { return category }
        if let match = Ingredient.seed.first(where: { text.localizedCaseInsensitiveContains($0.name) }) {
            return match.category
        }
        return .other
    }
}

// MARK: - Preferences
@Observable
final class Preferences {
    static let shared = Preferences()

    var diet: DietMode { didSet { defaults.set(diet.rawValue, forKey: Keys.diet) } }
    var excluded: Set<String> { didSet { defaults.set(Array(excluded), forKey: Keys.excluded) } }
    var favorites: Set<String> { didSet { defaults.set(Array(favorites), forKey: Keys.favorites) } }
    var shopping: [ShoppingItem] { didSet { saveShopping() } }
    var pantry: Set<String> { didSet { defaults.set(Array(pantry), forKey: Keys.pantry) } }
    /// Vorrats-Mengen in Gramm je Zutatname (optional — nur wo der Nutzer eine
    /// Menge gesetzt hat). Additiv zu `pantry` (in-Vorrat ja/nein).
    var pantryAmounts: [String: Int] { didSet { savePantryAmounts() } }
    /// Wochenplan: Wochentag (rawValue) → Rezeptnamen.
    var plan: [String: [String]] { didSet { savePlan() } }

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let diet = "pref.diet", excluded = "pref.excluded"
        static let favorites = "pref.favorites", shopping = "pref.shopping"
        static let pantry = "pref.pantry", plan = "pref.plan"
        static let pantryAmounts = "pref.pantryAmounts"
    }

    private init() {
        diet = DietMode(rawValue: defaults.string(forKey: Keys.diet) ?? "") ?? .all
        excluded = Set(defaults.stringArray(forKey: Keys.excluded) ?? [])
        favorites = Set(defaults.stringArray(forKey: Keys.favorites) ?? [])
        pantry = Set(defaults.stringArray(forKey: Keys.pantry) ?? [])
        if let data = defaults.data(forKey: Keys.pantryAmounts),
           let amounts = try? JSONDecoder().decode([String: Int].self, from: data) {
            pantryAmounts = amounts
        } else {
            pantryAmounts = [:]
        }
        if let data = defaults.data(forKey: Keys.shopping),
           let items = try? JSONDecoder().decode([ShoppingItem].self, from: data) {
            shopping = items
        } else {
            shopping = []
        }
        if let data = defaults.data(forKey: Keys.plan),
           let p = try? JSONDecoder().decode([String: [String]].self, from: data) {
            plan = p
        } else {
            plan = [:]
        }
    }

    // MARK: Favoriten
    func isFavorite(_ recipeName: String) -> Bool { favorites.contains(recipeName) }
    func toggleFavorite(_ recipeName: String) {
        if favorites.contains(recipeName) { favorites.remove(recipeName) }
        else { favorites.insert(recipeName) }
    }

    // MARK: Ausschluss
    func toggleExcluded(_ ingredientName: String) {
        if excluded.contains(ingredientName) { excluded.remove(ingredientName) }
        else { excluded.insert(ingredientName) }
    }

    /// Mehrere Zutaten auf einmal aus-/einschließen (für Onboarding-Presets).
    func setExcluded(_ ingredientNames: [String], excluded shouldExclude: Bool) {
        if shouldExclude { excluded.formUnion(ingredientNames) }
        else { excluded.subtract(ingredientNames) }
    }

    // MARK: Einkaufsliste
    func addToShopping(_ recipe: Recipe, scaledBy factor: Double = 1) {
        for item in recipe.ingredients {
            let text = factor == 1 ? item.formatted : item.formatted(scaledBy: factor)
            if !shopping.contains(where: { $0.text == text }) {
                shopping.append(ShoppingItem(text: text, category: item.ingredient.category))
            }
        }
    }
    func clearDoneShopping() { shopping.removeAll { $0.done } }

    private func saveShopping() {
        if let data = try? JSONEncoder().encode(shopping) {
            defaults.set(data, forKey: Keys.shopping)
        }
    }

    // MARK: Vorratsschrank
    func hasInPantry(_ ingredientName: String) -> Bool { pantry.contains(ingredientName) }
    func togglePantry(_ ingredientName: String) {
        if pantry.contains(ingredientName) {
            pantry.remove(ingredientName)
            // Nicht mehr im Vorrat → gespeicherte Menge verwerfen (ehrlich)
            pantryAmounts[ingredientName] = nil
        } else {
            pantry.insert(ingredientName)
        }
    }

    /// Gesetzte Vorrats-Menge in der kanonischen Einheit der Zutat (g/ml/Stück …);
    /// nil = keine Menge hinterlegt. Der Wert ist einheitenlos gespeichert — die
    /// Einheit liefert die Zutat (`Ingredient.unit`), es wird nichts umgerechnet.
    func pantryAmount(_ ingredientName: String) -> Int? { pantryAmounts[ingredientName] }
    /// Menge setzen (in der Einheit der Zutat). 0 löscht die Menge; setzt implizit „im Vorrat".
    func setPantryAmount(_ amount: Int, for ingredientName: String) {
        if amount <= 0 {
            pantryAmounts[ingredientName] = nil
        } else {
            pantryAmounts[ingredientName] = amount
            pantry.insert(ingredientName)
        }
    }

    private func savePantryAmounts() {
        if let data = try? JSONEncoder().encode(pantryAmounts) {
            defaults.set(data, forKey: Keys.pantryAmounts)
        }
    }
    /// Wie viele Zutaten des Rezepts sind im Vorrat (0…1)?
    func pantryCoverage(_ recipe: Recipe) -> Double {
        guard !recipe.ingredients.isEmpty else { return 0 }
        let have = recipe.ingredients.filter { pantry.contains($0.ingredient.name) }.count
        return Double(have) / Double(recipe.ingredients.count)
    }
    /// Fehlende Zutaten eines Rezepts (nicht im Vorrat).
    func missingIngredients(_ recipe: Recipe) -> [RecipeIngredient] {
        recipe.ingredients.filter { !pantry.contains($0.ingredient.name) }
    }

    // MARK: Wochenplan
    func plannedRecipes(_ day: Weekday) -> [String] { plan[day.rawValue] ?? [] }
    func addToPlan(_ recipeName: String, day: Weekday) {
        var list = plan[day.rawValue] ?? []
        guard !list.contains(recipeName) else { return }
        list.append(recipeName)
        plan[day.rawValue] = list
    }
    func removeFromPlan(_ recipeName: String, day: Weekday) {
        plan[day.rawValue]?.removeAll { $0 == recipeName }
        if plan[day.rawValue]?.isEmpty == true { plan[day.rawValue] = nil }
    }
    var plannedCount: Int { plan.values.reduce(0) { $0 + $1.count } }

    private func savePlan() {
        if let data = try? JSONEncoder().encode(plan) {
            defaults.set(data, forKey: Keys.plan)
        }
    }
}
