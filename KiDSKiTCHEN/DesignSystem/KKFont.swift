//
//  KKFont.swift
//  KiDSKiTCHEN
//
//  Rebuild P4: benannte Serifen-Skala statt der bisher verstreuten
//  `.font(.system(.xxx, design: .serif))`-Aufrufe. Typo-Standard (Jay, 3.7.):
//  Serifen global — die App setzt `.fontDesign(.serif)` bereits am App-Root
//  (KiDSKiTCHENApp), diese Skala ist der benannte Baustein für neue Screens
//  (ab P5), damit Größe/Gewicht nicht an jeder Stelle neu erfunden werden.
//  Bestehende Screens (P6/P7-Umbau) bleiben unangetastet — kein Massen-Umbau
//  ohne Aufrufer-Nutzen.
//

import SwiftUI

enum KKFont {
    static let largeTitle = Font.system(.largeTitle, design: .serif).bold()
    static let title = Font.system(.title, design: .serif).bold()
    static let title2 = Font.system(.title2, design: .serif).bold()
    static let title3 = Font.system(.title3, design: .serif).bold()
    static let headline = Font.system(.headline, design: .serif)
    static let body = Font.system(.body, design: .serif)
    static let callout = Font.system(.callout, design: .serif)
    static let subheadline = Font.system(.subheadline, design: .serif)
    static let footnote = Font.system(.footnote, design: .serif)
    static let caption = Font.system(.caption, design: .serif)
}
