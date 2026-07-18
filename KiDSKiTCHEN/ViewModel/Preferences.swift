//
//  Preferences.swift
//  KiDSKiTCHEN
//
//  Created by Claude Fable 5 on 03.07.26.
//  Persistente Nutzer-Einstellungen (UserDefaults): Diät, ausgeschlossene Zutaten,
//  Favoriten, Einkaufsliste. Bewusst leichtgewichtig (kein SwiftData) — die große
//  Speicher-Entscheidung (Supabase/Vapor) bleibt davon unberührt.
//

import Foundation
import Observation

// MARK: - ShoppingItem
struct ShoppingItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var text: String
    var done: Bool = false
    /// Kategorie der Zutat (seit Teil C). Optional: Alt-Posten aus früheren
    /// Versionen haben den Schlüssel nicht → nil, dann per `resolvedCategory`
    /// aus dem Text abgeleitet.
    var category: IngredientCategory?

    // MARK: Vorschlags-Felder (Weiterbau 8, Teil A)
    /// Automatisch aus dem Wochenplan-Bedarf erzeugt? Hand-Einträge bleiben `false`
    /// und werden von der Bedarf-Rechnung NIE angefasst (kein stilles Überschreiben).
    var suggested: Bool = false
    /// Herkunft des Vorschlags, z. B. „für Mittwoch: Bananen-Pfannkuchen".
    var origin: String?
    /// Struktur-Daten zum Zurückbuchen in den Vorrat beim Abhaken (nur gesetzt,
    /// wenn die Einheit zur kanonischen Zutat-Einheit passt — sonst keine Menge).
    var ingredientName: String?
    var amount: Int?
    var unit: IngredientUnit?
    /// Wurde die Menge schon in den Vorrat gebucht? Verhindert Doppel-Buchung beim
    /// Ab-/Anhaken (symmetrisch: abhaken bucht ein, wieder aufhaken bucht aus).
    var booked: Bool = false

    /// Bucht dieser Posten beim Abhaken eine Menge in den Vorrat? (strukturierter Vorschlag)
    var booksIntoPantry: Bool { ingredientName != nil && amount != nil && unit != nil }

    /// Echte Kategorie für Filter/Anzeige — leitet fehlende Werte aus dem Text ab.
    var resolvedCategory: IngredientCategory {
        if let category { return category }
        if let match = Ingredient.seed.first(where: { text.localizedCaseInsensitiveContains($0.name) }) {
            return match.category
        }
        return .other
    }

    // MARK: Codable (rückwärtskompatibel — Alt-Posten haben die neuen Schlüssel nicht)
    enum CodingKeys: String, CodingKey {
        case id, text, done, category
        case suggested, origin, ingredientName, amount, unit, booked
    }

    init(id: UUID = UUID(), text: String, done: Bool = false,
         category: IngredientCategory? = nil, suggested: Bool = false,
         origin: String? = nil, ingredientName: String? = nil,
         amount: Int? = nil, unit: IngredientUnit? = nil, booked: Bool = false) {
        self.id = id; self.text = text; self.done = done; self.category = category
        self.suggested = suggested; self.origin = origin
        self.ingredientName = ingredientName; self.amount = amount
        self.unit = unit; self.booked = booked
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        text = try c.decode(String.self, forKey: .text)
        done = try c.decodeIfPresent(Bool.self, forKey: .done) ?? false
        category = try c.decodeIfPresent(IngredientCategory.self, forKey: .category)
        suggested = try c.decodeIfPresent(Bool.self, forKey: .suggested) ?? false
        origin = try c.decodeIfPresent(String.self, forKey: .origin)
        ingredientName = try c.decodeIfPresent(String.self, forKey: .ingredientName)
        amount = try c.decodeIfPresent(Int.self, forKey: .amount)
        unit = try c.decodeIfPresent(IngredientUnit.self, forKey: .unit)
        booked = try c.decodeIfPresent(Bool.self, forKey: .booked) ?? false
    }
}

