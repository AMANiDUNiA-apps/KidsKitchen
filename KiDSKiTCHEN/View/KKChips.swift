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
