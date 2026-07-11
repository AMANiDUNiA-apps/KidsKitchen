//
//  IngredientRow.swift
//  KiDSKiTCHEN
//
//  Created by Claude Fable 5 on 02.07.26.
//

import SwiftUI

// MARK: - IngredientRow
struct IngredientRow: View {
    @State var rowViewModel: IngredientViewModel

    // Mindestbreiten skalieren mit Dynamic Type mit, statt fest zu klemmen —
    // so bleibt die Spalte bündig, ohne dass „Stück"/„Prise" umbrechen.
    @ScaledMetric(relativeTo: .body) private var amountWidth: CGFloat = 64
    @ScaledMetric(relativeTo: .body) private var unitMinWidth: CGFloat = 56
    // Bei Accessibility-Größen bricht die Menge/Einheit-Gruppe in eine zweite
    // Zeile um, statt Feld/Einheit/Button horizontal ineinander zu quetschen.
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Group {
            if typeSize.isAccessibilitySize {
                // Vertikaler Reflow: Name+Button oben, Mengen-Eingabe darunter
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        nameLabel
                        Spacer(minLength: 8)
                        actionButton
                    }
                    if rowViewModel.isSelected {
                        HStack(spacing: 8) {
                            amountField
                            unitPicker
                            Spacer(minLength: 0)
                        }
                    }
                }
            } else {
                HStack {
                    nameLabel
                    Spacer(minLength: 8)
                    if rowViewModel.isSelected {
                        amountField
                        unitPicker
                    }
                    actionButton
                }
            }
        }
        .onChange(of: rowViewModel.amount) { _, _ in
            if rowViewModel.isSelected { rowViewModel.addIngredient() }
        }
        .onChange(of: rowViewModel.unit) { _, _ in
            if rowViewModel.isSelected { rowViewModel.addIngredient() }
        }
    }

    // MARK: - Bausteine
    private var nameLabel: some View {
        HStack {
            rowViewModel.ingredient.category.image
                .foregroundStyle(rowViewModel.ingredient.category.color)
                .accessibilityHidden(true)
            // Name weicht als Erster (truncation), damit Menge/Einheit Platz behalten
            Text(rowViewModel.ingredientName)
                .lineLimit(1)
        }
    }

    private var amountField: some View {
        // Zahlen-only (Ziffern + de_DE-Komma) via KKNumberField/RestrictedTF —
        // filtert ungültige Zeichen (Einfügen/Hardware-Tastatur) hart heraus.
        // Skalierende Breite hält Menge/Einheit über alle Zeilen bündig.
        KKNumberField(value: $rowViewModel.amount)
            .frame(width: amountWidth)
            .textFieldStyle(.roundedBorder)
    }

    private var unitPicker: some View {
        Picker("Einheit", selection: $rowViewModel.unit) {
            ForEach(IngredientUnit.allCases) { unit in
                Text(unit.rawValue).tag(unit)
            }
        }
        .labelsHidden()
        // fixedSize verhindert den „Stück"-Umbruch; minWidth hält die Spalte bündig
        .fixedSize()
        .frame(minWidth: unitMinWidth, alignment: .trailing)
    }

    private var actionButton: some View {
        Button(
            rowViewModel.isSelected ? "Entfernen" : "Hinzufügen",
            systemImage: rowViewModel.isSelected ? "checkmark.circle.fill" : "plus.circle"
        ) {
            if rowViewModel.isSelected {
                rowViewModel.deleteIngredient()
            } else {
                rowViewModel.addIngredient()
            }
        }
        .labelStyle(.iconOnly)
        .foregroundStyle(rowViewModel.isSelected ? .green : .accentColor)
    }
}

#Preview {
    IngredientRow(rowViewModel: IngredientViewModel(ingredient: .longMock))
}
