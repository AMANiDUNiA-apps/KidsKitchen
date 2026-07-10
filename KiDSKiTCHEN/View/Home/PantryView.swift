//
//  PantryView.swift
//  KiDSKiTCHEN
//
//  Created by Claude Fable 5 on 03.07.26.
//  Vorratsschrank: was habe ich zu Hause? Grundlage für „Was kann ich kochen?"
//  (Home-Filter) und für die Einkaufsliste (nur Fehlendes).
//
//  Weiterbau 4, Teil E — direkt vom `List` auf ein Kachelraster umgestellt (kein
//  Zwischenschritt): Zutaten als Kacheln in einem Magazin-Raster mit wechselnden
//  Größen. Vorlage: Kavsoft „CompositionalGridLayout" (Balaji Venkatesh),
//  s. KKCompositionalGrid. Kacheln sind bildbereit — die freigestellten
//  PNG-mit-Alpha-Bilder aus der macMini-Pipeline füllen später den Symbol-Slot
//  1:1, ohne Layout-Änderung.
//

import SwiftUI

struct PantryView: View {
    @State private var prefs: Preferences = .shared
    @State private var search = ""

    private var sections: [(category: IngredientCategory, items: [Ingredient])] {
        IngredientCategory.allCases.compactMap { category in
            let items = Ingredient.seed
                .filter { $0.category == category }
                .filter { search.isEmpty || $0.name.localizedStandardContains(search) }
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            return items.isEmpty ? nil : (category, items)
        }
    }

    var body: some View {
        KKScroll {
            if !prefs.pantry.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text("\(prefs.pantry.count) im Vorrat")
                        .font(.subheadline.weight(.medium))
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 4)
            }

            ForEach(sections, id: \.category) { section in
                VStack(alignment: .leading, spacing: 8) {
                    KKSectionHeader(title: section.category.title,
                                    systemImage: section.category.symbolName,
                                    tint: section.category.color)
                        .padding(.horizontal, 4)

                    KKCompositionalGrid {
                        ForEach(section.items) { ingredient in
                            PantryTile(
                                ingredient: ingredient,
                                inStock: prefs.pantry.contains(ingredient.name)
                            ) {
                                withAnimation(.snappy(duration: 0.2)) {
                                    prefs.togglePantry(ingredient.name)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Vorratsschrank")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $search, prompt: "Zutat suchen")
    }
}

// MARK: - PantryTile
/// Bildbereite Zutaten-Kachel. Der Symbol-Slot in der Mitte wird später vom
/// freigestellten PNG-mit-Alpha ersetzt (macMini-Pipeline) — Rahmen/Abstände
/// bleiben gleich. Tippen schaltet „im Vorrat" um (sichtbarer grüner Haken).
private struct PantryTile: View {
    let ingredient: Ingredient
    let inStock: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 8) {
                    // Bild-Slot (Platzhalter bis zum PNG): Kategorie-Symbol.
                    Image(systemName: ingredient.category.symbolName)
                        .font(.system(size: 34))
                        .foregroundStyle(ingredient.category.color)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    Text(ingredient.name)
                        .font(.system(.subheadline, design: .serif).weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    inStock ? ingredient.category.color.opacity(0.18)
                            : Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 18)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(inStock ? ingredient.category.color : .clear, lineWidth: 2)
                }

                if inStock {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                        .padding(8)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(ingredient.name)
        .accessibilityValue(inStock ? "im Vorrat" : "nicht im Vorrat")
        .accessibilityHint("Zum Umschalten tippen")
    }
}

#Preview {
    NavigationStack { PantryView() }
}