// MARK: - Preferences
@Observable
final class Preferences {
    static let shared = Preferences()

    var diet: DietMode { didSet { defaults.set(diet.rawValue, forKey: Keys.diet) } }
    var excluded: Set<String> { didSet { defaults.set(Array(excluded), forKey: Keys.excluded) } }
    var favorites: Set<String> { didSet { defaults.set(Array(favorites), forKey: Keys.favorites) } }
    var shopping: [ShoppingItem] { didSet { saveShopping() } }
    var pantry: Set<String> { didSet { defaults.set(Array(pantry), forKey: Keys.pantry) } }
    /// Vorrats-Mengen in Gramm je Zutatname (optional — nur wo der Nutzer eine
    /// Menge gesetzt hat). Additiv zu `pantry` (in-Vorrat ja/nein).
    var pantryAmounts: [String: Int] { didSet { savePantryAmounts() } }
    /// Wochenplan: Wochentag (rawValue) → Rezeptnamen.
    var plan: [String: [String]] { didSet { savePlan() } }
    /// Gekochte Mahlzeiten (Weiterbau 8, Teil B): Schlüssel „Tag|Rezept".
    var cooked: Set<String> { didSet { defaults.set(Array(cooked), forKey: Keys.cooked) } }
    /// Was beim Kochen je Mahlzeit tatsächlich vom Vorrat abgebucht wurde
    /// (mealKey → Zutatname → Menge). Erlaubt exaktes Rückbuchen beim Aufheben.
    var cookedDeductions: [String: [String: Int]] { didSet { saveCookedDeductions() } }
    /// Eltern-Sperre: setzt eine Freigabehürde (Rechenaufgabe) vor Rezept-Import-URLs.
    var kidsControlEnabled: Bool { didSet { defaults.set(kidsControlEnabled, forKey: Keys.kidsControl) } }

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let diet = "pref.diet", excluded = "pref.excluded"
        static let favorites = "pref.favorites", shopping = "pref.shopping"
        static let pantry = "pref.pantry", plan = "pref.plan"
        static let pantryAmounts = "pref.pantryAmounts"
        static let cooked = "pref.cooked", cookedDeductions = "pref.cookedDeductions"
        static let kidsControl = "pref.kidsControl"
    }

    private init() {
        // Eltern-Sperre standardmäßig AKTIV (Kinder-App): register greift nur,
        // solange der Nutzer den Wert nie selbst gesetzt hat.
        defaults.register(defaults: [Keys.kidsControl: true])
        diet = DietMode(rawValue: defaults.string(forKey: Keys.diet) ?? "") ?? .all
        excluded = Set(defaults.stringArray(forKey: Keys.excluded) ?? [])
        favorites = Set(defaults.stringArray(forKey: Keys.favorites) ?? [])
        pantry = Set(defaults.stringArray(forKey: Keys.pantry) ?? [])
        if let data = defaults.data(forKey: Keys.pantryAmounts),
           let amounts = try? JSONDecoder().decode([String: Int].self, from: data) {
            pantryAmounts = amounts
        } else {
            pantryAmounts = [:]
        }
        if let data = defaults.data(forKey: Keys.shopping),
           let items = try? JSONDecoder().decode([ShoppingItem].self, from: data) {
            shopping = items
        } else {
            shopping = []
        }
        if let data = defaults.data(forKey: Keys.plan),
           let p = try? JSONDecoder().decode([String: [String]].self, from: data) {
            plan = p
        } else {
            plan = [:]
        }
        cooked = Set(defaults.stringArray(forKey: Keys.cooked) ?? [])
        if let data = defaults.data(forKey: Keys.cookedDeductions),
           let d = try? JSONDecoder().decode([String: [String: Int]].self, from: data) {
            cookedDeductions = d
        } else {
            cookedDeductions = [:]
        }
        kidsControlEnabled = defaults.bool(forKey: Keys.kidsControl)

        // Migration (18.7., echte Wochen-Navigation): alte Schlüssel ohne
        // Wochen-Präfix werden der AKTUELLEN Woche zugeordnet — kein Datenverlust.
        let wk = Preferences.weekKey(.kkWeekStart())
        if plan.keys.contains(where: { !$0.contains("|") }) {
            var migratedPlan: [String: [String]] = [:]
            for (key, value) in plan {
                let migratedKey = key.contains("|") ? key : "\(wk)|\(key)"
                var merged = migratedPlan[migratedKey] ?? []
                for recipeName in value where !merged.contains(recipeName) {
                    merged.append(recipeName)
                }
                migratedPlan[migratedKey] = merged
            }
            plan = migratedPlan
            savePlan()
        }
        let sep = "\u{1F}"
        if cooked.contains(where: { $0.components(separatedBy: sep).count == 2 }) {
            cooked = Set(cooked.map {
                $0.components(separatedBy: sep).count == 2 ? "\(wk)\(sep)\($0)" : $0
            })
            defaults.set(Array(cooked), forKey: Keys.cooked)   // didSet feuert im init nicht
        }
        if cookedDeductions.keys.contains(where: { $0.components(separatedBy: sep).count == 2 }) {
            var migratedDeductions: [String: [String: Int]] = [:]
            for (key, value) in cookedDeductions {
                let migratedKey = key.components(separatedBy: sep).count == 2 ? "\(wk)\(sep)\(key)" : key
                migratedDeductions[migratedKey, default: [:]].merge(value) { current, incoming in
                    max(current, incoming)
                }
            }
            cookedDeductions = migratedDeductions
            saveCookedDeductions()
        }
    }

    /// Persistenz-Wochenschlüssel „JJJJ-MM-TT" (Montag der Woche).
    static func weekKey(_ week: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: week)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    // MARK: Favoriten
    func isFavorite(_ recipeName: String) -> Bool { favorites.contains(recipeName) }
    func toggleFavorite(_ recipeName: String) {
        if favorites.contains(recipeName) { favorites.remove(recipeName) }
        else { favorites.insert(recipeName) }
    }

    // MARK: Ausschluss
    func toggleExcluded(_ ingredientName: String) {
        if excluded.contains(ingredientName) { excluded.remove(ingredientName) }
        else { excluded.insert(ingredientName) }
    }

    /// Mehrere Zutaten auf einmal aus-/einschließen (für Onboarding-Presets).
    func setExcluded(_ ingredientNames: [String], excluded shouldExclude: Bool) {
        if shouldExclude { excluded.formUnion(ingredientNames) }
        else { excluded.subtract(ingredientNames) }
    }

    // MARK: Einkaufsliste
    func addToShopping(_ recipe: Recipe, scaledBy factor: Double = 1) {
        for item in recipe.ingredients {
            let text = factor == 1 ? item.formatted : item.formatted(scaledBy: factor)
            if !shopping.contains(where: { $0.text == text }) {
                shopping.append(ShoppingItem(text: text, category: item.ingredient.category))
            }
        }
    }
    func clearDoneShopping() { shopping.removeAll { $0.done } }

    private func saveShopping() {
        if let data = try? JSONEncoder().encode(shopping) {
            defaults.set(data, forKey: Keys.shopping)
        }
    }

    // MARK: Vorratsschrank
    func hasInPantry(_ ingredientName: String) -> Bool { pantry.contains(ingredientName) }
    func togglePantry(_ ingredientName: String) {
        if pantry.contains(ingredientName) {
            pantry.remove(ingredientName)
            // Nicht mehr im Vorrat → gespeicherte Menge verwerfen (ehrlich)
            pantryAmounts[ingredientName] = nil
        } else {
            pantry.insert(ingredientName)
        }
    }

    /// Gesetzte Vorrats-Menge in der kanonischen Einheit der Zutat (g/ml/Stück …);
    /// nil = keine Menge hinterlegt. Der Wert ist einheitenlos gespeichert — die
    /// Einheit liefert die Zutat (`Ingredient.unit`), es wird nichts umgerechnet.
    func pantryAmount(_ ingredientName: String) -> Int? { pantryAmounts[ingredientName] }
    /// Menge setzen (in der Einheit der Zutat). 0 löscht die Menge; setzt implizit „im Vorrat".
    func setPantryAmount(_ amount: Int, for ingredientName: String) {
        if amount <= 0 {
            pantryAmounts[ingredientName] = nil
        } else {
            pantryAmounts[ingredientName] = amount
            pantry.insert(ingredientName)
        }
    }

    private func savePantryAmounts() {
        if let data = try? JSONEncoder().encode(pantryAmounts) {
            defaults.set(data, forKey: Keys.pantryAmounts)
        }
    }
    /// Wie viele Zutaten des Rezepts sind im Vorrat (0…1)?
    func pantryCoverage(_ recipe: Recipe) -> Double {
        guard !recipe.ingredients.isEmpty else { return 0 }
        let have = recipe.ingredients.filter { pantry.contains($0.ingredient.name) }.count
        return Double(have) / Double(recipe.ingredients.count)
    }
    /// Fehlende Zutaten eines Rezepts (nicht im Vorrat).
    func missingIngredients(_ recipe: Recipe) -> [RecipeIngredient] {
        recipe.ingredients.filter { !pantry.contains($0.ingredient.name) }
    }

    // MARK: Wochenplan (seit 18.7. je Kalenderwoche — Schlüssel „JJJJ-MM-TT|Tag";
    // `week` default = aktuelle Woche, damit alle Aufrufer außerhalb der
    // Wochen-Navigation unverändert die aktuelle Woche meinen)
    private static func planKey(_ day: Weekday, _ week: Date) -> String {
        "\(weekKey(week))|\(day.rawValue)"
    }
    func plannedRecipes(_ day: Weekday, week: Date = .kkWeekStart()) -> [String] {
        plan[Preferences.planKey(day, week)] ?? []
    }
    func addToPlan(_ recipeName: String, day: Weekday, week: Date = .kkWeekStart()) {
        let key = Preferences.planKey(day, week)
        var list = plan[key] ?? []
        guard !list.contains(recipeName) else { return }
        list.append(recipeName)
        plan[key] = list
    }
    func removeFromPlan(_ recipeName: String, day: Weekday, week: Date = .kkWeekStart()) {
        let key = Preferences.planKey(day, week)
        plan[key]?.removeAll { $0 == recipeName }
        if plan[key]?.isEmpty == true { plan[key] = nil }
        // Gekocht-Marker mitnehmen — aber KEIN Rückbuchen (aus dem Plan nehmen ≠
        // „nicht gekocht"; der Vorrat bleibt, wie das Kochen ihn hinterlassen hat).
        let meal = Preferences.mealKey(day, recipeName, week: week)
        cooked.remove(meal)
        cookedDeductions[meal] = nil
    }
    /// Geplante Mahlzeiten der AKTUELLEN Woche (Badge/Einkaufs-Banner).
    var plannedCount: Int {
        Weekday.allCases.reduce(0) { $0 + plannedRecipes($1).count }
    }

    private func savePlan() {
        if let data = try? JSONEncoder().encode(plan) {
            defaults.set(data, forKey: Keys.plan)
        }
    }
    private func saveCookedDeductions() {
        if let data = try? JSONEncoder().encode(cookedDeductions) {
            defaults.set(data, forKey: Keys.cookedDeductions)
        }
    }
}

