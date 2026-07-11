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

// MARK: - Namens-Normalisierung → Asset-Name
extension Ingredient {
    /// Normalisiert einen deutschen Zutatnamen auf den Datei-Stamm der Bild-
    /// Assets (z. B. „Süßkartoffel" → „suesskartoffel", „Öl" → „oel").
    /// Muss mit der Pipeline-Normalisierung übereinstimmen (prompts.json).
    static func imageAssetKey(for name: String) -> String {
        var s = name.lowercased()
        s = s.replacingOccurrences(of: "ä", with: "ae")
        s = s.replacingOccurrences(of: "ö", with: "oe")
        s = s.replacingOccurrences(of: "ü", with: "ue")
        s = s.replacingOccurrences(of: "ß", with: "ss")
        return String(s.unicodeScalars.filter { CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789").contains($0) })
    }

    /// Asset-Name, wenn für diese Zutat ein echtes Bild im Katalog liegt, sonst nil.
    var imageAssetName: String? {
        let key = Ingredient.imageAssetKey(for: name)
        return IngredientImageCatalog.names.contains(key) ? key : nil
    }

    /// True, wenn ein fotorealistisches Zutat-Bild existiert (sonst Kategorie-Symbol).
    var hasIngredientImage: Bool { imageAssetName != nil }
}

// MARK: - IngredientImageView
/// Zeigt das freigestellte Zutat-Foto (Alpha, hell/dunkel-tauglich) in einem
/// quadratischen Slot; ohne Treffer das getönte Kategorie-Symbol als Fallback.
/// `size` ist die Kantenlänge des Slots in Punkten.
struct IngredientImageView: View {
    let ingredient: Ingredient
    var size: CGFloat

    var body: some View {
        Group {
            if let asset = ingredient.imageAssetName {
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
