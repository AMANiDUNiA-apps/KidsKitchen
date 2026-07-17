//
//  PantryLayout.swift
//  KiDSKiTCHEN
//
//  Umschaltbare Ansicht-Varianten für die Zutaten-Übersicht.
//
//  bau/air (16.7.) — A6: plus.circle Icon entfernt.
//  War: „inStock → grüner Haken, sonst rotes +". Jetzt: nur der grüne Haken (opacity
//  0→1), eingeblendet mit spring-Animation — klar lesbar, ohne verwirrende Aktion.
//

import SwiftUI

// MARK: - PantryLayout
enum PantryLayout: String, CaseIterable, Identifiable {
    case grid
    case cards
    case list
    case gallery

    var id: String { rawValue }

    var title: String {
        switch self {
        case .grid:    "Raster"
        case .cards:   "Große Karten"
        case .list:    "Liste"
        case .gallery: "Galerie"
        }
    }

    var symbol: String {
        switch self {
        case .grid:    "square.grid.2x2"
        case .cards:   "rectangle.grid.1x2"
        case .list:    "list.bullet"
        case .gallery: "rectangle.stack"
        }
    }

    var next: PantryLayout {
        let all = Self.allCases
        let i = all.firstIndex(of: self) ?? 0
        return all[(i + 1) % all.count]
    }
}

// MARK: - PantryBigCard (Variante „Große Karten")
/// Breite Karte: großes Zutat-Foto links, Name + Menge rechts.
/// Kein plus-Icon mehr — der grüne Haken blendet sich beim Hinzufügen sanft ein.
struct PantryBigCard: View {
    let ingredient: Ingredient
    let inStock: Bool
    let amount: Int?
    let onSingle: () -> Void
    let onDouble: () -> Void
    @State private var settings: ThemeSettings = .shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .topTrailing) {
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

            // Grüner Haken blendet sich bei inStock==true ein (kein plus mehr)
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.green)
                .padding(10)
                .opacity(inStock ? 1 : 0)
                .scaleEffect(inStock ? 1 : 0.5)
                .symbolEffect(.bounce, value: reduceMotion ? false : inStock)
                .animation(.spring(response: 0.3), value: inStock)
        }
        .pantryTapGestures(onSingle: onSingle, onDouble: onDouble)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(ingredient.name)
        .accessibilityValue(inStock ? "im Vorrat" : "nicht im Vorrat")
        .accessibilityHint("Einmal tippen für die Menge, zweimal für die Details")
    }
}

// MARK: - PantryListRow (Variante „Liste")
/// Kompakte Zeile: mittleres Foto + Name, Status rechts.
/// Kein plus-Icon — Haken blendet sich ein wie bei der Karte.
struct PantryListRow: View {
    let ingredient: Ingredient
    let inStock: Bool
    let amount: Int?
    let onSingle: () -> Void
    let onDouble: () -> Void
    @State private var settings: ThemeSettings = .shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .trailing) {
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

                // Platz für den Haken (damit Text nicht darunter liegt)
                Color.clear.frame(width: 28)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .background(
                inStock ? ingredient.category.color.opacity(0.14) : settings.theme.cardSurface.opacity(0.6),
                in: RoundedRectangle(cornerRadius: settings.cardCornerRadius)
            )

            // Grüner Haken
            Image(systemName: "checkmark.circle.fill")
                .font(.body)
                .foregroundStyle(.green)
                .padding(.trailing, 12)
                .opacity(inStock ? 1 : 0)
                .scaleEffect(inStock ? 1 : 0.5)
                .symbolEffect(.bounce, value: reduceMotion ? false : inStock)
                .animation(.spring(response: 0.3), value: inStock)
        }
        .pantryTapGestures(onSingle: onSingle, onDouble: onDouble)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(ingredient.name)
        .accessibilityValue(inStock ? "im Vorrat" : "nicht im Vorrat")
        .accessibilityHint("Einmal tippen für die Menge, zweimal für die Details")
    }
}
