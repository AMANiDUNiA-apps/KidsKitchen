//
//  IngredientSectionHeader.swift
//  KiDSKiTCHEN
//
//  Created by Claude Fable 5 on 03.07.26.
//  Kategorie-Kopf im IngredientPicker: Farbe + Symbol der Kategorie,
//  „Abwählen" entfernt alle gewählten Zutaten dieser Kategorie.
//

import SwiftUI

struct IngredientSectionHeader: View {
    let category: IngredientCategory
    let hasSelection: Bool

    @State private var viewModel: RecipeEditorViewModel = .shared

    var body: some View {
        HStack {
            Label(category.title, systemImage: category.symbolName)
                .foregroundStyle(category.color)
                .bold()

            Spacer()

            if hasSelection {
                Button("Abwählen", systemImage: "xmark.circle") {
                    viewModel.deselectCategory(category)
                }
                .font(.caption)
                .buttonStyle(.borderless)
            }
        }
    }
}

#Preview {
    List {
        Section {
            Text("Apfel")
        } header: {
            IngredientSectionHeader(category: .fruit, hasSelection: true)
        }
    }
}
