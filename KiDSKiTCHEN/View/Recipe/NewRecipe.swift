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
        // UI-Bauweise (Jay 10.7.): selbstgebautes Formular statt `Form`/`List` —
        // KKScroll + KKSection tragen die Eingabefelder. Entfernen als sichtbarer
        // Lösch-Knopf (KKDeleteButton) statt Swipe (Jay 11.7., Herz-Knopf-Referenz).
        KKScroll {
            // MARK: Basis
            KKSection(title: "Rezept", systemImage: "square.and.pencil") {
                TextField("Name", text: $newRecipe.name)
                    .textFieldStyle(.roundedBorder)
                TextField("Beschreibung", text: $newRecipe.details, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)
                Divider()
                HStack {
                    Text("Kategorie")
                    Spacer(minLength: 8)
                    Picker("Kategorie", selection: $newRecipe.category) {
                        Text("—").tag(RecipeCategory?.none)
                        ForEach(RecipeCategory.allCases) { category in
                            Label(category.rawValue, systemImage: category.symbolName)
                                .tag(RecipeCategory?.some(category))
                        }
                    }
                    .labelsHidden()
                }
                Divider()
                Stepper("Portionen: \(newRecipe.servings)", value: $newRecipe.servings, in: 1...20)
            }

            // MARK: Zutaten
            KKSection(title: "Zutaten", systemImage: "basket") {
                if viewModel.recipeIngredients.isEmpty {
                    Text("Noch keine Zutaten gewählt.")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(viewModel.recipeIngredients.enumerated()), id: \.element.id) { index, recipeIngredient in
                            if index > 0 { Divider() }
                            HStack {
                                Text(recipeIngredient.formatted)
                                Spacer(minLength: 8)
                                KKDeleteButton(accessibilityLabel: "\(recipeIngredient.formatted) entfernen") {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        viewModel.removeRecipeIngredient(recipeIngredient: recipeIngredient)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                Button("Zutaten auswählen", systemImage: "basket") {
                    viewModel.showRecipeIngredients()
                }
                .padding(.top, 4)
            }

            // MARK: Zubereitung
            KKSection(title: "Zubereitung", systemImage: "list.number") {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.recipeInstructions.enumerated()), id: \.element.id) { index, instruction in
                        if index > 0 { Divider() }
                        HStack(alignment: .top, spacing: 8) {
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
                            KKDeleteButton(accessibilityLabel: "Schritt \(index + 1) löschen") {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.recipeInstruction = instruction
                                    viewModel.removeRecipeInstruction()
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                HStack {
                    TextField(
                        viewModel.isEditingInstruction ? "Schritt bearbeiten" : "Neuer Schritt",
                        text: $viewModel.instructionsTextField,
                        axis: .vertical
                    )
                    .textFieldStyle(.roundedBorder)
                    Button(
                        viewModel.isEditingInstruction ? "Übernehmen" : "Hinzufügen",
                        systemImage: viewModel.isEditingInstruction ? "checkmark.circle.fill" : "plus.circle.fill"
                    ) {
                        viewModel.addRecipeInstruction()
                    }
                    .labelStyle(.iconOnly)
                    .font(.title2)
                    .disabled(viewModel.instructionsTextField.isEmpty)
                }
                .padding(.top, 4)
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
