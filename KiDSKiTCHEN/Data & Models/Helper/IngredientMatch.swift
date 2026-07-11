//
//  IngredientMatch.swift
//  KiDSKiTCHEN
//
//  Match-Schicht (Zutaten-Mapping 11.7.): freier Zutat-String → Bild-Asset-Stamm.
//  Rein deterministisch und synchron — schnell genug für lazy Auflösung pro Zeile.
//  Stufen: (1) exakt nach Normalisierung, (2) kuratierte Alias-/Plural-Tabelle,
//  (3) Teilwort-Enthalten (Komposita), (4) Fuzzy (Levenshtein). Bleibt ein Fall
//  unsicher, liefert resolve() Kandidaten für die on-device-FoundationModels-Stufe
//  (siehe IngredientImageMapping). NICHTS wird hier geraten: unsichere Treffer
//  werden als solche markiert, nicht als Treffer ausgegeben.
//
//  Abgestimmt auf die Datei-Normalisierung der Bild-Pipeline (Ingredient.imageAssetKey):
//  Umlaute → ae/oe/ue, ß → ss, Kleinschreibung, nur a–z/0–9.
//

import Foundation

enum IngredientMatch {

    // MARK: - Ergebnis
    struct Result: Equatable {
        enum Tier: String { case exact, alias, contains, fuzzy, uncertain, none }
        /// Der aufgelöste Asset-Stamm (nil, wenn kein sicherer Treffer).
        let assetKey: String?
        let tier: Tier
        /// Bei `.uncertain`: die besten Kandidaten für die FoundationModels-Stufe.
        let candidates: [String]
        /// Fuzzy-Score des besten Treffers (0…1) — nur zur Diagnose.
        let score: Double
    }

    // MARK: - Normalisierung
    /// Zerlegt einen Zutat-String, wirft Mengen-/Einheiten-/Füll-Tokens weg und
    /// reduziert den Rest auf den Datei-Stamm (z. B. „600 g Kartoffeln" → „kartoffeln",
    /// „1 EL Olivenöl" → „olivenoel").
    static func normalize(_ raw: String) -> String {
        let lowered = raw.lowercased()
        let separators = CharacterSet.alphanumerics.inverted
        let tokens = lowered.components(separatedBy: separators).filter { !$0.isEmpty }
        let content = tokens.filter { tok in
            if unitTokens.contains(tok) { return false }
            if tok.allSatisfy(\.isNumber) { return false }
            return true
        }
        let joined = content.isEmpty ? lowered : content.joined(separator: " ")
        // imageAssetKey erledigt Umlaute + Reduktion auf a–z/0–9 (eine Quelle der Wahrheit).
        return Ingredient.imageAssetKey(for: joined)
    }

    /// Mengen-/Einheiten- und Füll-Tokens, die vor dem Matching entfernt werden.
    /// (Nur ganze Tokens — Komposita wie „knoblauchzehe" bleiben unangetastet.)
    private static let unitTokens: Set<String> = [
        "g", "kg", "mg", "ml", "l", "el", "tl", "cl", "dl",
        "stück", "stueck", "stk", "prise", "prisen", "bund", "dose", "dosen",
        "packung", "päckchen", "paeckchen", "pck", "tasse", "tassen",
        "zehe", "zehen", "scheibe", "scheiben", "msp", "messerspitze",
        "handvoll", "etwas", "ca", "evtl", "nach", "belieben", "frisch", "frische",
    ]

