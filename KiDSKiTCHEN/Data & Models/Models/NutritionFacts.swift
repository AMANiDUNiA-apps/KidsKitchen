//
//  NutritionFacts.swift
//  KiDSKiTCHEN
//
//  Created by Claude Fable 5 on 03.07.26.
//  Echte BLS-Nährwerte (je 100 g) für die Rezept-Zutaten, aus Supabase
//  „BLS | DE | Ingredients | ALL NEW" (2021 kochbare Zutaten) gezogen.
//  Provisorischer Seed für die Detailansicht — später aus Supabase/Vapor live.
//  Werte je 100 g essbarer Anteil; nil = im BLS unter Nachweisgrenze/kein Wert.
//

import Foundation

// MARK: - NutritionFacts (je 100 g)
struct NutritionFacts {
    let source: String        // BLS-Eintragsname (Nachvollziehbarkeit)
    var kcal: Double?
    var protein: Double?
    var fat: Double?
    var carbs: Double?
    var sugar: Double?
    var fiber: Double?
    var water: Double?
    var sodium: Double?       // mg
    var calcium: Double?      // mg
    var iron: Double?         // mg
    var magnesium: Double?    // mg
    var potassium: Double?    // mg
    var vitaminC: Double?     // mg
    var vitaminB12: Double?   // µg

    /// Aus den Daten abgeleitete Kurz-Aussagen („wofür gut") — kein Raten, nur Schwellen.
    var highlights: [String] {
        var out: [String] = []
        if let k = kcal, k < 40 { out.append("kalorienarm") }
        if let p = protein, p >= 10 { out.append("proteinreich") }
        if let f = fiber, f >= 5 { out.append("ballaststoffreich") }
        if let f = fat, f <= 1 { out.append("fettarm") }
        if let c = vitaminC, c >= 20 { out.append("reich an Vitamin C") }
        if let c = calcium, c >= 100 { out.append("gute Calciumquelle") }
        if let k = potassium, k >= 300 { out.append("kaliumreich") }
        if let i = iron, i >= 2 { out.append("eisenreich") }
        return out
    }

    /// Skaliert die Makros auf eine Grammmenge (für spätere Rezept-Summierung).
    func scaled(toGrams grams: Double) -> (kcal: Double, protein: Double, fat: Double, carbs: Double) {
        let f = grams / 100
        return ((kcal ?? 0) * f, (protein ?? 0) * f, (fat ?? 0) * f, (carbs ?? 0) * f)
    }
}

extension NutritionFacts {
    /// Nachschlagen über den (deutschen) Zutatennamen.
    static func bls(for ingredientName: String) -> NutritionFacts? {
        blsSeed[ingredientName]
    }

