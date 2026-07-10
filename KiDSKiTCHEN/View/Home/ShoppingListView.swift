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

import SwiftUI

struct ShoppingListView: View {
    @State private var prefs: Preferences = .shared
    /// Aktive Kategorie-Filter (leer = alles zeigen). Mehrfachauswahl.
    @State private var selectedCategories: [IngredientCategory] = []

    /// Kategorien, die in der Liste tatsächlich vorkommen — in kanonischer
    /// Reihenfolge (echte Einkaufslisten-Kategorien).
    private var presentCategories: [IngredientCategory] {
        let present = Set(prefs.shopping.map(\.resolvedCategory))
        return IngredientCategory.allCases.filter { present.contains($0) }
    }

    private func isVisible(_ item: ShoppingItem) -> Bool {
        selectedCategories.isEmpty || selectedCategories.contains(item.resolvedCategory)
    }

    var body: some View {
        KKScroll {
            if prefs.shopping.isEmpty {
                KKCard {
                    ContentUnavailableView(
                        "Einkaufsliste ist leer",
                        systemImage: "cart",
                        description: Text("Füge Zutaten aus einem Rezept hinzu.")
                    )
                }
                .padding(.top, 40)
            } else {
                // Kategorie-Filter — nur zeigen, wenn es mehr als eine Kategorie gibt
                if presentCategories.count > 1 {
                    ChipsView(tags: presentCategories) { category, isSelected in
                        CategoryChip(category: category, isSelected: isSelected)
                    } didChangeSelection: { selection in
                        selectedCategories = selection
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 4)
                }

                ForEach($prefs.shopping) { $item in
                    if isVisible(item) {
                    KKCard {
                        HStack(spacing: 10) {
                            Button {
                                item.done.toggle()
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: item.done ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                        .foregroundStyle(item.done ? .green : .secondary)
                                    Text(item.text)
                                        .strikethrough(item.done)
                                        .foregroundStyle(item.done ? .secondary : .primary)
                                    Spacer(minLength: 8)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(item.text)
                            .accessibilityValue(item.done ? "abgehakt" : "offen")
                            .accessibilityHint("Zum Abhaken tippen")

                            KKDeleteButton(accessibilityLabel: "\(item.text) löschen") {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    prefs.shopping.removeAll { $0.id == item.id }
                                }
                            }
                        }
                    }
                    }
                }
            }
        }
        .navigationTitle("Einkaufsliste")
        .toolbar {
            if prefs.shopping.contains(where: \.done) {
                ToolbarItem(placement: .primaryAction) {
                    Button("Erledigte löschen") { prefs.clearDoneShopping() }
                }
            }
        }
    }
}

// MARK: - CategoryChip
/// Kindgerechter Kategorie-Chip (Serifen, de_DE). Gefüllt in Kategoriefarbe,
/// wenn ausgewählt — sichtbare Bedienung statt versteckter Filter.
private struct CategoryChip: View {
    let category: IngredientCategory
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: category.symbolName)
                .font(.footnote)
            Text(category.title)
                .font(.system(.subheadline, design: .serif).weight(.medium))
        }
        .foregroundStyle(isSelected ? .white : category.color)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            isSelected ? category.color : category.color.opacity(0.14),
            in: .capsule
        )
        .overlay(
            Capsule().strokeBorder(category.color.opacity(isSelected ? 0 : 0.35), lineWidth: 1)
        )
        .accessibilityLabel(category.title)
        .accessibilityValue(isSelected ? "Filter aktiv" : "Filter aus")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    NavigationStack { ShoppingListView() }
}
