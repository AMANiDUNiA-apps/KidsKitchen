//
//  Ingredient+Seed.swift
//  KiDSKiTCHEN
//
//  Created by Claude Fable 5 on 03.07.26.
//  Kuratierter Grundstock für den IngredientPicker — kindküchen-tauglich,
//  alle Kategorien vertreten. Die Massenbefüllung kommt später aus
//  Supabase/USDA (siehe SESSION-mac-apps.md, Nutrition-Pipeline).
//
//  Einheiten (W6, Teil B): jede Zutat trägt ihre KANONISCHE Maßeinheit für
//  Vorrat/Einkauf. Nur eindeutige Fälle sind gesetzt — `.piece` für zählbare
//  ganze Stücke, `.milliliter` für Flüssiges. Alles Übrige bleibt Default `.gram`
//  (Schütt-/Wiegezutaten). KEINE Umrechnungen, nur die reale Einheit.
//

import Foundation

extension Ingredient {
    static let seed: [Ingredient] = [
        // MARK: Obst
        Ingredient(name: "Apfel", category: .fruit, unit: .piece),
        Ingredient(name: "Banane", category: .fruit, unit: .piece),
        Ingredient(name: "Birne", category: .fruit, unit: .piece),
        Ingredient(name: "Erdbeere", category: .fruit),
        Ingredient(name: "Himbeere", category: .fruit),
        Ingredient(name: "Heidelbeere", category: .fruit),
        Ingredient(name: "Traube", category: .fruit),
        Ingredient(name: "Orange", category: .fruit, unit: .piece),
        Ingredient(name: "Mandarine", category: .fruit, unit: .piece),
        Ingredient(name: "Zitrone", category: .fruit, unit: .piece),
        Ingredient(name: "Pfirsich", category: .fruit, unit: .piece),
        Ingredient(name: "Kirsche", category: .fruit),
        Ingredient(name: "Wassermelone", category: .fruit, unit: .piece),
        Ingredient(name: "Pflaume", category: .fruit, unit: .piece),

        // MARK: Gemüse
        Ingredient(name: "Karotte", category: .vegetable, unit: .piece),
        Ingredient(name: "Kartoffel", category: .vegetable, unit: .piece),
        Ingredient(name: "Süßkartoffel", category: .vegetable, unit: .piece),
        Ingredient(name: "Tomate", category: .vegetable, unit: .piece),
        Ingredient(name: "Gurke", category: .vegetable, unit: .piece),
        Ingredient(name: "Paprika", category: .vegetable, unit: .piece),
        Ingredient(name: "Zucchini", category: .vegetable, unit: .piece),
        Ingredient(name: "Brokkoli", category: .vegetable),
        Ingredient(name: "Blumenkohl", category: .vegetable),
        Ingredient(name: "Spinat", category: .vegetable),
        Ingredient(name: "Erbsen", category: .vegetable),
        Ingredient(name: "Mais", category: .vegetable),
        Ingredient(name: "Kürbis", category: .vegetable),
        Ingredient(name: "Zwiebel", category: .vegetable, unit: .piece),
        Ingredient(name: "Knoblauch", category: .vegetable),
        Ingredient(name: "Salat", category: .vegetable, unit: .piece),

        // MARK: Getreide
        Ingredient(name: "Haferflocken", category: .cereals),
        Ingredient(name: "Vollkornmehl", category: .cereals,
                   details: "Mehl aus dem vollen Korn — mehr Ballaststoffe als Weißmehl."),
        Ingredient(name: "Weizenmehl", category: .cereals),
        Ingredient(name: "Dinkelmehl", category: .cereals),
        Ingredient(name: "Reis", category: .cereals),
        Ingredient(name: "Nudeln", category: .cereals),
        Ingredient(name: "Couscous", category: .cereals),
        Ingredient(name: "Quinoa", category: .cereals),
        Ingredient(name: "Hirse", category: .cereals),
        Ingredient(name: "Brot", category: .cereals),
        Ingredient(name: "Toast", category: .cereals, unit: .piece),
        Ingredient(name: "Grieß", category: .cereals),

        // MARK: Nüsse & Saat
        Ingredient(name: "Mandeln", category: .nuts),
        Ingredient(name: "Haselnüsse", category: .nuts),
        Ingredient(name: "Walnüsse", category: .nuts),
        Ingredient(name: "Erdnüsse", category: .nuts),
        Ingredient(name: "Cashewkerne", category: .nuts),
        Ingredient(name: "Sonnenblumenkerne", category: .nuts),
        Ingredient(name: "Kürbiskerne", category: .nuts),
        Ingredient(name: "Leinsamen", category: .nuts),
        Ingredient(name: "Sesam", category: .nuts),
        Ingredient(name: "Chiasamen", category: .nuts),

        // MARK: Milchprodukte
        Ingredient(name: "Milch", category: .dairy, unit: .milliliter),
        Ingredient(name: "Joghurt", category: .dairy),
        Ingredient(name: "Quark", category: .dairy),
        Ingredient(name: "Frischkäse", category: .dairy),
        Ingredient(name: "Käse", category: .dairy),
        Ingredient(name: "Mozzarella", category: .dairy),
        Ingredient(name: "Parmesan", category: .dairy),
        Ingredient(name: "Sahne", category: .dairy, unit: .milliliter),
        Ingredient(name: "Schmand", category: .dairy),

        // MARK: Rotes Fleisch
        Ingredient(name: "Rinderhack", category: .redMeat),
        Ingredient(name: "Rindfleisch", category: .redMeat),
        Ingredient(name: "Schweinefleisch", category: .redMeat),
        Ingredient(name: "Lammfleisch", category: .redMeat),

        // MARK: Geflügel
        Ingredient(name: "Hähnchenbrust", category: .poultry),
        Ingredient(name: "Hähnchenschenkel", category: .poultry),
        Ingredient(name: "Putenbrust", category: .poultry),

        // MARK: Fisch & Meeresfrüchte
        Ingredient(name: "Lachs", category: .fish),
        Ingredient(name: "Forelle", category: .fish),
        Ingredient(name: "Kabeljau", category: .fish),
        Ingredient(name: "Thunfisch", category: .fish),
        Ingredient(name: "Garnelen", category: .fish),
        Ingredient(name: "Fischstäbchen", category: .fish, unit: .piece),

        // MARK: Fette & Öle
        Ingredient(name: "Butter", category: .fatsAndOils),
        Ingredient(name: "Olivenöl", category: .fatsAndOils, unit: .milliliter),
        Ingredient(name: "Rapsöl", category: .fatsAndOils, unit: .milliliter),
        Ingredient(name: "Sonnenblumenöl", category: .fatsAndOils, unit: .milliliter),
        Ingredient(name: "Kokosöl", category: .fatsAndOils),
        Ingredient(name: "Margarine", category: .fatsAndOils),

        // MARK: Kräuter
        Ingredient(name: "Petersilie", category: .herbs, unit: .bunch),
        Ingredient(name: "Schnittlauch", category: .herbs, unit: .bunch),
        Ingredient(name: "Basilikum", category: .herbs, unit: .bunch),
        Ingredient(name: "Dill", category: .herbs, unit: .bunch),
        Ingredient(name: "Rosmarin", category: .herbs, unit: .bunch),
        Ingredient(name: "Thymian", category: .herbs, unit: .bunch),
        Ingredient(name: "Oregano", category: .herbs, unit: .bunch),
        Ingredient(name: "Minze", category: .herbs, unit: .bunch),

        // MARK: Gewürze
        Ingredient(name: "Salz", category: .spices),
        Ingredient(name: "Pfeffer", category: .spices),
        Ingredient(name: "Zimt", category: .spices),
        Ingredient(name: "Paprikapulver", category: .spices),
        Ingredient(name: "Currypulver", category: .spices),
        Ingredient(name: "Muskatnuss", category: .spices),
        Ingredient(name: "Kurkuma", category: .spices),
        Ingredient(name: "Vanillezucker", category: .spices),

        // MARK: Sonstige
        Ingredient(name: "Ei", category: .other, unit: .piece),
        Ingredient(name: "Honig", category: .other),
        Ingredient(name: "Zucker", category: .other),
        Ingredient(name: "Backpulver", category: .other),
        Ingredient(name: "Hefe", category: .other),
        Ingredient(name: "Kakao", category: .other),
        Ingredient(name: "Schokolade", category: .other),
        Ingredient(name: "Marmelade", category: .other),
        Ingredient(name: "Essig", category: .other, unit: .milliliter),
        Ingredient(name: "Senf", category: .other),
        Ingredient(name: "Ketchup", category: .other),
        Ingredient(name: "Tomatenmark", category: .other),
        Ingredient(name: "Gemüsebrühe", category: .other, unit: .milliliter),
        Ingredient(name: "Apfelmus", category: .other),
        Ingredient(name: "Rosinen", category: .other),
    ]
}
