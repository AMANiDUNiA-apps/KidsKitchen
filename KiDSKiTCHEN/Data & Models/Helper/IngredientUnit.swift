//
//  IngredientUnit.swift
//  KiDSKiTCHEN
//
//  Created by Claude Fable 5 on 02.07.26.
//  (abgeleitet aus ViewModel-Nutzung: .gram als Default)
//

import Foundation

// MARK: - IngredientUnit
enum IngredientUnit: String, Codable, CaseIterable, Identifiable {
    var id: Self { self }

    case gram = "g"
    case kilogram = "kg"
    case milliliter = "ml"
    case liter = "l"
    case piece = "Stück"
    case tablespoon = "EL"
    case teaspoon = "TL"
    case pinch = "Prise"
    case bunch = "Bund"

    // MARK: title (ausgeschrieben, für Detail-Ansichten)
    var title: String {
        switch self {
        case .gram: "Gramm"
        case .kilogram: "Kilogramm"
        case .milliliter: "Milliliter"
        case .liter: "Liter"
        case .piece: "Stück"
        case .tablespoon: "Esslöffel"
        case .teaspoon: "Teelöffel"
        case .pinch: "Prise"
        case .bunch: "Bund"
        }
    }

    // MARK: - Vorrats-Picker (Strich-Picker rastert je Einheit passend)
    // Keine Umrechnung zwischen Einheiten — nur die passende Schrittweite/Obergrenze
    // für die jeweilige reale Einheit der Zutat.

    /// Schrittweite pro Rastung im Vorrats-Strich-Picker.
    var pantryStep: Int {
        switch self {
        case .gram, .milliliter: 10
        case .piece, .bunch, .tablespoon, .teaspoon, .pinch: 1
        case .kilogram, .liter: 1
        }
    }

    /// Höchstwert im Vorrats-Strich-Picker (in dieser Einheit).
    var pantryMaxValue: Int {
        switch self {
        case .gram, .milliliter: 2000
        case .piece: 24
        case .bunch: 10
        case .tablespoon, .teaspoon, .pinch: 20
        case .kilogram, .liter: 20
        }
    }

    /// Menge mit Einheit formatiert, z. B. „200 ml", „3 Stück", „150 g".
    func formattedAmount(_ value: Int) -> String { "\(value) \(rawValue)" }
}
