//
//  ContentView.swift
//  KiDSKiTCHEN
//
//  TabView-Navigation: Rezepte / Zutaten / Woche / Einkaufen / Mehr.
//  Leiste: eigene Glas-Kapsel (KKGlassTabBar, Jay-Entscheid 17.7.) statt der
//  nativen TabView-Leiste — dazu die native Leiste je Tab ausgeblendet.
//
//  Rezepte-Tab: Gespeicherte Rezepte über Trailing-Toolbar erreichbar.
//  Zutaten-Tab: Saisonkalender (Leading) + Filter & Diät (Trailing).
//  Mehr: nur noch Rezept-Import + Einführung.
//

import SwiftUI

struct ContentView: View {
    @State private var prefs: Preferences = .shared
    @State private var settings: ThemeSettings = .shared
    @AppStorage("kk.hasOnboarded") private var hasOnboarded = false
    @State private var activeTab: KKTab = .recipes
    // Kochmodus-Zustand (app-weit) — für die Mini-Leiste über der Tabbar.
    @State private var cookingSession = KKCookingSession.shared

    var body: some View {
        TabView(selection: $activeTab) {
            Tab(value: KKTab.recipes) {
                NavigationStack { RezepteTabRoot() }
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
            Tab(value: KKTab.ingredients) {
                NavigationStack { ZutatenTabRoot() }
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
            Tab(value: KKTab.week) {
                NavigationStack { WeekPlanView() }
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
            Tab(value: KKTab.shopping) {
                NavigationStack { ShoppingListView() }
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
            Tab(value: KKTab.more) {
                NavigationStack { MoreView() }
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
        }
        .tint(settings.theme.accent)
        // App-Erscheinung (System/Hell/Dunkel) wird am echten App-Root gesetzt
        // (KiDSKiTCHENApp), NICHT hier — Team-Runde v2 #7: getrennt von
        // theme.isDark, das nur die Kartenfarben bestimmt.
        .safeAreaInset(edge: .bottom, spacing: 10) {
            VStack(spacing: 10) {
                KKCookingMiniBar(session: cookingSession)
                KKGlassTabBar(activeTab: $activeTab, badge: badgeCount)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 6)
        }
        .environment(\.locale, Locale(identifier: "de_DE"))
        .toolbarBackground(settings.theme.headerBackground, for: .tabBar)
        .fullScreenCover(isPresented: Binding(
            get: { !hasOnboarded },
            set: { presented in if !presented { hasOnboarded = true } }
        )) {
            OnboardingView { hasOnboarded = true }
        }
        .fullScreenCover(isPresented: $cookingSession.isFullScreenPresented) {
            KKCookingModeView(session: cookingSession)
        }
    }

    /// Badge-Zahlen je Tab — ersetzt die vorherigen `.badge()`-Modifier der nativen Leiste.
    private func badgeCount(_ tab: KKTab) -> Int {
        switch tab {
        case .week: prefs.plannedCount
        case .shopping: prefs.shopping.filter { !$0.done }.count
        default: 0
        }
    }
}

// MARK: - Rezepte-Tab
/// Home als Haupt-Screen; Gespeicherte Rezepte über den Trailing-Knopf erreichbar.
private struct RezepteTabRoot: View {
    var body: some View {
        Home()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SavedRecipesView()) {
                        Label("Gespeichert", systemImage: "arrow.down.circle")
                            .labelStyle(.iconOnly)
                    }
                    .accessibilityLabel("Offline gespeicherte Rezepte")
                }
            }
    }
}

// MARK: - Zutaten-Tab
/// Vorratsschrank als Haupt-Screen; Saisonkalender (Leading) + Filter & Diät (Trailing).
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
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: PreferencesView()) {
                        Label("Filter & Diät", systemImage: "slider.horizontal.3")
                            .labelStyle(.iconOnly)
                    }
                    .accessibilityLabel("Filter & Diät")
                }
            }
    }
}

// MARK: - MoreView (schlank — Rezept-Import + Einführung)
// Gespeichert → Rezepte-Tab · Filter & Diät → Zutaten-Tab
// UI-Bauweise (Jay 10.7.): selbstgebaute Container statt `List`.
private struct MoreView: View {
    @AppStorage("kk.hasOnboarded") private var hasOnboarded = false
    @State private var settings: ThemeSettings = .shared

    var body: some View {
        KKScroll {
            navCard("Rezept importieren", symbol: "sparkles", tint: .indigo) {
                RecipeImportView()
            }

            Button {
                hasOnboarded = false
            } label: {
                menuRow("Einführung nochmal ansehen", symbol: "wand.and.stars", tint: .pink, showsChevron: false)
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
