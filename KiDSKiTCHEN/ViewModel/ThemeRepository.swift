//
//  ThemeRepository.swift
//  KiDSKiTCHEN
//
//  Kapselt UserDefaults für die drei Design-Einstellungen.
//  Views greifen NICHT direkt auf UserDefaults — nur über ThemeSettings (ViewModel).
//

import Foundation

final class ThemeRepository {
    static let shared = ThemeRepository()
    private let defaults = UserDefaults.standard
    private init() {}

    private enum Keys {
        static let themeID    = "kk.theme.id"
        static let glassLevel = "kk.theme.glassLevel"
        static let loopSpeed  = "kk.theme.loopSpeed"
    }

    var themeID: String {
        get { defaults.string(forKey: Keys.themeID) ?? "storybook" }
        set { defaults.set(newValue, forKey: Keys.themeID) }
    }

    var glassLevel: GlassLevel {
        get { GlassLevel(rawValue: defaults.integer(forKey: Keys.glassLevel)) ?? .none }
        set { defaults.set(newValue.rawValue, forKey: Keys.glassLevel) }
    }

    var loopSpeed: LoopSpeed {
        get { LoopSpeed(rawValue: defaults.integer(forKey: Keys.loopSpeed)) ?? .off }
        set { defaults.set(newValue.rawValue, forKey: Keys.loopSpeed) }
    }
}
