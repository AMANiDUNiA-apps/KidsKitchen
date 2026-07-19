//
//  NutritionBars.swift
//  KiDSKiTCHEN
//
//  Visuelle Nährwertbalken für Rezept-Detail und Zutat-Detail.
//  NutritionDepth: Kurz / Mehr / Alles (vormals in IngredientDetailView verschachtelt).
//

import SwiftUI

// MARK: - NutritionDepth
enum NutritionDepth: String, CaseIterable, Identifiable {
    case mini = "Kurz"
    case mid  = "Mehr"
    case full = "Alles"
    var id: Self { self }
}

// MARK: - MacroBar  (einzelner beschrifteter Fortschrittsbalken)
struct MacroBar: View {
    let label: String
    let value: Double?
    let unit: String
    let color: Color
    let fraction: Double
    var emphasized: Bool = false
    var indented: Bool = false

    private var clamped: Double { max(0.02, min(fraction, 1.0)) }
    private var formatted: String {
        guard let v = value else { return "—" }
        return v.formatted(.number.precision(.fractionLength(0...1))) + "\u{202F}" + unit
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(emphasized ? .subheadline.bold() : .caption)
                .foregroundStyle(emphasized ? .primary : .secondary)
                .frame(width: 112, alignment: .leading)
                .lineLimit(1)
                .padding(.leading, indented ? 14 : 0)

            // Balken: Capsule als Hintergrund, GeometryReader im Overlay für exakte Breite
            Capsule()
                .fill(color.opacity(0.13))
                .frame(height: emphasized ? 10 : 7)
                .overlay(alignment: .leading) {
                    GeometryReader { geo in
                        Capsule()
                            .fill(color.gradient)
                            .frame(width: geo.size.width * clamped,
                                   height: emphasized ? 10 : 7)
                    }
                }

            Text(formatted)
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 62, alignment: .trailing)
                .lineLimit(1)
        }
        .frame(height: emphasized ? 24 : 20)
    }
}

// MARK: - RecipeNutritionBars  (je Rezept / Portion)
/// Tagesreferenz: kcal 2000, Eiweiß 50 g, KH 260 g, Fett 70 g, Ballaststoffe 30 g
struct RecipeNutritionBars: View {
    let nutrition: Nutrition

    private let ref = (kcal: 2000.0, protein: 50.0, carbs: 260.0, fat: 70.0, fiber: 30.0)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Energie")
                    .font(.system(.headline, design: .serif))
                Spacer()
                Text("\(Int(nutrition.kcal ?? 0)) kcal")
                    .font(.title3.bold())
                    .foregroundStyle(.orange)
            }

            MacroBar(label: "vom Tagesbedarf",
                     value: nutrition.kcal, unit: "kcal",
                     color: .orange,
                     fraction: (nutrition.kcal ?? 0) / ref.kcal,
                     emphasized: true)

            Divider()

            MacroBar(label: "Eiweiß",       value: nutrition.protein, unit: "g",
                     color: .blue,   fraction: (nutrition.protein ?? 0) / ref.protein)
            MacroBar(label: "Kohlenhydrate", value: nutrition.carbs,   unit: "g",
                     color: .orange, fraction: (nutrition.carbs ?? 0)  / ref.carbs)
            MacroBar(label: "Fett",          value: nutrition.fat,     unit: "g",
                     color: .yellow, fraction: (nutrition.fat ?? 0)    / ref.fat)
            MacroBar(label: "Ballaststoffe", value: nutrition.fiber,   unit: "g",
                     color: .green,  fraction: (nutrition.fiber ?? 0)  / ref.fiber)
        }
    }
}

// MARK: - IngredientNutritionBars  (je 100 g, aus BLS)
/// Referenz je 100 g: kcal 400, Eiweiß 30, KH 80, Fett 40, Fiber 15, Wasser 100
struct IngredientNutritionBars: View {
    let facts: Nutrition
    let depth: NutritionDepth

    private let ref = (kcal: 400.0, protein: 30.0, carbs: 80.0, fat: 40.0,
                       fiber: 15.0, water: 100.0, sodium: 2000.0, calcium: 1200.0,
                       iron: 15.0, mg: 400.0, potassium: 4000.0, vitC: 90.0, vitB12: 3.0)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Energie")
                    .font(.system(.subheadline, design: .serif).bold())
                Spacer()
                Text("\(Int(facts.kcal ?? 0)) kcal")
                    .font(.subheadline.bold()).foregroundStyle(.orange)
            }
            MacroBar(label: "je 100 g",
                     value: facts.kcal, unit: "kcal",
                     color: .orange,
                     fraction: (facts.kcal ?? 0) / ref.kcal,
                     emphasized: true)

            Divider()

            // Mini + Mehr + Alles
            MacroBar(label: "Eiweiß",        value: facts.protein, unit: "g",
                     color: .blue,   fraction: (facts.protein ?? 0) / ref.protein)
            MacroBar(label: "Fett",           value: facts.fat,     unit: "g",
                     color: .yellow, fraction: (facts.fat     ?? 0) / ref.fat)
            MacroBar(label: "Kohlenhydrate",  value: facts.carbs,   unit: "g",
                     color: .orange, fraction: (facts.carbs   ?? 0) / ref.carbs)

            // Mehr + Alles
            if depth != .mini {
                MacroBar(label: "davon Zucker",  value: facts.sugar, unit: "g",
                         color: .orange, fraction: (facts.sugar ?? 0) / ref.carbs,
                         indented: true)
                MacroBar(label: "Ballaststoffe", value: facts.fiber, unit: "g",
                         color: .green,  fraction: (facts.fiber ?? 0) / ref.fiber)
                MacroBar(label: "Wasser",        value: facts.water, unit: "g",
                         color: .cyan,   fraction: (facts.water ?? 0) / ref.water)
            }

            // Alles
            if depth == .full {
                Divider()
                MacroBar(label: "Natrium",     value: facts.sodium,    unit: "mg",
                         color: .indigo,          fraction: (facts.sodium    ?? 0) / ref.sodium)
                MacroBar(label: "Calcium",     value: facts.calcium,   unit: "mg",
                         color: .blue.opacity(0.6), fraction: (facts.calcium  ?? 0) / ref.calcium)
                MacroBar(label: "Eisen",       value: facts.iron,      unit: "mg",
                         color: .brown,           fraction: (facts.iron      ?? 0) / ref.iron)
                MacroBar(label: "Magnesium",   value: facts.magnesium, unit: "mg",
                         color: .teal,            fraction: (facts.magnesium ?? 0) / ref.mg)
                MacroBar(label: "Kalium",      value: facts.potassium, unit: "mg",
                         color: .purple,          fraction: (facts.potassium ?? 0) / ref.potassium)
                MacroBar(label: "Vitamin C",   value: facts.vitaminC,  unit: "mg",
                         color: .yellow,          fraction: (facts.vitaminC  ?? 0) / ref.vitC)
                MacroBar(label: "Vitamin B12", value: facts.vitaminB12, unit: "µg",
                         color: .pink,            fraction: (facts.vitaminB12 ?? 0) / ref.vitB12)
            }
        }
    }
}

#Preview("Rezept-Balken") {
    List {
        Section("Nährwerte") {
            RecipeNutritionBars(
                nutrition: Nutrition(kcal: 320, protein: 11, carbs: 52, fat: 7, fiber: 8)
            )
            .listRowSeparator(.hidden)
        }
    }
}
