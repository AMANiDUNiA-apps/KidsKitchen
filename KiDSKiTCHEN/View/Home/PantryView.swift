//
//  PantryView.swift
//  KiDSKiTCHEN
//
//  Created by Claude Fable 5 on 03.07.26.
//  Vorratsschrank: was habe ich zu Hause? Grundlage für „Was kann ich kochen?"
//  (Home-Filter) und für die Einkaufsliste (nur Fehlendes).
//

import SwiftUI

struct PantryView: View {
    @State private var prefs: Preferences = .shared
    @State private var search = ""

    private var sections: [(category: IngredientCategory, items: [Ingredient])] {
        IngredientCategory.allCases.compactMap { category in
            let items = Ingredient.seed
                .filter { $0.category == category }
                .filter { search.isEmpty || $0.name.localizedStandardContains(search) }
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            return items.isEmpty ? nil : (category, items)
        }
    }

    var body: some View {
        List {
            if !prefs.pantry.isEmpty {
                Section("Im Vorrat (\(prefs.pantry.count))") {
                    ForEach(prefs.pantry.sorted(), id: \.self) { name in
                        Button {
                            prefs.togglePantry(name)
                        } label: {
                            Label(name, systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
            }

            ForEach(sections, id: \.category) { section in
                Section(section.category.title) {
                    ForEach(section.items) { ingredient in
                        Button {
                            prefs.togglePantry(ingredient.name)
                        } label: {
                            HStack {
                                Text(ingredient.name).foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: prefs.pantry.contains(ingredient.name)
                                      ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(prefs.pantry.contains(ingredient.name) ? .green : .secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationTitle("Vorratsschrank")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $search, prompt: "Zutat suchen")
    }
}

#Preview {
    NavigationStack { PantryView() }
}
