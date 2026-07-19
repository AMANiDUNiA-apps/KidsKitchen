//
//  CustomTheme.swift
//  KiDSKiTCHEN
//
//  Datenmodell für bis zu 3 eigene Theme-Vorlagen (BRIEF-kk-themes-eigene-vorlagen,
//  18.7., Team-Runde v2). Color ist nicht direkt Codable → RGBA-Rohwerte (sRGB
//  0...1) speichern. Auflösung passiert zentral in ThemeSettings, NICHT hier und
//  NICHT in KKTheme.byID (der kennt den Store nicht, s. Brief #1).
//
//  IDs: "custom-<UUID>" (Team-Runde v2 #2 — keine Wiederverwendungs-Falle wie
//  custom-1..3). Editor-Umfang bewusst begrenzt (#5): nur Hintergrund/Karten/
//  Akzent, Textfarbe wird automatisch kontrastsicher abgeleitet (#6).
//

import SwiftUI

// MARK: - RGBAColor
/// sRGB-Farbwerte 0...1 — Codable-Ersatz für `Color`.
struct RGBAColor: Codable, Hashable {
    var r: Double
    var g: Double
    var b: Double
    var a: Double

    init(r: Double, g: Double, b: Double, a: Double = 1) {
        self.r = r; self.g = g; self.b = b; self.a = a
    }

    /// Zerlegt eine SwiftUI-Color in ihre sRGB-Komponenten (Picker-Ausgabe).
    init(_ color: Color) {
        let ui = UIColor(color)
        var rr: CGFloat = 0, gg: CGFloat = 0, bb: CGFloat = 0, aa: CGFloat = 0
        ui.getRed(&rr, green: &gg, blue: &bb, alpha: &aa)
        r = Double(rr); g = Double(gg); b = Double(bb); a = Double(aa)
    }

    var color: Color { Color(.sRGB, red: r, green: g, blue: b, opacity: a) }

    /// Geklammert auf 0...1 · nicht-endliche Werte (NaN/∞ aus kaputtem JSON) → nil,
    /// das ganze Theme wird dann beim Laden verworfen (Team-Runde v2 #4).
    var clampedOrNil: RGBAColor? {
        guard r.isFinite, g.isFinite, b.isFinite, a.isFinite else { return nil }
        func clamp(_ v: Double) -> Double { min(max(v, 0), 1) }
        return RGBAColor(r: clamp(r), g: clamp(g), b: clamp(b), a: clamp(a))
    }

    /// Dunkle Farbe nach WCAG-Relativluminanz (Basis der Kontrast-Rollen).
    var isDarkColor: Bool {
        func linear(_ c: Double) -> Double {
            c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        let luminance = 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
        return luminance <= 0.5
    }

    /// Kontrastsichere Text-/Symbolfarbe (Schwarz/Weiß), automatisch abgeleitet
    /// statt vom Kind gewählt (Team-Runde v2 #5/#6).
    var contrastingTextColor: Color { isDarkColor ? .white : .black }
}

// MARK: - KKTheme Kontrast-Rollen
/// Zentrale cardTextColor-Rolle (Terra-Review 18.7. #2, Team-Entscheid): aus der
/// ECHTEN Kartenfarbe per Luminanz abgeleitet — nicht aus isDark. KKCard stellt
/// darüber das colorScheme des Karteninhalts, damit .primary/.secondary auf
/// Theme-Karten kontrastsicher auflösen; der Editor-Preview nutzt dieselbe Rolle.
extension KKTheme {
    /// Kartenfläche ist dunkel (Luminanz der cardSurface).
    var hasDarkCard: Bool { RGBAColor(cardSurface).isDarkColor }
    /// Sichere Textfarbe auf der Kartenfläche.
    var cardTextColor: Color { hasDarkCard ? .white : .black }
}

// MARK: - CustomTheme
/// Ein eigenes Theme: nur die kindgerechten Rollen Hintergrund/Karten/Akzent,
/// keine der übrigen KKTheme-Farbwerte (Editor-Umfang bewusst begrenzt).
struct CustomTheme: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var isDark: Bool
    var background: RGBAColor
    var card: RGBAColor
    var accent: RGBAColor

    static let idPrefix = "custom-"
    static let maxNameLength = 24

    /// Zentrale ID-Validierung (Terra-Review 18.7. #1): exakt `custom-<UUID>`.
    /// Das schließt Built-in-Kollisionen strukturell aus (kein eingebautes Theme
    /// trägt das Präfix) und verwirft freie Formen wie "custom-1".
    var hasValidID: Bool {
        id.hasPrefix(Self.idPrefix)
            && UUID(uuidString: String(id.dropFirst(Self.idPrefix.count))) != nil
    }

    /// Bereinigter Name: getrimmt + längenbegrenzt; nil wenn danach leer
    /// (Terra-Review 18.7. #4 — manipuliertes JSON darf keinen Leer-/Riesen-
    /// Namen ins UI bringen).
    static func sanitizedName(_ raw: String) -> String? {
        let trimmed = String(raw.trimmingCharacters(in: .whitespacesAndNewlines).prefix(maxNameLength))
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Wandelt das eigene Theme in ein anzeigbares KKTheme um (secondary/cta
    /// teilen sich bewusst den einen Akzent — kindgerecht, eine Farbe genügt).
    func asKKTheme() -> KKTheme {
        KKTheme(
            id: id, name: name, isDark: isDark,
            backgroundColors: [background.color],
            accent: accent.color, secondary: accent.color, cta: accent.color,
            chipTextColor: accent.contrastingTextColor,
            cardSurface: card.color,
            cardStroke: accent.color.opacity(0.35),
            shadowColor: Color.black.opacity(0.15),
            headerBackground: background.color,
            decoSymbol: "paintpalette.fill"
        )
    }
}

// MARK: - CustomThemesPayload
/// Versioniertes Speicherformat (Team-Runde v2 #4).
struct CustomThemesPayload: Codable {
    var version: Int
    var themes: [CustomTheme]
}

// MARK: - CustomThemesCodec
/// Reine Kodier-/Dekodier-Logik, ohne UserDefaults-Zugriff (testbar ohne Store).
/// Dekodieren bereinigt IMMER: falsche Version/kaputtes JSON → leer · über 3
/// Einträge gekappt · ungültige IDs (kein custom-<UUID>) und ID-Duplikate
/// verworfen · nicht-endliche Farbwerte verworfen · Namen getrimmt/gekappt,
/// leere verworfen. Nie ein Crash, nie mehr als 3 Themes.
enum CustomThemesCodec {
    static let currentVersion = 1

    static func decode(_ data: Data?) -> [CustomTheme] {
        guard let data,
              let payload = try? JSONDecoder().decode(CustomThemesPayload.self, from: data),
              payload.version == currentVersion
        else { return [] }

        var seenIDs = Set<String>()
        return Array(
            payload.themes
                .compactMap { sanitized($0) }
                .filter { $0.hasValidID && seenIDs.insert($0.id).inserted }
                .prefix(3)
        )
    }

    static func encode(_ themes: [CustomTheme]) -> Data? {
        try? JSONEncoder().encode(CustomThemesPayload(version: currentVersion, themes: themes))
    }

    private static func sanitized(_ theme: CustomTheme) -> CustomTheme? {
        guard let name = CustomTheme.sanitizedName(theme.name),
              let background = theme.background.clampedOrNil,
              let card = theme.card.clampedOrNil,
              let accent = theme.accent.clampedOrNil
        else { return nil }
        var cleaned = theme
        cleaned.name = name
        cleaned.background = background
        cleaned.card = card
        cleaned.accent = accent
        return cleaned
    }
}
