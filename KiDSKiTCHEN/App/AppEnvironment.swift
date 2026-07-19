//
//  AppEnvironment.swift
//  KiDSKiTCHEN
//
//  Composition-Root der App (Rebuild, Re-Founding P1).
//  Bündelt alle app-weiten Abhängigkeiten an EINER Stelle und wird am App-Root
//  via `.environment(_:)` injiziert — statt der bisherigen verstreuten
//  `.shared`-Singletons. Aufrufstellen lesen künftig aus dem Environment
//  (`@Environment(AppEnvironment.self)`), nicht mehr aus globalen Singletons.
//
//  P1-Zwischenstand (bewusst): die Felder brücken noch auf die vorhandenen
//  `.shared`-Instanzen, damit der Umbau grün bleibt. In P3 (Data-Layer) und
//  P4 (Design-System) werden die Implementierungen HINTER diesem Seam
//  ausgetauscht (SwiftData-Stores, injizierter ThemeStore), ohne dass die
//  Aufrufstellen erneut angefasst werden müssen.
//
//  P3-Zwischenstand: `recipes`/`savedRecipes` sind jetzt Teil des Environments
//  (Repository-Layer + EIN SwiftData-Container, s. Data/Store/Container.swift).
//  `prefs` (Vorrat/Plan/Einkauf/Favoriten) bleibt bewusst auf `.shared` gebrückt —
//  die konsumierenden Screens (Pantry/WeekPlan/Shopping) werden erst in P6/P7
//  neu gebaut, ein SwiftData-Ersatz vorher wäre spekulativ (kein Aufrufer in
//  P1–P5). Siehe Abweichungs-Hinweis in der Fertigmeldung.
//

import SwiftUI

@MainActor
@Observable
final class AppEnvironment {
    /// App-weite Erscheinung/Themes. Wird in P4 zu einem injizierten ThemeStore.
    let theme: ThemeSettings
    /// Nutzer-Daten (Vorrat/Plan/Einkauf/Favoriten/Kochzyklus).
    /// Wird in P6/P7 durch SwiftData-gestützte Stores ersetzt (s. Kommentar oben).
    let prefs: Preferences
    /// App-weiter Kochmodus (Mini-Leiste über der Tabbar, Vollbild-Kochen).
    let cooking: KKCookingSession
    /// Rezeptliste (Seed/Supabase hinter Offline-Guard, s. RecipeListViewModel).
    let recipes: RecipeListViewModel
    /// Offline gespeicherte Rezepte (SwiftData, s. Data/Repositories).
    let savedRecipes: SavedRecipeRepository

    // Keine Default-Parameter mit `.shared` — ein Default-Ausdruck läuft in
    // Swift nicht im MainActor-Kontext des Aufrufers, das erzeugt bei jedem
    // `= .shared` eine „main actor-isolated … nonisolated context"-Warnung.
    // Zuweisung im Rumpf statt im Parameter vermeidet das, ohne die
    // Bridging-Absicht zu ändern.
    init() {
        theme = .shared
        prefs = .shared
        cooking = .shared
        recipes = .shared
        savedRecipes = .shared
    }
}
