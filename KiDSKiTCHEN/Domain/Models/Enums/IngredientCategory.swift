//
//  IngredientCategory.swift
//  KiDSKiTCHEN
//
//  Created by Joscha Amani Gaber on 25.09.25. (Original: Recipes-Projekt, Oktober 25)
//  Rebuild P2 (Domain): reine Warenkunde-Taxonomie, KEIN SwiftUI — Farbe/Symbol-Image
//  liegen als Präsentations-Extension in DesignSystem/CategoryPresentation.swift.
//

import Foundation

// MARK: - IngredientCategory
enum IngredientCategory: String, Codable, CaseIterable, Identifiable {
    var id: Self { self }

    case fruit = "Obst"
    case vegetable = "Gemüse"
    case cereals = "Getreide"
    case nuts = "Nüsse & Saat"
    case dairy = "Milchprodukte"
    case redMeat = "Rotes Fleisch"
    case poultry = "Geflügel"
    case fish = "Fisch & Meeresfrüchte"
    case fatsAndOils = "Fette & Öle"
    case herbs = "Kräuter"
    case spices = "Gewürze"
    case other = "Sonstige"

    // MARK: title
    var title: String { rawValue }

    // MARK: symbol (SF-Symbol-Name — die SwiftUI-Image wird in DesignSystem gebaut)
    var symbolName: String {
        switch self {
        case .fruit: "apple.logo"
        case .vegetable: "carrot.fill"
        case .cereals: "laurel.leading"
        case .nuts: "leaf.circle.fill"
        case .dairy: "waterbottle.fill"
        case .redMeat: "flame.fill"
        case .poultry: "bird.fill"
        case .fish: "fish.fill"
        case .fatsAndOils: "drop.fill"
        case .herbs: "leaf.fill"
        case .spices: "sparkles"
        case .other: "basket.fill"
        }
    }
}
