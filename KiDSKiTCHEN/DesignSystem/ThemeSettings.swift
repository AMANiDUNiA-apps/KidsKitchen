//
//  ThemeSettings.swift
//  KiDSKiTCHEN
//
//  Beobachtbares ViewModel für die Design-Einstellungen.
//  Persistiert automatisch via ThemeRepository (UserDefaults).
//  Muster: @State private var settings: ThemeSettings = .shared
//

import Foundation
import Observation
import SwiftUI

// MARK: - PantryTransitionStyle
/// Übergangs-Animation beim Einblenden von Zutaten in der Vorratsschrank-Übersicht.
enum PantryTransitionStyle: String, CaseIterable, Identifiable {
    case gentle = "gentle"
    case spring = "spring"
    case off    = "off"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .gentle: "Sanft"
        case .spring: "Spring"
        case .off:    "Aus"
        }
    }

    var transition: AnyTransition {
        switch self {
        case .gentle: .opacity.combined(with: .scale(scale: 0.96))
        case .spring: .scale(scale: 0.72).combined(with: .opacity)
        case .off:    .identity
        }
    }

    var animation: Animation {
        switch self {
        case .gentle: .easeInOut(duration: 0.32)
        case .spring: .spring(response: 0.4, dampingFraction: 0.72)
        case .off:    .linear(duration: 0)
        }
    }
}

// MARK: - AppearanceMode
/// App-Erscheinung außen (Leiste/Systemfenster) — getrennt von `KKTheme.isDark`
/// (bestimmt nur die Kartenfarben). Am ECHTEN App-Root gesetzt (KiDSKiTCHENApp),
/// NICHT mehr in ContentView (Team-Runde v2 #7 — Zwei-Achsen-Klarheit).
enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: "Automatisch"
        case .light:  "Hell"
        case .dark:   "Dunkel"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light:  .light
        case .dark:   .dark
        }
    }
}

// MARK: - ThemeSettings
@Observable
final class ThemeSettings {
    static let shared = ThemeSettings()

    /// Sentinel-`themeID`: Farbstyle folgt dem System-Hell/Dunkel (opt-in, Jay
    /// 20.7. „ermöglichen, nicht erzwingen"). NICHT der Default — der bleibt
    /// `storybook`. Kollidiert nicht mit eingebauten IDs oder `custom-<UUID>`.
    static let systemThemeID = "system"

    /// Hell-/Dunkel-Paar für den System-Modus (beide warm: Bücherei ↔ Kakao).
    private static let systemLightTheme = KKTheme.storybook
    private static let systemDarkTheme  = KKTheme.kakao

    /// Effektives System-colorScheme, vom App-Root gespiegelt (`\.colorScheme`
    /// UNTER `preferredColorScheme` — respektiert also auch eine erzwungene
    /// Hell/Dunkel-Erscheinung). Laufzeit-Zustand, NICHT persistiert.
    var systemIsDark = false

    private let repo: ThemeRepository

    /// Backing für `themeID` — beim Lösch-Fallback direkt gesetzt, damit die
    /// Persistenz dort als EINE Repository-Operation läuft (Terra #3) statt
    /// über einen zweiten didSet-Schreiber.
    private var _themeID: String

    var themeID: String {
        get { _themeID }
        set { _themeID = newValue; repo.themeID = newValue }
    }

    /// App-Erscheinung außen. Unbekannter/kaputter Rohwert → .system (Default).
    var appearanceMode: AppearanceMode { didSet { repo.appearanceMode = appearanceMode.rawValue } }

    /// Bis zu 3 eigene Theme-Vorlagen. Mutation NUR über die CRUD-Methoden unten
    /// (setzt 3er-Limit + ID-Validierung fachlich durch, nicht nur im UI).
    private(set) var customThemes: [CustomTheme]

    private func persistCustomThemes() {
        repo.customThemesData = CustomThemesCodec.encode(customThemes)
    }

    /// 0.0 = Klar (transparent, Hintergrund sichtbar) · 1.0 = Aus (solide Karte).
    var cardOpacity: Double { didSet { repo.cardOpacity = cardOpacity } }

    /// Ecken-Radius in Punkten (8–36, stufenlos).
    var cardCornerRadius: CGFloat { didSet { repo.cardCornerRadius = cardCornerRadius } }

