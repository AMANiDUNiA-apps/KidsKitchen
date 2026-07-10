//
//  SavedRecipesView.swift
//  KiDSKiTCHEN
//
//  Zeigt die offline gespeicherten Rezepte (SwiftData, über SavedRecipeRepository).
//  Das Bild kommt aus dem persistierten Blob — funktioniert also auch ohne Netz.
//
//  UI-Bauweise (Jay 10.7.): selbstgebaute Container statt `List` — hier KKScroll +
//  KKCard. Löschen als sichtbarer, kindgerechter Knopf (KKDeleteButton) mit
//  Sicherheitsabfrage, kein verstecktes Wischen (Jay 11.7., Herz-Knopf-Referenz).
//

import SwiftUI
import UIKit

struct SavedRecipesView: View {
    @State private var items: [SavedRecipe] = []
    @State private var pendingDelete: SavedRecipe?

    var body: some View {
        KKScroll {
            if items.isEmpty {
                KKCard {
                    ContentUnavailableView(
                        "Nichts gespeichert",
                        systemImage: "arrow.down.circle",
                        description: Text("Speichere ein Rezept über das Pfeil-Symbol in der Detailansicht, um es offline zu behalten.")
                    )
                }
                .padding(.top, 40)
            } else {
                ForEach(items) { item in
                    KKCard {
                        HStack(spacing: 12) {
                            thumbnail(item)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.recipeName)
                                    .font(.system(.body, design: .serif).bold())
                                if item.kcal > 0 {
                                    Text("\(Int(item.kcal)) kcal")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            Spacer(minLength: 8)
                            KKDeleteButton(accessibilityLabel: "\(item.recipeName) löschen") {
                                pendingDelete = item
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Offline gespeichert")
        .task { reload() }
        .confirmationDialog(
            "Dieses Rezept löschen?",
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            titleVisibility: .visible,
            presenting: pendingDelete
        ) { item in
            Button("Löschen", role: .destructive) {
                SavedRecipeRepository.shared.delete(item)
                pendingDelete = nil
                reload()
            }
            Button("Behalten", role: .cancel) { pendingDelete = nil }
        } message: { item in
            Text("„\(item.recipeName)“ wird aus den Offline-Rezepten entfernt.")
        }
    }

    @ViewBuilder
    private func thumbnail(_ item: SavedRecipe) -> some View {
        if let data = item.imageData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        } else {
            RoundedRectangle(cornerRadius: 10)
                .fill(.orange.opacity(0.15))
                .frame(width: 52, height: 52)
                .overlay(Image(systemName: "fork.knife").foregroundStyle(.orange))
        }
    }

    private func reload() { items = SavedRecipeRepository.shared.all() }
}
