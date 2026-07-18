//
//  KKCategoryBar.swift
//  KiDSKiTCHEN
//
//  Kategorie-Leiste im MTabBar-Stil (Jay-Entscheid): Kavsoft „MTabBar" von
//  Balaji Venkatesh (Mail-App-Tabbar) als Kategorien-Leiste über der
//  Rezeptliste — der aktive Tab wächst zu Symbol+Titel in Kategoriefarbe,
//  inaktive bleiben schmale Symbol-Kapseln. Übernommen: die wachsende Kapsel
//  per GeometryReader + Größenmessung des Titels. Vereinfacht ggü. Vorlage:
//  kein Wisch-Geste-Toggle, kein „letzter Tab"-Sonderfall — hier reicht
//  Antippen = Kategorie wählen, „Alle" hebt den Filter auf.
//  Quelle: ~/z/Agents/Claude/xCode/kavsoft/MTabBar.
//

import SwiftUI

/// Geteilter Kategorie-Filter: die MTabBar-Leiste in Home UND die farbigen
/// Badges auf Rezept-Karten/-Detail schreiben/lesen denselben Zustand — ein
/// Badge-Tipp in der Detailansicht filtert die Home-Liste, ohne Bindings
/// durch die Navigation zu reichen. Rein UI-State (nicht persistiert, anders
/// als `Preferences`).
@Observable
final class RecipeCategoryFilter {
    static let shared = RecipeCategoryFilter()
    var selected: RecipeCategory?
    private init() {}
}

/// Ein Tab der Kategorie-Leiste — „Alle" plus jede echte `RecipeCategory`.
private enum KKCategoryTab: Hashable {
    case all
    case category(RecipeCategory)

    static var allTabs: [KKCategoryTab] { [.all] + RecipeCategory.allCases.map(KKCategoryTab.category) }

    var title: String {
        switch self {
        case .all: "Alle"
        case .category(let c): c.rawValue
        }
    }
    var symbol: String {
        switch self {
        case .all: "square.grid.2x2"
        case .category(let c): c.symbolName
        }
    }
    var tint: Color {
        switch self {
        case .all: .orange
        case .category(let c): c.color
        }
    }
}

/// Kategorie-Leiste im MTabBar-Stil (s. Datei-Kopf).
struct KKCategoryBar: View {
    @Binding var selection: RecipeCategory?
    var spacing: CGFloat = 8
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var activeTab: KKCategoryTab { selection.map(KKCategoryTab.category) ?? .all }

    @State private var tabTitleSizes: [KKCategoryTab: CGSize] = [:]

    var body: some View {
        GeometryReader { proxy in
            let allTabs = KKCategoryTab.allTabs
            let activeTitleWidth = tabTitleSizes[activeTab]?.width ?? 0
            /// Symbol: 20, horizontales Padding: 32, Abstand: 6
            let activeWidth = activeTitleWidth + 52 + 6
            let spacingValue = CGFloat(allTabs.count - 1) * spacing
            let inactiveWidth = max(0, (proxy.size.width - activeWidth - spacingValue) / CGFloat(allTabs.count - 1))

            HStack(spacing: spacing) {
                ForEach(allTabs, id: \.self) { tab in
                    tabButton(tab, inactiveWidth: inactiveWidth)
                }
            }
        }
        .frame(height: 44)
        .animation(reduceMotion ? nil : .interpolatingSpring(duration: 0.3, bounce: 0), value: activeTab)
    }

    @ViewBuilder
    private func tabButton(_ tab: KKCategoryTab, inactiveWidth: CGFloat) -> some View {
        let isActive = tab == activeTab
        Button {
            selection = if case .category(let c) = tab { c } else { nil }
        } label: {
            HStack(spacing: isActive ? 6 : 0) {
                Image(systemName: tab.symbol)
                    .font(.body)
                    .frame(width: 20)
                Text(tab.title)
                    .font(.system(.callout, design: .serif).weight(.semibold))
                    .fixedSize(horizontal: true, vertical: false)
                    .lineLimit(1)
                    .onGeometryChange(for: CGSize.self) { $0.size } action: { tabTitleSizes[tab] = $0 }
                    .frame(width: isActive ? nil : 0, alignment: .leading)
                    .opacity(isActive ? 1 : 0)
            }
            .foregroundStyle(isActive ? .white : tab.tint)
            .padding(.horizontal, isActive ? 16 : 0)
            .frame(maxHeight: .infinity)
            .frame(width: isActive ? nil : inactiveWidth)
            .background(Capsule().fill(isActive ? tab.tint : tab.tint.opacity(0.14)))
            .clipShape(.capsule)
            .contentShape(.capsule)
            .geometryGroup()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isActive ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview {
    @Previewable @State var selection: RecipeCategory? = nil
    KKCategoryBar(selection: $selection)
        .padding(.horizontal, 16)
}
