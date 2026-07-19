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

import SwiftUI

@MainActor
@Observable
final class AppEnvironment {
    /// App-weite Erscheinung/Themes. Wird in P4 zu einem injizierten ThemeStore.
    let theme: ThemeSettings
    /// Nutzer-Daten (Vorrat/Plan/Einkauf/Favoriten/Kochzyklus).
    /// Wird in P3 durch SwiftData-gestützte Stores ersetzt.
    let prefs: Preferences
    /// App-weiter Kochmodus (Mini-Leiste über der Tabbar, Vollbild-Kochen).
    let cooking: KKCookingSession

    init(theme: ThemeSettings = .shared,
         prefs: Preferences = .shared,
         cooking: KKCookingSession = .shared) {
        self.theme = theme
        self.prefs = prefs
        self.cooking = cooking
    }
}
