//
//  IngredientDetailView.swift
//  KiDSKiTCHEN
//
//  Zutat-Detailansicht: visuelle BLS-Nährwertbalken in drei Tiefen (NutritionDepth).
//

import SwiftUI

struct IngredientDetailView: View {
    let ingredient: Ingredient

    var body: some View {
        // UI-Bauweise (Jay 10.7.): selbstgebaute Container statt `List` — KKScroll + KKSection.
        KKScroll {
            KKCard { header }
            IngredientFactsSections(ingredient: ingredient)
        }
        .navigationTitle(ingredient.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Header
    private var header: some View {
        HStack(spacing: 14) {
            // Foto der Zutat freistehend (Alpha), ohne farbigen Kreis-Hintergrund
            // (Jay 11.7.: PNGs stehen frei, deutlich größer). Fallback = Kategorie-Symbol.
            // Zum Vergrößern tippen (Jay 17.7.), s. KKZoomableImage.swift.
            IngredientImageView(ingredient: ingredient, size: 64)
                .kkZoomable()
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

// MARK: - IngredientFactsSections
/// Nährwert-/„Gut zu wissen"-Sektionen einer Zutat (BLS je 100 g), mit
/// umschaltbarer Detailtiefe. Aus IngredientDetailView herausgelöst, damit die
/// Groß-Bild-Detailansicht im Vorratsschrank (PantryDetailView) dieselben Details
/// zeigt — eine Quelle statt Duplikat.
struct IngredientFactsSections: View {
    let ingredient: Ingredient
    @State private var depth: NutritionDepth = .mini
    @State private var mode: NutritionMode = .kids

    private var facts: Nutrition? { Nutrition.bls(for: ingredient.name) }

    var body: some View {
        Group {
            if let facts {
                KKSection(title: "Nährwerte je 100 g", systemImage: "chart.bar") {
                    Picker("Detailtiefe", selection: $depth) {
                        ForEach(NutritionDepth.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    Picker("Erklär-Ebene", selection: $mode) {
                        ForEach(NutritionMode.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    IngredientNutritionBars(facts: facts, depth: depth)
                        .padding(.top, 4)

                    NutrientExplainerRows(depth: depth, mode: mode)
                }

                if !facts.highlights.isEmpty {
                    KKSection(title: "Gut zu wissen", systemImage: "sparkles") {
                        FlexibleChips(items: facts.highlights)
                    }
                }

                KKCard {
                    Text("Quelle: Bundeslebensmittelschlüssel — \(facts.source ?? "BLS")")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                KKCard {
                    ContentUnavailableView(
                        "Nährwerte folgen",
                        systemImage: "fork.knife",
                        description: Text("Für \u{201E}\(ingredient.name)\u{201C} liegen noch keine Werte vor.")
                    )
                }
                .padding(.top, 40)
            }
        }
        .animation(.spring(response: 0.3), value: depth)
        .animation(.spring(response: 0.25), value: mode)
    }
}

// MARK: - NutrientExplainerRows
/// Erklär-Texte zu den sichtbaren Nährstoffen (passt sich an NutritionDepth + NutritionMode an).
private struct NutrientExplainerRows: View {
    let depth: NutritionDepth
    let mode: NutritionMode

    private var visibleKeys: [String] {
        switch depth {
        case .mini:
            return ["kcal", "protein", "fat", "carbs"]
        case .mid:
            return ["kcal", "protein", "fat", "carbs", "sugar", "fiber"]
        case .full:
            return ["kcal", "protein", "fat", "carbs", "sugar", "fiber",
                    "sodium", "calcium", "iron", "magnesium", "potassium",
                    "vitaminC", "vitaminB12"]
        }
    }

    private let labels: [String: String] = [
        "kcal": "Kalorien", "protein": "Eiweiß", "fat": "Fett",
        "carbs": "Kohlenhydrate", "sugar": "Zucker", "fiber": "Ballaststoffe",
        "sodium": "Natrium", "calcium": "Calcium", "iron": "Eisen",
        "magnesium": "Magnesium", "potassium": "Kalium",
        "vitaminC": "Vitamin C", "vitaminB12": "Vitamin B12"
    ]

    var body: some View {
        let entries = visibleKeys.compactMap { key -> (String, String)? in
            guard let text = NutrientExplainer.explain(key, mode: mode) else { return nil }
            return (labels[key] ?? key, text)
        }
        if !entries.isEmpty {
            Divider()
            VStack(alignment: .leading, spacing: 10) {
                ForEach(entries, id: \.0) { label, text in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(label)
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Text(text)
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
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
