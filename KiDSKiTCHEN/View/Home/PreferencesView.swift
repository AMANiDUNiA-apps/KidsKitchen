//
//  PreferencesView.swift
//  KiDSKiTCHEN
//
//  Created by Claude Fable 5 on 03.07.26.
//  Jays „Onboarding über Ausschluss": Diät wählen + einzelne Zutaten ausschließen.
//  Beides filtert die Rezeptliste. Zutaten kategorieweise, mit Suche.
//
//  UI-Bauweise (Jay 10.7.): selbstgebaute Container statt `List` — KKScroll + KKSection.
//

import SwiftUI

struct PreferencesView: View {
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
        KKScroll {
            KKSection(title: "Diät", systemImage: "leaf") {
                Picker("Diät", selection: $prefs.diet) {
                    ForEach(DietMode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
            }

            if !prefs.excluded.isEmpty {
                KKSection(title: "Ausgeschlossen (\(prefs.excluded.count))",
                          systemImage: "minus.circle", tint: .red) {
                    ForEach(prefs.excluded.sorted(), id: \.self) { name in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { prefs.toggleExcluded(name) }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                                Text(name).foregroundStyle(.primary)
                                Spacer(minLength: 8)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(name), ausgeschlossen")
                        .accessibilityHint("Zum Wiederzulassen tippen")
                    }
                }
            }

            ForEach(sections, id: \.category) { section in
                KKSection(title: section.category.title,
                          systemImage: section.category.symbolName,
                          tint: section.category.color) {
                    ForEach(section.items) { ingredient in
                        let isExcluded = prefs.excluded.contains(ingredient.name)
                        Button {
                            prefs.toggleExcluded(ingredient.name)
                        } label: {
                            HStack {
                                Text(ingredient.name).foregroundStyle(.primary)
                                Spacer(minLength: 8)
                                if isExcluded {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.red)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityValue(isExcluded ? "ausgeschlossen" : "erlaubt")
                    }
                }
            }
        }
        .navigationTitle("Filter & Diät")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $search, prompt: "Zutat suchen")
    }
}

#Preview {
    NavigationStack { PreferencesView() }
}
