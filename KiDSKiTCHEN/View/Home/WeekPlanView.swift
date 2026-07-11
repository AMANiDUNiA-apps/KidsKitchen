//
//  WeekPlanView.swift
//  KiDSKiTCHEN
//
//  Created by Claude Fable 5 on 03.07.26.
//  Wochenplaner: je Wochentag geplante Rezepte, heutiger Tag hervorgehoben.
//  Rezepte werden aus der Detailansicht („Zum Wochenplan") hinzugefügt.
//
//  Weiterbau 4, Teil C — Wochenansicht mit gepinnten Tages-Headern und einem
//  Wochenstreifen, der mit der Scrollposition mitläuft. Vorlage: Kavsoft
//  „CalendarScrollEffect" (Balaji Venkatesh) — pinnedViews-Sticky-Header +
//  scrollPosition-Sync, hier auf das echte Weekday/Plan-Modell adaptiert
//  (deutsche Wochentage, KEINE erfundenen Kalender-Termine).
//
//  UI-Bauweise (Jay 10.7.): selbstgebaute Container statt `List`. Entfernen als
//  sichtbarer Lösch-Knopf (Jay 11.7., Herz-Knopf-Referenz).
//
//  Weiterbau 7, Teil B: „+" im Tages-Header öffnet ein inhaltshohes Sheet
//  (Kavsoft „DynamicHeightSheet", s. KKDynamicSheet), um dem Tag ein echtes Rezept
//  zuzuordnen (prefs.addToPlan) — kompakt statt Vollbild.
//

import SwiftUI

struct WeekPlanView: View {
    @State private var prefs: Preferences = .shared
    @State private var viewModel: RecipeListViewModel = .shared
    /// Tag, dem gerade ein Rezept zugeordnet wird (Hinzufügen-Sheet, Teil B).
    @State private var addTarget: Weekday?
    /// Tag, für den gerade Koch-Vorschläge aus dem Vorrat gezeigt werden (Teil C).
    @State private var cookTarget: Weekday?
    // Startet oben am Wochenanfang (Montag) — der Streifen spiegelt so von Anfang an
    // die echte Scrollposition. „Heute" bleibt über Badge + Punkt klar markiert.
    // (Auto-Scroll-zu-heute bewusst weggelassen: bei LazyVStack nicht verlässlich
    //  ohne Klick-Test verifizierbar, und der Streifen würde sonst desynchron wirken.)
    @State private var selectedDay: Weekday? = Weekday.allCases.first
    /// Aktive Kategorie-Filter nach Mahlzeit-Art (leer = alles zeigen).
    @State private var selectedCategories: [RecipeCategory] = []
    @Namespace private var stripNamespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            weekStrip

