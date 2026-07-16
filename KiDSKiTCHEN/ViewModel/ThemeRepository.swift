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
        static let themeID            = "kk.theme.id"
        static let cardOpacity        = "kk.theme.cardOpacity"
        static let cardCornerRadius   = "kk.theme.cardCornerRadius"
        static let animationEnabled   = "kk.theme.animationEnabled"
        static let animationSeconds   = "kk.theme.animationSeconds"
        static let pantryTransition   = "kk.theme.pantryTransition"
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

    /// Ecken-Radius in Punkten (8–36). Default 22.0.
    var cardCornerRadius: CGFloat {
        get {
            guard defaults.object(forKey: Keys.cardCornerRadius) != nil else { return 22 }
            return CGFloat(defaults.double(forKey: Keys.cardCornerRadius))
        }
        set { defaults.set(Double(newValue), forKey: Keys.cardCornerRadius) }
    }

    /// Hintergrund-Animation aktiv. Default true (vorher: Default 0.0 → eingefroren).
    var animationEnabled: Bool {
        get {
            guard defaults.object(forKey: Keys.animationEnabled) != nil else { return true }
            return defaults.bool(forKey: Keys.animationEnabled)
        }
        set { defaults.set(newValue, forKey: Keys.animationEnabled) }
    }

    /// Loop-Dauer in Sekunden (21–86). Default 43.
    var animationSeconds: Double {
        get {
            guard defaults.object(forKey: Keys.animationSeconds) != nil else { return 43 }
            let v = defaults.double(forKey: Keys.animationSeconds)
            return v < 1 ? 43 : v   // Migration: alter loopFactor-Wert war < 1
        }
        set { defaults.set(newValue, forKey: Keys.animationSeconds) }
    }

    /// Übergangs-Animation Zutaten-Übersicht (rawValue PantryTransitionStyle). Default "gentle".
    var pantryTransition: String {
        get { defaults.string(forKey: Keys.pantryTransition) ?? "gentle" }
        set { defaults.set(newValue, forKey: Keys.pantryTransition) }
    }
}
