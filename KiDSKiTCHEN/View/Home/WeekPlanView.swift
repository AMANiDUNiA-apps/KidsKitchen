//
//  WeekPlanView.swift
//  KiDSKiTCHEN
//
//  Wochenplaner: je Wochentag geplante Rezepte, heutiger Tag hervorgehoben.
//  Rezepte werden aus der Detailansicht („Zum Wochenplan") hinzugefügt.
//
//  Weiterbau bau/air (16.7.):
//  — Datum je Tag (Mo 14.7.) im Streifen + Tages-Header
//  — Navigation zu vorheriger/nächster Woche (weekOffset)
//  — AddRecipeToDaySheet: alle hardcodierten Radii auf Theme-Token umgestellt (A2)
//
//  Weiterbau 4, Teil C — Wochenansicht mit gepinnten Tages-Headern und einem
//  Wochenstreifen, der mit der Scrollposition mitläuft. Ursprünglich Kavsoft
//  „CalendarScrollEffect" (native pinnedViews); seit 17.7. auf KKStickySection
//  umgestellt (Kavsoft „WSSection", Jay: „super für Kalender") — jeder Wochentag
//  ist ein eigener Abschnitt mit Voll-Header, der beim Scrollen zu einem
//  Minimiert-Header zusammenfällt, statt nur oben zu kleben.
//
//  UI-Bauweise (Jay 10.7.): selbstgebaute Container statt `List`. Entfernen als
//  sichtbarer Lösch-Knopf (KKDeleteButton, Jay 11.7.).
//
//  Kavsoft-Runde 2: der Wochenstreifen schrumpft/verblasst sanft, sobald darunter
//  gescrollt wird (kkCollapsingOnScroll, zusätzlich zum bestehenden Kollabieren
//  JE Tag in KKStickySection). KKGooeyRefreshable zieht die Rezeptliste per
//  Pull-to-Refresh neu vom Server (RecipeListViewModel) — echte Aktion.
//

import SwiftUI

struct WeekPlanView: View {
    @State private var prefs: Preferences = .shared
    @State private var viewModel: RecipeListViewModel = .shared
    @State private var settings: ThemeSettings = .shared
    /// Wochen-Versatz zur aktuellen Woche (0 = diese Woche, −1 = letzte, +1 = nächste).
    @State private var weekOffset: Int = 0
    @State private var addTarget: Weekday?
    @State private var cookTarget: Weekday?
    @State private var selectedDay: Weekday? = Weekday.allCases.first
    @State private var selectedCategories: [RecipeCategory] = []
    @Namespace private var stripNamespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Scroll-Offset des Wochenplans — treibt das sanfte Schrumpfen des Wochenstreifens.
    @State private var scrollOffset: CGFloat = 0

    // MARK: Datum-Rechnung

    /// Montag der Zielwoche (weekOffset = 0 → aktuelle Woche) — gemeinsame
    /// Rechnung mit den Persistenzschlüsseln (Date.kkWeekStart, Weekday.swift).
    private var weekStart: Date { .kkWeekStart(offset: weekOffset) }

    /// Kalender-Datum für den gegebenen Wochentag in der aktuellen Zielwoche.
    private func calendarDate(for day: Weekday) -> Date {
        let idx = Weekday.allCases.firstIndex(of: day) ?? 0
        return Calendar.current.date(byAdding: .day, value: idx, to: weekStart) ?? weekStart
    }

    /// True wenn der Tag das heutige Datum trägt (nur bei weekOffset == 0 möglich).
    private func isToday(_ day: Weekday) -> Bool {
        weekOffset == 0 && day == Weekday.today
    }

