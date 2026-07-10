//
//  Home.swift
//  KiDSKiTCHEN
//
//  Rezeptliste im Kids-Modus: Hero-Banner + horizontale Kategorie-Chips zum Stöbern,
//  darunter die Rezepte in Abschnitten mit KLEBENDEN Kategorie-Headern (Food-App-Stil).
//  UI-Muster nach Kavsoft „StickyHeaderList" portiert und an KidsKitchen angepasst.
//  (Vormals vier umschaltbare Modi — auf Kids reduziert, 6.7.)
//
//  Container-Umbau 10.7. (Jay §UI-Bauweise): KEIN `List` mehr — ScrollView +
//  LazyVStack(pinnedViews: [.sectionHeaders]) trägt die klebenden Kategorie-Header
//  selbst; die Rezepte sitzen in eigenen KKCard/Row-Karten. Favorisieren früher per
//  Leading-Swipe (List-only) → jetzt sichtbarer Herz-Knopf auf der Karte.
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
    @State private var weekCarouselIndex = 0

    /// True im normalen Stöber-Zustand (keine Suche/Filter aktiv) — nur dann zeigt
    /// Home das Wochen-Karussell, damit es das gefilterte Blättern nicht überlagert.
    private var isBrowsingDefault: Bool {
        search.isEmpty && kidsCat == nil && !favoritesOnly && !pantryOnly
    }

    /// Ehrliche Wochen-Rotation: deterministisch aus der Kalenderwoche über den
    /// echten Rezeptbestand (der zur Diät passt und nichts Ausgeschlossenes enthält).
    /// Keine „Empfehlungs-KI" — dieselbe Woche ergibt immer dieselbe Auswahl, und
    /// die Auswahl wandert Woche für Woche weiter.
    private var weeklyPicks: [Recipe] {
        let pool = viewModel.recipes.filter {
            $0.fits(prefs.diet) && !$0.containsExcluded(prefs.excluded)
        }
        guard !pool.isEmpty else { return [] }
        let ordered = pool.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        let week = Calendar(identifier: .gregorian).component(.weekOfYear, from: .now)
        let start = week % ordered.count
        let count = min(5, ordered.count)
        return (0..<count).map { ordered[(start + $0) % ordered.count] }
    }

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
        ScrollView {
            // Selbstgebauter Container: klebende Kategorie-Header über pinnedViews,
            // kein List-Verhalten. Hero + Chips scrollen als normale Zeilen mit weg.
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                // Hero-Banner (scrollt mit weg) — echtes UI-Element, kein Bildplatzhalter.
                HeroBanner()
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 6)

                // Kategorie-Chips (horizontal) — behalten das bisherige Filter-Verhalten.
                categoryChips
                    .padding(.top, 4)
                    .padding(.bottom, 6)

                // Wochen-Karussell (Teil D) — nur im normalen Stöber-Zustand.
                if isBrowsingDefault && weeklyPicks.count >= 2 {
                    weeklySpotlight
                        .padding(.bottom, 4)
                }

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
                    ForEach(sections, id: \.category) { section in
                        Section {
                            ForEach(section.recipes) { recipe in
                                NavigationLink { Rezepte(recipe: recipe) } label: {
                                    KidsRecipeRow(recipe: recipe)
                                }
                                .buttonStyle(.plain)
                                // Herz-Knopf als eigener Tap-Bereich NEBEN dem Link
                                // (Overlay statt verschachtelter Button → zuverlässig
                                //  tippbar). Ersetzt den früheren List-Leading-Swipe.
                                .overlay(alignment: .trailing) {
                                    FavoriteButton(
                                        isFavorite: prefs.isFavorite(recipe.name),
                                        action: {
                                            withAnimation(.spring(response: 0.3)) {
                                                prefs.toggleFavorite(recipe.name)
                                            }
                                        }
                                    )
                                    .padding(.trailing, 22)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 5)
                            }
                        } header: {
                            CategoryHeader(category: section.category)
                        }
                    }
                }
            }
            .padding(.bottom, 16)
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

    // MARK: Wochen-Karussell (Teil D)
    private var weeklySpotlight: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("Diese Woche")
                    .font(.system(.title3, design: .serif).bold())
                Spacer(minLength: 8)
                Label("wechselt jede Woche", systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .labelStyle(.titleAndIcon)
            }
            .padding(.horizontal, 20)

            KKCarousel(activeIndex: $weekCarouselIndex) {
                ForEach(weeklyPicks) { recipe in
                    NavigationLink { Rezepte(recipe: recipe) } label: {
                        WeeklyCard(recipe: recipe)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(height: 150)

            // Punkt-Indikator (spiegelt die sichtbare Seite).
            HStack(spacing: 6) {
                ForEach(weeklyPicks.indices, id: \.self) { i in
                    Circle()
                        .fill(i == weekCarouselIndex ? Color.orange : Color.secondary.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)
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
        // Deckt beim Kleben (pinnedViews) den durchscrollenden Inhalt zu.
        .background(Color(.systemGroupedBackground))
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
            // Platz für den Herz-Knopf, den die Home-Ebene als Overlay einblendet.
            Color.clear.frame(width: 34, height: 34)
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Wochen-Karten
/// Farbige Vorschlags-Karte fürs Wochen-Karussell. Noch ohne Foto (die
/// Zutaten-/Rezept-Bilder kommen aus der macMini-Pipeline) — nutzt bis dahin
/// Kategorie-Farbe + Symbol, kein Bildplatzhalter.
private struct WeeklyCard: View {
    let recipe: Recipe

    var body: some View {
        let color = recipe.category?.color ?? .orange
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(.white.opacity(0.25)).frame(width: 74, height: 74)
                Image(systemName: recipe.category?.symbolName ?? "fork.knife")
                    .font(.system(size: 34))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(recipe.category?.rawValue ?? "Rezept")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.9))
                Text(recipe.name)
                    .font(.system(.title3, design: .serif).bold())
                    .foregroundStyle(.white)
                    .lineLimit(2)
                if recipe.totalTime > 0 {
                    Label("\(recipe.totalTime) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [color, color.opacity(0.7)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: color.opacity(0.25), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(recipe.name), \(recipe.category?.rawValue ?? "Rezept")")
    }
}

// MARK: - Favoriten-Knopf
/// Sichtbarer, direkt tippbarer Herz-Knopf auf der Rezeptkarte (ersetzt den früheren
/// List-Leading-Swipe, der außerhalb von `List` nicht existiert).
private struct FavoriteButton: View {
    let isFavorite: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.title3)
                .foregroundStyle(.pink)
                .frame(width: 34, height: 34)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isFavorite ? "Aus Favoriten entfernen" : "Zu Favoriten")
    }
}

#Preview {
    NavigationStack { Home() }
}
