//
//  KKScroll.swift
//  KiDSKiTCHEN
//
//  Rebuild P4: aus KKContainer.swift herausgelöst (Plan-Zielstruktur
//  „KKContainer/KKCard/KKScroll/KKSection" — je Baustein eine Datei).
//  Selbstgebautes Container-System statt Standard-`List` (Jay-Entscheid 10.7.,
//  Projekt-CLAUDE.md §UI-Bauweise). Grundbaustein für Home + Rezept-Detail:
//  ScrollView + LazyVStack tragen den Inhalt, KKCard/KKSection formen die Karten.
//

import SwiftUI

// MARK: - KKScroll
/// Vertikaler Grund-Container: ScrollView + LazyVStack mit einheitlichem Rand.
/// Hintergrund: KKAnimatedBackground (Theme-Farben + loopFactor).
struct KKScroll<Content: View>: View {
    var spacing: CGFloat = 16
    var horizontalPadding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            LazyVStack(spacing: spacing) {
                content
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, 12)
        }
        .background { KKAnimatedBackground().ignoresSafeArea() }
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
    }
}

// MARK: - Transparente Navigationsleiste
extension View {
    /// Durchsichtige Navigationsleiste (Jay 11.7.): kein Balken-Hintergrund, der
    /// Inhalt läuft beim Scrollen sichtbar unter Zurück-Knopf & Co. durch.
    func kkTransparentNavBar() -> some View {
        toolbarBackgroundVisibility(.hidden, for: .navigationBar)
    }

    /// Gear-Button ganz rechts in der Navigationsleiste, öffnet ThemeSettingsView.
    /// Selbstständig: eigener @State, kein Binding erforderlich.
    func kkSettingsGear() -> some View {
        modifier(KKSettingsGearModifier())
    }
}

// MARK: - Settings-Gear-Modifier
private struct KKSettingsGearModifier: ViewModifier {
    @State private var showSettings = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                // .primaryAction = semantisch rechts außen → eigene Kapsel in iOS 26,
                // getrennt von .topBarTrailing-Items wie dem + Knopf.
                ToolbarItem(placement: .primaryAction) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Design-Einstellungen")
                }
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack { ThemeSettingsView() }
                    .presentationDragIndicator(.visible)
            }
    }
}

#Preview {
    KKScroll {
        KKSection(title: "Info", systemImage: "info.circle", tint: .orange) {
            Label("Frühstück", systemImage: "sun.max")
            Label("15 Minuten", systemImage: "clock")
        }
        KKSection(title: "Zutaten", tint: .green, footer: "je Portion") {
            Text("2 Äpfel")
            Text("100 g Haferflocken")
        }
        KKCard {
            Text("Freie Karte ohne Titel")
                .font(.system(.body, design: .serif))
        }
    }
}
