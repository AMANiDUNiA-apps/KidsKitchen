//
//  ThemeRepository.swift
//  KiDSKiTCHEN
//
//  Kapselt UserDefaults für die Design-Einstellungen.
//  Views greifen NICHT direkt auf UserDefaults — nur über ThemeSettings (ViewModel).
//

import Foundation

final class ThemeRepository {
    static let shared = ThemeRepository()
    private let defaults = UserDefaults.standard
    private init() {}

    private enum Keys {
        static let themeID          = "kk.theme.id"
        static let cardOpacity      = "kk.theme.cardOpacity"
        static let loopFactor       = "kk.theme.loopFactor"
        static let cardCornerRadius = "kk.theme.cardCornerRadius"
    }

    var themeID: String {
        get { defaults.string(forKey: Keys.themeID) ?? "storybook" }
        set { defaults.set(newValue, forKey: Keys.themeID) }
    }

    /// 0.0 = Klar (Hintergrund sichtbar) · 1.0 = Aus (solide Karte). Default 1.0.
    var cardOpacity: Double {
        get {
            guard defaults.object(forKey: Keys.cardOpacity) != nil else { return 1.0 }
            return defaults.double(forKey: Keys.cardOpacity)
        }
        set { defaults.set(newValue, forKey: Keys.cardOpacity) }
    }

    /// 0.0 = Aus (statisch) · 1.0 = Lebhaft (30s/Zyklus). Default 0.0.
    var loopFactor: Double {
        get {
            guard defaults.object(forKey: Keys.loopFactor) != nil else { return 0.0 }
            return defaults.double(forKey: Keys.loopFactor)
        }
        set { defaults.set(newValue, forKey: Keys.loopFactor) }
    }

    /// Ecken-Radius in Punkten (8–36). Default 22.0.
    var cardCornerRadius: CGFloat {
        get {
            guard defaults.object(forKey: Keys.cardCornerRadius) != nil else { return 22 }
            return CGFloat(defaults.double(forKey: Keys.cardCornerRadius))
        }
        set { defaults.set(Double(newValue), forKey: Keys.cardCornerRadius) }
    }
}
