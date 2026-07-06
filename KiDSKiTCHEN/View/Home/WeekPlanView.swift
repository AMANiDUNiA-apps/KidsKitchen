//
//  WeekPlanView.swift
//  KiDSKiTCHEN
//
//  Created by Claude Fable 5 on 03.07.26.
//  Wochenplaner: je Wochentag geplante Rezepte, heutiger Tag hervorgehoben.
//  Rezepte werden aus der Detailansicht („Zum Wochenplan") hinzugefügt.
//

import SwiftUI

struct WeekPlanView: View {
    @State private var prefs: Preferences = .shared
    @State private var viewModel: RecipeListViewModel = .shared

    var body: some View {
        List {
            ForEach(Weekday.allCases) { day in
                Section {
                    let names = prefs.plannedRecipes(day)
                    if names.isEmpty {
                        Text("nichts geplant")
                            .foregroundStyle(.tertiary)
                            .font(.subheadline)
                    } else {
                        ForEach(names, id: \.self) { name in
                            if let recipe = recipe(named: name) {
                                NavigationLink(name) { Rezepte(recipe: recipe) }
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            prefs.removeFromPlan(name, day: day)
                                        } label: { Label("Entfernen", systemImage: "trash") }
                                    }
                            } else {
                                Text(name).foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text(day.rawValue)
                        if day == Weekday.today {
                            Text("heute")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6).padding(.vertical, 1)
                                .background(.tint, in: Capsule())
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
        }
        .navigationTitle("Wochenplan")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func recipe(named name: String) -> Recipe? {
        viewModel.recipes.first { $0.name == name }
    }
}

#Preview {
    NavigationStack { WeekPlanView() }
}
