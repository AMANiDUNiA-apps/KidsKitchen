//
//  KKChips.swift
//  KiDSKiTCHEN
//
//  Mehrfach-Auswahl-Chips mit umbrechendem Layout. Übernommen aus Kavsoft
//  „ChipSelection" von Balaji Venkatesh (10/03/25) — Logik unverändert, nur
//  Preview an KK angepasst. Quelle: ~/z/Agents/Claude/xCode/kavsoft/ChipSelection.
//

import SwiftUI

struct ChipsView<Content: View, Tag: Equatable>: View where Tag: Hashable {
    var spacing: CGFloat = 10
    var animation: Animation = .easeInOut(duration: 0.2)
    var tags: [Tag]
    @ViewBuilder var content: (Tag, Bool) -> Content
    var didChangeSelection: ([Tag]) -> ()
    /// View Properties
    @State private var selectedTags: [Tag] = []
    var body: some View {
        CustomChipLayout(spacing: spacing) {
            ForEach(tags, id: \.self) { tag in
                content(tag, selectedTags.contains(tag))
                    .contentShape(.rect)
                    .onTapGesture {
                        withAnimation(animation) {
                            if selectedTags.contains(tag) {
                                selectedTags.removeAll(where: { $0 == tag })
                            } else {
                                selectedTags.append(tag)
                            }
                        }

                        /// Callback after update!
                        didChangeSelection(selectedTags)
                    }
            }
        }
    }
}

fileprivate struct CustomChipLayout: Layout {
    var spacing: CGFloat
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        return .init(width: width, height: maxHeight(proposal: proposal, subviews: subviews))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var origin = bounds.origin

        for subview in subviews {
            let fitSize = subview.sizeThatFits(proposal)

            if (origin.x + fitSize.width) > bounds.maxX {
                origin.x = bounds.minX
                origin.y += fitSize.height + spacing

                subview.place(at: origin, proposal: proposal)
                origin.x += fitSize.width + spacing
            } else {
                subview.place(at: origin, proposal: proposal)
                origin.x += fitSize.width + spacing
            }
        }
    }

    private func maxHeight(proposal: ProposedViewSize, subviews: Subviews) -> CGFloat {
        var origin: CGPoint = .zero

        for subview in subviews {
            let fitSize = subview.sizeThatFits(proposal)

            if (origin.x + fitSize.width) > (proposal.width ?? 0) {
                origin.x = 0
                origin.y += fitSize.height + spacing

                origin.x += fitSize.width + spacing
            } else {
                origin.x += fitSize.width + spacing
            }

            if subview == subviews.last {
                origin.y += fitSize.height
            }
        }

        return origin.y
    }
}

// MARK: - Kategorie-Filter (geteilt: Einkaufsliste · Wochenplaner · Vorratsschrank)

/// Etwas, das als Kategorie-Filter-Chip dargestellt werden kann. Erlaubt EINEN
/// Chip-Typ für IngredientCategory (Einkaufsliste/Vorrat) UND RecipeCategory
/// (Wochenplaner) — ohne Umbau der jeweiligen Kategorie-Enums.
protocol CategoryChipRepresentable: Hashable {
    var chipTitle: String { get }
    var chipColor: Color { get }
    var chipSymbol: String { get }
}

extension IngredientCategory: CategoryChipRepresentable {
    var chipTitle: String { title }
    var chipColor: Color { color }
    var chipSymbol: String { symbolName }
}

extension RecipeCategory: CategoryChipRepresentable {
    var chipTitle: String { rawValue }
    var chipColor: Color { color }
    var chipSymbol: String { symbolName }
}

/// Kindgerechter Kategorie-Chip (Serifen, de_DE). Gefüllt in Kategoriefarbe,
/// wenn ausgewählt — sichtbare Bedienung statt versteckter Filter.
struct CategoryChip<C: CategoryChipRepresentable>: View {
    let category: C
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: category.chipSymbol)
                .font(.footnote)
            Text(category.chipTitle)
                .font(.system(.subheadline, design: .serif).weight(.medium))
        }
        .foregroundStyle(isSelected ? .white : category.chipColor)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            isSelected ? category.chipColor : category.chipColor.opacity(0.14),
            in: .capsule
        )
        .overlay(
            Capsule().strokeBorder(category.chipColor.opacity(isSelected ? 0 : 0.35), lineWidth: 1)
        )
        .accessibilityLabel(category.chipTitle)
        .accessibilityValue(isSelected ? "Filter aktiv" : "Filter aus")
        .accessibilityAddTraits(.isButton)
    }
}

/// Umbrechender Kategorie-Filterstreifen. Zeigt nur die übergebenen — real
/// vorhandenen — Kategorien und meldet die Mehrfach-Auswahl zurück (leer = alles).
struct CategoryFilterChips<C: CategoryChipRepresentable>: View {
    let categories: [C]
    var onChange: ([C]) -> Void

    var body: some View {
        ChipsView(tags: categories) { category, isSelected in
            CategoryChip(category: category, isSelected: isSelected)
        } didChangeSelection: { onChange($0) }
    }
}

#Preview {
    ChipsView(tags: ["Obst", "Gemüse", "Getreide", "Milchprodukte"]) { tag, isSelected in
        Text(tag)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color(.secondarySystemBackground),
                        in: .capsule)
    } didChangeSelection: { _ in }
        .padding()
}
