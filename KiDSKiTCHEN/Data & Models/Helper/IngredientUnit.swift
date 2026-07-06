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
}
