//
//  KKGlassTabBar.swift
//  KiDSKiTCHEN
//
//  Eigene Haupt-Tabbar im Liquid-Glass-Stil mit Morphing-Auswahl (Jay-Entscheid
//  17.7.). Technik/Ansatz angelehnt an Kavsoft „CustomGlassTabBar" (Glas-Kapsel
//  via glassEffect) und „MorphingTabBarEffect" (Wechsel-Animation) — eigene,
//  schlanke Implementierung ohne UIViewRepresentable/ImageRenderer-Umweg: der
//  Auswahl-Umriss läuft per matchedGeometryEffect mit, dasselbe Muster wie der
//  Wochenstreifen in WeekPlanView.
//
//  Ersetzt die native TabView-Leiste (ausgeblendet via toolbarVisibility) durch
//  eine eigene Glas-Kapsel im safeAreaInset — volle Gestaltungskontrolle, wie im
//  restlichen KK-Container-System (KKContainer.swift).
//

import SwiftUI

// MARK: - KKTab
/// Die vier Hauptbereiche der App (bestehende Ziele aus ContentView, unverändert).
enum KKTab: CaseIterable, Hashable {
    case recipes, week, shopping, more

    var title: String {
        switch self {
        case .recipes: "Rezepte"
        case .week: "Woche"
        case .shopping: "Einkaufen"
        case .more: "Mehr"
        }
    }

    var symbol: String {
        switch self {
        case .recipes: "fork.knife"
        case .week: "calendar"
        case .shopping: "cart"
        case .more: "ellipsis"
        }
    }
}

// MARK: - KKGlassTabBar
struct KKGlassTabBar: View {
    @Binding var activeTab: KKTab
    /// Badge-Zahl je Tab (0 = kein Badge) — Aufrufer liefert die echten Zählwerte.
    var badge: (KKTab) -> Int = { _ in 0 }
    @Namespace private var morphNamespace

    var body: some View {
        HStack(spacing: 2) {
            ForEach(KKTab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .padding(6)
        .glassEffect(.regular, in: .capsule)
        .accessibilityElement(children: .contain)
    }

    private func tabButton(_ tab: KKTab) -> some View {
        let isActive = tab == activeTab
        return Button {
            withAnimation(.snappy(duration: 0.3, extraBounce: 0.1)) { activeTab = tab }
        } label: {
            VStack(spacing: 3) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: tab.symbol)
                        .font(.title3)
                        .symbolVariant(isActive ? .fill : .none)
                    let count = badge(tab)
                    if count > 0 {
                        Text(count > 99 ? "99+" : "\(count)")
                            .font(.system(size: 10).bold())
                            .padding(.horizontal, 4)
                            .frame(minWidth: 14, minHeight: 14)
                            .background(Color.red, in: Capsule())
                            .foregroundStyle(.white)
                            .offset(x: 12, y: -8)
                    }
                }
                Text(tab.title)
                    .font(.caption2.weight(.medium))
            }
            .foregroundStyle(isActive ? Color.orange : Color.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background {
                if isActive {
                    Capsule()
                        .fill(Color.orange.opacity(0.15))
                        .matchedGeometryEffect(id: "activeGlassTab", in: morphNamespace)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isActive ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview {
    @Previewable @State var tab: KKTab = .recipes
    ZStack(alignment: .bottom) {
        Color(.systemGroupedBackground).ignoresSafeArea()
        KKGlassTabBar(activeTab: $tab) { $0 == .week ? 3 : 0 }
            .padding(.horizontal, 16)
    }
}
