//
//  ShoppingListView.swift
//  KiDSKiTCHEN
//
//  Created by Claude Fable 5 on 03.07.26.
//  Einkaufsliste: aus Rezepten gesammelte Zutaten, abhakbar, persistent.
//
//  UI-Bauweise (Jay 10.7.): selbstgebaute Container statt `List` — KKScroll + KKCard.
//  Abhaken (Tippen aufs Häkchen) und ein sichtbarer Lösch-Knopf pro Zeile
//  (KKDeleteButton, Jay 11.7. Herz-Knopf-Referenz) — kein verstecktes Wischen.
//  Einzelposten sind geringwertig/wiederherstellbar → Löschen direkt, ohne Abfrage;
//  „Erledigte löschen" bleibt als Sammel-Aktion in der Toolbar.
//
//  Weiterbau 8, Teil A: Bedarf aus dem Wochenplan gegen den Vorrat rechnen. Was
//  fehlt, kommt als klar erkennbarer Vorschlags-Posten (mit Herkunft) dazu — Hand-
//  Einträge bleiben unangetastet. Abhaken eines Vorschlags bucht die Menge in den
//  Vorrat (setShoppingDone).
//

import SwiftUI

struct ShoppingListView: View {
    @State private var prefs: Preferences = .shared
    @State private var viewModel: RecipeListViewModel = .shared
    /// Aktive Kategorie-Filter (leer = alles zeigen). Mehrfachauswahl.
    @State private var selectedCategories: [IngredientCategory] = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    // Rückgängig/Wiederholen fürs Löschen einzelner Posten (Jay 17.7.).
    @Environment(\.undoManager) private var undoManager

    /// Kategorien, die in der Liste tatsächlich vorkommen — in kanonischer
    /// Reihenfolge (echte Einkaufslisten-Kategorien).
    private var presentCategories: [IngredientCategory] {
        let present = Set(prefs.shopping.map(\.resolvedCategory))
        return IngredientCategory.allCases.filter { present.contains($0) }
    }

    private func isVisible(_ item: ShoppingItem) -> Bool {
        selectedCategories.isEmpty || selectedCategories.contains(item.resolvedCategory)
    }

    /// Offener Nachkauf-Bedarf aus dem Wochenplan (für den Bedarf-Knopf).
    private var shortfallCount: Int { prefs.shortfallCount(recipes: viewModel.recipes) }

    var body: some View {
        KKScroll {
            // Bedarf aus dem Wochenplan berechnen — nur wenn überhaupt geplant ist.
            if prefs.plannedCount > 0 {
                needBanner
                    .padding(.horizontal, 4)
            }

            if prefs.shopping.isEmpty {
                KKCard {
                    ContentUnavailableView(
                        "Einkaufsliste ist leer",
                        systemImage: "cart",
                        description: Text("Füge Zutaten aus einem Rezept hinzu — oder berechne den Bedarf aus deinem Wochenplan.")
                    )
                }
                .padding(.top, 24)
            } else {
                // Kategorie-Filter — nur zeigen, wenn es mehr als eine Kategorie gibt
                if presentCategories.count > 1 {
                    CategoryFilterChips(categories: presentCategories) { selection in
                        selectedCategories = selection
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 4)
                }

                ForEach($prefs.shopping) { $item in
                    if isVisible(item) {
                        KKCard {
                            shoppingRow($item)
                        }
                    }
                }
            }
        }
        .navigationTitle("Einkaufsliste")
        .kkTransparentNavBar()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                KKUndoRedoButton(undoManager: undoManager)
            }
            if prefs.shopping.contains(where: \.done) {
                ToolbarItem(placement: .primaryAction) {
                    Button("Erledigte löschen") { prefs.clearDoneShopping() }
                }
            }
        }
    }

    // MARK: Löschen mit Rückgängig/Wiederholen
    // Symmetrisch registriert: jede Rückgängig-Aktion registriert beim Ausführen
    // gleich wieder ihr Gegenstück, sonst würde Wiederholen (Redo) nach einem
    // Undo nicht mehr funktionieren (Kavsoft „UndoHelper"-Prinzip).
    private func deleteShoppingItem(_ item: ShoppingItem) {
        prefs.shopping.removeAll { $0.id == item.id }
        registerRestoreUndo(item)
        undoManager?.setActionName("Eintrag löschen")
    }

    private func registerRestoreUndo(_ item: ShoppingItem) {
        undoManager?.registerUndo(withTarget: prefs) { target in
            target.shopping.append(item)
            registerDeleteUndo(item)
        }
    }

    private func registerDeleteUndo(_ item: ShoppingItem) {
        undoManager?.registerUndo(withTarget: prefs) { target in
            target.shopping.removeAll { $0.id == item.id }
            registerRestoreUndo(item)
        }
    }

    // MARK: Bedarf-Knopf (Teil A)
    private var needBanner: some View {
        Button {
            withAnimation(.snappy(duration: 0.25)) {
                _ = prefs.refreshShoppingSuggestions(recipes: viewModel.recipes)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Bedarf aus dem Wochenplan")
                        .font(.system(.subheadline, design: .serif).weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(shortfallCount == 0
                         ? "Alles im Vorrat — nichts nachzukaufen."
                         : "\(shortfallCount) Zutat\(shortfallCount == 1 ? "" : "en") fehlt — als Vorschlag eintragen.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Image(systemName: "arrow.clockwise")
                    .font(.footnote.bold())
                    .foregroundStyle(.orange)
            }
            .padding(14)
            .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Bedarf aus dem Wochenplan berechnen")
        .accessibilityValue(shortfallCount == 0 ? "nichts nachzukaufen" : "\(shortfallCount) Zutaten fehlen")
    }

    // MARK: Zeile
    @ViewBuilder
    private func shoppingRow(_ item: Binding<ShoppingItem>) -> some View {
        let value = item.wrappedValue
        HStack(spacing: 10) {
            Button {
                prefs.setShoppingDone(value.id, done: !value.done)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: value.done ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(value.done ? .green : .secondary)
                        // Abhaken-Feedback (Teil D): weiches Kreis→Haken-Wechseln
                        // + kleiner Bounce, aus/ein je Reduce Motion.
                        .contentTransition(.symbolEffect(.replace))
                        .symbolEffect(.bounce, value: reduceMotion ? false : value.done)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(value.text)
                            .strikethrough(value.done)
                            .foregroundStyle(value.done ? .secondary : .primary)
                        // Vorschlags-Herkunft klar erkennbar (Teil A).
                        if value.suggested, let origin = value.origin {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles").font(.caption2)
                                Text(origin).lineLimit(1)
                            }
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        }
                    }
                    Spacer(minLength: 8)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(value.text)
            .accessibilityValue(value.done ? "abgehakt" : "offen")
            .accessibilityHint(value.booksIntoPantry
                               ? "Zum Abhaken tippen — die Menge wandert in den Vorrat"
                               : "Zum Abhaken tippen")

            KKDeleteButton(accessibilityLabel: "\(value.text) löschen") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    deleteShoppingItem(value)
                }
            }
        }
    }
}

#Preview {
    NavigationStack { ShoppingListView() }
}
