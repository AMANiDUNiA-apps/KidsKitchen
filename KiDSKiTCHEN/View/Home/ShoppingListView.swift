//
//  ShoppingListView.swift
//  KiDSKiTCHEN
//
//  Created by Claude Fable 5 on 03.07.26.
//  Einkaufsliste: aus Rezepten gesammelte Zutaten, abhakbar, persistent.
//

import SwiftUI

struct ShoppingListView: View {
    @State private var prefs: Preferences = .shared

    var body: some View {
        List {
            if prefs.shopping.isEmpty {
                ContentUnavailableView(
                    "Einkaufsliste ist leer",
                    systemImage: "cart",
                    description: Text("Füge Zutaten aus einem Rezept hinzu.")
                )
            } else {
                ForEach($prefs.shopping) { $item in
                    Button {
                        item.done.toggle()
                    } label: {
                        HStack {
                            Image(systemName: item.done ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(item.done ? .green : .secondary)
                            Text(item.text)
                                .strikethrough(item.done)
                                .foregroundStyle(item.done ? .secondary : .primary)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { prefs.shopping.remove(atOffsets: $0) }
            }
        }
        .navigationTitle("Einkaufsliste")
        .toolbar {
            if prefs.shopping.contains(where: \.done) {
                ToolbarItem(placement: .primaryAction) {
                    Button("Erledigte löschen") { prefs.clearDoneShopping() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack { ShoppingListView() }
}
