//
//  PantryLayout.swift
//  KiDSKiTCHEN
//
//  Umschaltbare Ansicht-Varianten für die Zutaten-Übersicht (Jay 11.7.:
//  bestehendes Magazin-Raster war unübersichtlich, Bilder zu klein für eine
//  Kinder-App). Vorlage: BigMountainStudio „Matched Geometry Effect"-Kapitel
//  (List / LazyVStack / LazyVGrid / VStack / HStack). Alle Varianten mit den
//  echten freigestellten PNGs, groß dargestellt. Umschalten über den
//  „Ansicht ändern"-Knopf, damit Jay am Gerät durchschalten und die
//  Gewinner-Variante bestimmen kann.
//

import SwiftUI

// MARK: - PantryLayout
/// Die wählbaren Layouts der Zutaten-Übersicht. `rawValue` wird persistiert
/// (@AppStorage), damit Jays Wahl über App-Starts bleibt.
enum PantryLayout: String, CaseIterable, Identifiable {
    case grid      // LazyVGrid, 2 gleich große Karten pro Reihe (großes Bild)
    case cards     // Eine große Karte pro Reihe (Bild links, Name/Menge rechts)
    case list      // Kompakte Liste (mittleres Bild + Name + Status)
    case gallery   // Horizontale Galerie je Kategorie (zum Wischen)

    var id: String { rawValue }

    var title: String {
        switch self {
        case .grid: "Raster"
        case .cards: "Große Karten"
        case .list: "Liste"
        case .gallery: "Galerie"
        }
    }

    /// SF-Symbol für den Umschalt-Knopf.
    var symbol: String {
        switch self {
        case .grid: "square.grid.2x2"
        case .cards: "rectangle.grid.1x2"
        case .list: "list.bullet"
        case .gallery: "rectangle.stack"
        }
    }

    /// Nächstes Layout im Kreis (für den „Ansicht ändern"-Knopf).
    var next: PantryLayout {
        let all = Self.allCases
        let i = all.firstIndex(of: self) ?? 0
        return all[(i + 1) % all.count]
    }
}

// MARK: - PantryBigCard (Variante „Große Karten")
/// Eine breite Karte pro Reihe: großes Zutat-Foto links, Name + Menge rechts.
struct PantryBigCard: View {
    let ingredient: Ingredient
    let inStock: Bool
    let amount: Int?
    let onSingle: () -> Void
    let onDouble: () -> Void
    @State private var settings: ThemeSettings = .shared

    var body: some View {
            HStack(spacing: 16) {
                IngredientImageView(ingredient: ingredient, size: 84)

                VStack(alignment: .leading, spacing: 4) {
                    Text(ingredient.name)
                        .font(.system(.title3, design: .serif).weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if let amount {
                        Text(ingredient.unit.formattedAmount(amount))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(ingredient.category.color)
                    } else {
                        Text(inStock ? "im Vorrat" : "tippen zum Hinzufügen")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 8)

                Image(systemName: inStock ? "checkmark.circle.fill" : "plus.circle")
                    .font(.title2)
                    .foregroundStyle(inStock ? .green : ingredient.category.color)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(
                inStock ? ingredient.category.color.opacity(0.18)
                        : settings.theme.cardSurface,
                in: RoundedRectangle(cornerRadius: settings.cardCornerRadius)
            )
            .overlay {
                RoundedRectangle(cornerRadius: settings.cardCornerRadius)
                    .strokeBorder(
                        inStock ? ingredient.category.color : settings.theme.cardStroke,
                        lineWidth: inStock ? 2 : 1
                    )
            }
            .shadow(color: settings.theme.shadowColor, radius: 3, y: 1)
            .pantryTapGestures(onSingle: onSingle, onDouble: onDouble)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(ingredient.name)
            .accessibilityValue(inStock ? "im Vorrat" : "nicht im Vorrat")
            .accessibilityHint("Einmal tippen für die Menge, zweimal für die Details")
    }
}

// MARK: - PantryListRow (Variante „Liste")
/// Kompakte Zeile: mittleres Foto + Name, Status rechts. Für schnelles Scannen.
struct PantryListRow: View {
    let ingredient: Ingredient
    let inStock: Bool
    let amount: Int?
    let onSingle: () -> Void
    let onDouble: () -> Void
    @State private var settings: ThemeSettings = .shared

    var body: some View {
            HStack(spacing: 14) {
                IngredientImageView(ingredient: ingredient, size: 48)

                Text(ingredient.name)
                    .font(.system(.body, design: .serif).weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer(minLength: 8)

                if let amount {
                    Text(ingredient.unit.formattedAmount(amount))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ingredient.category.color)
                }
                Image(systemName: inStock ? "checkmark.circle.fill" : "plus.circle")
                    .font(.title3)
                    .foregroundStyle(inStock ? .green : ingredient.category.color)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .background(
                inStock ? ingredient.category.color.opacity(0.14) : settings.theme.cardSurface.opacity(0.6),
                in: RoundedRectangle(cornerRadius: settings.cardCornerRadius)
            )
            .pantryTapGestures(onSingle: onSingle, onDouble: onDouble)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(ingredient.name)
            .accessibilityValue(inStock ? "im Vorrat" : "nicht im Vorrat")
            .accessibilityHint("Einmal tippen für die Menge, zweimal für die Details")
    }
}
