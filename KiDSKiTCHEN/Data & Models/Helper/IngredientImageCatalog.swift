//
//  IngredientImageCatalog.swift
//  KiDSKiTCHEN
//
//  GENERIERT aus pipelines/ingredient-images/prompts.json (111 Zutat-Bilder,
//  Bilder-Einbau 11.7.). Enthält die Asset-Namen (= normalisierte Datei-Stämme)
//  aller vorhandenen Zutat-Fotos. Bei neuen Bildern neu generieren, nicht von
//  Hand pflegen. Siehe IngredientImageView.swift für die Auflösung.
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