            // Kategorie-Filter (Mahlzeit-Art) — nur real geplante Kategorien, ab zwei.
            if presentCategories.count > 1 {
                CategoryFilterChips(categories: presentCategories) { selection in
                    selectedCategories = selection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .background(Color(.systemGroupedBackground))
            }

            GeometryReader { geo in
                ScrollView(.vertical) {
                    // Native pinned section headers erzeugen den Klebe-Effekt (Kavsoft).
                    LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                        ForEach(Weekday.allCases) { day in
                            Section {
                                dayContent(day)
                                    // Der letzte Tag braucht Resthöhe, damit er beim
                                    // Antippen ganz nach oben scrollen kann.
                                    .frame(minHeight: day == Weekday.allCases.last ? geo.size.height - 120 : nil,
                                           alignment: .top)
                            } header: {
                                dayHeader(day)
                            }
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .scrollPosition(id: $selectedDay, anchor: .top)
                .background(Color(.systemGroupedBackground))
            }
        }
        .navigationTitle("Wochenplan")
        .kkTransparentNavBar()
        .navigationBarTitleDisplayMode(.inline)
        .animation(.snappy(duration: 0.25), value: selectedDay)
        .sheet(item: $addTarget) { day in
            KKDynamicSheet(animation: .snappy(duration: 0.3, extraBounce: 0)) {
                AddRecipeToDaySheet(day: day)
            }
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $cookTarget) { day in
            CookableSuggestionsView(day: day)
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: Wochenstreifen (springt zum Tag, folgt der Scrollposition)
    private var weekStrip: some View {
        HStack(spacing: 0) {
            ForEach(Weekday.allCases) { day in
                let isSelected = day == selectedDay
                VStack(spacing: 4) {
                    Text(day.short)
                        .font(.caption.bold())
                        .foregroundStyle(isSelected ? .white : .secondary)
                    if day == Weekday.today {
                        Circle()
                            .fill(isSelected ? Color.white : Color.orange)
                            .frame(width: 5, height: 5)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(.orange)
                            .matchedGeometryEffect(id: "selectedDay", in: stripNamespace)
                            .padding(.horizontal, 4)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.snappy(duration: 0.25)) { selectedDay = day }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(day.rawValue + (day == Weekday.today ? ", heute" : ""))
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: Gepinnter Tages-Header
    private func dayHeader(_ day: Weekday) -> some View {
        HStack(spacing: 8) {
            Text(day.rawValue)
                .font(.system(.title3, design: .serif).bold())
                .foregroundStyle(.primary)
            if day == Weekday.today {
                Text("heute")
                    .font(.caption2.bold())
                    .padding(.horizontal, 6).padding(.vertical, 1)
                    .background(.tint, in: Capsule())
                    .foregroundStyle(.white)
            }
            Spacer(minLength: 0)
            let count = visibleNames(day).count
            if count > 0 {
                Text("\(count)")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            // Rezept diesem Tag zuordnen (öffnet das inhaltshohe Sheet, Teil B).
            Button {
                addTarget = day
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Rezept zu \(day.rawValue) hinzufügen")
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        // Deckt beim Kleben den durchscrollenden Inhalt zu.
        .background(Color(.systemGroupedBackground))
        // Header bleibt Überschrift, „+" ist ein eigenständiges Bedienelement.
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: Tages-Inhalt
    @ViewBuilder
    private func dayContent(_ day: Weekday) -> some View {
        let names = visibleNames(day)
        KKCard {
            if names.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(selectedCategories.isEmpty ? "nichts geplant" : "nichts in dieser Auswahl")
                        .foregroundStyle(.tertiary)
                        .font(.subheadline)
                    // Einstieg „Was kann ich kochen?" (Teil C) — nur an wirklich
                    // leeren Tagen, nicht wenn nur der Filter leert.
                    if selectedCategories.isEmpty {
                        Button {
                            cookTarget = day
                        } label: {
                            Label("Was kann ich kochen?", systemImage: "sparkles")
                                .font(.system(.subheadline, design: .serif).weight(.medium))
                                .foregroundStyle(.orange)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Zeigt Rezepte, die zu deinem Vorrat passen, und ordnet sie \(day.rawValue) zu")
                    }
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(names.enumerated()), id: \.element) { index, name in
                        if index > 0 { Divider() }
                        planRow(name: name, day: day)
                            // Neu zugeordnetes Rezept (Teil B/„+"-Sheet) ploppt sanft
                            // hinein (Teil D). Reduce Motion → nur Einblenden.
                            .transition(reduceMotion
                                        ? .opacity
                                        : .scale(scale: 0.85).combined(with: .opacity))
                    }
                }
            }
        }
    }

    // MARK: Zeile
    @ViewBuilder
    private func planRow(name: String, day: Weekday) -> some View {
        let resolved = recipe(named: name)
        let cooked = prefs.isCooked(day, name)
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                // Gekocht-Knopf (Teil B): bucht die Zutaten vom Vorrat ab.
                if let recipe = resolved {
                    cookButton(recipe: recipe, day: day, cooked: cooked)
                }

                if let recipe = resolved {
                    NavigationLink { Rezepte(recipe: recipe) } label: {
                        HStack {
                            Text(name).font(.system(.body, design: .serif))
                                .strikethrough(cooked)
                                .foregroundStyle(cooked ? .secondary : .primary)
                            Spacer(minLength: 8)
                            Image(systemName: "chevron.right")
                                .font(.footnote.bold())
                                .foregroundStyle(.tertiary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(name).foregroundStyle(.secondary)
                    Spacer(minLength: 8)
                }
                KKDeleteButton(accessibilityLabel: "\(name) aus \(day.rawValue) entfernen") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        prefs.removeFromPlan(name, day: day)
                    }
                }
            }

            // Ehrlicher Hinweis, wenn beim Kochen Zutaten nicht im Vorrat waren.
            if cooked, let recipe = resolved {
                let missing = prefs.cookMissingNames(day, recipe: recipe)
                if !missing.isEmpty {
                    Label(missing.count == 1
                          ? "\(missing[0]) war nicht im Vorrat"
                          : "\(missing.count) Zutaten waren nicht im Vorrat",
                          systemImage: "exclamationmark.circle")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 42)
                }
            }
        }
        .padding(.vertical, 4)
    }

    /// Runder Gekocht-Umschalter — leerer Kreis → grüner Haken mit kleinem Bounce
    /// (W7-D-Muster, Reduce-Motion-sicher).
    private func cookButton(recipe: Recipe, day: Weekday, cooked: Bool) -> some View {
        Button {
            withAnimation(.snappy(duration: 0.25)) {
                if cooked { prefs.unmarkCooked(day, recipe: recipe) }
                else { prefs.markCooked(day, recipe: recipe) }
            }
        } label: {
            Image(systemName: cooked ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(cooked ? .green : .secondary)
                .contentTransition(.symbolEffect(.replace))
                .symbolEffect(.bounce, value: reduceMotion ? false : cooked)
                .frame(width: 34, height: 34)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(recipe.name) gekocht")
        .accessibilityValue(cooked ? "gekocht, Vorrat abgebucht" : "noch nicht gekocht")
        .accessibilityHint(cooked ? "Zum Zurücknehmen tippen" : "Zum Abhaken tippen — die Zutaten werden vom Vorrat abgebucht")
    }

    private func recipe(named name: String) -> Recipe? {
        viewModel.recipes.first { $0.name == name }
    }

    /// Mahlzeit-Kategorien, die in der ganzen Woche tatsächlich geplant sind
    /// (kanonische Reihenfolge) — nur real vorhandene Chips.
    private var presentCategories: [RecipeCategory] {
        let cats = Set(Weekday.allCases
            .flatMap { prefs.plannedRecipes($0) }
            .compactMap { recipe(named: $0)?.category })
        return RecipeCategory.allCases.filter { cats.contains($0) }
    }

    /// Geplante Rezepte eines Tages nach aktivem Kategorie-Filter. Rezepte ohne
    /// auflösbare Kategorie erscheinen nur, wenn kein Filter aktiv ist.
    private func visibleNames(_ day: Weekday) -> [String] {
        let names = prefs.plannedRecipes(day)
        guard !selectedCategories.isEmpty else { return names }
        return names.filter { name in
            guard let category = recipe(named: name)?.category else { return false }
            return selectedCategories.contains(category)
        }
    }
}

// MARK: - AddRecipeToDaySheet (Teil B)
/// Inhaltshoher Inhalt für das KKDynamicSheet: listet die echten Rezepte, die dem
/// Tag noch NICHT zugeordnet sind, und ordnet das getippte Rezept zu (addToPlan).
/// Eigener Container (KKCard-artige Zeilen), kein `List`. Die Liste ist auf den
/// Inhalt gedeckelt — wenige Rezepte → niedriges Sheet, viele → scrollbar.
private struct AddRecipeToDaySheet: View {
    let day: Weekday
    @State private var prefs: Preferences = .shared
    @State private var viewModel: RecipeListViewModel = .shared
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    /// Noch nicht für den Tag geplante Rezepte (optional nach Suche gefiltert).
    private var candidates: [Recipe] {
        let planned = Set(prefs.plannedRecipes(day))
        return viewModel.recipes
            .filter { !planned.contains($0.name) }
            .filter { search.isEmpty || $0.name.localizedStandardContains(search) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// Höhe des Treffer-Containers: bis zu 6 Zeilen sichtbar, darüber wird gescrollt.
    private var listHeight: CGFloat { CGFloat(min(candidates.count, 6)) * 60 }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rezept hinzufügen")
                        .font(.system(.title3, design: .serif).bold())
                    Text(day.rawValue + (day == Weekday.today ? " · heute" : ""))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary, Color(.tertiarySystemFill))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Schließen")
            }

            // Suchfeld erst ab genug Rezepten (sonst unnötig).
            if viewModel.recipes.count > 6 {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Rezept suchen", text: $search)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Color(.secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 12))
            }

            if candidates.isEmpty {
                Text(search.isEmpty
                     ? "Alle Rezepte sind für \(day.rawValue) schon eingeplant."
                     : "Nichts gefunden.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 20)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(candidates) { recipe in
                            Button {
                                withAnimation(.snappy(duration: 0.2)) {
                                    prefs.addToPlan(recipe.name, day: day)
                                }
                                dismiss()
                            } label: {
                                candidateRow(recipe)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(height: listHeight)
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func candidateRow(_ recipe: Recipe) -> some View {
        let color = recipe.category?.color ?? .orange
        return HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: recipe.category?.symbolName ?? "fork.knife")
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(recipe.name)
                    .font(.system(.body, design: .serif).weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                if let cat = recipe.category {
                    Text(cat.rawValue).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            Image(systemName: "plus.circle.fill")
                .font(.title3)
                .foregroundStyle(color)
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(recipe.name) zu \(day.rawValue) hinzufügen")
    }
}

#Preview {
    NavigationStack { WeekPlanView() }
}
