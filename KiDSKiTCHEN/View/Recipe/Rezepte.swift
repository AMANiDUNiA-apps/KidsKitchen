//
//  Rezepte.swift
//  KiDSKiTCHEN
//
//  Rezept-Detailansicht: visuelle Nährwertbalken, Zutaten mit Kategorie-Icons,
//  nummerierte Zubereitungsschritte mit farbigen Schritt-Kreisen.
//

import SwiftUI

private enum SaveState { case idle, saving, saved }

struct Rezepte: View {
    let recipe: Recipe
    @State private var prefs: Preferences = .shared
    @State private var addedToCart = false
    @State private var saveState: SaveState = .idle
    @State private var toastConfig = InlineToastConfig(icon: "checkmark", title: "", tint: .green)
    @State private var showToast = false
    @State private var toastTask: Task<Void, Never>?
    // Einmaliges Gesten-Tutorial beim ersten geöffneten Rezept.
    @AppStorage("kk.hasSeenGestureTutorial") private var hasSeenTutorial = false
    @State private var showTutorial = false
    // Portionswahl (WheelPicker) — startet bei der Basis-Portionszahl des Rezepts.
    @State private var servings: Int
    // Zutatenliste gestaffelt einblenden (nur ohne Reduce-Motion).
    @State private var ingredientsVisible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(recipe: Recipe) {
        self.recipe = recipe
        _servings = State(initialValue: max(recipe.servings, 1))
    }

    private var tint: Color { recipe.category?.color ?? .orange }

    /// Basis-Portionszahl (nie 0, um Division abzusichern).
    private var baseServings: Int { max(recipe.servings, 1) }
    /// Skalierungsfaktor der Zutatenmengen relativ zur Basis-Portionszahl.
    private var scaleFactor: Double { Double(servings) / Double(baseServings) }

    private var saveConfig: AnimatedStateButton.Config {
        switch saveState {
        case .idle:
            .init(title: "Rezept offline speichern",
                  foregroundColor: .white,
                  background: recipe.category?.color ?? .orange,
                  symbolImage: "arrow.down.circle.fill")
        case .saving:
            .init(title: "Speichern …",
                  foregroundColor: .white,
                  background: recipe.category?.color ?? .orange,
                  symbolImage: nil)
        case .saved:
            .init(title: "Offline gespeichert",
                  foregroundColor: .white,
                  background: .green,
                  symbolImage: "checkmark.circle.fill")
        }
    }

    /// Zeigt einen Inline-Toast und blendet ihn nach kurzer Zeit wieder aus.
    private func flashToast(_ config: InlineToastConfig) {
        toastTask?.cancel()
        toastConfig = config
        withAnimation(.snappy) { showToast = true }
        toastTask = Task {
            try? await Task.sleep(for: .seconds(2.2))
            guard !Task.isCancelled else { return }
            withAnimation(.snappy) { showToast = false }
        }
    }

    /// Eine Zutatenzeile mit Verlinkung in die Zutat-Detailansicht.
    @ViewBuilder
    private func ingredientLink(_ item: RecipeIngredient) -> some View {
        NavigationLink {
            IngredientDetailView(ingredient: item.ingredient)
        } label: {
            IngredientVisualRow(item: item, factor: scaleFactor)
        }
    }

    var body: some View {
        List {
            // Beschreibung
            if !recipe.details.isEmpty {
                Section { Text(recipe.details) }
            }

            // Offline speichern — Zustands-Button (echte async-Aktion: läuft → fertig ✓)
            Section {
                AnimatedStateButton(config: saveConfig) {
                    guard saveState != .saved else { return }
                    withAnimation { saveState = .saving }
                    await SavedRecipeRepository.shared.save(recipe)
                    withAnimation { saveState = .saved }
                }
                .allowsHitTesting(saveState != .saved)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
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

            // Portionen — Auswahl-Rad, skaliert die Zutatenmengen ehrlich mit.
            Section("Portionen") {
                WheelPickerView(range: 1...12, selectedValue: $servings,
                                config: .init(activeTint: tint)) { value in
                    VStack(spacing: 0) {
                        Text("\(value)")
                            .font(.system(.title, design: .serif).bold())
                            .contentTransition(.numericText())
                        Text(value == 1 ? "Portion" : "Portionen")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .listRowSeparator(.hidden)
                .accessibilityRepresentation {
                    Stepper("Portionen: \(servings)", value: $servings, in: 1...12)
                }
                if servings != baseServings {
                    Text("Mengen für \(servings) statt \(baseServings) Portionen angepasst.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .listRowSeparator(.hidden)
                }
            }

            // Nährwerte — visuell (nur zeigen, wenn hinterlegt oder verlässlich berechenbar).
            // Werte sind PRO PORTION und damit unabhängig von der gewählten Portionszahl —
            // sie bleiben bewusst unverändert (keine erfundene Skalierung).
            if let nutrition = recipe.displayNutrition {
                Section {
                    RecipeNutritionBars(nutrition: nutrition)
                        .listRowSeparator(.hidden)
                } header: {
                    Text("Nährwerte")
                } footer: {
                    Text("je Portion")
                }
            }

            // Zutaten — visuell mit Kategorie-Icon
            Section("Zutaten") {
                // Reduce-Motion: ohne Staffelung direkt anzeigen. Sonst gestaffelt einblenden.
                if reduceMotion {
                    ForEach(recipe.ingredients) { item in ingredientLink(item) }
                } else {
                    StaggeredView {
                        ForEach(ingredientsVisible ? recipe.ingredients : []) { item in
                            ingredientLink(item)
                        }
                    }
                }
                Button {
                    prefs.addToShopping(recipe, scaledBy: scaleFactor)
                    addedToCart = true
                    flashToast(.init(icon: "cart.badge.plus",
                                     title: "Zur Einkaufsliste hinzugefügt",
                                     subTitle: "^[\(recipe.ingredients.count) Zutat](inflect: true)",
                                     tint: .green))
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
        .inlineToast(config: toastConfig, isPresented: showToast)
        .overlay {
            if showTutorial {
                GestureTutorialOverlay(tint: tint) {
                    hasSeenTutorial = true
                    withAnimation(.smooth(duration: 0.25)) { showTutorial = false }
                }
            }
        }
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.large)
        .task {
            if saveState != .saving {
                saveState = SavedRecipeRepository.shared.isSaved(recipe.name) ? .saved : .idle
            }
            // Zutaten gestaffelt einblenden (einmal pro Detailöffnung).
            if !reduceMotion, !ingredientsVisible {
                withAnimation { ingredientsVisible = true }
            }
        }
        .task {
            // Kurz warten, damit die Detailansicht steht, bevor das Tutorial erscheint.
            guard !hasSeenTutorial else { return }
            try? await Task.sleep(for: .seconds(0.45))
            guard !hasSeenTutorial else { return }
            showTutorial = true
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ForEach(Weekday.allCases) { day in
                        Button(day.rawValue) {
                            prefs.addToPlan(recipe.name, day: day)
                            flashToast(.init(icon: "calendar.badge.plus",
                                             title: "Zum Wochenplan hinzugefügt",
                                             subTitle: day.rawValue,
                                             tint: .orange))
                        }
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
    var factor: Double = 1

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
                Text(item.formatted(scaledBy: factor))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack { Rezepte(recipe: .mock) }
}
