//
//  IngredientImageView.swift
//  KiDSKiTCHEN
//
//  Zutat-Bild-Strecke (Bilder-Einbau 11.7.): je Zutat ein fotorealistisches
//  PNG-mit-Alpha aus dem Asset-Katalog (Ordner „Ingredients", 111 Zutaten,
//  Jay-Entscheid 11.7.: Foto-Stil). Kein Treffer → bisheriges Kategorie-
//  SF-Symbol als Fallback (nichts wird kaputt gemacht). Die Zuordnung läuft
//  über eine deterministische Namens-Normalisierung, die 1:1 die Dateinamen
//  aus pipelines/ingredient-images/prompts.json reproduziert
//  (Umlaute → ae/oe/ue, ß → ss, Kleinschreibung, nur a–z/0–9).
//

import SwiftUI

// Namens-Normalisierung/Katalog-Zugehörigkeit (imageAssetKey/imageAssetName/
// hasIngredientImage) sitzen seit Rebuild P2 in Domain/Matching/IngredientImageCatalog.swift.

// MARK: - IngredientImageView
/// Zeigt das freigestellte Zutat-Foto (Alpha, hell/dunkel-tauglich) in einem
/// quadratischen Slot; ohne Treffer das getönte Kategorie-Symbol als Fallback.
/// `size` ist die Kantenlänge des Slots in Punkten.
struct IngredientImageView: View {
    let ingredient: Ingredient
    var size: CGFloat

    var body: some View {
        // Auflösung über die Match-Schicht (exakt → Alias → Fuzzy → FoundationModels),
        // lazy gecacht im Mapping-Store. Für die sauber benannten Seed-Zutaten ist das
        // exakt derselbe Treffer wie zuvor; zusätzlich greifen Plural/Synonyme/Fuzzy.
        let asset = IngredientImageMapping.shared.assetKey(for: ingredient.name)
        Group {
            if let asset {
                Image(asset)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: ingredient.category.symbolName)
                    .font(.system(size: size * 0.8))
                    .foregroundStyle(ingredient.category.color)
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    HStack(spacing: 16) {
        IngredientImageView(ingredient: Ingredient(name: "Apfel", category: .fruit), size: 60)
        IngredientImageView(ingredient: Ingredient(name: "Süßkartoffel", category: .vegetable), size: 60)
        // Fallback: kein Bild vorhanden → Kategorie-Symbol
        IngredientImageView(ingredient: Ingredient(name: "Ausgedachtes", category: .other), size: 60)
    }
    .padding()
}
