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
    /// Wochenplan: Wochentag (rawValue) → Rezeptnamen.
    var plan: [String: [String]] { didSet { savePlan() } }

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let diet = "pref.diet", excluded = "pref.excluded"
        static let favorites = "pref.favorites", shopping = "pref.shopping"
        static let pantry = "pref.pantry", plan = "pref.plan"
    }

    private init() {
        diet = DietMode(rawValue: defaults.string(forKey: Keys.diet) ?? "") ?? .all
        excluded = Set(defaults.stringArray(forKey: Keys.excluded) ?? [])
        favorites = Set(defaults.stringArray(forKey: Keys.favorites) ?? [])
        pantry = Set(defaults.stringArray(forKey: Keys.pantry) ?? [])
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

    // MARK: Einkaufsliste
    func addToShopping(_ recipe: Recipe) {
        for item in recipe.ingredients {
            let text = item.formatted
            if !shopping.contains(where: { $0.text == text }) {
                shopping.append(ShoppingItem(text: text))
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
        if pantry.contains(ingredientName) { pantry.remove(ingredientName) }
        else { pantry.insert(ingredientName) }
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
