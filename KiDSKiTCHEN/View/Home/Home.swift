//
//  Home.swift
//  KiDSKiTCHEN
//
//  Rezeptliste im Kids-Modus: Hero-Banner + horizontale Kategorie-Chips zum Stöbern,
//  darunter die Rezepte in Abschnitten mit KLEBENDEN Kategorie-Headern (Food-App-Stil).
//  UI-Muster nach Kavsoft „StickyHeaderList" portiert und an KidsKitchen angepasst
//  (native List-Sticky-Sections; Hero als Verlaufs-Banner, da Bilder extern entstehen).
//  (Vormals vier umschaltbare Modi — auf Kids reduziert, 6.7.)
//

import SwiftUI

// MARK: - Home
struct Home: View {
    @State private var viewModel: RecipeListViewModel = .shared
    @State private var prefs: Preferences = .shared
    @State private var search = ""
    @State private var favoritesOnly = false
    @State private var pantryOnly = false
    @State private var kidsCat: RecipeCategory? = nil

    private var filtered: [Recipe] {
        viewModel.recipes.filter { recipe in
            (search.isEmpty || recipe.name.localizedStandardContains(search))
            && recipe.fits(prefs.diet)
            && !recipe.containsExcluded(prefs.excluded)
            && (!favoritesOnly || prefs.isFavorite(recipe.name))
            && (!pantryOnly || prefs.pantryCoverage(recipe) >= 1.0)
            && (kidsCat == nil || recipe.category == kidsCat)
        }
    }

    /// Gefilterte Rezepte nach Kategorie gruppiert (leere Kategorien fallen weg),
    /// in fester RecipeCategory-Reihenfolge; Rezepte ohne Kategorie am Ende.
    private var sections: [(category: RecipeCategory?, recipes: [Recipe])] {
        let all = filtered
        var result: [(RecipeCategory?, [Recipe])] = []
        for cat in RecipeCategory.allCases {
            let items = all.filter { $0.category == cat }
            if !items.isEmpty { result.append((cat, items)) }
        }
        let uncategorized = all.filter { $0.category == nil }
        if !uncategorized.isEmpty { result.append((nil, uncategorized)) }
        return result
    }

    var body: some View {
        List {
            // Hero-Banner (scrollt mit weg) — echtes UI-Element, kein Bildplatzhalter.
            HeroBanner()
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 6, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

            // Kategorie-Chips (horizontal) — behalten das bisherige Filter-Verhalten.
            categoryChips
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 6, trailing: 0))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

            if filtered.isEmpty {
                ContentUnavailableView(
                    viewModel.recipes.isEmpty ? "Noch keine Rezepte" : "Nichts gefunden",
                    systemImage: viewModel.recipes.isEmpty ? "frying.pan" : "magnifyingglass",
                    description: Text(viewModel.recipes.isEmpty
                        ? "Leg dein erstes Rezept an."
                        : "Kein Rezept passt zu Suche und Filtern.")
                )
                .padding(.top, 40)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            } else {
                ForEach(sections, id: \.category) { section in
                    Section {
                        ForEach(section.recipes) { recipe in
                            NavigationLink { Rezepte(recipe: recipe) } label: {
                                KidsRecipeRow(recipe: recipe,
                                             isFavorite: prefs.isFavorite(recipe.name))
                            }
                            .buttonStyle(.plain)
                            .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .leading) {
                                Button { prefs.toggleFavorite(recipe.name) } label: {
                                    Label("Favorit",
                                          systemImage: prefs.isFavorite(recipe.name)
                                            ? "heart.slash" : "heart")
                                }
                                .tint(.pink)
                            }
                        }
                    } header: {
                        CategoryHeader(category: section.category)
                    }
                }
            }
        }
        .listStyle(.plain)
        .listRowSpacing(0)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("KidsKitchen")
        .task { await viewModel.loadRecipes() }
        .searchable(text: $search, prompt: "Rezept suchen")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { filterMenu }
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    NewRecipe(newRecipe: .emptyMock)
                } label: { Image(systemName: "plus") }
            }
        }
    }

    // MARK: Kategorie-Chips
    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(RecipeCategory.allCases) { cat in
                    KidsCatButton(cat: cat, selected: kidsCat == cat) {
                        withAnimation(.spring(response: 0.3)) {
                            kidsCat = kidsCat == cat ? nil : cat
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
    }

    // MARK: Toolbar
    private var filterActive: Bool {
        prefs.diet != .all || !prefs.excluded.isEmpty || favoritesOnly || pantryOnly
    }

    private var filterMenu: some View {
        Menu {
            Picker("Diät", selection: $prefs.diet) {
                ForEach(DietMode.allCases) {
                    Label($0.rawValue, systemImage: $0.symbolName).tag($0)
                }
            }
            Toggle(isOn: $favoritesOnly) { Label("Nur Favoriten", systemImage: "heart") }
            Toggle(isOn: $pantryOnly) { Label("Aus Vorrat kochbar", systemImage: "checklist") }
        } label: {
            Label("Filter", systemImage: filterActive
                  ? "line.3.horizontal.decrease.circle.fill"
                  : "line.3.horizontal.decrease.circle")
        }
    }
}

// MARK: - Hero-Banner
private struct HeroBanner: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [.orange, .pink.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Image(systemName: "fork.knife")
                .font(.system(size: 88))
                .foregroundStyle(.white.opacity(0.18))
                .offset(x: 18, y: 8)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text("Was kochen wir heute?")
                    .font(.system(.title2, design: .serif).bold())
                Text("Tipp eine Kategorie an oder stöber los.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
            }
            .foregroundStyle(.white)
            .padding(18)
        }
        .frame(height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .orange.opacity(0.25), radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Klebender Kategorie-Header
private struct CategoryHeader: View {
    let category: RecipeCategory?

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: category?.symbolName ?? "fork.knife")
                .font(.subheadline)
                .foregroundStyle(category?.color ?? .orange)
            Text(category?.rawValue ?? "Sonstiges")
                .font(.system(.title3, design: .serif).bold())
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGroupedBackground))
        .listRowInsets(EdgeInsets())
    }
}

// MARK: - Kids sub-views

private struct KidsCatButton: View {
    let cat: RecipeCategory
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(selected ? cat.color : cat.color.opacity(0.14))
                        .frame(width: 62, height: 62)
                    Image(systemName: cat.symbolName)
                        .font(.title2)
                        .foregroundStyle(selected ? .white : cat.color)
                }
                Text(cat.rawValue)
                    .font(.caption.bold())
                    .foregroundStyle(selected ? cat.color : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: 78)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(selected ? 1.08 : 1)
        .animation(.spring(response: 0.28), value: selected)
    }
}

private struct KidsRecipeRow: View {
    let recipe: Recipe
    let isFavorite: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill((recipe.category?.color ?? .orange).opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: recipe.category?.symbolName ?? "fork.knife")
                    .font(.title2)
                    .foregroundStyle(recipe.category?.color ?? .orange)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(.system(.body, design: .serif).bold())
                    .foregroundStyle(.primary)
                HStack(spacing: 8) {
                    if recipe.totalTime > 0 {
                        Label("\(recipe.totalTime) min", systemImage: "clock")
                    }
                    if let cat = recipe.category { Text(cat.rawValue) }
                }
                .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if isFavorite {
                Image(systemName: "heart.fill").foregroundStyle(.pink).font(.caption)
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    NavigationStack { Home() }
}
