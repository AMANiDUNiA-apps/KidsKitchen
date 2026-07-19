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
            // UI-Bauweise (Jay 10.7.): selbstgebaute Container statt `List` — KKScroll + KKCard.
            KKScroll {
                ForEach(viewModel.pickerSections, id: \.category) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        IngredientSectionHeader(
                            category: section.category,
                            hasSelection: section.items.contains(where: { viewModel.isSelected($0) })
                        )
                        .padding(.horizontal, 4)
                        KKCard {
                            VStack(spacing: 0) {
                                ForEach(Array(section.items.enumerated()), id: \.element.id) { index, ingredient in
                                    if index > 0 { Divider() }
                                    IngredientRow(rowViewModel: IngredientViewModel(ingredient: ingredient))
                                        .padding(.vertical, 4)
                                }
                            }
                        }
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
