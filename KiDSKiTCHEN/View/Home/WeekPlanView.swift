//
//  WeekPlanView.swift
//  KiDSKiTCHEN
//
//  Created by Claude Fable 5 on 03.07.26.
//  Wochenplaner: je Wochentag geplante Rezepte, heutiger Tag hervorgehoben.
//  Rezepte werden aus der Detailansicht („Zum Wochenplan") hinzugefügt.
//
//  UI-Bauweise (Jay 10.7.): selbstgebaute Container statt `List` — KKScroll + KKCard.
//  Entfernen als sichtbarer Lösch-Knopf statt Swipe (Jay 11.7., Herz-Knopf-Referenz).
//  Teil C setzt auf diesen Container die gepinnte Wochenansicht (CalendarScrollEffect).
//

import SwiftUI

struct WeekPlanView: View {
    @State private var prefs: Preferences = .shared
    @State private var viewModel: RecipeListViewModel = .shared

    var body: some View {
        KKScroll {
            ForEach(Weekday.allCases) { day in
                VStack(alignment: .leading, spacing: 8) {
                    dayHeader(day)
                    KKCard {
                        let names = prefs.plannedRecipes(day)
                        if names.isEmpty {
                            Text("nichts geplant")
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
            }
        }
        .navigationTitle("Wochenplan")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Tages-Kopf
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
        }
        .padding(.horizontal, 4)
        .accessibilityAddTraits(.isHeader)
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
}

#Preview {
    NavigationStack { WeekPlanView() }
}
