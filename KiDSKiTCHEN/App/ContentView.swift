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
