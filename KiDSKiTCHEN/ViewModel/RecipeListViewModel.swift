//
//  RecipeListViewModel.swift
//  KiDSKiTCHEN
//
//  Lese-/Anzeige-Seite: die Rezeptliste für Home & Wochenplan. Holt die Rezepte
//  übers Repository (echter API-Call), fällt offline auf die Seed-Rezepte zurück.
//  Aus dem früheren God-ViewModel herausgelöst (nur Anzeige, keine Editier-Logik).
//

import Foundation
import Observation

@Observable
class RecipeListViewModel {
    // MARK: - .shared
    static let shared = RecipeListViewModel()

    /// Startet mit den Seed-Rezepten (sofort da, offline). `loadRecipes()` ersetzt sie
    /// bei Erfolg durch die per API geladenen.
    var recipes: [Recipe] = Recipe.seed

    /// Läuft der API-Abruf gerade? (für Ladeanzeige)
    var isLoadingRecipes = false

    // MARK: - Repository (Datenquelle der Rezepte, injizierbar)
    private let recipeRepository: RecipeRepository

    private init(recipeRepository: RecipeRepository? = nil) {
        // Offline-Guard (V1): Ohne anon-Key (Release/Demo — Env-Vars greifen im Archive nie)
        // wird das Seed-Repository gewählt, das KEINEN Netz-Request auslöst. Damit ist der
        // ausgelieferte Build beweisbar offline (Datenschutz-Zusage Kinder-Kategorie: keine
        // Geräte-/IP-Daten an Dritte). Mit gesetztem Key: echter Supabase-Abruf wie bisher.
        self.recipeRepository = recipeRepository
            ?? (SupabaseSecrets.anonKey.isEmpty ? SeedRecipeRepository() : SupabaseRecipeRepository())
    }

    // MARK: - loadRecipes (echter API-Call übers Repository)
    @MainActor
    func loadRecipes() async {
        isLoadingRecipes = true
        defer { isLoadingRecipes = false }
        do {
            let fetched = try await recipeRepository.fetchRecipes()
            if !fetched.isEmpty { recipes = fetched }
        } catch {
            // Offline oder kein Key hinterlegt: Seed-Rezepte bleiben stehen.
        }
    }

    // MARK: - add (selbst erstelltes Rezept in die Liste aufnehmen)
    func add(_ recipe: Recipe) {
        recipes.append(recipe)
    }
}
