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

@Observable
final class ThemeSettings {
    static let shared = ThemeSettings()

    private let repo: ThemeRepository

    var themeID: String { didSet { repo.themeID = themeID } }

    /// 0.0 = Klar (transparent, Hintergrund sichtbar) · 1.0 = Aus (solide Karte).
    var cardOpacity: Double { didSet { repo.cardOpacity = cardOpacity } }

    /// 0.0 = Aus (kein Drift) · 1.0 = Lebhaft (30s/Zyklus).
    var loopFactor: Double { didSet { repo.loopFactor = loopFactor } }

    /// Ecken-Radius in Punkten (8–36, stufenlos).
    var cardCornerRadius: CGFloat { didSet { repo.cardCornerRadius = cardCornerRadius } }

    /// Aktuell gewähltes Theme-Objekt.
    var theme: KKTheme { KKTheme.byID(themeID) }

    /// Innen-Radius (Icon-Badges u. ä.) — proportional zum äußeren Radius.
    var cardInnerRadius: CGFloat { max(4, cardCornerRadius * 0.55) }

    /// Drift-Dauer in Sekunden. 0 = Hintergrund statisch.
    var loopDuration: Double { loopFactor == 0 ? 0 : (30.0 + (1.0 - loopFactor) * 90.0) }

    /// Hintergrund-Animation pausiert.
    var isLoopPaused: Bool { loopFactor == 0 }

    private init(repo: ThemeRepository = .shared) {
        self.repo             = repo
        self.themeID          = repo.themeID
        self.cardOpacity      = repo.cardOpacity
        self.loopFactor       = repo.loopFactor
        self.cardCornerRadius = repo.cardCornerRadius
    }
}
