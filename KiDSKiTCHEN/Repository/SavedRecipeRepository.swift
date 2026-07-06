//
//  SavedRecipeRepository.swift
//  KiDSKiTCHEN
//
//  Kapselt SwiftData hinter dem Repository (Jays Vorgabe): Views/VMs sprechen nie direkt
//  mit dem ModelContext, sondern nur mit diesem Repository. Erfüllt die Abschluss-Anforderung
//  „Datenpersistenz (SwiftData)".
//

import Foundation
import SwiftData

@MainActor
final class SavedRecipeRepository {
    static let shared = SavedRecipeRepository()

    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    private init() {
        do {
            container = try ModelContainer(for: SavedRecipe.self)
        } catch {
            fatalError("SwiftData-Container konnte nicht erstellt werden: \(error)")
        }
    }

    /// Alle gespeicherten Rezepte, neueste zuerst.
    func all() -> [SavedRecipe] {
        let descriptor = FetchDescriptor<SavedRecipe>(
            sortBy: [SortDescriptor(\.savedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Ist ein Rezept (per Name) bereits gespeichert?
    func isSaved(_ name: String) -> Bool {
        let descriptor = FetchDescriptor<SavedRecipe>(
            predicate: #Predicate { $0.recipeName == name }
        )
        return ((try? context.fetchCount(descriptor)) ?? 0) > 0
    }

    /// Rezept offline speichern — vorhandene Bild-URL wird einmal heruntergeladen und mitgespeichert.
    func save(_ recipe: Recipe) async {
        guard !isSaved(recipe.name) else { return }
        var imageData: Data?
        if let urlString = recipe.imageURL, let url = URL(string: urlString) {
            imageData = try? await URLSession.shared.data(from: url).0
        }
        context.insert(SavedRecipe(from: recipe, imageData: imageData))
        try? context.save()
    }

    func delete(_ item: SavedRecipe) {
        context.delete(item)
        try? context.save()
    }
}