    /// Seed: Zutatenname → BLS-Nährwerte je 100 g.
    static let blsSeed: [String: NutritionFacts] = [
        "Apfel": .init(source: "Apfel roh", kcal: 58, protein: 0.424, fat: 0.5, carbs: 11.7, sugar: 10.487, fiber: 2.275, water: 83.554, sodium: 1, calcium: 5, iron: 0.1, magnesium: 5, potassium: 111, vitaminC: 10.16, vitaminB12: 0),
        "Banane": .init(source: "Banane roh", kcal: 79, protein: 1.319, fat: 0.4, carbs: 15.89, sugar: 13.89, fiber: 2, water: 74.4, sodium: 0.52, calcium: 6, iron: 0.4, magnesium: 28, potassium: 334, vitaminC: 11, vitaminB12: 0),
        "Butter": .init(source: "Süßrahmbutter", kcal: 747, protein: 0.59, fat: 82.5, carbs: 0.6, sugar: 0.6, fiber: nil, water: 15.8, sodium: 12, calcium: 14.5, iron: 0.1, magnesium: 2.05, potassium: 25, vitaminC: nil, vitaminB12: nil),
        "Ei": .init(source: "Hühnerei roh", kcal: 135, protein: 13.175, fat: 9, carbs: 0.34, sugar: 0.34, fiber: 0, water: 76.36, sodium: 154, calcium: 52, iron: 1.8, magnesium: 13, potassium: 138, vitaminC: nil, vitaminB12: 2.7),
        "Erdbeere": .init(source: "Erdbeere roh", kcal: 38, protein: 0.82, fat: 0.4, carbs: 5.917, sugar: 5.857, fiber: 2, water: 90.1, sodium: 1, calcium: 16, iron: 0.459, magnesium: 13, potassium: 183, vitaminC: 56.864, vitaminB12: 0),
        "Gurke": .init(source: "Gurke roh", kcal: 16, protein: 1.062, fat: 0.2, carbs: 1.97, sugar: 1.97, fiber: 0.9, water: 97, sodium: 3, calcium: 19, iron: 0.228, magnesium: 12, potassium: 181, vitaminC: 8, vitaminB12: 0),
        "Haferflocken": .init(source: "Hafer Flocken", kcal: 348, protein: 13.22, fat: 6.65, carbs: 53.3, sugar: 0.74, fiber: 10.983, water: 10.07, sodium: 1.98, calcium: 44, iron: 4.437, magnesium: 121.3, potassium: 381.9, vitaminC: nil, vitaminB12: 0),
        "Heidelbeere": .init(source: "Heidelbeere roh", kcal: 61, protein: 0.5, fat: 0.6, carbs: 9.7, sugar: 9.7, fiber: 4.9, water: 86.5, sodium: 2, calcium: 11, iron: 0.708, magnesium: 6, potassium: 84, vitaminC: 22, vitaminB12: 0),
        "Honig": .init(source: "Honig", kcal: 305, protein: 0.4, fat: 0, carbs: 74.091, sugar: 70.764, fiber: nil, water: 17.5, sodium: 3, calcium: 5, iron: 0.3, magnesium: 4, potassium: 67, vitaminC: 0.389, vitaminB12: 0),
        "Joghurt": .init(source: "Joghurt mild, mind. 3,5 % Fett", kcal: 67, protein: 3.98, fat: 3.46, carbs: 4.13, sugar: 4.13, fiber: 0, water: 86.6, sodium: 40, calcium: 110.5, iron: 0.022, magnesium: 11.2, potassium: 172.5, vitaminC: nil, vitaminB12: 0.208),
        "Karotte": .init(source: "Karotte/Möhre, roh", kcal: 40, protein: 0.84, fat: 0.4, carbs: 6.471, sugar: 6.37, fiber: 2.9, water: 88, sodium: 22.7, calcium: 21.1, iron: 0.355, magnesium: 12, potassium: 355.1, vitaminC: 3.22, vitaminB12: 0),
        "Milch": .init(source: "H-Vollmilch 3,5 % Fett", kcal: 62, protein: 3.18, fat: 3.49, carbs: 4.19, sugar: 4.19, fiber: 0, water: 84.5, sodium: 35.8, calcium: 111.7, iron: 0.02, magnesium: 10.6, potassium: 154, vitaminC: 0.923, vitaminB12: 0.599),
        "Nudeln": .init(source: "Hartweizen (Vollkorn)", kcal: 346, protein: 14.4, fat: 2.32, carbs: 60.94, sugar: 1.071, fiber: 11.76, water: 11.92, sodium: 0.7, calcium: 36, iron: 3.417, magnesium: 94.7, potassium: 401.3, vitaminC: nil, vitaminB12: 0),
        "Olivenöl": .init(source: "Olivenöl", kcal: 899, protein: 0, fat: 99.9, carbs: 0, sugar: 0, fiber: 0, water: 0.107, sodium: 1.49, calcium: 0.23, iron: 0.132, magnesium: 0.81, potassium: 1.31, vitaminC: 0, vitaminB12: 0),
        "Paprika": .init(source: "Gemüsepaprika rot, roh", kcal: 36, protein: 1.025, fat: 0.2, carbs: 6.19, sugar: 6.19, fiber: 2.2, water: 92.1, sodium: 1.25, calcium: 8, iron: 0.377, magnesium: 14.12, potassium: 211, vitaminC: 159.81, vitaminB12: 0),
        "Quark": .init(source: "Speisequark 40 % Fett i. Tr.", kcal: 159, protein: 10.874, fat: 11.4, carbs: 2.6, sugar: 2.6, fiber: 0, water: 73.5, sodium: 34, calcium: 95, iron: 0.34, magnesium: 10, potassium: 82, vitaminC: 0.5, vitaminB12: 0.72),
        "Salz": .init(source: "Speisesalz jodiert", kcal: 0, protein: 0, fat: 0, carbs: 0, sugar: 0, fiber: 0, water: nil, sodium: 38145, calcium: 51.9, iron: nil, magnesium: 4.825, potassium: 140, vitaminC: 0, vitaminB12: 0),
        "Schnittlauch": .init(source: "Schnittlauch roh", kcal: 29, protein: 2.6, fat: 0.74, carbs: 1.54, sugar: 1.54, fiber: 2.6, water: 83.3, sodium: 9.6, calcium: 116.3, iron: 0.9, magnesium: 20.5, potassium: 301.8, vitaminC: 47, vitaminB12: 0),
        "Tomate": .init(source: "Tomate roh", kcal: 22, protein: 0.95, fat: 0.11, carbs: 3.25, sugar: 3.25, fiber: 1.3, water: 94.4, sodium: 4, calcium: 10, iron: 0.2, magnesium: 12, potassium: 239, vitaminC: 24.76, vitaminB12: 0),
        "Zwiebel": .init(source: "Speisezwiebel roh", kcal: 34, protein: 1.156, fat: 0.15, carbs: 6.01, sugar: 6.01, fiber: 1.4, water: 89.7, sodium: 9, calcium: 25, iron: 0.685, magnesium: 10, potassium: 174, vitaminC: 7.4, vitaminB12: 0),
    ]
}
