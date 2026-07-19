//
//  CategoryPresentation.swift
//  KiDSKiTCHEN
//
//  Rebuild P2: SwiftUI-Präsentation (Farbe/Symbol-Image) für die reinen
//  Domain-Kategorien. Getrennt von Domain/Models/Enums, damit Domain KEIN
//  SwiftUI importiert (Abhängigkeitsrichtung Features → Data → Domain ← DesignSystem).
//

import SwiftUI

// MARK: - IngredientCategory
extension IngredientCategory {
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

    var image: Image { Image(systemName: symbolName) }
}

// MARK: - RecipeCategory
extension RecipeCategory {
    var color: Color {
        switch self {
        case .breakfast: .orange
        case .mainDish:  .red
        case .sideDish:  .green
        case .dessert:   .pink
        case .snack:     .mint
        case .baking:    .brown
        case .drink:     .cyan
        }
    }
}
