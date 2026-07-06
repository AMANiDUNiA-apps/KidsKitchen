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

    var body: some View {
        HStack {
            rowViewModel.ingredient.category.image
                .foregroundStyle(rowViewModel.ingredient.category.color)
                .accessibilityHidden(true)
            Text(rowViewModel.ingredientName)

            Spacer()

            if rowViewModel.isSelected {
                // Feste Breiten, damit Menge/Einheit über alle Zeilen bündig stehen
                TextField("Menge", value: $rowViewModel.amount, format: .number)
                    .keyboardType(.decimalPad)
                    .frame(width: 64)
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.trailing)
                Picker("Einheit", selection: $rowViewModel.unit) {
                    ForEach(IngredientUnit.allCases) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .labelsHidden()
                .frame(width: 78, alignment: .trailing)
            }

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
        .onChange(of: rowViewModel.amount) { _, _ in
            if rowViewModel.isSelected { rowViewModel.addIngredient() }
        }
        .onChange(of: rowViewModel.unit) { _, _ in
            if rowViewModel.isSelected { rowViewModel.addIngredient() }
        }
    }
}

#Preview {
    IngredientRow(rowViewModel: IngredientViewModel(ingredient: .longMock))
}
