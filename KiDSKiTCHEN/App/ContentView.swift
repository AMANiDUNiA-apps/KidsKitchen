//
//  ContentView.swift
//  KiDSKiTCHEN
//
//  TabView-Navigation: Rezepte / Wochenplan / Einkaufen / Mehr.
//

import SwiftUI

struct ContentView: View {
    @State private var prefs: Preferences = .shared
    // Erst-Start-Onboarding: einmalig, aus „Mehr" erneut auslösbar.
    @AppStorage("kk.hasOnboarded") private var hasOnboarded = false

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
        .fullScreenCover(isPresented: Binding(
            get: { !hasOnboarded },
            set: { presented in if !presented { hasOnboarded = true } }
        )) {
            OnboardingView { hasOnboarded = true }
        }
    }
}

// MARK: - MoreView
private struct MoreView: View {
    @AppStorage("kk.hasOnboarded") private var hasOnboarded = false

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

            Section {
                Button {
                    // Startet das Erst-Start-Onboarding erneut (ContentView-Cover reagiert).
                    hasOnboarded = false
                } label: {
                    Label("Einführung nochmal ansehen", systemImage: "sparkles")
                }
            }
        }
        .navigationTitle("Mehr")
    }
}

#Preview { ContentView() }
