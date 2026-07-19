//
//  IngredientImageCatalog.swift
//  KiDSKiTCHEN
//
//  GENERIERT aus pipelines/ingredient-images/prompts.json (111 Zutat-Bilder,
//  Bilder-Einbau 11.7.). Enthält die Asset-Namen (= normalisierte Datei-Stämme)
//  aller vorhandenen Zutat-Fotos. Bei neuen Bildern neu generieren, nicht von
//  Hand pflegen. Siehe IngredientImageView.swift (Features) für die Auflösung.
//

import Foundation

enum IngredientImageCatalog {
    /// Alle vorhandenen Zutat-Bild-Assets (normalisierte Namen). Membership-Check
    /// entscheidet Foto vs. Kategorie-Symbol-Fallback.
    static let names: Set<String> = [
        "apfel", "apfelmus", "backpulver", "banane",
        "basilikum", "birne", "blumenkohl", "brokkoli",
        "brot", "butter", "cashewkerne", "chiasamen",
        "couscous", "currypulver", "dill", "dinkelmehl",
        "ei", "erbsen", "erdbeere", "erdnuesse",
        "essig", "fischstaebchen", "forelle", "frischkaese",
        "garnelen", "gemuesebruehe", "griess", "gurke",
        "haehnchenbrust", "haehnchenschenkel", "haferflocken", "haselnuesse",
        "hefe", "heidelbeere", "himbeere", "hirse",
        "honig", "joghurt", "kabeljau", "kaese",
        "kakao", "karotte", "kartoffel", "ketchup",
        "kirsche", "knoblauch", "kokosoel", "kuerbis",
        "kuerbiskerne", "kurkuma", "lachs", "lammfleisch",
        "leinsamen", "mais", "mandarine", "mandeln",
        "margarine", "marmelade", "milch", "minze",
        "mozzarella", "muskatnuss", "nudeln", "olivenoel",
        "orange", "oregano", "paprika", "paprikapulver",
        "parmesan", "petersilie", "pfeffer", "pfirsich",
        "pflaume", "putenbrust", "quark", "quinoa",
        "rapsoel", "reis", "rinderhack", "rindfleisch",
        "rosinen", "rosmarin", "sahne", "salat",
        "salz", "schmand", "schnittlauch", "schokolade",
        "schweinefleisch", "senf", "sesam", "sonnenblumenkerne",
        "sonnenblumenoel", "spinat", "suesskartoffel", "thunfisch",
        "thymian", "toast", "tomate", "tomatenmark",
        "traube", "vanillezucker", "vollkornmehl", "walnuesse",
        "wassermelone", "weizenmehl", "zimt", "zitrone",
        "zucchini", "zucker", "zwiebel",
    ]
}

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