// MARK: - Vorrats-Kreislauf (Weiterbau 8)
extension Preferences {

    // MARK: Teil A — Bedarf-Rechnung Wochenplan → Einkauf
    /// Rechnet den Zutatenbedarf ALLER geplanten (noch nicht gekochten) Rezepte gegen
    /// den Vorrat. Aggregiert je Zutat über die ganze Woche. Kein Umrechnen: passt die
    /// Rezept-Einheit nicht zur kanonischen Einheit, wird nur Vorhandensein geprüft.
    func weekPlanShortfalls(recipes: [Recipe]) -> [PantryShortfall] {
        struct Agg { var needed = 0; var numeric = true; var origins: [String] = [] }
        var byName: [String: Agg] = [:]
        var order: [String] = []

        for day in Weekday.allCases {
            for recipeName in plannedRecipes(day) {
                // Schon gekocht → verbraucht, kein Bedarf mehr (Teil B greift in A).
                guard !isCooked(day, recipeName),
                      let recipe = recipes.first(where: { $0.name == recipeName }) else { continue }
                let origin = "\(day.rawValue): \(recipe.name)"
                for ri in recipe.ingredients {
                    let name = ri.ingredient.name
                    if byName[name] == nil { byName[name] = Agg(); order.append(name) }
                    byName[name]?.origins.append(origin)
                    if ri.unit == Ingredient.canonicalUnit(for: name) {
                        byName[name]?.needed += Int(ri.amount.rounded(.up))
                    } else {
                        // Einheit passt nicht → keine Mengen-Zahl, nur Vorhandensein.
                        byName[name]?.numeric = false
                    }
                }
            }
        }

        return order.compactMap { name in
            guard let agg = byName[name] else { return nil }
            return PantryShortfall(
                ingredientName: name,
                category: Ingredient.category(for: name),
                unit: Ingredient.canonicalUnit(for: name),
                needed: agg.needed,
                have: pantryAmount(name) ?? 0,
                numeric: agg.numeric,
                origins: agg.origins
            )
        }
    }

