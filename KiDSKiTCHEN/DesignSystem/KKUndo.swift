//
//  KKUndo.swift
//  KiDSKiTCHEN
//
//  Rückgängig/Wiederholen für Lösch-/Änder-Aktionen (Einkaufsliste, Vorrat,
//  offline gespeicherte Rezepte). Vorlage: Kavsoft „UndoHelper" (Balaji
//  Venkatesh), ~/z/Agents/Claude/xCode/kavsoft/UndoHelper — dort ein
//  Property-Wrapper (@UndoState) für lokalen @State. Hier NICHT übernommen,
//  weil KidsKitchens Listen (Preferences, SavedRecipeRepository) über
//  Singleton-Klassen laufen statt über lokalen View-State — stattdessen wird
//  das Prinzip direkt mit Foundations `UndoManager.registerUndo(withTarget:)`
//  umgesetzt (dieselbe Technik, die der Wrapper innen benutzt), symmetrisch:
//  jede Rückgängig-Aktion registriert beim Ausführen gleich wieder ihr
//  Gegenstück, damit Wiederholen (Redo) funktioniert.
//

import SwiftUI

/// Kompaktes Rückgängig/Wiederholen-Menü fürs Toolbar — überall gleich, wo
/// Löschen/Ändern rückgängig gemacht werden soll.
struct KKUndoRedoButton: View {
    let undoManager: UndoManager?

    var body: some View {
        Menu {
            Button {
                undoManager?.undo()
            } label: {
                Label("Rückgängig", systemImage: "arrow.uturn.backward")
            }
            .disabled(!(undoManager?.canUndo ?? false))

            Button {
                undoManager?.redo()
            } label: {
                Label("Wiederholen", systemImage: "arrow.uturn.forward")
            }
            .disabled(!(undoManager?.canRedo ?? false))
        } label: {
            Image(systemName: "arrow.uturn.backward.circle")
        }
        .disabled(!(undoManager?.canUndo ?? false) && !(undoManager?.canRedo ?? false))
        .accessibilityLabel("Rückgängig/Wiederholen")
    }
}
