//
//  Home.swift
//  KiDSKiTCHEN
//
//  Rezeptliste im Kids-Modus: Kategorie-Buttons zum Stöbern + Rezept-Reihen.
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

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 94))], spacing: 14) {
                ForEach(RecipeCategory.allCases) { cat in
                    KidsCatButton(cat: cat, selected: kidsCat == cat) {
                        withAnimation(.spring(response: 0.3)) {
                            kidsCat = kidsCat == cat ? nil : cat
                        }
                    }
                }
            }
            .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 4)

            if filtered.isEmpty {
                ContentUnavailableView(
                    viewModel.recipes.isEmpty ? "Noch keine Rezepte" : "Nichts gefunden",
                    systemImage: viewModel.recipes.isEmpty ? "frying.pan" : "magnifyingglass",
                    description: Text(viewModel.recipes.isEmpty
                        ? "Leg dein erstes Rezept an."
                        : "Kein Rezept passt zu Suche und Filtern.")
                )
                .padding(.top, 40)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(filtered) { recipe in
                        NavigationLink { Rezepte(recipe: recipe) } label: {
                            KidsRecipeRow(recipe: recipe,
                                         isFavorite: prefs.isFavorite(recipe.name))
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .leading) {
                            Button { prefs.toggleFavorite(recipe.name) } label: {
                                Label("Favorit",
                                      systemImage: prefs.isFavorite(recipe.name)
                                        ? "heart.slash" : "heart")
                            }
                            .tint(.pink)
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.bottom, 20)
            }
        }
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
            Image(systemName: "chevron.right").foregroundStyle(.tertiary).font(.caption)
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    NavigationStack { Home() }
}