    // Datum-Formatter (statisch — einmal erzeugt)
    private static let stripDayFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "d."; f.locale = Locale(identifier: "de_DE"); return f
    }()
    private static let headerDateFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "d.M."; f.locale = Locale(identifier: "de_DE"); return f
    }()
    private static let rangeFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "d.M."; f.locale = Locale(identifier: "de_DE"); return f
    }()

    private var weekTitle: String {
        switch weekOffset {
        case 0:  return "Diese Woche"
        case 1:  return "Nächste Woche"
        case -1: return "Letzte Woche"
        default:
            let end = Calendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
            return "\(Self.rangeFormatter.string(from: weekStart))–\(Self.rangeFormatter.string(from: end))"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            weekNavigationBar
            weekStrip
                .kkCollapsingOnScroll(offset: scrollOffset)

            if presentCategories.count > 1 {
                CategoryFilterChips(categories: presentCategories) { selection in
                    selectedCategories = selection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .background(settings.theme.headerBackground)
            }

            ScrollView(.vertical) {
                LazyVStack(spacing: 12) {
                    ForEach(Weekday.allCases) { day in
                        // A2: Karten-Radius + -Fläche der Sticky-Karte aus den Theme-Token.
                        KKStickySection(config: .init(
                            cornerRadius: settings.cardCornerRadius,
                            background: AnyShapeStyle(settings.theme.cardSurface.opacity(settings.cardOpacity))
                        )) {
                            dayContent(day)
                        } header: {
                            dayHeader(day)
                        } minimisedHeader: {
                            dayMinimisedHeader(day)
                        }
                    }
                    nextWeekAnchor
                }
                .scrollTargetLayout()
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                // Resthöhe, damit auch der letzte Tag ganz nach oben scrollen und
                // sein Voll-Header/Minimiert-Übergang komplett ablaufen kann.
                .padding(.bottom, 120)
            }
            .scrollPosition(id: $selectedDay, anchor: .top)
            // Kein opaker Hintergrund — KKAnimatedBackground (MeshGradient, bau/air)
            // liegt hinter dem gesamten Screen und soll durchscheinen.
            .background(.clear)
            .onScrollGeometryChange(for: CGFloat.self, of: {
                $0.contentOffset.y + $0.contentInsets.top
            }, action: { _, newValue in
                scrollOffset = newValue
            })
            .kkGooeyRefreshable {
                await viewModel.loadRecipes()
            }
        }
        .background { KKAnimatedBackground().ignoresSafeArea() }
        .navigationTitle("Wochenplan")
        .kkTransparentNavBar()
        .kkSettingsGear()
        .navigationBarTitleDisplayMode(.inline)
        .animation(.snappy(duration: 0.25), value: selectedDay)
        .onChange(of: weekOffset) { _, _ in pruneSelectedCategories() }
        .onChange(of: presentCategories) { _, _ in pruneSelectedCategories() }
        .sheet(item: $addTarget) { day in
            KKDynamicSheet(animation: .snappy(duration: 0.3, extraBounce: 0)) {
                AddRecipeToDaySheet(day: day, week: weekStart)
            }
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $cookTarget) { day in
            CookableSuggestionsView(day: day, week: weekStart)
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: Wochen-Navigations-Leiste (neu bau/air)
    private var weekNavigationBar: some View {
        HStack(spacing: 0) {
            Button {
                withAnimation(.snappy(duration: 0.25)) { weekOffset -= 1 }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.bold())
                    .frame(width: 44, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Vorherige Woche")

            Spacer()

            Button {
                withAnimation(.snappy(duration: 0.25)) { weekOffset = 0 }
            } label: {
                Text(weekTitle)
                    .font(.system(.subheadline, design: .serif).weight(.semibold))
                    .foregroundStyle(weekOffset == 0 ? .primary : settings.theme.accent)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(weekOffset == 0 ? "Aktuelle Woche" : "Zur aktuellen Woche tippen")

            Spacer()

            Button {
                withAnimation(.snappy(duration: 0.25)) { weekOffset += 1 }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.bold())
                    .frame(width: 44, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Nächste Woche")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(settings.theme.headerBackground)
        .foregroundStyle(.primary)
    }

    // MARK: Wochenstreifen (springt zum Tag, folgt der Scrollposition)
    private var weekStrip: some View {
        HStack(spacing: 0) {
            ForEach(Weekday.allCases) { day in
                let isSelected = day == selectedDay
                VStack(spacing: 2) {
                    Text(day.short)
                        .font(.caption.bold())
                        .foregroundStyle(isSelected ? .white : .secondary)
                    Text(Self.stripDayFormatter.string(from: calendarDate(for: day)))
                        .font(.system(size: 10))
                        .foregroundStyle(isSelected ? .white.opacity(0.85) : .secondary.opacity(0.7))
                    if isToday(day) {
                        Circle()
                            .fill(isSelected ? Color.white : settings.theme.accent)
                            .frame(width: 5, height: 5)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(settings.theme.accent)
                            .matchedGeometryEffect(id: "selectedDay", in: stripNamespace)
                            .padding(.horizontal, 4)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.snappy(duration: 0.25)) { selectedDay = day }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(day.rawValue + (isToday(day) ? ", heute" : "")
                    + ", " + Self.stripDayFormatter.string(from: calendarDate(for: day)))
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(settings.theme.headerBackground)
    }

    // MARK: „Nächste Woche"-Anschluss (Listenende, Aufgabe 3 BRIEF-kk-endstrecke)
    /// Ans Wochenende (So) gescrollt → statt Sackgasse ein klarer, antippbarer
    /// Anschluss in die nächste Woche zum Vorausplanen. Nutzt dieselbe
    /// `weekOffset`-Navigation wie die Pfeile oben — die Persistenz landet damit
    /// garantiert unter dem Key der NÄCHSTEN Woche (`weekStart` folgt `weekOffset`).
    private var nextWeekAnchor: some View {
        Button {
            withAnimation(.snappy(duration: 0.25)) {
                weekOffset += 1
                selectedDay = Weekday.allCases.first
            }
        } label: {
            HStack {
                Text("Nächste Woche planen")
                    .font(.system(.subheadline, design: .serif).weight(.medium))
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.footnote.bold())
            }
            .foregroundStyle(settings.theme.accent)
            .padding(14)
            .background(settings.theme.cardSurface.opacity(settings.cardOpacity),
                        in: RoundedRectangle(cornerRadius: settings.cardCornerRadius))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Springt zur nächsten Woche zum Vorausplanen")
    }

    // MARK: Voll-Header (Tagesname, „heute", Anzahl, „+")
    private func dayHeader(_ day: Weekday) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    Text(day.rawValue)
                        .font(.system(.title3, design: .serif).bold())
                        .foregroundStyle(.primary)
                    if isToday(day) {
                        Text("heute")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6).padding(.vertical, 1)
                            .background(.tint, in: Capsule())
                            .foregroundStyle(.white)
                    }
                }
                Text(Self.headerDateFormatter.string(from: calendarDate(for: day)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            let count = visibleNames(day).count
            if count > 0 {
                Text("\(count)")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            Button {
                addTarget = day
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(settings.theme.accent)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Rezept zu \(day.rawValue) hinzufügen")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // Header bleibt Überschrift, „+" ist ein eigenständiges Bedienelement.
        // Kein eigener Hintergrund mehr — KKStickySection zeichnet die
        // Karten-Fläche (config.background) selbst hinter Voll- und Minimiert-Header.
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: Minimiert-Header (eine Zeile, blendet ein, sobald der Voll-Header wegscrollt)
    private func dayMinimisedHeader(_ day: Weekday) -> some View {
        HStack(spacing: 6) {
            Text(day.short.uppercased())
                .font(.caption.bold())
            if isToday(day) {
                Circle().fill(settings.theme.accent).frame(width: 5, height: 5)
            }
            Spacer(minLength: 0)
            let count = visibleNames(day).count
            if count > 0 {
                Text("\(count)")
                    .font(.caption2.bold())
            }
        }
        .foregroundStyle(.secondary)
        .accessibilityHidden(true)
    }

    // MARK: Tages-Inhalt
    @ViewBuilder
    private func dayContent(_ day: Weekday) -> some View {
        let names = visibleNames(day)
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
                            .foregroundStyle(settings.theme.accent)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Zeigt Rezepte, die zu deinem Vorrat passen, und ordnet sie \(day.rawValue) zu")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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

    // MARK: Zeile
    @ViewBuilder
    private func planRow(name: String, day: Weekday) -> some View {
        let resolved = recipe(named: name)
        let cooked = prefs.isCooked(day, name, week: weekStart)
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
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
                        prefs.removeFromPlan(name, day: day, week: weekStart)
                    }
                }
            }
            if cooked, let recipe = resolved {
                let missing = prefs.cookMissingNames(day, recipe: recipe, week: weekStart)
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

    private func cookButton(recipe: Recipe, day: Weekday, cooked: Bool) -> some View {
        Button {
            withAnimation(.snappy(duration: 0.25)) {
                if cooked { prefs.unmarkCooked(day, recipe: recipe, week: weekStart) }
                else { prefs.markCooked(day, recipe: recipe, week: weekStart) }
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

    private var presentCategories: [RecipeCategory] {
        let cats = Set(Weekday.allCases
            .flatMap { prefs.plannedRecipes($0, week: weekStart) }
            .compactMap { recipe(named: $0)?.category })
        return RecipeCategory.allCases.filter { cats.contains($0) }
    }

    private func visibleNames(_ day: Weekday) -> [String] {
        let names = prefs.plannedRecipes(day, week: weekStart)
        guard !selectedCategories.isEmpty else { return names }
        return names.filter { name in
            guard let category = recipe(named: name)?.category else { return false }
            return selectedCategories.contains(category)
        }
    }

    private func pruneSelectedCategories() {
        let available = Set(presentCategories)
        selectedCategories.removeAll { !available.contains($0) }
    }
}

// MARK: - AddRecipeToDaySheet (A2: alle hardcodierten Radii → Theme-Token)
private struct AddRecipeToDaySheet: View {
    let day: Weekday
    /// Wochenstart der angezeigten Woche — Hinzufügen trifft GENAU diese Woche.
    let week: Date
    @State private var prefs: Preferences = .shared
    @State private var viewModel: RecipeListViewModel = .shared
    @State private var settings: ThemeSettings = .shared
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    private var candidates: [Recipe] {
        let planned = Set(prefs.plannedRecipes(day, week: week))
        return viewModel.recipes
            .filter { !planned.contains($0.name) }
            .filter { search.isEmpty || $0.name.localizedStandardContains(search) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

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

            if viewModel.recipes.count > 6 {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Rezept suchen", text: $search)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Color(.secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: settings.cardInnerRadius))
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
                                    prefs.addToPlan(recipe.name, day: day, week: week)
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
        let color = recipe.category?.color ?? settings.theme.accent
        return HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: settings.cardInnerRadius)
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
                    in: RoundedRectangle(cornerRadius: settings.cardCornerRadius))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(recipe.name) zu \(day.rawValue) hinzufügen")
    }
}

#Preview {
    NavigationStack { WeekPlanView() }
}
