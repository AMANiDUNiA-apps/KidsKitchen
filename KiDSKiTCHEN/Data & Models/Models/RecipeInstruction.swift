//
//  RecipeInstruction.swift
//  KiDSKiTCHEN
//
//  Created by Claude Fable 5 on 02.07.26.
//

import Foundation

// MARK: - RecipeInstruction
struct RecipeInstruction: Identifiable {
    let id: UUID
    var text: String

    init(id: UUID = UUID(), text: String) {
        self.id = id
        self.text = text
    }

    // MARK: - Mocks
    static let mock: [RecipeInstruction] = [
        RecipeInstruction(text: "Haferflocken in eine Schüssel geben."),
        RecipeInstruction(text: "Milch dazugießen und kurz umrühren."),
        RecipeInstruction(text: "Apfel waschen, in kleine Stücke schneiden und untermischen."),
        RecipeInstruction(text: "Mit einer Prise Zimt bestreuen — fertig!"),
    ]
}