    /// Hintergrund-Animation aktiv (Toggle). Default true.
    var animationEnabled: Bool { didSet { repo.animationEnabled = animationEnabled } }

    /// Loop-Dauer in echten Sekunden (21–86). Gilt nur wenn animationEnabled == true.
    var animationSeconds: Double { didSet { repo.animationSeconds = animationSeconds } }

    /// Übergangs-Animation für die Zutaten-Übersicht.
    var pantryTransition: PantryTransitionStyle { didSet { repo.pantryTransition = pantryTransition.rawValue } }

    /// Aktuell gewähltes Theme-Objekt — löst eingebaute UND eigene Themes auf.
    /// Zentrale Auflösung (Team-Runde v2 #1, NICHT in KKTheme.byID — der kennt
    /// den Store nicht). Invariante: liefert IMMER ein gültiges Theme; Decode-
    /// Fehler, gelöschte ID oder ID-Kollision brechen das nie.
    var theme: KKTheme {
        if themeID == Self.systemThemeID {
            return systemIsDark ? Self.systemDarkTheme : Self.systemLightTheme
        }
        if let builtIn = KKTheme.all.first(where: { $0.id == themeID }) { return builtIn }
        if let custom = customThemes.first(where: { $0.id == themeID }) { return custom.asKKTheme() }
        return .storybook
    }

    /// Legt ein eigenes Theme an. `false` bei erreichtem 3er-Limit, ungültiger
    /// ID (kein custom-<UUID>, Terra #1) oder ID-Duplikat — fachlich
    /// durchgesetzt, nicht nur im UI-Knopf.
    @discardableResult
    func addCustomTheme(_ theme: CustomTheme) -> Bool {
        guard customThemes.count < 3,
              theme.hasValidID,
              !customThemes.contains(where: { $0.id == theme.id })
        else { return false }
        customThemes.append(theme)
        persistCustomThemes()
        return true
    }

    /// Ersetzt ein bestehendes eigenes Theme (Bearbeiten-Commit). ID muss passen.
    func updateCustomTheme(_ theme: CustomTheme) {
        guard let index = customThemes.firstIndex(where: { $0.id == theme.id }) else { return }
        customThemes[index] = theme
        persistCustomThemes()
    }

    /// Löscht ein eigenes Theme. War es aktiv: Fallback auf storybook + Entfernen
    /// als EINE Repository-Operation mit definierter Reihenfolge (erst themeID
    /// persistieren, dann Payload — Team-Runde v2 #3 / Terra #3).
    func deleteCustomTheme(id: String) {
        var remaining = customThemes
        remaining.removeAll { $0.id == id }
        let fallsBack = _themeID == id
        repo.deleteCustomTheme(
            fallbackToStorybook: fallsBack,
            payload: CustomThemesCodec.encode(remaining)
        )
        if fallsBack { _themeID = "storybook" }
        customThemes = remaining
    }

    /// Innen-Radius (Icon-Badges u. ä.) — proportional zum äußeren Radius.
    var cardInnerRadius: CGFloat { max(4, cardCornerRadius * 0.55) }

    /// Drift-Dauer in Sekunden. 0 = Hintergrund statisch.
    var loopDuration: Double { animationEnabled ? animationSeconds : 0 }

    /// Hintergrund-Animation pausiert.
    var isLoopPaused: Bool { !animationEnabled }

    /// Nicht `private` (mehr): DEBUG-Selbstchecks (KKThemeSettingsDebugCheck) erzeugen
    /// eigene Instanzen gegen eine isolierte ThemeRepository-Suite — nie gegen den
    /// echten `.shared`-Store (Terra-Lehre 18.7.).
    init(repo: ThemeRepository = .shared) {
        self.repo              = repo
        self._themeID          = repo.themeID
        self.appearanceMode    = AppearanceMode(rawValue: repo.appearanceMode) ?? .system
        self.customThemes      = CustomThemesCodec.decode(repo.customThemesData)
        self.cardOpacity       = repo.cardOpacity
        self.cardCornerRadius  = repo.cardCornerRadius
        self.animationEnabled  = repo.animationEnabled
        self.animationSeconds  = repo.animationSeconds
        self.pantryTransition  = PantryTransitionStyle(rawValue: repo.pantryTransition) ?? .gentle
    }
}
