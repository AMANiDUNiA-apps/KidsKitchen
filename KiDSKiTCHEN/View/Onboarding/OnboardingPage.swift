//
//  OnboardingPage.swift
//  KiDSKiTCHEN
//
//  Datengrundlage des Erst-Start-Onboardings. UI-Muster nach Kavsoft „CustomIntroPage"
//  portiert und an KidsKitchen angepasst: statt Fitness-Icons kindgerechte Koch-Seiten,
//  letzte Seite = Diät-/Ausschluss-Auswahl über die EXISTIERENDEN Filter-Modelle
//  (DietMode + reale Seed-Zutaten). Keine erfundenen Nähr-/Allergendaten.
//

import SwiftUI

// MARK: - OnboardingPage
struct OnboardingPage: Identifiable {
    let id = UUID()
    var symbol: String
    var tint: Color
    var title: String
    var message: String
    /// Die letzte Seite trägt keine Illustration, sondern die Diät-/Ausschluss-Auswahl.
    var isPreferences: Bool = false

    static let pages: [OnboardingPage] = [
        .init(symbol: "fork.knife.circle.fill", tint: .orange,
              title: "Willkommen in der KidsKitchen",
              message: "Hier findest du einfache Rezepte zum Selberkochen — Schritt für Schritt."),
        .init(symbol: "hand.tap.fill", tint: .pink,
              title: "Rezepte entdecken",
              message: "Tipp eine Kategorie an oder stöber durch die Liste. Dein Lieblingsrezept merkst du dir mit dem Herz."),
        .init(symbol: "checkmark.circle.fill", tint: .green,
              title: "Schritt für Schritt kochen",
              message: "Jeden Kochschritt schiebst du zur Seite, wenn du ihn geschafft hast — so verlierst du nie den Faden."),
        .init(symbol: "leaf.circle.fill", tint: .teal,
              title: "Was soll nicht drin sein?",
              message: "Sag uns, was du nicht magst oder nicht essen darfst — passende Rezepte blenden wir aus.",
              isPreferences: true)
    ]
}

// MARK: - ExclusionPreset
/// Ein Ausschluss-Vorschlag im Onboarding. Löst sich zu ECHTEN Seed-Zutatennamen auf
/// (kategorie- oder namensbasiert) und schreibt sie in `Preferences.excluded` —
/// dieselbe Menge, die schon „Filter & Diät" und die Rezeptliste auswerten.
struct ExclusionPreset: Identifiable {
    let id = UUID()
    var label: String
    var symbol: String
    /// Aus dem realen Seed abgeleitete Zutatennamen (nichts erfunden).
    var ingredientNames: [String]

    /// Alle Seed-Zutaten einer Kategorie.
    private static func names(in category: IngredientCategory) -> [String] {
        Ingredient.seed.filter { $0.category == category }.map(\.name)
    }

    /// Nur Namen, die es im Seed wirklich gibt (schützt vor Tippfehlern).
    private static func names(_ wanted: String...) -> [String] {
        let known = Set(Ingredient.seed.map(\.name))
        return wanted.filter { known.contains($0) }
    }

    static let all: [ExclusionPreset] = [
        .init(label: "Nüsse", symbol: "leaf.circle.fill", ingredientNames: names(in: .nuts)),
        .init(label: "Milchprodukte", symbol: "waterbottle.fill", ingredientNames: names(in: .dairy)),
        .init(label: "Fisch", symbol: "fish.fill", ingredientNames: names(in: .fish)),
        .init(label: "Ei", symbol: "oval.portrait.fill", ingredientNames: names("Ei")),
        .init(label: "Honig", symbol: "drop.fill", ingredientNames: names("Honig"))
    ].filter { !$0.ingredientNames.isEmpty }
}
