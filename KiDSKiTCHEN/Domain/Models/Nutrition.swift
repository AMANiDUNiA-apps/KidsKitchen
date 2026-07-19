//
//  Nutrition.swift
//  KiDSKiTCHEN
//
//  Rebuild P2 (Domain): EIN Nährwert-Modell statt der früheren zwei parallelen
//  (`Nutrition` fürs Rezept, `NutritionFacts` je 100 g BLS-Zutat). Die fünf
//  Rezept-Makros bleiben optional mit Default 0 (unverändert nutzbar durch
//  Recipe/RemoteRecipe/NutritionBars), die BLS-Zusatzwerte sind echte Optionals,
//  weil sie je Zutat fehlen können (kein Wert erfinden). `source` = BLS-
//  Eintragsname zur Nachvollziehbarkeit, nil bei Rezept-eigenen Werten.
//

import Foundation

// MARK: - Nutrition
struct Nutrition: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var source: String?
    var kcal: Double? = 0
    var protein: Double? = 0
    var carbs: Double? = 0
    var fat: Double? = 0
    var fiber: Double? = 0
    var sugar: Double?
    var water: Double?
    var sodium: Double?       // mg
    var calcium: Double?      // mg
    var iron: Double?         // mg
    var magnesium: Double?    // mg
    var potassium: Double?    // mg
    var vitaminC: Double?     // mg
    var vitaminB12: Double?   // µg

    // MARK: leer (für neue Rezepte)
    static let empty = Nutrition()

    /// Keine hinterlegten Werte.
    var isEmpty: Bool {
        (kcal ?? 0) == 0 && (protein ?? 0) == 0 && (carbs ?? 0) == 0
            && (fat ?? 0) == 0 && (fiber ?? 0) == 0
    }

    // MARK: shortSummary (z.B. „245 kcal · 12 g Protein · …")
    var shortSummary: String {
        "\(Int(kcal ?? 0)) kcal · \(Int(protein ?? 0)) g Protein · \(Int(carbs ?? 0)) g KH · \(Int(fat ?? 0)) g Fett"
    }

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

    /// Skaliert die Makros auf eine Grammmenge (für Rezept-Summierung, § NutritionMath).
    func scaled(toGrams grams: Double) -> (kcal: Double, protein: Double, fat: Double, carbs: Double) {
        let f = grams / 100
        return ((kcal ?? 0) * f, (protein ?? 0) * f, (fat ?? 0) * f, (carbs ?? 0) * f)
    }
}
