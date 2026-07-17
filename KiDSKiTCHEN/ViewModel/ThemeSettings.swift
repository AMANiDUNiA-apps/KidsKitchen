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

// MARK: - ThemeSettings
@Observable
final class ThemeSettings {
    static let shared = ThemeSettings()

    private let repo: ThemeRepository

    var themeID: String { didSet { repo.themeID = themeID } }

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

    /// Aktuell gewähltes Theme-Objekt.
    var theme: KKTheme { KKTheme.byID(themeID) }

    /// Innen-Radius (Icon-Badges u. ä.) — proportional zum äußeren Radius.
    var cardInnerRadius: CGFloat { max(4, cardCornerRadius * 0.55) }

    /// Drift-Dauer in Sekunden. 0 = Hintergrund statisch.
    var loopDuration: Double { animationEnabled ? animationSeconds : 0 }

    /// Hintergrund-Animation pausiert.
    var isLoopPaused: Bool { !animationEnabled }

    private init(repo: ThemeRepository = .shared) {
        self.repo              = repo
        self.themeID           = repo.themeID
        self.cardOpacity       = repo.cardOpacity
        self.cardCornerRadius  = repo.cardCornerRadius
        self.animationEnabled  = repo.animationEnabled
        self.animationSeconds  = repo.animationSeconds
        self.pantryTransition  = PantryTransitionStyle(rawValue: repo.pantryTransition) ?? .gentle
    }
}
