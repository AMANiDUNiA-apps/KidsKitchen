//
//  AppRoot.swift
//  KiDSKiTCHEN
//
//  Neuer App-Root (Rebuild, Re-Founding P1) — ersetzt das frühere ContentView.
//  Gleiche 5-Tab-Struktur (Rezepte / Zutaten / Woche / Einkaufen / Mehr) mit
//  eigener Glas-Kapsel (KKGlassTabBar, Jay-Entscheid 17.7.), aber alle
//  app-weiten Zustände kommen aus dem injizierten AppEnvironment statt aus
//  `.shared`-Singletons. Die einzelnen Screens werden phasenweise darunter
//  erneuert (MVP-first: P5 Kern-Screens), die App bleibt durchgehend nutzbar.
//
//  UI-Bauweise (Jay 10.7.): selbstgebaute Container statt `List`.
//

import SwiftUI

struct AppRoot: View {
    @Environment(AppEnvironment.self) private var env
    @AppStorage("kk.hasOnboarded") private var hasOnboarded = false
    @State private var activeTab: KKTab = .recipes

    var body: some View {
        @Bindable var cooking = env.cooking

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
        .tint(env.theme.theme.accent)
        // Untere Safe-Area (Home-Indicator-Streifen unter der schwebenden Glas-Leiste)
        // mit der Theme-Grundfarbe füllen — sonst schien dort reinweißes systemBackground
        // durch (die App läuft in heller System-Erscheinung; Jay 19.7.). ShapeStyle-Form
        // mit ignoresSafeAreaEdges: .bottom blutet zuverlässig bis zur Bildschirmkante.
        // (Weiße-Balken-Fix, von main d9e23ad geliftet, Rebuild P4.)
        .background(env.theme.theme.backgroundColors.first ?? Color.clear,
                    ignoresSafeAreaEdges: .bottom)
        .safeAreaInset(edge: .bottom, spacing: 10) {
            VStack(spacing: 10) {
                KKCookingMiniBar(session: env.cooking)
                KKGlassTabBar(activeTab: $activeTab, badge: badgeCount)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 6)
        }
        .environment(\.locale, Locale(identifier: "de_DE"))
        .toolbarBackground(env.theme.theme.headerBackground, for: .tabBar)
        .fullScreenCover(isPresented: Binding(
            get: { !hasOnboarded },
            set: { presented in if !presented { hasOnboarded = true } }
        )) {
            OnboardingView { hasOnboarded = true }
        }
        .fullScreenCover(isPresented: $cooking.isFullScreenPresented) {
            KKCookingModeView(session: cooking)
        }
    }

    /// Badge-Zahlen je Tab — ersetzt die `.badge()`-Modifier der nativen Leiste.
    private func badgeCount(_ tab: KKTab) -> Int {
        switch tab {
        case .week: env.prefs.plannedCount
        case .shopping: env.prefs.shopping.filter { !$0.done }.count
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
private struct MoreView: View {
    @AppStorage("kk.hasOnboarded") private var hasOnboarded = false
    @Environment(AppEnvironment.self) private var env

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
                    RoundedRectangle(cornerRadius: env.theme.cardInnerRadius)
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
