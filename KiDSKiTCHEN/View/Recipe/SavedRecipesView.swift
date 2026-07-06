//
//  SavedRecipesView.swift
//  KiDSKiTCHEN
//
//  Zeigt die offline gespeicherten Rezepte (SwiftData, über SavedRecipeRepository).
//  Das Bild kommt aus dem persistierten Blob — funktioniert also auch ohne Netz.
//

import SwiftUI
import UIKit

struct SavedRecipesView: View {
    @State private var items: [SavedRecipe] = []

    var body: some View {
        List {
            if items.isEmpty {
                ContentUnavailableView(
                    "Nichts gespeichert",
                    systemImage: "arrow.down.circle",
                    description: Text("Speichere ein Rezept über das Pfeil-Symbol in der Detailansicht, um es offline zu behalten.")
                )
            } else {
                ForEach(items) { item in
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
                    }
                    .padding(.vertical, 2)
                }
                .onDelete { indexSet in
                    for index in indexSet { SavedRecipeRepository.shared.delete(items[index]) }
                    reload()
                }
            }
        }
        .navigationTitle("Offline gespeichert")
        .task { reload() }
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
