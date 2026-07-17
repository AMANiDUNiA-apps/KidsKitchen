//
//  KKTheme.swift
//  KiDSKiTCHEN
//
//  8 visuelle Styles (Bücherei / Ernte / Eisblume / Nacht / Sonnenschein /
//  Beerenzeit / Wassermelone / Kakao). Glas-Deckkraft, Drift-Faktor und
//  Ecken-Radius sind stufenlos als Double/CGFloat in ThemeSettings gespeichert.
//  WCAG-Kontrast (4,5:1 Text, 3:1 große Schrift) wurde je Theme geprüft;
//  zu helle Original-Töne (sonnenschein #F2B33D) wurden nachdunkelt (→ #7D5200).
//

import SwiftUI

// MARK: - KKTheme
struct KKTheme: Identifiable {
    let id: String
    let name: String
    let isDark: Bool

    /// Hintergrundfarben (1 = Vollton, 2–3 = rotierender Gradient).
    let backgroundColors: [Color]

    /// Haupt-Akzent (Chips, Icons, Hervorhebungen).
    let accent: Color
    /// Sekundärer Akzent.
    let secondary: Color
    /// Call-to-Action (Primärknopf).
    let cta: Color

    /// Textfarbe auf accent-gefülltem Chip/Button (WCAG-gesichert).
    let chipTextColor: Color

    // Karte (Solid-Modus)
    let cardSurface: Color
    let cardStroke: Color
    let shadowColor: Color

    /// Hintergrund des klebenden Kategorie-Headers.
    let headerBackground: Color

    /// SF-Symbol im Hero-Banner.
    let decoSymbol: String
}

// MARK: - 8 Themes
extension KKTheme {

    static let all: [KKTheme] = [
        storybook, natureHarvest, liquidGlassFrosted, liquidGlassNeon,
        sonnenschein, beerenzeit, wassermelone, kakao
    ]

    static var `default`: KKTheme { storybook }

    static func byID(_ id: String) -> KKTheme {
        all.first { $0.id == id } ?? storybook
    }

    // 1. Storybook — warmes Creme, Erdorange (DEFAULT)
    static let storybook = KKTheme(
        id: "storybook", name: "Bücherei", isDark: false,
        backgroundColors: [Color(kkHex: "#F7EDD4"), Color(kkHex: "#F0E0BC")],
        accent:    Color(kkHex: "#B05E20"),
        secondary: Color(kkHex: "#8B5E3C"),
        cta:       Color(kkHex: "#C0392B"),
        chipTextColor: .white,
        cardSurface:      Color(kkHex: "#FFF8EC"),
        cardStroke:       Color(kkHex: "#D9B87A").opacity(0.4),
        shadowColor:      Color(kkHex: "#8B5E3C").opacity(0.15),
        headerBackground: Color(kkHex: "#F7EDD4"),
        decoSymbol: "book.fill"
    )

    // 2. Nature Harvest — helles Salbei, Dunkelgrün
    static let natureHarvest = KKTheme(
        id: "nature-harvest", name: "Ernte", isDark: false,
        backgroundColors: [Color(kkHex: "#EDF0E0"), Color(kkHex: "#DDE8D0")],
        accent:    Color(kkHex: "#2D6A4F"),
        secondary: Color(kkHex: "#40916C"),
        cta:       Color(kkHex: "#C0392B"),
        chipTextColor: .white,
        cardSurface:      Color(kkHex: "#F6F8F1"),
        cardStroke:       Color(kkHex: "#74C69D").opacity(0.35),
        shadowColor:      Color(kkHex: "#2D6A4F").opacity(0.12),
        headerBackground: Color(kkHex: "#EDF0E0"),
        decoSymbol: "leaf.fill"
    )

    // 3. Liquid Glass Frosted — Lavendel→Rosa Gradient
    static let liquidGlassFrosted = KKTheme(
        id: "liquid-glass-frosted", name: "Eisblume", isDark: false,
        backgroundColors: [Color(kkHex: "#D9C7FF"), Color(kkHex: "#FFD1E6"), Color(kkHex: "#C4E3FF")],
        accent:    Color(kkHex: "#6D28D9"),
        secondary: Color(kkHex: "#DB2777"),
        cta:       Color(kkHex: "#C0392B"),
        chipTextColor: .white,
        cardSurface:      Color(kkHex: "#F8F4FF"),
        cardStroke:       Color(kkHex: "#A78BFA").opacity(0.3),
        shadowColor:      Color(kkHex: "#7C3AED").opacity(0.12),
        headerBackground: Color(kkHex: "#EDE9FF"),
        decoSymbol: "sparkles"
    )

