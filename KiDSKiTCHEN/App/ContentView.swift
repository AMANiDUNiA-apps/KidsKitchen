//
//  ContentView.swift
//  KiDSKiTCHEN
//
//  TabView-Navigation: Rezepte / Wochenplan / Einkaufen / Mehr.
//  Leiste: eigene Glas-Kapsel (KKGlassTabBar, Jay-Entscheid 17.7.) statt der
//  nativen TabView-Leiste — dazu die native Leiste je Tab ausgeblendet.
//

import SwiftUI

struct ContentView: View {
    @State private var prefs: Preferences = .shared
    // Erst-Start-Onboarding: einmalig, aus „Mehr" erneut auslösbar.
    @AppStorage("kk.hasOnboarded") private var hasOnboarded = false
    @State private var activeTab: KKTab = .recipes

    var body: some View {
        TabView(selection: $activeTab) {
            Tab(value: KKTab.recipes) {
                NavigationStack { Home() }
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
        .tint(Color(red:0.72,green:0.40,blue:0.18))
        .safeAreaInset(edge: .bottom, spacing: 0) {
            KKGlassTabBar(activeTab: $activeTab, badge: badgeCount)
                .padding(.horizontal, 20)
                .padding(.bottom, 6)
        }
        .environment(\.locale, Locale(identifier: "de_DE"))
        .fullScreenCover(isPresented: Binding(
            get: { !hasOnboarded },
            set: { presented in if !presented { hasOnboarded = true } }
        )) {
            OnboardingView { hasOnboarded = true }
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

// MARK: - MoreView
// UI-Bauweise (Jay 10.7.): selbstgebaute Container statt `List` — die Menüpunkte
// sind eigene KKCards mit Symbol, Titel und Chevron.
private struct MoreView: View {
    @AppStorage("kk.hasOnboarded") private var hasOnboarded = false

    var body: some View {
        KKScroll {
            navCard("Offline gespeichert", symbol: "arrow.down.circle", tint: .orange) {
                SavedRecipesView()
            }
            navCard("Vorratsschrank", symbol: "cabinet", tint: .green) {
                PantryView()
            }
            navCard("Filter & Diät", symbol: "slider.horizontal.3", tint: .blue) {
                PreferencesView()
            }

            Button {
                // Startet das Erst-Start-Onboarding erneut (ContentView-Cover reagiert).
                hasOnboarded = false
            } label: {
                menuRow("Einführung nochmal ansehen", symbol: "sparkles", tint: .pink, showsChevron: false)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .navigationTitle("Mehr")
        .kkTransparentNavBar()
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
                    RoundedRectangle(cornerRadius: 10)
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
