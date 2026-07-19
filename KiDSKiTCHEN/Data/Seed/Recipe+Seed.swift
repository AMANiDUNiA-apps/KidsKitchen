//
//  Recipe+Seed.swift
//  KiDSKiTCHEN
//
//  Created by Claude Fable 5 on 03.07.26.
//  Handgemachte, kindgerechte Start-Rezepte (gute deutsche Texte statt Scrape-Übersetzung).
//  Nutzt nur vorhandene Seed-Zutaten + Einheiten. Später ersetzt die Supabase/Vapor-Quelle
//  diese Liste — bis dahin macht sie die Home-Liste für den MVP lebendig.
//

import Foundation

extension Recipe {
    /// Was die App beim Start zeigt (inkl. des bestehenden Porridge-Mocks).
    static let seed: [Recipe] = [
        .mock,

        Recipe(
            name: "Bananen-Pfannkuchen",
            details: "Fluffige Pfannkuchen, die ganz ohne Zucker süß sind — die Banane macht's.",
            category: .breakfast,
            level: "leicht",
            ingredients: [
                RecipeIngredient(ingredient: Ingredient(name: "Banane", category: .fruit), amount: 2, unit: .piece),
                RecipeIngredient(ingredient: Ingredient(name: "Ei", category: .other), amount: 2, unit: .piece),
                RecipeIngredient(ingredient: Ingredient(name: "Haferflocken", category: .cereals), amount: 60, unit: .gram),
                RecipeIngredient(ingredient: Ingredient(name: "Butter", category: .fatsAndOils), amount: 1, unit: .teaspoon),
            ],
            instructions: [
                RecipeInstruction(text: "Bananen mit einer Gabel zu Mus zerdrücken."),
                RecipeInstruction(text: "Eier und Haferflocken untermischen, kurz quellen lassen."),
                RecipeInstruction(text: "Butter in der Pfanne schmelzen und kleine Pfannkuchen backen."),
                RecipeInstruction(text: "Von beiden Seiten goldbraun braten — fertig!"),
            ],
            nutrition: Nutrition(kcal: 290, protein: 12, carbs: 38, fat: 9, fiber: 5),
            prepTime: 5, cookTime: 10, restTime: 0
        ),

        Recipe(
            name: "Rührei mit Schnittlauch",
            details: "In fünf Minuten auf dem Teller — perfekt fürs schnelle Frühstück.",
            category: .breakfast,
            level: "leicht",
            ingredients: [
                RecipeIngredient(ingredient: Ingredient(name: "Ei", category: .other), amount: 3, unit: .piece),
                RecipeIngredient(ingredient: Ingredient(name: "Milch", category: .dairy), amount: 30, unit: .milliliter),
                RecipeIngredient(ingredient: Ingredient(name: "Butter", category: .fatsAndOils), amount: 1, unit: .teaspoon),
                RecipeIngredient(ingredient: Ingredient(name: "Schnittlauch", category: .herbs), amount: 1, unit: .tablespoon),
                RecipeIngredient(ingredient: Ingredient(name: "Salz", category: .spices), amount: 1, unit: .pinch),
            ],
            instructions: [
                RecipeInstruction(text: "Eier mit Milch und einer Prise Salz verquirlen."),
                RecipeInstruction(text: "Butter in der Pfanne schmelzen lassen."),
                RecipeInstruction(text: "Eiermasse hineingeben und bei kleiner Hitze langsam rühren."),
                RecipeInstruction(text: "Mit Schnittlauch bestreuen und sofort essen."),
            ],
            nutrition: Nutrition(kcal: 240, protein: 19, carbs: 2, fat: 17, fiber: 0),
            prepTime: 3, cookTime: 5, restTime: 0
        ),

        Recipe(
            name: "Nudeln mit Tomatensauce",
            details: "Der Klassiker, den fast jedes Kind liebt — mit einer schnellen frischen Sauce.",
            category: .mainDish,
            level: "leicht",
            ingredients: [
                RecipeIngredient(ingredient: Ingredient(name: "Nudeln", category: .cereals), amount: 250, unit: .gram),
                RecipeIngredient(ingredient: Ingredient(name: "Tomate", category: .vegetable), amount: 4, unit: .piece),
                RecipeIngredient(ingredient: Ingredient(name: "Zwiebel", category: .vegetable), amount: 1, unit: .piece),
                RecipeIngredient(ingredient: Ingredient(name: "Olivenöl", category: .fatsAndOils), amount: 1, unit: .tablespoon),
                RecipeIngredient(ingredient: Ingredient(name: "Salz", category: .spices), amount: 1, unit: .pinch),
            ],
            instructions: [
                RecipeInstruction(text: "Nudeln nach Packung in Salzwasser kochen."),
                RecipeInstruction(text: "Zwiebel klein schneiden und in Olivenöl glasig dünsten."),
                RecipeInstruction(text: "Tomaten würfeln, dazugeben und 10 Minuten köcheln lassen."),
                RecipeInstruction(text: "Mit Salz abschmecken und über die Nudeln geben."),
            ],
            nutrition: Nutrition(kcal: 420, protein: 13, carbs: 78, fat: 7, fiber: 6),
            prepTime: 10, cookTime: 15, restTime: 0
        ),

        Recipe(
            name: "Gemüsesticks mit Joghurt-Dip",
            details: "Bunt, knackig und zum Selber-Dippen — ein Snack, der Spaß macht.",
            category: .snack,
            level: "leicht",
            ingredients: [
                RecipeIngredient(ingredient: Ingredient(name: "Karotte", category: .vegetable), amount: 2, unit: .piece),
                RecipeIngredient(ingredient: Ingredient(name: "Gurke", category: .vegetable), amount: 1, unit: .piece),
                RecipeIngredient(ingredient: Ingredient(name: "Paprika", category: .vegetable), amount: 1, unit: .piece),
                RecipeIngredient(ingredient: Ingredient(name: "Joghurt", category: .dairy), amount: 150, unit: .gram),
                RecipeIngredient(ingredient: Ingredient(name: "Schnittlauch", category: .herbs), amount: 1, unit: .tablespoon),
            ],
            instructions: [
                RecipeInstruction(text: "Gemüse waschen und in Sticks schneiden."),
                RecipeInstruction(text: "Joghurt mit fein geschnittenem Schnittlauch verrühren."),
                RecipeInstruction(text: "Alles hübsch auf einem Teller anrichten."),
                RecipeInstruction(text: "Sticks in den Dip tunken und genießen."),
            ],
            nutrition: Nutrition(kcal: 150, protein: 7, carbs: 18, fat: 5, fiber: 6),
            prepTime: 10, cookTime: 0, restTime: 0
        ),

        Recipe(
            name: "Beeren-Quark",
            details: "Cremiger Quark mit Beeren und einem Hauch Honig — süß, aber gesund.",
            category: .dessert,
            level: "leicht",
            ingredients: [
                RecipeIngredient(ingredient: Ingredient(name: "Quark", category: .dairy), amount: 250, unit: .gram),
                RecipeIngredient(ingredient: Ingredient(name: "Heidelbeere", category: .fruit), amount: 100, unit: .gram),
                RecipeIngredient(ingredient: Ingredient(name: "Erdbeere", category: .fruit), amount: 100, unit: .gram),
                RecipeIngredient(ingredient: Ingredient(name: "Honig", category: .other), amount: 1, unit: .tablespoon),
            ],
            instructions: [
                RecipeInstruction(text: "Quark mit Honig glatt rühren."),
                RecipeInstruction(text: "Erdbeeren in kleine Stücke schneiden."),
                RecipeInstruction(text: "Beeren unter den Quark heben oder als Schicht anrichten."),
                RecipeInstruction(text: "Kalt servieren."),
            ],
            nutrition: Nutrition(kcal: 220, protein: 20, carbs: 26, fat: 4, fiber: 3),
            prepTime: 8, cookTime: 0, restTime: 0
        ),

        // MARK: V1-Aufstockung (6.7.) — bewusst OHNE nutrition-Parameter:
        // Anzeige läuft über displayNutrition (echte BLS-Werte, ≥80 % Abdeckung),
        // sonst wird die Sektion ausgeblendet. Keine geratenen Zahlen.

        Recipe(
            name: "Erdbeer-Bananen-Smoothie",
            details: "Rosa, cremig und in zwei Minuten fertig — Obst zum Trinken.",
            category: .drink,
            level: "leicht",
            ingredients: [
                RecipeIngredient(ingredient: Ingredient(name: "Erdbeere", category: .fruit), amount: 150, unit: .gram),
                RecipeIngredient(ingredient: Ingredient(name: "Banane", category: .fruit), amount: 1, unit: .piece),
                RecipeIngredient(ingredient: Ingredient(name: "Milch", category: .dairy), amount: 200, unit: .milliliter),
                RecipeIngredient(ingredient: Ingredient(name: "Honig", category: .other), amount: 1, unit: .teaspoon),
            ],
            instructions: [
                RecipeInstruction(text: "Erdbeeren waschen und den grünen Deckel entfernen."),
                RecipeInstruction(text: "Banane schälen und in Stücke brechen."),
                RecipeInstruction(text: "Alles mit Milch und Honig in den Mixer geben."),
                RecipeInstruction(text: "So lange mixen, bis keine Stückchen mehr zu sehen sind."),
            ],
            prepTime: 5, cookTime: 0, restTime: 0
        ),

        Recipe(
            name: "Overnight-Oats mit Heidelbeeren",
            details: "Abends anrühren, morgens löffeln — das Frühstück macht sich über Nacht selbst.",
            category: .breakfast,
            level: "leicht",
            ingredients: [
                RecipeIngredient(ingredient: Ingredient(name: "Haferflocken", category: .cereals), amount: 80, unit: .gram),
                RecipeIngredient(ingredient: Ingredient(name: "Joghurt", category: .dairy), amount: 150, unit: .gram),
                RecipeIngredient(ingredient: Ingredient(name: "Milch", category: .dairy), amount: 100, unit: .milliliter),
                RecipeIngredient(ingredient: Ingredient(name: "Heidelbeere", category: .fruit), amount: 100, unit: .gram),
                RecipeIngredient(ingredient: Ingredient(name: "Honig", category: .other), amount: 1, unit: .teaspoon),
            ],
            instructions: [
                RecipeInstruction(text: "Haferflocken, Joghurt, Milch und Honig in ein Glas geben und verrühren."),
                RecipeInstruction(text: "Glas verschließen und über Nacht in den Kühlschrank stellen."),
                RecipeInstruction(text: "Am Morgen die Heidelbeeren waschen und obendrauf geben."),
                RecipeInstruction(text: "Direkt aus dem Glas löffeln."),
            ],
            prepTime: 5, cookTime: 0, restTime: 480
        ),

        Recipe(
            name: "Ofen-Kartoffelspalten mit Quark-Dip",
            details: "Knusprige Spalten aus dem Ofen — wie Pommes, nur selbst gemacht.",
            category: .sideDish,
            level: "leicht",
            ingredients: [
                RecipeIngredient(ingredient: Ingredient(name: "Kartoffel", category: .vegetable), amount: 600, unit: .gram),
                RecipeIngredient(ingredient: Ingredient(name: "Olivenöl", category: .fatsAndOils), amount: 2, unit: .tablespoon),
                RecipeIngredient(ingredient: Ingredient(name: "Paprikapulver", category: .spices), amount: 1, unit: .teaspoon),
                RecipeIngredient(ingredient: Ingredient(name: "Salz", category: .spices), amount: 1, unit: .pinch),
                RecipeIngredient(ingredient: Ingredient(name: "Quark", category: .dairy), amount: 200, unit: .gram),
                RecipeIngredient(ingredient: Ingredient(name: "Schnittlauch", category: .herbs), amount: 1, unit: .tablespoon),
            ],
            instructions: [
                RecipeInstruction(text: "Backofen auf 200 Grad vorheizen — das macht ein Erwachsener."),
                RecipeInstruction(text: "Kartoffeln gut waschen und in Spalten schneiden."),
                RecipeInstruction(text: "Spalten mit Öl, Paprikapulver und Salz in einer Schüssel mischen."),
                RecipeInstruction(text: "Auf ein Blech legen und etwa 30 Minuten backen, bis sie goldbraun sind."),
                RecipeInstruction(text: "Quark mit Schnittlauch verrühren und zu den Spalten dippen."),
            ],
            prepTime: 15, cookTime: 30, restTime: 0
        ),

        Recipe(
            name: "Kunterbunter Nudelsalat",
            details: "Viele Farben in einer Schüssel — perfekt fürs Picknick oder die Brotdose.",
            category: .mainDish,
            level: "leicht",
            ingredients: [
                RecipeIngredient(ingredient: Ingredient(name: "Nudeln", category: .cereals), amount: 250, unit: .gram),
                RecipeIngredient(ingredient: Ingredient(name: "Tomate", category: .vegetable), amount: 2, unit: .piece),
                RecipeIngredient(ingredient: Ingredient(name: "Gurke", category: .vegetable), amount: 1, unit: .piece),
                RecipeIngredient(ingredient: Ingredient(name: "Mais", category: .vegetable), amount: 140, unit: .gram),
                RecipeIngredient(ingredient: Ingredient(name: "Käse", category: .dairy), amount: 100, unit: .gram),
                RecipeIngredient(ingredient: Ingredient(name: "Olivenöl", category: .fatsAndOils), amount: 2, unit: .tablespoon),
            ],
            instructions: [
                RecipeInstruction(text: "Nudeln kochen, abgießen und abkühlen lassen."),
                RecipeInstruction(text: "Tomaten, Gurke und Käse in kleine Würfel schneiden."),
                RecipeInstruction(text: "Alles mit dem Mais in eine große Schüssel geben."),
                RecipeInstruction(text: "Olivenöl darüber geben und kräftig durchmischen."),
            ],
            prepTime: 15, cookTime: 10, restTime: 20
        ),

        Recipe(
            name: "Mini-Pizzen auf Toast",
            details: "Deine eigene kleine Pizza — jeder belegt, wie er mag.",
            category: .snack,
            level: "leicht",
            ingredients: [
                RecipeIngredient(ingredient: Ingredient(name: "Toast", category: .cereals), amount: 4, unit: .piece),
                RecipeIngredient(ingredient: Ingredient(name: "Tomatenmark", category: .other), amount: 2, unit: .tablespoon),
                RecipeIngredient(ingredient: Ingredient(name: "Käse", category: .dairy), amount: 80, unit: .gram),
                RecipeIngredient(ingredient: Ingredient(name: "Paprika", category: .vegetable), amount: 1, unit: .piece),
                RecipeIngredient(ingredient: Ingredient(name: "Oregano", category: .herbs), amount: 1, unit: .pinch),
            ],
            instructions: [
                RecipeInstruction(text: "Backofen auf 180 Grad vorheizen — das macht ein Erwachsener."),
                RecipeInstruction(text: "Toastscheiben dünn mit Tomatenmark bestreichen."),
                RecipeInstruction(text: "Paprika in kleine Stücke schneiden und die Toasts damit belegen."),
                RecipeInstruction(text: "Käse darüber streuen und eine Prise Oregano dazu."),
                RecipeInstruction(text: "Etwa 10 Minuten backen, bis der Käse schmilzt."),
            ],
            prepTime: 10, cookTime: 10, restTime: 0
        ),

        Recipe(
            name: "Gemüse-Couscous mit Erbsen",
            details: "Winzige Kügelchen, die Brühe trinken — Couscous kocht sich fast von allein.",
            category: .mainDish,
            level: "leicht",
            ingredients: [
                RecipeIngredient(ingredient: Ingredient(name: "Couscous", category: .cereals), amount: 200, unit: .gram),
                RecipeIngredient(ingredient: Ingredient(name: "Gemüsebrühe", category: .other), amount: 250, unit: .milliliter),
                RecipeIngredient(ingredient: Ingredient(name: "Erbsen", category: .vegetable), amount: 150, unit: .gram),
                RecipeIngredient(ingredient: Ingredient(name: "Karotte", category: .vegetable), amount: 2, unit: .piece),
                RecipeIngredient(ingredient: Ingredient(name: "Olivenöl", category: .fatsAndOils), amount: 1, unit: .tablespoon),
            ],
            instructions: [
                RecipeInstruction(text: "Karotten schälen und in kleine Würfel schneiden."),
                RecipeInstruction(text: "Karotten und Erbsen in etwas Öl ein paar Minuten dünsten."),
                RecipeInstruction(text: "Heiße Gemüsebrühe über den Couscous gießen und abdecken."),
                RecipeInstruction(text: "Fünf Minuten warten, mit der Gabel auflockern und das Gemüse untermischen."),
            ],
            prepTime: 10, cookTime: 10, restTime: 5
        ),

        Recipe(
            name: "Fischstäbchen mit Kartoffel-Erbsen-Stampf",
            details: "Der Klassiker aus dem Ofen mit grünem Wolken-Püree.",
            category: .mainDish,
            level: "mittel",
            ingredients: [
                RecipeIngredient(ingredient: Ingredient(name: "Fischstäbchen", category: .fish), amount: 8, unit: .piece),
                RecipeIngredient(ingredient: Ingredient(name: "Kartoffel", category: .vegetable), amount: 500, unit: .gram),
                RecipeIngredient(ingredient: Ingredient(name: "Erbsen", category: .vegetable), amount: 150, unit: .gram),
                RecipeIngredient(ingredient: Ingredient(name: "Milch", category: .dairy), amount: 100, unit: .milliliter),
                RecipeIngredient(ingredient: Ingredient(name: "Butter", category: .fatsAndOils), amount: 1, unit: .tablespoon),
                RecipeIngredient(ingredient: Ingredient(name: "Salz", category: .spices), amount: 1, unit: .pinch),
            ],
            instructions: [
                RecipeInstruction(text: "Kartoffeln schälen, würfeln und in Salzwasser weich kochen."),
                RecipeInstruction(text: "Fischstäbchen nach Packung im Ofen backen — den Ofen bedient ein Erwachsener."),
                RecipeInstruction(text: "Erbsen die letzten fünf Minuten zu den Kartoffeln geben."),
                RecipeInstruction(text: "Wasser abgießen, Milch und Butter dazu und alles stampfen."),
                RecipeInstruction(text: "Stampf mit den Fischstäbchen anrichten."),
            ],
            prepTime: 15, cookTime: 20, restTime: 0
        ),

        Recipe(
            name: "Milde Hähnchen-Reispfanne",
            details: "Alles in einer Pfanne: zartes Hähnchen, buntes Gemüse und lockerer Reis.",
            category: .mainDish,
            level: "mittel",
            ingredients: [
                RecipeIngredient(ingredient: Ingredient(name: "Hähnchenbrust", category: .poultry), amount: 300, unit: .gram),
                RecipeIngredient(ingredient: Ingredient(name: "Reis", category: .cereals), amount: 200, unit: .gram),
                RecipeIngredient(ingredient: Ingredient(name: "Paprika", category: .vegetable), amount: 1, unit: .piece),
                RecipeIngredient(ingredient: Ingredient(name: "Erbsen", category: .vegetable), amount: 100, unit: .gram),
                RecipeIngredient(ingredient: Ingredient(name: "Rapsöl", category: .fatsAndOils), amount: 1, unit: .tablespoon),
                RecipeIngredient(ingredient: Ingredient(name: "Currypulver", category: .spices), amount: 1, unit: .teaspoon),
            ],
            instructions: [
                RecipeInstruction(text: "Reis nach Packung kochen."),
                RecipeInstruction(text: "Hähnchen in Würfel schneiden — danach gut die Hände waschen!"),
                RecipeInstruction(text: "Hähnchen im Öl rundherum goldbraun braten, bis es innen ganz durch ist."),
                RecipeInstruction(text: "Paprikawürfel und Erbsen dazugeben und mitbraten."),
                RecipeInstruction(text: "Reis und eine Prise Currypulver untermischen und kurz durchschwenken."),
            ],
            prepTime: 15, cookTime: 25, restTime: 0
        ),

        Recipe(
            name: "Kürbis-Kartoffel-Suppe",
            details: "Eine orange Löffelsuppe, die von innen wärmt — mit lustigem Kürbisgesicht-Potenzial.",
            category: .mainDish,
            seasons: [.autumn, .winter],
            level: "mittel",
            ingredients: [
                RecipeIngredient(ingredient: Ingredient(name: "Kürbis", category: .vegetable), amount: 500, unit: .gram),
                RecipeIngredient(ingredient: Ingredient(name: "Kartoffel", category: .vegetable), amount: 300, unit: .gram),
                RecipeIngredient(ingredient: Ingredient(name: "Zwiebel", category: .vegetable), amount: 1, unit: .piece),
                RecipeIngredient(ingredient: Ingredient(name: "Gemüsebrühe", category: .other), amount: 750, unit: .milliliter),
                RecipeIngredient(ingredient: Ingredient(name: "Sahne", category: .dairy), amount: 100, unit: .milliliter),
                RecipeIngredient(ingredient: Ingredient(name: "Rapsöl", category: .fatsAndOils), amount: 1, unit: .tablespoon),
            ],
            instructions: [
                RecipeInstruction(text: "Kürbis und Kartoffeln in Würfel schneiden — beim Kürbis hilft ein Erwachsener."),
                RecipeInstruction(text: "Zwiebel würfeln und im Öl glasig dünsten."),
                RecipeInstruction(text: "Kürbis, Kartoffeln und Brühe dazugeben und 20 Minuten kochen."),
                RecipeInstruction(text: "Alles fein pürieren — Vorsicht, heiß!"),
                RecipeInstruction(text: "Sahne einrühren und die Suppe in Schüsseln füllen."),
            ],
            prepTime: 15, cookTime: 25, restTime: 0
        ),

        Recipe(
            name: "Milchreis mit Kirschen",
            details: "Cremiger Reis wie eine warme Umarmung — mit fruchtigen Kirschen obendrauf.",
            category: .dessert,
            level: "mittel",
            ingredients: [
                RecipeIngredient(ingredient: Ingredient(name: "Reis", category: .cereals), amount: 125, unit: .gram),
                RecipeIngredient(ingredient: Ingredient(name: "Milch", category: .dairy), amount: 500, unit: .milliliter),
                RecipeIngredient(ingredient: Ingredient(name: "Zucker", category: .other), amount: 2, unit: .tablespoon),
                RecipeIngredient(ingredient: Ingredient(name: "Vanillezucker", category: .spices), amount: 1, unit: .teaspoon),
                RecipeIngredient(ingredient: Ingredient(name: "Kirsche", category: .fruit), amount: 150, unit: .gram),
            ],
            instructions: [
                RecipeInstruction(text: "Milch mit Zucker und Vanillezucker aufkochen — ein Erwachsener bleibt am Topf."),
                RecipeInstruction(text: "Reis einrühren und bei kleinster Hitze 30 Minuten quellen lassen."),
                RecipeInstruction(text: "Zwischendurch umrühren, damit nichts anbrennt."),
                RecipeInstruction(text: "Kirschen entkernen und über den fertigen Milchreis geben."),
            ],
            prepTime: 5, cookTime: 35, restTime: 0
        ),

        Recipe(
            name: "Grießbrei mit Apfelmus",
            details: "Weich, warm und süß — der Löffel bleibt fast von allein stecken.",
            category: .dessert,
            level: "leicht",
            ingredients: [
                RecipeIngredient(ingredient: Ingredient(name: "Grieß", category: .cereals), amount: 80, unit: .gram),
                RecipeIngredient(ingredient: Ingredient(name: "Milch", category: .dairy), amount: 500, unit: .milliliter),
                RecipeIngredient(ingredient: Ingredient(name: "Zucker", category: .other), amount: 1, unit: .tablespoon),
                RecipeIngredient(ingredient: Ingredient(name: "Apfelmus", category: .other), amount: 4, unit: .tablespoon),
                RecipeIngredient(ingredient: Ingredient(name: "Zimt", category: .spices), amount: 1, unit: .pinch),
            ],
            instructions: [
                RecipeInstruction(text: "Milch mit Zucker aufkochen — ein Erwachsener bleibt am Topf."),
                RecipeInstruction(text: "Grieß unter Rühren einrieseln lassen."),
                RecipeInstruction(text: "Bei kleiner Hitze ein paar Minuten quellen lassen und dabei rühren."),
                RecipeInstruction(text: "In Schälchen füllen und mit Apfelmus und Zimt servieren."),
            ],
            prepTime: 5, cookTime: 10, restTime: 5
        ),

        Recipe(
            name: "Apfel-Zimt-Muffins",
            details: "Kleine Kuchen mit Apfelstückchen — die ganze Küche duftet nach Zimt.",
            category: .baking,
            level: "mittel",
            ingredients: [
                RecipeIngredient(ingredient: Ingredient(name: "Weizenmehl", category: .cereals), amount: 250, unit: .gram),
                RecipeIngredient(ingredient: Ingredient(name: "Backpulver", category: .other), amount: 2, unit: .teaspoon),
                RecipeIngredient(ingredient: Ingredient(name: "Zucker", category: .other), amount: 80, unit: .gram),
                RecipeIngredient(ingredient: Ingredient(name: "Ei", category: .other), amount: 2, unit: .piece),
                RecipeIngredient(ingredient: Ingredient(name: "Butter", category: .fatsAndOils), amount: 80, unit: .gram),
                RecipeIngredient(ingredient: Ingredient(name: "Milch", category: .dairy), amount: 150, unit: .milliliter),
                RecipeIngredient(ingredient: Ingredient(name: "Apfel", category: .fruit), amount: 2, unit: .piece),
                RecipeIngredient(ingredient: Ingredient(name: "Zimt", category: .spices), amount: 1, unit: .teaspoon),
            ],
            instructions: [
                RecipeInstruction(text: "Backofen auf 180 Grad vorheizen — das macht ein Erwachsener."),
                RecipeInstruction(text: "Weiche Butter, Zucker und Eier schaumig rühren."),
                RecipeInstruction(text: "Mehl, Backpulver, Zimt und Milch untermischen."),
                RecipeInstruction(text: "Äpfel in kleine Würfel schneiden und unterheben."),
                RecipeInstruction(text: "Teig in Muffinförmchen füllen und etwa 20 Minuten backen."),
                RecipeInstruction(text: "Mit einem Holzstäbchen testen: bleibt nichts kleben, sind sie fertig."),
            ],
            servings: 12,
            prepTime: 20, cookTime: 20, restTime: 10
        ),

        Recipe(
            name: "Bunte Obstspieße mit Joghurt",
            details: "Obst am Stiel! Aufspießen, dippen, glücklich sein.",
            category: .snack,
            level: "leicht",
            ingredients: [
                RecipeIngredient(ingredient: Ingredient(name: "Erdbeere", category: .fruit), amount: 150, unit: .gram),
                RecipeIngredient(ingredient: Ingredient(name: "Banane", category: .fruit), amount: 1, unit: .piece),
                RecipeIngredient(ingredient: Ingredient(name: "Traube", category: .fruit), amount: 100, unit: .gram),
                RecipeIngredient(ingredient: Ingredient(name: "Joghurt", category: .dairy), amount: 150, unit: .gram),
                RecipeIngredient(ingredient: Ingredient(name: "Honig", category: .other), amount: 1, unit: .teaspoon),
            ],
            instructions: [
                RecipeInstruction(text: "Obst waschen und in mundgerechte Stücke schneiden."),
                RecipeInstruction(text: "Die Stücke bunt gemischt auf Holzspieße stecken."),
                RecipeInstruction(text: "Joghurt mit Honig verrühren — das ist der Dip."),
                RecipeInstruction(text: "Spieße eintunken und wegnaschen."),
            ],
            prepTime: 15, cookTime: 0, restTime: 0
        ),
    ]
}