    // 4. Liquid Glass Neon — dunkles Blauviolett
    static let liquidGlassNeon = KKTheme(
        id: "liquid-glass-neon", name: "Nacht", isDark: true,
        backgroundColors: [Color(kkHex: "#0F0A24"), Color(kkHex: "#1A0F33"), Color(kkHex: "#0D1F2D")],
        accent:    Color(kkHex: "#A78BFA"),
        secondary: Color(kkHex: "#22D3EE"),
        cta:       Color(kkHex: "#F59E0B"),
        chipTextColor: Color(UIColor.label),
        cardSurface:      Color(kkHex: "#1E1440"),
        cardStroke:       Color(kkHex: "#7C3AED").opacity(0.4),
        shadowColor:      Color(kkHex: "#A78BFA").opacity(0.2),
        headerBackground: Color(kkHex: "#0F0A24"),
        decoSymbol: "wand.and.stars"
    )

    // 5. Sonnenschein — Buttergelb
    static let sonnenschein = KKTheme(
        id: "sonnenschein", name: "Sonnenschein", isDark: false,
        backgroundColors: [Color(kkHex: "#FFF6DE"), Color(kkHex: "#FFF0C0")],
        accent:    Color(kkHex: "#7D5200"),
        secondary: Color(kkHex: "#C85A1A"),
        cta:       Color(kkHex: "#C0392B"),
        chipTextColor: .white,
        cardSurface:      Color(kkHex: "#FFFBF0"),
        cardStroke:       Color(kkHex: "#E8A040").opacity(0.35),
        shadowColor:      Color(kkHex: "#E8703A").opacity(0.12),
        headerBackground: Color(kkHex: "#FFF6DE"),
        decoSymbol: "sun.max.fill"
    )

    // 6. Beerenzeit — zartes Rosé
    static let beerenzeit = KKTheme(
        id: "beerenzeit", name: "Beerenzeit", isDark: false,
        backgroundColors: [Color(kkHex: "#FFF2F4"), Color(kkHex: "#FFE0E8")],
        accent:    Color(kkHex: "#B0305A"),
        secondary: Color(kkHex: "#C03838"),
        cta:       Color(kkHex: "#8C2040"),
        chipTextColor: .white,
        cardSurface:      Color(kkHex: "#FFF8FA"),
        cardStroke:       Color(kkHex: "#E88BA0").opacity(0.35),
        shadowColor:      Color(kkHex: "#C9426B").opacity(0.12),
        headerBackground: Color(kkHex: "#FFF2F4"),
        decoSymbol: "heart.fill"
    )

    // 7. Wassermelone — Grünhauch
    static let wassermelone = KKTheme(
        id: "wassermelone", name: "Wassermelone", isDark: false,
        backgroundColors: [Color(kkHex: "#F4FBF2"), Color(kkHex: "#E8F8E4"), Color(kkHex: "#FFF2F4")],
        accent:    Color(kkHex: "#C8455D"),
        secondary: Color(kkHex: "#2E7048"),
        cta:       Color(kkHex: "#C0392B"),
        chipTextColor: .white,
        cardSurface:      Color(kkHex: "#F8FCF7"),
        cardStroke:       Color(kkHex: "#3E8E5A").opacity(0.3),
        shadowColor:      Color(kkHex: "#3E8E5A").opacity(0.1),
        headerBackground: Color(kkHex: "#F4FBF2"),
        decoSymbol: "leaf.circle.fill"
    )

    // 8. Kakao — warmes Dunkelbraun
    static let kakao = KKTheme(
        id: "kakao", name: "Kakao", isDark: true,
        backgroundColors: [Color(kkHex: "#2B1E16"), Color(kkHex: "#3D2718"), Color(kkHex: "#221510")],
        accent:    Color(kkHex: "#E8A04C"),
        secondary: Color(kkHex: "#F5E8D8"),
        cta:       Color(kkHex: "#E8703A"),
        chipTextColor: Color(UIColor.label),
        cardSurface:      Color(kkHex: "#3D2B20"),
        cardStroke:       Color(kkHex: "#594030").opacity(0.6),
        shadowColor:      Color(kkHex: "#000000").opacity(0.2),
        headerBackground: Color(kkHex: "#2B1E16"),
        decoSymbol: "cup.and.saucer.fill"
    )
}

// MARK: - Color aus Hex-String
extension Color {
    /// Erzeugt eine Color aus #RRGGBB (mit oder ohne führendes #).
    init(kkHex hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch h.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red:     Double(r) / 255,
                  green:   Double(g) / 255,
                  blue:    Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}