    /// Erneuert die Vorschlags-Posten auf der Einkaufsliste aus dem aktuellen Bedarf.
    /// NUR eigene, noch offene Vorschläge werden ersetzt — Hand-Einträge und bereits
    /// abgehakte Posten bleiben unangetastet. Gibt die Anzahl neuer Vorschläge zurück.
    @discardableResult
    func refreshShoppingSuggestions(recipes: [Recipe]) -> Int {
        let shortfalls = weekPlanShortfalls(recipes: recipes).filter(\.isShort)
        let newSuggestions = shortfalls.map { s -> ShoppingItem in
            let canBook = s.numeric && s.missing > 0
            return ShoppingItem(
                text: s.shoppingText,
                category: s.category,
                suggested: true,
                origin: s.originText,
                ingredientName: canBook ? s.ingredientName : nil,
                amount: canBook ? s.missing : nil,
                unit: canBook ? s.unit : nil
            )
        }
        // Einmal zuweisen statt N appends → nur 1 didSet/saveShopping()-Call
        var kept = shopping.filter { !$0.suggested || $0.done }
        kept.append(contentsOf: newSuggestions)
        shopping = kept
        return newSuggestions.count
    }

    /// Wie viele offene Bedarfs-Posten stünden gerade an (für Badge/Knopf-Text)?
    func shortfallCount(recipes: [Recipe]) -> Int {
        weekPlanShortfalls(recipes: recipes).filter(\.isShort).count
    }

