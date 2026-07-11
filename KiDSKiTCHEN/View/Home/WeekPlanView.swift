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

import SwiftUI

struct WeekPlanView: View {
    @State private var prefs: Preferences = .shared
    @State private var viewModel: RecipeListViewModel = .shared
    // Startet oben am Wochenanfang (Montag) — der Streifen spiegelt so von Anfang an
    // die echte Scrollposition. „Heute" bleibt über Badge + Punkt klar markiert.
    // (Auto-Scroll-zu-heute bewusst weggelassen: bei LazyVStack nicht verlässlich
    //  ohne Klick-Test verifizierbar, und der Streifen würde sonst desynchron wirken.)
    @State private var selectedDay: Weekday? = Weekday.allCases.first
    /// Aktive Kategorie-Filter nach Mahlzeit-Art (leer = alles zeigen).
    @State private var selectedCategories: [RecipeCategory] = []
    @Namespace private var stripNamespace

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
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        // Deckt beim Kleben den durchscrollenden Inhalt zu.
        .background(Color(.systemGroupedBackground))
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: Tages-Inhalt
    @ViewBuilder
    private func dayContent(_ day: Weekday) -> some View {
        let names = visibleNames(day)
        KKCard {
            if names.isEmpty {
                Text(selectedCategories.isEmpty ? "nichts geplant" : "nichts in dieser Auswahl")
                    .foregroundStyle(.tertiary)
                    .font(.subheadline)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(names.enumerated()), id: \.element) { index, name in
                        if index > 0 { Divider() }
                        planRow(name: name, day: day)
                    }
                }
            }
        }
    }

    // MARK: Zeile
    @ViewBuilder
    private func planRow(name: String, day: Weekday) -> some View {
        HStack(spacing: 8) {
            if let recipe = recipe(named: name) {
                NavigationLink { Rezepte(recipe: recipe) } label: {
                    HStack {
                        Text(name).font(.system(.body, design: .serif))
                            .foregroundStyle(.primary)
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
        .padding(.vertical, 4)
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

#Preview {
    NavigationStack { WeekPlanView() }
}
