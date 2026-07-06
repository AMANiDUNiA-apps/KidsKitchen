//
//  ContentView.swift
//  KiDSKiTCHEN
//
//  TabView-Navigation: Rezepte / Wochenplan / Einkaufen / Mehr.
//

import SwiftUI

struct ContentView: View {
    @State private var prefs: Preferences = .shared

    var body: some View {
        TabView {
            NavigationStack { Home() }
                .tabItem { Label("Rezepte", systemImage: "fork.knife") }

            NavigationStack { WeekPlanView() }
                .tabItem { Label("Woche", systemImage: "calendar") }
                .badge(prefs.plannedCount)

            NavigationStack { ShoppingListView() }
                .tabItem { Label("Einkaufen", systemImage: "cart") }
                .badge(prefs.shopping.filter { !$0.done }.count)

            NavigationStack { MoreView() }
                .tabItem { Label("Mehr", systemImage: "ellipsis") }
        }
        .tint(.orange)
        .environment(\.locale, Locale(identifier: "de_DE"))
    }
}

// MARK: - MoreView
private struct MoreView: View {
    var body: some View {
        List {
            NavigationLink { SavedRecipesView() } label: {
                Label("Offline gespeichert", systemImage: "arrow.down.circle")
            }
            NavigationLink { PantryView() } label: {
                Label("Vorratsschrank", systemImage: "cabinet")
            }
            NavigationLink { PreferencesView() } label: {
                Label("Filter & Diät", systemImage: "slider.horizontal.3")
            }
        }
        .navigationTitle("Mehr")
    }
}

#Preview { ContentView() }
