//
//  RecipeRepository.swift
//  KiDSKiTCHEN
//
//  Repository-Layer (6.7.): abstrahiert die Datenquelle der Rezepte vom Rest der App.
//  Views/ViewModels kennen nur dieses Protokoll — nicht, ob die Rezepte aus dem Seed
//  oder per API (Supabase) kommen. Erfüllt die Abschluss-Anforderung „Repository + API".
//

import Foundation

// MARK: - RecipeRepository
protocol RecipeRepository {
    /// Lädt die Rezepte (ggf. asynchron über eine API).
    func fetchRecipes() async throws -> [Recipe]
}

// MARK: - SeedRecipeRepository
/// Offline-Fallback: die kuratierten Seed-Rezepte, fest im Code (kein Netz nötig).
struct SeedRecipeRepository: RecipeRepository {
    func fetchRecipes() async throws -> [Recipe] { Recipe.seed }
}

// MARK: - RepositoryError
enum RepositoryError: Error {
    case badURL
    case badStatus(Int)
}
