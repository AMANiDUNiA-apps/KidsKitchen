//
//  Season.swift
//  KiDSKiTCHEN
//
//  Created by Claude Fable 5 on 02.07.26.
//  (thirdwiki-Taxonomie: „Saisonal Regional" — Saison gehört zur Warenkunde)
//

import Foundation

// MARK: - Season
enum Season: String, Codable, CaseIterable, Identifiable {
    var id: Self { self }

    case spring = "Frühling"
    case summer = "Sommer"
    case autumn = "Herbst"
    case winter = "Winter"
    case allYear = "Ganzjährig"

    var symbolName: String {
        switch self {
        case .spring: "leaf.fill"
        case .summer: "sun.max.fill"
        case .autumn: "wind"
        case .winter: "snowflake"
        case .allYear: "calendar"
        }
    }
}
