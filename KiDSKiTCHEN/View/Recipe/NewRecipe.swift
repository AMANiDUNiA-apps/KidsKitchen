//
//  NewRecipe.swift
//  KiDSKiTCHEN
//
//  Created by Claude Fable 5 on 02.07.26.
//  Nutzt exakt die bestehende ViewModel-API (Instructions-Editor, Zutaten-Sheet).
//

import SwiftUI

struct NewRecipe: View {
    @State private var newRecipe: Recipe
    @State private var viewModel: RecipeEditorViewModel = .shared
    @State private var listViewModel: RecipeListViewModel = .shared
    @State private var didPrepare = false
    @Environment(\.dismiss) private var dismiss

    init(newRecipe: Recipe) {
        _newRecipe = State(initialValue: newRecipe)
    }

    /// Leeren Editor für ein frisches Rezept (einmalig, überschreibt die Mock-Vorbelegung).
    private func prepareIfNeeded() {
        guard !didPrepare else { return }
        didPrepare = true
        if newRecipe.name.isEmpty {
            viewModel.recipeIngredients = []
            viewModel.recipeInstructions = []
        }
    }

    private func save() {
        var recipe = newRecipe
        recipe.ingredients = viewModel.recipeIngredients
        recipe.instructions = viewModel.recipeInstructions
        recipe.nutrition = recipe.computedNutrition   // Nährwerte aus den Zutaten
        listViewModel.add(recipe)
        // Editor für das nächste Rezept leeren
        viewModel.recipeIngredients = []
        viewModel.recipeInstructions = []
        dismiss()
    }

    var body: some View {
        Form {
            // MARK: Basis
            Section("Rezept") {
                TextField("Name", text: $newRecipe.name)
                TextField("Beschreibung", text: $newRecipe.details, axis: .vertical)
                    .lineLimit(2...4)
                Picker("Kategorie", selection: $newRecipe.category) {
                    Text("—").tag(RecipeCategory?.none)
                    ForEach(RecipeCategory.allCases) { category in
                        Label(category.rawValue, systemImage: category.symbolName)
                            .tag(RecipeCategory?.some(category))
                    }
                }
                Stepper("Portionen: \(newRecipe.servings)", value: $newRecipe.servings, in: 1...20)
            }

            // MARK: Zutaten
            Section {
                ForEach(viewModel.recipeIngredients) { recipeIngredient in
                    Text(recipeIngredient.formatted)
                        .swipeActions {
                            Button("Entfernen", systemImage: "trash", role: .destructive) {
                                viewModel.removeRecipeIngredient(recipeIngredient: recipeIngredient)
                            }
                        }
                }
                Button("Zutaten auswählen", systemImage: "basket") {
                    viewModel.showRecipeIngredients()
                }
            } header: {
                Text("Zutaten")
            }

            // MARK: Zubereitung
            Section("Zubereitung") {
                ForEach(viewModel.recipeInstructions.enumerated(), id: \.element.id) { index, instruction in
                    Button {
                        viewModel.editRecipeInstruction(instruction: instruction)
                    } label: {
                        HStack(alignment: .top) {
                            Text("\(index + 1).")
                                .foregroundStyle(.secondary)
                            Text(instruction.text)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .swipeActions {
                        Button("Löschen", systemImage: "trash", role: .destructive) {
                            viewModel.recipeInstruction = instruction
                            viewModel.removeRecipeInstruction()
                        }
                    }
                }
                HStack {
                    TextField(
                        viewModel.isEditingInstruction ? "Schritt bearbeiten" : "Neuer Schritt",
                        text: $viewModel.instructionsTextField,
                        axis: .vertical
                    )
                    Button(
                        viewModel.isEditingInstruction ? "Übernehmen" : "Hinzufügen",
                        systemImage: viewModel.isEditingInstruction ? "checkmark.circle.fill" : "plus.circle.fill"
                    ) {
                        viewModel.addRecipeInstruction()
                    }
                    .labelStyle(.iconOnly)
                    .disabled(viewModel.instructionsTextField.isEmpty)
                }
            }
        }
        .navigationTitle(newRecipe.name.isEmpty ? "Neues Rezept" : newRecipe.name)
        .onAppear(perform: prepareIfNeeded)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Speichern", action: save)
                    .disabled(newRecipe.name.isEmpty || viewModel.recipeIngredients.isEmpty)
            }
        }
        .sheet(isPresented: $viewModel.isShowingIngredients) {
            IngredientPicker()
        }
    }
}

#Preview {
    NavigationStack { NewRecipe(newRecipe: .emptyMock) }
}
