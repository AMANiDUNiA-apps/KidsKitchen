//
//  SupabaseRecipeRepository.swift
//  KiDSKiTCHEN
//
//  Repository-Implementierung mit echtem API-Call gegen Supabase (PostgREST).
//  Erfüllt die Abschluss-Anforderung „API-Anbindung + Repository". Schlägt der Call fehl
//  (offline, kein Key), fängt das ViewModel das ab und behält die Seed-Rezepte.
//

import Foundation

struct SupabaseRecipeRepository: RecipeRepository {
    /// Wie viele Rezepte pro Abruf (die Tabelle hat ~32k Zeilen — für V1 begrenzt).
    var limit = 40

    /// Tabelle mit Leerzeichen/Pipe im Namen → für die URL kodieren.
    private let table = "AllRecipes | DE | All"
    private let columns = "id,title,description,category,image,servings,prep_time,cook_time,directions,instructions_list,calories,protein_g,carbohydrates_g,fat_g,dietary_fiber_g"

    func fetchRecipes() async throws -> [Recipe] {
        let encodedTable = table.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? table
        guard var components = URLComponents(string: "\(SupabaseSecrets.url)/rest/v1/\(encodedTable)") else {
            throw RepositoryError.badURL
        }
        components.queryItems = [
            URLQueryItem(name: "select", value: columns),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        guard let url = components.url else { throw RepositoryError.badURL }

        var request = URLRequest(url: url)
        request.setValue(SupabaseSecrets.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(SupabaseSecrets.anonKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw RepositoryError.badStatus(-1)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw RepositoryError.badStatus(http.statusCode)
        }

        let remote = try JSONDecoder().decode([RemoteRecipe].self, from: data)
        return remote.map { $0.toRecipe() }
    }
}
