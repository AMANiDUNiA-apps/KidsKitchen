//
//  IngredientPicker.swift
//  KiDSKiTCHEN
//
//  Created by Claude Fable 5 on 02.07.26.
//  Sheet: durchsuchbare Zutatenliste; je Zeile ein IngredientViewModel.
//

import SwiftUI

struct IngredientPicker: View {
    @State private var viewModel: RecipeEditorViewModel = .shared

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.pickerSections, id: \.category) { section in
                    Section {
                        ForEach(section.items) { ingredient in
                            IngredientRow(rowViewModel: IngredientViewModel(ingredient: ingredient))
                        }
                    } header: {
                        IngredientSectionHeader(
                            category: section.category,
                            hasSelection: section.items.contains(where: \.isSelected)
                        )
                    }
                }
            }
            .searchable(text: $viewModel.ingredientSearchText, prompt: "Zutat suchen")
            .navigationTitle("Zutaten")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { viewModel.closeRecipeIngredients() }
                }
            }
        }
    }
}

#Preview {
    IngredientPicker()
}
