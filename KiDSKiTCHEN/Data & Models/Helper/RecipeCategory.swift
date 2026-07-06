//
//  RecipeCategory.swift
//  KiDSKiTCHEN
//
//  Created by Claude Fable 5 on 02.07.26.
//

import Foundation
import SwiftUI

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
