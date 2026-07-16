//
//  ContentView.swift
//  KiDSKiTCHEN
//
//  TabView-Navigation (bau/air 16.7.):
//  Rezepte / Zutaten / Woche / Einkaufen / Mehr
//
//  NEU — Zutaten-Tab: Vorratsschrank als Haupt-Screen, Saisonkalender über
//  Leading-Toolbar-Link erreichbar. Mehr: schlanker (ohne Vorrat + Saison).
//  Tab-Struktur als Screenshot an Jay — vor dem weiteren Umbau abstimmen.
//

import SwiftUI

struct ContentView: View {
    @State private var prefs: Preferences = .shared
    @State private var settings: ThemeSettings = .shared
    @AppStorage("kk.hasOnboarded") private var hasOnboarded = false

    var body: some View {
        TabView {
            NavigationStack { Home() }
                .tabItem { Label("Rezepte", systemImage: "fork.knife") }

            NavigationStack { ZutatenTabRoot() }
                .tabItem { Label("Zutaten", systemImage: "basket") }

            NavigationStack { WeekPlanView() }
                .tabItem { Label("Woche", systemImage: "calendar") }
                .badge(prefs.plannedCount)

            NavigationStack { ShoppingListView() }
                .tabItem { Label("Einkaufen", systemImage: "cart") }
                .badge(prefs.shopping.filter { !$0.done }.count)

            NavigationStack { MoreView() }
                .tabItem { Label("Mehr", systemImage: "ellipsis") }
        }
        .tint(settings.theme.accent)
        .preferredColorScheme(settings.theme.isDark ? .dark : .light)
        .environment(\.locale, Locale(identifier: "de_DE"))
        .toolbarBackground(settings.theme.headerBackground, for: .tabBar)
        .fullScreenCover(isPresented: Binding(
            get: { !hasOnboarded },
            set: { presented in if !presented { hasOnboarded = true } }
        )) {
            OnboardingView { hasOnboarded = true }
        }
    }
}

// MARK: - Zutaten-Tab
/// Vorratsschrank als Haupt-Screen; Saisonkalender über den Leading-Knopf erreichbar.
private struct ZutatenTabRoot: View {
    var body: some View {
        PantryView()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(destination: SeasonalCalendarView()) {
                        Label("Saisonkalender", systemImage: "leaf")
                            .labelStyle(.iconOnly)
                    }
                    .accessibilityLabel("Saisonkalender")
                }
            }
    }
}

// MARK: - MoreView (schlanker — Vorrat + Saison jetzt im Zutaten-Tab)
// UI-Bauweise (Jay 10.7.): selbstgebaute Container statt `List`.
private struct MoreView: View {
    @AppStorage("kk.hasOnboarded") private var hasOnboarded = false
    @State private var settings: ThemeSettings = .shared

    var body: some View {
        KKScroll {
            navCard("Offline gespeichert", symbol: "arrow.down.circle", tint: .orange) {
                SavedRecipesView()
            }
            navCard("Filter & Diät", symbol: "slider.horizontal.3", tint: .blue) {
                PreferencesView()
            }
            navCard("Rezept importieren", symbol: "sparkles", tint: .indigo) {
                RecipeImportView()
            }

            Button {
                hasOnboarded = false
            } label: {
                menuRow("Einführung nochmal ansehen", symbol: "sparkles", tint: .pink, showsChevron: false)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .navigationTitle("Mehr")
        .kkTransparentNavBar()
        .kkSettingsGear()
    }

    private func navCard<Destination: View>(
        _ title: String, symbol: String, tint: Color,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink(destination: destination()) {
            menuRow(title, symbol: symbol, tint: tint, showsChevron: true)
        }
        .buttonStyle(.plain)
    }

    private func menuRow(_ title: String, symbol: String, tint: Color, showsChevron: Bool) -> some View {
        KKCard {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: settings.cardInnerRadius)
                        .fill(tint.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: symbol)
                        .font(.title3)
                        .foregroundStyle(tint)
                }
                Text(title)
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(.primary)
                Spacer(minLength: 8)
                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.footnote.bold())
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}

#Preview { ContentView() }
