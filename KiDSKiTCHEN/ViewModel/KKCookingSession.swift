//
//  KKCookingSession.swift
//  KiDSKiTCHEN
//
//  App-weiter Kochmodus-Zustand (Singleton, wie Preferences.shared): welches
//  Rezept läuft gerade, bei welchem Schritt steht man, ist die Vollansicht offen
//  oder nur die Mini-Leiste über der Tabbar sichtbar. Keine Persistenz — ein
//  Kochdurchlauf lebt nur im Speicher (wie der Fortschritt in CookingSteps).
//

import Foundation
import Observation

@Observable
final class KKCookingSession {
    static let shared = KKCookingSession()
    private init() {}

    private(set) var recipe: Recipe?
    private(set) var stepIndex = 0
    /// true = Vollbild-Kochmodus offen, false = nur Mini-Leiste (falls aktiv).
    var isFullScreenPresented = false

    var isActive: Bool { recipe != nil }
    var totalSteps: Int { recipe?.instructions.count ?? 0 }
    var isLastStep: Bool { stepIndex >= totalSteps - 1 }
    var currentStep: RecipeInstruction? {
        guard let recipe, recipe.instructions.indices.contains(stepIndex) else { return nil }
        return recipe.instructions[stepIndex]
    }

    /// Startet den Kochmodus. Nur sinnvoll mit mindestens einem Schritt.
    func start(_ recipe: Recipe) {
        guard !recipe.instructions.isEmpty else { return }
        self.recipe = recipe
        stepIndex = 0
        isFullScreenPresented = true
    }

    /// Nächster Schritt — beendet den Kochmodus nach dem letzten Schritt.
    func next() {
        guard recipe != nil else { return }
        if isLastStep {
            stop()
        } else {
            stepIndex += 1
        }
    }

    func back() {
        stepIndex = max(0, stepIndex - 1)
    }

    func stop() {
        recipe = nil
        stepIndex = 0
        isFullScreenPresented = false
    }
}