    // MARK: - Alias-/Plural-Tabelle (kuratiert, deterministisch)
    /// Normalisierte Variante → kanonischer Asset-Stamm. Nur belegte, eindeutige
    /// Zuordnungen (Plural, gängige Synonyme). Kein Raten — im Zweifel weglassen,
    /// dann greift Fuzzy/FoundationModels.
    /// Keys sind bereits NORMALISIERT (a–z/0–9), Ziele müssen im Katalog liegen —
    /// sonst greift der Alias nicht (resolve prüft catalog.contains).
    static let aliases: [String: String] = [
        // Plural → Singular
        "kartoffeln": "kartoffel", "tomaten": "tomate", "zwiebeln": "zwiebel",
        "eier": "ei", "aepfel": "apfel", "bananen": "banane", "karotten": "karotte",
        "erdbeeren": "erdbeere", "heidelbeeren": "heidelbeere", "himbeeren": "himbeere",
        "kirschen": "kirsche", "trauben": "traube", "weintrauben": "traube",
        "birnen": "birne", "orangen": "orange", "mandarinen": "mandarine",
        "gurken": "gurke", "paprikas": "paprika",
        "pflaumen": "pflaume", "pfirsiche": "pfirsich",
        // Synonyme / Regionalformen
        "moehre": "karotte", "moehren": "karotte", "wurzel": "karotte",
        "erdapfel": "kartoffel", "erdaepfel": "kartoffel",
        "paprikaschote": "paprika", "knoblauchzehe": "knoblauch", "knoblauchzehen": "knoblauch",
        "haehnchen": "haehnchenbrust", "huhn": "haehnchenbrust",
        "hackfleisch": "rinderhack", "gehacktes": "rinderhack",
        "schlagsahne": "sahne", "schlagrahm": "sahne", "rahm": "sahne",
        "speisequark": "quark", "magerquark": "quark", "naturjoghurt": "joghurt",
        "vollmilch": "milch", "hmilch": "milch",
        "spaghetti": "nudeln", "penne": "nudeln", "makkaroni": "nudeln",
        "fusilli": "nudeln", "vollkornnudeln": "nudeln",
        "pflanzenoel": "rapsoel", "gemuesebruehepulver": "gemuesebruehe",
    ]

    // MARK: - Auflösen
    static func resolve(_ rawName: String) -> Result {
        let key = normalize(rawName)
        guard !key.isEmpty else { return .init(assetKey: nil, tier: .none, candidates: [], score: 0) }
        let catalog = IngredientImageCatalog.names

        // 1) Exakt
        if catalog.contains(key) { return .init(assetKey: key, tier: .exact, candidates: [], score: 1) }

        // 2) Alias
        if let alias = aliases[key], catalog.contains(alias) {
            return .init(assetKey: alias, tier: .alias, candidates: [], score: 1)
        }

        // 3) Teilwort/Kompositum (nur ab 4 Zeichen, gegen Fehltreffer wie „ei" in vielem)
        if key.count >= 4 {
            let contained = catalog.filter { $0.contains(key) || (key.contains($0) && $0.count >= 4) }
            if let best = contained.min(by: {
                abs($0.count - key.count) < abs($1.count - key.count)
            }) {
                return .init(assetKey: best, tier: .contains, candidates: [], score: 0.9)
            }
        }

        // 4) Fuzzy (Levenshtein-Ähnlichkeit über den Katalog)
        let scored = catalog
            .map { ($0, similarity(key, $0)) }
            .sorted { $0.1 > $1.1 }
        if let (bestKey, bestScore) = scored.first {
            if bestScore >= 0.82 {
                return .init(assetKey: bestKey, tier: .fuzzy, candidates: [], score: bestScore)
            }
            if bestScore >= 0.62 {
                return .init(assetKey: nil, tier: .uncertain,
                             candidates: Array(scored.prefix(3).map(\.0)), score: bestScore)
            }
            return .init(assetKey: nil, tier: .none, candidates: [], score: bestScore)
        }
        return .init(assetKey: nil, tier: .none, candidates: [], score: 0)
    }

    // MARK: - Ähnlichkeit
    /// Normalisierte Levenshtein-Ähnlichkeit (1 = identisch, 0 = maximal verschieden).
    static func similarity(_ a: String, _ b: String) -> Double {
        if a == b { return 1 }
        if a.isEmpty || b.isEmpty { return 0 }
        let dist = levenshtein(Array(a), Array(b))
        return 1 - Double(dist) / Double(max(a.count, b.count))
    }

    private static func levenshtein(_ a: [Character], _ b: [Character]) -> Int {
        var prev = Array(0...b.count)
        var cur = [Int](repeating: 0, count: b.count + 1)
        for i in 1...a.count {
            cur[0] = i
            for j in 1...b.count {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                cur[j] = min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost)
            }
            swap(&prev, &cur)
        }
        return prev[b.count]
    }
}

#if DEBUG
extension IngredientMatch {
    /// Diagnose: Tier-Verteilung über eine Namensliste (für die Fertigmeldungs-Statistik).
    static func audit(_ names: [String]) -> [Result.Tier: Int] {
        var counts: [Result.Tier: Int] = [:]
        for name in Set(names) { counts[resolve(name).tier, default: 0] += 1 }
        return counts
    }
}
#endif
