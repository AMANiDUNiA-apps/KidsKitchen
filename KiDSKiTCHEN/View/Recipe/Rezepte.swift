//
//  Rezepte.swift
//  KiDSKiTCHEN
//
//  Rezept-Detailansicht: visuelle Nährwertbalken, Zutaten mit Kategorie-Icons,
//  nummerierte Zubereitungsschritte mit farbigen Schritt-Kreisen.
//

import SwiftUI

struct Rezepte: View {
    let recipe: Recipe
    @State private var prefs: Preferences = .shared
    @State private var addedToCart = false
    @State private var isSaved = false
    @State private var isSaving = false

    var body: some View {
        List {
            // Beschreibung
            if !recipe.details.isEmpty {
                Section { Text(recipe.details) }
            }

            // Kurzinfo
            Section("Info") {
                if let category = recipe.category {
                    Label(category.rawValue, systemImage: category.symbolName)
                        .foregroundStyle(category.color)
                }
                if recipe.totalTime > 0 {
                    Label("^[\(recipe.totalTime) Minute](inflect: true)",
                          systemImage: "clock")
                }
                if recipe.prepTime > 0 || recipe.cookTime > 0 {
                    HStack(spacing: 16) {
                        if recipe.prepTime > 0 {
                            Label("\(recipe.prepTime) min vorbereiten", systemImage: "knife")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        if recipe.cookTime > 0 {
                            Label("\(recipe.cookTime) min kochen", systemImage: "flame")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                if let level = recipe.level {
                    Label(level, systemImage: "chart.bar.doc.horizontal")
                }
            }

            // Nährwerte — visuell (nur zeigen, wenn hinterlegt oder verlässlich berechenbar)
            if let nutrition = recipe.displayNutrition {
                Section("Nährwerte") {
                    RecipeNutritionBars(nutrition: nutrition)
                        .listRowSeparator(.hidden)
                }
            }

            // Zutaten — visuell mit Kategorie-Icon
            Section("Zutaten") {
                ForEach(recipe.ingredients) { item in
                    NavigationLink {
                        IngredientDetailView(ingredient: item.ingredient)
                    } label: {
                        IngredientVisualRow(item: item)
                    }
                }
                Button {
                    prefs.addToShopping(recipe)
                    addedToCart = true
                } label: {
                    Label(addedToCart ? "Auf der Einkaufsliste" : "Auf die Einkaufsliste",
                          systemImage: addedToCart ? "checkmark.circle.fill" : "cart.badge.plus")
                }
                .disabled(addedToCart)
            }

            // Zubereitung — Schritt für Schritt, mit kindersicherer Slide-Bestätigung
            if !recipe.instructions.isEmpty {
                CookingSteps(instructions: recipe.instructions,
                             tint: recipe.category?.color ?? .orange)
            }
        }
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.large)
        .task { isSaved = SavedRecipeRepository.shared.isSaved(recipe.name) }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        isSaving = true
                        await SavedRecipeRepository.shared.save(recipe)
                        isSaved = true
                        isSaving = false
                    }
                } label: {
                    Label("Offline speichern",
                          systemImage: isSaved ? "arrow.down.circle.fill" : "arrow.down.circle")
                }
                .disabled(isSaved || isSaving)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ForEach(Weekday.allCases) { day in
                        Button(day.rawValue) { prefs.addToPlan(recipe.name, day: day) }
                    }
                } label: {
                    Label("Zum Wochenplan", systemImage: "calendar.badge.plus")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        prefs.toggleFavorite(recipe.name)
                    }
                } label: {
                    Image(systemName: prefs.isFavorite(recipe.name) ? "heart.fill" : "heart")
                        .foregroundStyle(.pink)
                }
            }
        }
    }
}

// MARK: - CookingSteps
/// Kochschritte einzeln abhakbar per Slide-Geste (kindersicher). Fortschritt lebt
/// nur im Speicher pro Rezept-Durchlauf — keine neue Persistenz.
private struct CookingSteps: View {
    let instructions: [RecipeInstruction]
    let tint: Color
    @State private var doneCount = 0

    private var allDone: Bool { doneCount >= instructions.count }

    var body: some View {
        Section {
            // Fortschritt
            VStack(alignment: .leading, spacing: 8) {
                if allDone {
                    Label("Alle Schritte geschafft! 🎉", systemImage: "party.popper.fill")
                        .font(.system(.headline, design: .serif))
                        .foregroundStyle(.green)
                } else {
                    Text("Schritt \(doneCount + 1) von \(instructions.count)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    ProgressView(value: Double(doneCount), total: Double(instructions.count))
                        .tint(tint)
                }
                if doneCount > 0 {
                    Button {
                        withAnimation(.smooth) { doneCount = 0 }
                    } label: {
                        Label("Von vorn", systemImage: "arrow.counterclockwise")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(.vertical, 4)

            // Schritte
            ForEach(Array(instructions.enumerated()), id: \.element.id) { idx, step in
                stepRow(idx, step)
            }
        } header: {
            Text("Zubereitung")
        }
    }

    @ViewBuilder
    private func stepRow(_ idx: Int, _ step: RecipeInstruction) -> some View {
        let isDone = idx < doneCount
        let isCurrent = idx == doneCount

        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isDone ? Color.green : (isCurrent ? tint : Color.gray.opacity(0.3)))
                        .frame(width: 26, height: 26)
                    if isDone {
                        Image(systemName: "checkmark").font(.caption.bold())
                    } else {
                        Text("\(idx + 1)").font(.caption.bold())
                    }
                }
                .foregroundStyle(.white)
                Text(step.text)
                    .foregroundStyle(isCurrent || isDone ? .primary : .secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if isCurrent {
                SlideToConfirm(config: .init(idleText: "Schritt geschafft!", tint: tint)) {
                    withAnimation(.smooth) { doneCount += 1 }
                }
                .id(idx) // frischer Slider für jeden Schritt
                .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
        .opacity(idx > doneCount ? 0.55 : 1)
    }
}

// MARK: - IngredientVisualRow
private struct IngredientVisualRow: View {
    let item: RecipeIngredient

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(item.ingredient.category.color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: item.ingredient.category.symbolName)
                    .font(.body)
                    .foregroundStyle(item.ingredient.category.color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.ingredient.name)
                    .font(.system(.body, design: .serif))
                Text(item.formatted)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack { Rezepte(recipe: .mock) }
}
