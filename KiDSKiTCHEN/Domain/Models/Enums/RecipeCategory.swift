//
//  RecipeCategory.swift
//  KiDSKiTCHEN
//
//  Rebuild P2 (Domain): reine Kategorie, KEIN SwiftUI — Farbe liegt als
//  Präsentations-Extension in DesignSystem/CategoryPresentation.swift.
//

import Foundation

// MARK: - RecipeCategory
enum RecipeCategory: String, Codable, CaseIterable, Identifiable {
    var id: Self { self }

    case breakfast = "Frühstück"
    case mainDish = "Hauptgericht"
    case sideDish = "Beilage"
    case dessert = "Nachtisch"
    case snack = "Snack"
    case baking = "Backen"
    case drink = "Getränk"

    var symbolName: String {
        switch self {
        case .breakfast: "sunrise.fill"
        case .mainDish: "fork.knife"
        case .sideDish: "carrot"
        case .dessert: "birthday.cake.fill"
        case .snack: "takeoutbag.and.cup.and.straw.fill"
        case .baking: "oven.fill"
        case .drink: "cup.and.saucer.fill"
        }
    }
}
