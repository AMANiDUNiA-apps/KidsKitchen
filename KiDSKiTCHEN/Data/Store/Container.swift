//
//  Container.swift
//  KiDSKiTCHEN
//
//  Rebuild P3 (Data): EIN SwiftData-Container für die App statt eines
//  privaten Containers je Repository (vormals in SavedRecipeRepository).
//  Weitere Nutzerdaten-Modelle (Pantry/Plan/Shopping/Favorite, s. REBUILD-PLAN
//  §Data/Store) reihen sich hier ein, sobald ihre Screens (P6/P7) sie brauchen —
//  Clean Slate, keine Migration alter UserDefaults-Daten (Plan §3).
//

import Foundation
import SwiftData

enum KKDataStore {
    static let container: ModelContainer = {
        do {
            let container = try ModelContainer(for: SavedRecipe.self)
            container.mainContext.undoManager = UndoManager()
            return container
        } catch {
            fatalError("SwiftData-Container konnte nicht erstellt werden: \(error)")
        }
    }()
}
