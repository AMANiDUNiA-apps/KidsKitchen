//
//  ShoppingListView.swift
//  KiDSKiTCHEN
//
//  Created by Claude Fable 5 on 03.07.26.
//  Einkaufsliste: aus Rezepten gesammelte Zutaten, abhakbar, persistent.
//
//  UI-Bauweise (Jay 10.7.): selbstgebaute Container statt `List` — KKScroll + KKCard.
//  Abhaken (Tippen aufs Häkchen) und ein sichtbarer Lösch-Knopf pro Zeile
//  (KKDeleteButton, Jay 11.7. Herz-Knopf-Referenz) — kein verstecktes Wischen.
//  Einzelposten sind geringwertig/wiederherstellbar → Löschen direkt, ohne Abfrage;
//  „Erledigte löschen" bleibt als Sammel-Aktion in der Toolbar.
//

import SwiftUI

struct ShoppingListView: View {
    @State private var prefs: Preferences = .shared

    var body: some View {
        KKScroll {
            if prefs.shopping.isEmpty {
                KKCard {
                    ContentUnavailableView(
                        "Einkaufsliste ist leer",
                        systemImage: "cart",
                        description: Text("Füge Zutaten aus einem Rezept hinzu.")
                    )
                }
                .padding(.top, 40)
            } else {
                ForEach($prefs.shopping) { $item in
                    KKCard {
                        HStack(spacing: 10) {
                            Button {
                                item.done.toggle()
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: item.done ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                        .foregroundStyle(item.done ? .green : .secondary)
                                    Text(item.text)
                                        .strikethrough(item.done)
                                        .foregroundStyle(item.done ? .secondary : .primary)
                                    Spacer(minLength: 8)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(item.text)
                            .accessibilityValue(item.done ? "abgehakt" : "offen")
                            .accessibilityHint("Zum Abhaken tippen")

                            KKDeleteButton(accessibilityLabel: "\(item.text) löschen") {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    prefs.shopping.removeAll { $0.id == item.id }
                                }
                            }
                        }
                    }
                }
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
