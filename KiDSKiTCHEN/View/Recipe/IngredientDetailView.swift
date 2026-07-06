//
//  IngredientDetailView.swift
//  KiDSKiTCHEN
//
//  Zutat-Detailansicht: visuelle BLS-Nährwertbalken in drei Tiefen (NutritionDepth).
//

import SwiftUI

struct IngredientDetailView: View {
    let ingredient: Ingredient
    @State private var depth: NutritionDepth = .mini

    private var facts: NutritionFacts? { NutritionFacts.bls(for: ingredient.name) }

    var body: some View {
        List {
            Section { header }

            if let facts {
                Section("Nährwerte je 100 g") {
                    Picker("Detailtiefe", selection: $depth) {
                        ForEach(NutritionDepth.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .listRowSeparator(.hidden)

                    IngredientNutritionBars(facts: facts, depth: depth)
                        .listRowSeparator(.hidden)
                        .padding(.top, 4)
                }

                if !facts.highlights.isEmpty {
                    Section("Gut zu wissen") {
                        FlexibleChips(items: facts.highlights)
                    }
                }

                Section {
                    Text("Quelle: Bundeslebensmittelschlüssel — \(facts.source)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                Section {
                    ContentUnavailableView(
                        "Nährwerte folgen",
                        systemImage: "fork.knife",
                        description: Text("Für \u{201E}\(ingredient.name)\u{201C} liegen noch keine Werte vor.")
                    )
                }
            }
        }
        .navigationTitle(ingredient.name)
        .navigationBarTitleDisplayMode(.inline)
        .animation(.spring(response: 0.3), value: depth)
    }

    // MARK: Header
    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(ingredient.category.color.opacity(0.15))
                    .frame(width: 54, height: 54)
                Image(systemName: ingredient.category.symbolName)
                    .font(.title)
                    .foregroundStyle(ingredient.category.color)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(ingredient.name).font(.title3.bold())
                HStack(spacing: 6) {
                    Text(ingredient.category.title)
                        .foregroundStyle(ingredient.category.color)
                    if let badge = dietBadge {
                        Text(badge)
                            .padding(.horizontal, 8).padding(.vertical, 2)
                            .background(.green.opacity(0.15), in: Capsule())
                            .foregroundStyle(.green)
                    }
                }
                .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }

    private var dietBadge: String? {
        switch ingredient.category {
        case .fruit, .vegetable, .cereals, .nuts, .herbs, .spices: "Vegan"
        case .dairy: "Vegetarisch"
        default: nil
        }
    }
}

// MARK: - FlexibleChips
private struct FlexibleChips: View {
    let items: [String]
    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(.tint.opacity(0.12), in: Capsule())
                    .foregroundStyle(.tint)
            }
        }
    }
}

// MARK: - FlowLayout
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > maxWidth { x = 0; y += rowHeight + spacing; rowHeight = 0 }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX { x = bounds.minX; y += rowHeight + spacing; rowHeight = 0 }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    NavigationStack {
        IngredientDetailView(ingredient: Ingredient(name: "Paprika", category: .vegetable))
    }
}