    // MARK: Ab-/Anhaken auf der Einkaufsliste (bucht strukturierte Vorschläge in den Vorrat)
    /// Setzt den Erledigt-Status eines Postens und bucht — falls es ein strukturierter
    /// Vorschlag ist — die Menge symmetrisch in den Vorrat ein bzw. wieder aus.
    func setShoppingDone(_ id: UUID, done: Bool) {
        guard let idx = shopping.firstIndex(where: { $0.id == id }) else { return }
        var item = shopping[idx]
        item.done = done

        if item.booksIntoPantry, let name = item.ingredientName,
           let amount = item.amount, let unit = item.unit,
           unit == Ingredient.canonicalUnit(for: name) {
            if done && !item.booked {
                setPantryAmount((pantryAmount(name) ?? 0) + amount, for: name)
                item.booked = true
            } else if !done && item.booked {
                let newValue = (pantryAmount(name) ?? 0) - amount
                setPantryAmount(max(0, newValue), for: name)
                item.booked = false
            }
        }
        // Einmal zuweisen → nur 1 didSet/saveShopping()-Call statt vorher 2
        shopping[idx] = item
    }

    // MARK: Teil B — „Gekocht" bucht den Vorrat ab
    static func mealKey(_ day: Weekday, _ recipeName: String, week: Date = .kkWeekStart()) -> String {
        "\(weekKey(week))\u{1F}\(day.rawValue)\u{1F}\(recipeName)"   // Unit Separator trennt sicher
    }

