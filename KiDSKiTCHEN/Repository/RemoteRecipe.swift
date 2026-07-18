//
//  RemoteRecipe.swift
//  KiDSKiTCHEN
//
//  DTO für die Supabase-Tabelle „AllRecipes | DE | All". Die Quelldaten sind gescrapt und
//  fast durchgehend Text (auch Nährwerte/Zeiten) — wir mappen nur die Felder, die die App
//  anzeigt, und parsen Zahlen defensiv. Fehlt/unlesbar → sinnvoller Default statt Absturz.
//

import Foundation

// MARK: - RemoteRecipe (Supabase-Spalten)
struct RemoteRecipe: Decodable {
    let id: String?
    let title: String?
    let description: String?
    let category: String?
    let image: String?
    let servings: Int?
    let prep_time: String?
    let cook_time: String?
    let directions: String?
    let instructions_list: String?
    let calories: String?
    let protein_g: String?
    let carbohydrates_g: String?
    let fat_g: String?
    let dietary_fiber_g: String?

    private enum CodingKeys: String, CodingKey {
        case id, title, description, category, image, servings, prep_time, cook_time, directions
        case instructions_list, calories, protein_g, carbohydrates_g, fat_g, dietary_fiber_g
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = Self.string(from: container, forKey: .id)
        title = Self.string(from: container, forKey: .title)
        description = Self.string(from: container, forKey: .description)
        category = Self.string(from: container, forKey: .category)
        image = Self.string(from: container, forKey: .image)
        servings = Self.int(from: container, forKey: .servings)
        prep_time = Self.string(from: container, forKey: .prep_time)
        cook_time = Self.string(from: container, forKey: .cook_time)
        directions = Self.string(from: container, forKey: .directions)
        instructions_list = Self.string(from: container, forKey: .instructions_list)
        calories = Self.string(from: container, forKey: .calories)
        protein_g = Self.string(from: container, forKey: .protein_g)
        carbohydrates_g = Self.string(from: container, forKey: .carbohydrates_g)
        fat_g = Self.string(from: container, forKey: .fat_g)
        dietary_fiber_g = Self.string(from: container, forKey: .dietary_fiber_g)
    }

    private static func string(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) -> String? {
        if let value = try? container.decodeIfPresent(String.self, forKey: key) {
            return value
        }
        if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
            return String(value)
        }
        if let value = try? container.decodeIfPresent(Double.self, forKey: key) {
            return String(value)
        }
        if let value = try? container.decodeIfPresent(Bool.self, forKey: key) {
            return String(value)
        }
        return nil
    }

    private static func int(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) -> Int? {
        if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
            return value
        }
        if let value = try? container.decodeIfPresent(Double.self, forKey: key) {
            return Int(value.rounded())
        }
        if let raw = Self.string(from: container, forKey: key) {
            return minutes(raw)
        }
        return nil
    }
}

extension RemoteRecipe {
    /// Auf das App-Modell abbilden. Kategorie/Zutaten bleiben in V1 leer (die Zutaten
    /// liegen in einer separaten Tabelle; Ausbau später) — Ausblick, „muss nicht fertig sein".
    func toRecipe() -> Recipe {
        let stepsText = instructions_list?.isEmpty == false ? instructions_list : directions
        let steps = Self.splitSteps(stepsText ?? "")
        return Recipe(
            name: title.flatMap { $0.isEmpty ? nil : $0 } ?? "Ohne Titel",
            details: description ?? "",
            imageURL: image,
            category: nil,
            instructions: steps.map { RecipeInstruction(text: $0) },
            nutrition: Nutrition(
                kcal: Self.number(calories),
                protein: Self.number(protein_g),
                carbs: Self.number(carbohydrates_g),
                fat: Self.number(fat_g),
                fiber: Self.number(dietary_fiber_g)
            ),
            servings: servings ?? 2,
            prepTime: Self.minutes(prep_time),
            cookTime: Self.minutes(cook_time)
        )
    }

    // MARK: Parse-Helfer (defensiv gegen rohe Textdaten)

    /// Erste Zahl aus einem Text als Double (Komma oder Punkt als Dezimaltrenner). Sonst 0.
    static func number(_ raw: String?) -> Double {
        guard let raw else { return 0 }
        let normalized = raw.replacingOccurrences(of: ",", with: ".")
        guard let range = normalized.range(of: #"[0-9]+(\.[0-9]+)?"#, options: .regularExpression) else {
            return 0
        }
        return Double(normalized[range]) ?? 0
    }

    /// Erste ganze Zahl (Minuten) aus einem Text. Sonst 0.
    static func minutes(_ raw: String?) -> Int {
        guard let raw, let range = raw.range(of: #"[0-9]+"#, options: .regularExpression) else {
            return 0
        }
        return Int(raw[range]) ?? 0
    }

    /// Zubereitungstext in einzelne Schritte zerlegen (Zeilenumbrüche oder „. ").
    static func splitSteps(_ raw: String) -> [String] {
        let byLines = raw
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        if byLines.count > 1 { return byLines }
        // Nur eine Zeile → an Satzenden trennen.
        return raw
            .components(separatedBy: ". ")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}
