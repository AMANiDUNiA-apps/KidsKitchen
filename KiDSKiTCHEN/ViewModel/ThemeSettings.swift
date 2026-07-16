//
//  ThemeSettings.swift
//  KiDSKiTCHEN
//
//  Beobachtbares ViewModel für die drei Design-Einstellungen.
//  Persistiert automatisch via ThemeRepository (UserDefaults).
//  Muster: @State private var settings: ThemeSettings = .shared
//

import Foundation
import Observation

@Observable
final class ThemeSettings {
    static let shared = ThemeSettings()

    private let repo: ThemeRepository

    var themeID: String {
        didSet { repo.themeID = themeID }
    }
    var glassLevel: GlassLevel {
        didSet { repo.glassLevel = glassLevel }
    }
    var loopSpeed: LoopSpeed {
        didSet { repo.loopSpeed = loopSpeed }
    }

    /// Aktuell gewähltes Theme-Objekt.
    var theme: KKTheme { KKTheme.byID(themeID) }

    private init(repo: ThemeRepository = .shared) {
        self.repo      = repo
        self.themeID   = repo.themeID
        self.glassLevel = repo.glassLevel
        self.loopSpeed  = repo.loopSpeed
    }
}