    func isCooked(_ day: Weekday, _ recipeName: String, week: Date = .kkWeekStart()) -> Bool {
        cooked.contains(Preferences.mealKey(day, recipeName, week: week))
    }

    /// Markiert eine geplante Mahlzeit als gekocht und bucht die Rezept-Zutaten vom
    /// Vorrat ab: nie unter 0, nur bei passender Einheit, fehlende Zutat = kein
    /// Blocker (wird einfach nicht abgebucht). Was abgebucht wurde, wird gemerkt.
    func markCooked(_ day: Weekday, recipe: Recipe, week: Date = .kkWeekStart()) {
        let key = Preferences.mealKey(day, recipe.name, week: week)
        guard !cooked.contains(key) else { return }
        var deducted: [String: Int] = [:]
        for ri in recipe.ingredients {
            let name = ri.ingredient.name
            guard ri.unit == Ingredient.canonicalUnit(for: name),
                  let have = pantryAmount(name), have > 0 else { continue }
            let take = min(have, Int(ri.amount.rounded(.up)))
            guard take > 0 else { continue }
            setPantryAmount(have - take, for: name)   // 0 entfernt aus dem Vorrat
            deducted[name] = take
        }
        cooked.insert(key)
        cookedDeductions[key] = deducted
    }

    /// Hebt „gekocht" auf und bucht die zuvor entnommenen Mengen exakt zurück.
    func unmarkCooked(_ day: Weekday, recipe: Recipe, week: Date = .kkWeekStart()) {
        let key = Preferences.mealKey(day, recipe.name, week: week)
        guard cooked.contains(key) else { return }
        if let deducted = cookedDeductions[key] {
            for (name, amount) in deducted {
                setPantryAmount((pantryAmount(name) ?? 0) + amount, for: name)
            }
        }
        cooked.remove(key)
        cookedDeductions[key] = nil
    }

    /// Rezept-Zutaten, die beim Kochen NICHT (voll) im Vorrat waren — für die
    /// ehrliche Anzeige „diese Zutaten fehlten" nach dem Abhaken.
    func cookMissingNames(_ day: Weekday, recipe: Recipe, week: Date = .kkWeekStart()) -> [String] {
        let deducted = cookedDeductions[Preferences.mealKey(day, recipe.name, week: week)] ?? [:]
        return recipe.ingredients.compactMap { ri in
            let name = ri.ingredient.name
            guard ri.unit == Ingredient.canonicalUnit(for: name) else { return nil }
            let need = Int(ri.amount.rounded(.up))
            return (deducted[name] ?? 0) < need ? name : nil
        }
    }

    // MARK: Teil C — „Was kann ich heute kochen?" (reines Set-Matching, kein LLM)
    /// Rezepte, für die höchstens `maxMissing` Zutaten fehlen — sortiert nach
    /// Fehl-Anzahl (alles da zuerst), bei Gleichstand alphabetisch. Deterministisch
    /// und offline: eine Zutat gilt als da, wenn ihr Name im Vorrat steht.
    func cookableSuggestions(from recipes: [Recipe], maxMissing: Int = 2) -> [CookableMatch] {
        recipes
            .filter { !$0.ingredients.isEmpty }
            .map { recipe in
                CookableMatch(
                    recipe: recipe,
                    missing: recipe.ingredients.filter { !pantry.contains($0.ingredient.name) }
                )
            }
            .filter { $0.missingCount <= maxMissing }
            .sorted { lhs, rhs in
                lhs.missingCount != rhs.missingCount
                    ? lhs.missingCount < rhs.missingCount
                    : lhs.recipe.name.localizedStandardCompare(rhs.recipe.name) == .orderedAscending
            }
    }
}
