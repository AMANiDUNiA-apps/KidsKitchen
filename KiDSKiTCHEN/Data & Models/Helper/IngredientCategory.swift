//
//  IngredientCategory.swift
//  KiDSKiTCHEN
//
//  Created by Joscha Amani Gaber on 25.09.25. (Original: Recipes-Projekt, Oktober 25)
//  Portiert von Claude Fable 5 am 02.07.26 — Bild-Assets fehlen im Katalog,
//  daher SF Symbols statt Image(.fruits) etc. Farben unverändert.
//

import Foundation
import SwiftUI

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

    // MARK: color
    var color: Color {
        switch self {
        case .fruit: .red
        case .vegetable: .green
        case .cereals: .yellow
        case .nuts: .orange
        case .dairy: .blue
        case .redMeat: .purple
        case .poultry: .pink
        case .fish: .cyan
        case .fatsAndOils: .indigo
        case .herbs: .teal
        case .spices: .mint
        case .other: .gray
        }
    }

    // MARK: title
    var title: String { rawValue }

    // MARK: symbol (SF Symbols — eigene Assets folgen später auf dem Mac)
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

    var image: Image { Image(systemName: symbolName) }
}
