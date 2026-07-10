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
    /// Aktive Kategorie-Filter (leer = alles zeigen). Mehrfachauswahl.
    @State private var selectedCategories: [IngredientCategory] = []
    /// Zutat, für die gerade die Menge bearbeitet wird (Mengen-Sheet).
    @State private var amountTarget: Ingredient?

    private var sections: [(category: IngredientCategory, items: [Ingredient])] {
        IngredientCategory.allCases.compactMap { category in
            let items = Ingredient.seed
                .filter { $0.category == category }
                .filter { search.isEmpty || $0.name.localizedStandardContains(search) }
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            return items.isEmpty ? nil : (category, items)
        }
    }

    /// Kategorien, die bei der aktuellen Suche tatsächlich vorkommen (echte Chips).
    private var presentCategories: [IngredientCategory] { sections.map(\.category) }

    /// Nach aktivem Kategorie-Filter eingeschränkte Abschnitte.
    private var visibleSections: [(category: IngredientCategory, items: [Ingredient])] {
        guard !selectedCategories.isEmpty else { return sections }
        return sections.filter { selectedCategories.contains($0.category) }
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

            // Kategorie-Filter — nur zeigen, wenn es mehr als eine Kategorie gibt.
            if presentCategories.count > 1 {
                CategoryFilterChips(categories: presentCategories) { selection in
                    selectedCategories = selection
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 4)
            }

            ForEach(visibleSections, id: \.category) { section in
                VStack(alignment: .leading, spacing: 8) {
                    KKSectionHeader(title: section.category.title,
                                    systemImage: section.category.symbolName,
                                    tint: section.category.color)
                        .padding(.horizontal, 4)

                    KKCompositionalGrid {
                        ForEach(section.items) { ingredient in
                            let inStock = prefs.pantry.contains(ingredient.name)
                            PantryTile(
                                ingredient: ingredient,
                                inStock: inStock,
                                amount: prefs.pantryAmount(ingredient.name)
                            ) {
                                if inStock {
                                    // Schon im Vorrat → Menge bearbeiten (oder entnehmen)
                                    amountTarget = ingredient
                                } else {
                                    // Schnell hinzufügen (wie bisher)
                                    withAnimation(.snappy(duration: 0.2)) {
                                        prefs.togglePantry(ingredient.name)
                                    }
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
        .sheet(item: $amountTarget) { ingredient in
            PantryAmountSheet(ingredient: ingredient, prefs: prefs)
                .presentationDetents([.medium])
        }
    }
}

// MARK: - PantryTile
/// Bildbereite Zutaten-Kachel. Der Symbol-Slot in der Mitte wird später vom
/// freigestellten PNG-mit-Alpha ersetzt (macMini-Pipeline) — Rahmen/Abstände
/// bleiben gleich. Tippen schaltet „im Vorrat" um (sichtbarer grüner Haken).
private struct PantryTile: View {
    let ingredient: Ingredient
    let inStock: Bool
    let amount: Int?
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
                    // Gesetzte Menge (nur wenn hinterlegt) — echte Einheit der Zutat
                    if let amount {
                        Text(ingredient.unit.formattedAmount(amount))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(ingredient.category.color)
                    }
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
        .accessibilityValue(pantryValueDescription)
        .accessibilityHint(inStock ? "Zum Bearbeiten der Menge tippen" : "Zum Hinzufügen tippen")
    }

    private var pantryValueDescription: String {
        guard inStock else { return "nicht im Vorrat" }
        if let amount { return "im Vorrat, \(amount) \(ingredient.unit.title)" }
        return "im Vorrat"
    }
}

// MARK: - PantryAmountSheet
/// Mengen-Eingabe für eine Vorrats-Zutat über den analogen Strich-Picker
/// (Kavsoft `TickPicker`). Schreibt echte Werte in der KANONISCHEN Einheit der
/// Zutat (g/ml/Stück …) in die Preferences — keine Umrechnung.
private struct PantryAmountSheet: View {
    let ingredient: Ingredient
    @Bindable var prefs: Preferences
    @Environment(\.dismiss) private var dismiss

    /// Einheit der Zutat bestimmt Schrittweite, Höchstwert und Beschriftung.
    private var unit: IngredientUnit { ingredient.unit }
    private var step: Int { unit.pantryStep }
    private var maxTicks: Int { unit.pantryMaxValue / unit.pantryStep }

    @State private var tick: Int = 0
    private var value: Int { tick * step }

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 6) {
                Image(systemName: ingredient.category.symbolName)
                    .font(.system(size: 40))
                    .foregroundStyle(ingredient.category.color)
                Text(ingredient.name)
                    .font(.system(.title2, design: .serif).weight(.semibold))
            }
            .padding(.top, 24)

            Text(unit.formattedAmount(value))
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
                .animation(.snappy, value: value)

            TickPicker(
                count: maxTicks,
                config: TickConfig(activeTint: ingredient.category.color),
                selection: $tick
            )
            .padding(.horizontal)

            HStack(spacing: 12) {
                Button(role: .destructive) {
                    // Entfernt aus dem Vorrat und verwirft die Menge (togglePantry)
                    prefs.togglePantry(ingredient.name)
                    dismiss()
                } label: {
                    Label("Aus dem Vorrat", systemImage: "xmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    prefs.setPantryAmount(value, for: ingredient.name)
                    dismiss()
                } label: {
                    Label("Sichern", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)

            Spacer(minLength: 0)
        }
        .fontDesign(.serif)
        .task {
            // Auf gespeicherten Wert vorpositionieren (auf 10-g-Raster gerundet)
            let saved = prefs.pantryAmount(ingredient.name) ?? 0
            tick = min(max(Int((Double(saved) / Double(step)).rounded()), 0), maxTicks)
        }
    }
}

#Preview {
    NavigationStack { PantryView() }
}
