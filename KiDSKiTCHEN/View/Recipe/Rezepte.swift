//
//  Rezepte.swift
//  KiDSKiTCHEN
//
//  Rezept-Detailansicht: visuelle Nährwertbalken, Zutaten mit Kategorie-Icons,
//  nummerierte Zubereitungsschritte mit farbigen Schritt-Kreisen.
//
//  Container-Umbau 10.7. (Jay §UI-Bauweise): KEIN `List` mehr — KKScroll + KKSection
//  (ScrollView + LazyVStack). Verhalten unverändert (Offline-Speichern, Portionen-Rad,
//  Slide-Abhaken, Toasts, Staffel-Animation). Portionen-Rad sitzt jetzt mit Luft in
//  einer nicht-clippenden Karte (Fix „Halbkreis abgehackt", Jay-Screenshot 10.7.).
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
    @Environment(\.dismiss) private var dismiss

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
        .buttonStyle(.plain)
    }

    var body: some View {
        KKScroll {
            // Großer Titel im Inhalt (Serifen, kindgerecht, mehrzeilig erlaubt).
            // Beim Container-Umbau (W4) landete der Name nur noch in der — dort
            // abgeschnittenen — Navigationsleiste; hier kommt er sichtbar zurück.
            // Die Navigationsleiste bleibt bewusst inline/klein (s. .navigationBarTitleDisplayMode).
            Text(recipe.name)
                .font(.system(.largeTitle, design: .serif).weight(.bold))
                .foregroundStyle(tint)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true) // mehrzeilig statt abgeschnitten
                .accessibilityAddTraits(.isHeader)
                .padding(.horizontal, 4)
                .padding(.top, 4)

            // Beschreibung — lange API-Texte klappen mit „mehr anzeigen" auf.
            if !recipe.details.isEmpty {
                KKCard {
                    ExpandableText(text: recipe.details)
                }
            }

            // Offline speichern — Zustands-Button (echte async-Aktion: läuft → fertig ✓).
            // Bewusst ohne KKCard: der Knopf bringt eigene Fläche/Optik mit.
            AnimatedStateButton(config: saveConfig) {
                guard saveState != .saved else { return }
                withAnimation { saveState = .saving }
                await SavedRecipeRepository.shared.save(recipe)
                withAnimation { saveState = .saved }
            }
            .allowsHitTesting(saveState != .saved)

            // Kurzinfo
            KKSection(title: "Info", systemImage: "info.circle", tint: tint) {
                if let category = recipe.category {
                    // Antippbar (Jay-Entscheid, ChipSelection-Badge): setzt den Home-
                    // Kategorie-Filter und springt zur gefilterten Liste zurück.
                    Button {
                        RecipeCategoryFilter.shared.selected = category
                        dismiss()
                    } label: {
                        CategoryChip(category: category, isSelected: false)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Nach \(category.rawValue) filtern")
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
            // Rad-Clipping-Fix (Jay-Screenshot 10.7.): horizontaler Innenabstand gibt
            // dem Halbkreis Luft; die KKCard clippt nicht → die runden Rad-Enden werden
            // nicht mehr an der Kartenkante abgeschnitten.
            KKSection(title: "Portionen", systemImage: "person.2.fill", tint: tint) {
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
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .accessibilityRepresentation {
                    Stepper("Portionen: \(servings)", value: $servings, in: 1...12)
                }
                if servings != baseServings {
                    Text("Mengen für \(servings) statt \(baseServings) Portionen angepasst.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Nährwerte — visuell (nur zeigen, wenn hinterlegt oder verlässlich berechenbar).
            // Werte sind PRO PORTION und damit unabhängig von der gewählten Portionszahl —
            // sie bleiben bewusst unverändert (keine erfundene Skalierung).
            if let nutrition = recipe.displayNutrition {
                KKSection(title: "Nährwerte", tint: tint, footer: "je Portion") {
                    RecipeNutritionBars(nutrition: nutrition)
                }
            }

            // Zutaten — visuell mit Kategorie-Icon
            KKSection(title: "Zutaten", tint: tint) {
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
                .padding(.top, 4)
            }

            // Zubereitung — Schritt für Schritt, mit kindersicherer Slide-Bestätigung
            if !recipe.instructions.isEmpty {
                // Einstieg in den Kochmodus (Vollansicht, Mini-Leiste über der Tabbar).
                Button {
                    KKCookingSession.shared.start(recipe)
                } label: {
                    Label("Kochen starten", systemImage: "flame.fill")
                        .font(.system(.headline, design: .serif))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(tint)
                .controlSize(.large)

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
        // Kein Leisten-Titel mehr: der große Serifen-Titel steht im Inhalt (W6 Teil A),
        // die durchsichtige Leiste zeigt nur noch Zurück-Knopf + Aktionen — sonst
        // stünde der Name doppelt da (Gerätetest-Bild 11.7.).
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .kkTransparentNavBar()
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
                            prefs.addToPlan(recipe.name, day: day, week: .kkWeekStart())
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
        KKSection(title: "Zubereitung", systemImage: "list.number", tint: tint) {
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
            // Echtes freigestelltes Zutat-Foto (Bilder-Einbau/Mapping 11.7.); ohne
            // Treffer bleibt das getönte Kategorie-Symbol als Fallback (IngredientImageView).
            IngredientImageView(ingredient: item.ingredient, size: 40)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.ingredient.name)
                    .font(.system(.body, design: .serif))
                Text(item.formatted(scaledBy: factor))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }
            Spacer()
            // Tap-Affordanz statt der früheren List-Disclosure — Zeile führt in die
            // Zutat-Detailansicht.
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack { Rezepte(recipe: .mock) }
}
