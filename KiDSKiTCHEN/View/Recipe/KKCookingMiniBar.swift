//
//  KKCookingMiniBar.swift
//  KiDSKiTCHEN
//
//  Kochmodus-Mini-Leiste über der Tabbar (Jay-Entscheid, „wie eine Mini-Player-
//  Leiste in Musik-Apps"): sichtbar, solange ein Rezept im Kochmodus läuft, aber
//  die Vollansicht zu ist. Zeigt Rezeptname + aktuellen Schritt + Fortschritt.
//  Antippen öffnet den Kochmodus wieder, X beendet ihn (mit Rückfrage).
//

import SwiftUI

struct KKCookingMiniBar: View {
    let session: KKCookingSession
    @State private var showEndConfirm = false

    var body: some View {
        if let recipe = session.recipe, !session.isFullScreenPresented {
            HStack(spacing: 12) {
                Button {
                    session.isFullScreenPresented = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: recipe.category?.symbolName ?? "flame.fill")
                            .foregroundStyle(recipe.category?.color ?? .orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(recipe.name)
                                .font(.system(.subheadline, design: .serif).bold())
                                .lineLimit(1)
                            if let step = session.currentStep {
                                Text("Schritt \(session.stepIndex + 1)/\(session.totalSteps): \(step.text)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        Spacer(minLength: 8)
                    }
                }
                .buttonStyle(.plain)

                Button {
                    showEndConfirm = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Kochmodus beenden")
            }
            .padding(12)
            .background(.background, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
            .confirmationDialog("Kochmodus beenden?", isPresented: $showEndConfirm) {
                Button("Beenden", role: .destructive) { session.stop() }
                Button("Weiterkochen", role: .cancel) {}
            }
        }
    }
}

#Preview {
    let session = KKCookingSession.shared
    session.start(.mock)
    session.isFullScreenPresented = false
    return KKCookingMiniBar(session: session)
        .padding()
}
