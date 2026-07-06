//
//  NutritionHelper.swift
//  KiDSKiTCHEN
//
//  Created by Claude Fable 5 on 02.07.26.
//  (Felder aus dem Nutritions-Struct des Recipes-Projekts, Oktober 25 —
//   passt zu den USDA/BLS-Nährwerttabellen für die spätere Befüllung)
//

import Foundation

// MARK: - Nutrition
struct Nutrition: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var kcal: Double = 0
    var protein: Double = 0
    var carbs: Double = 0
    var fat: Double = 0
    var fiber: Double = 0

    // MARK: leer (für neue Rezepte)
    static let empty = Nutrition()

    /// Keine hinterlegten Werte (alle Felder 0).
    var isEmpty: Bool {
        kcal == 0 && protein == 0 && carbs == 0 && fat == 0 && fiber == 0
    }

    // MARK: shortSummary (z.B. „245 kcal · 12 g Protein · …")
    var shortSummary: String {
        "\(Int(kcal)) kcal · \(Int(protein)) g Protein · \(Int(carbs)) g KH · \(Int(fat)) g Fett"
    }
}
