//
//  GestureTutorialOverlay.swift
//  KiDSKiTCHEN
//
//  Einmaliges Kurz-Tutorial (AppStorage), das beim ersten Öffnen eines Rezepts die
//  neuen Paket-1-Gesten erklärt: Schritt sliden, offline speichern, Rückmeldung per
//  Toast. Max. 3 Hinweise, keine Text-Wände.
//  UI-Muster nach Kavsoft „UserTutorialScreen" portiert und an KidsKitchen angepasst:
//  Die Vorlage spotlightet echte UI-Elemente über ein Snapshot-UIWindow — für eine
//  Kinder-App bewusst zu einem ruhigen, robusten Karten-Overlay reduziert.
//

import SwiftUI

struct GestureTutorialOverlay: View {
    var tint: Color
    var onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appear = false

    private struct Tip: Identifiable {
        let id = UUID()
        var icon: String
        var title: String
        var text: String
    }

    private let tips: [Tip] = [
        .init(icon: "hand.draw.fill", title: "Schritt abhaken",
              text: "Zieh den Regler nach rechts, wenn du einen Kochschritt geschafft hast."),
        .init(icon: "arrow.down.circle.fill", title: "Offline speichern",
              text: "Tipp auf Speichern — dann ist das Rezept auch ohne Internet da."),
        .init(icon: "checkmark.seal.fill", title: "Kurze Rückmeldung",
              text: "Nach jeder Aktion bekommst du oben eine kleine Bestätigung.")
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture(perform: dismiss)
                .accessibilityHidden(true)

            card
                .padding(24)
                .opacity(appear ? 1 : 0)
                .offset(y: appear || reduceMotion ? 0 : 24)
        }
        .onAppear {
            guard !appear else { return }
            if reduceMotion { appear = true }
            else { withAnimation(.smooth(duration: 0.35)) { appear = true } }
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("So funktioniert's")
                    .font(.system(.title2, design: .serif).bold())
                Text("Drei kleine Handgriffe beim Kochen:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ForEach(tips) { tip in
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: tip.icon)
                        .font(.title3)
                        .foregroundStyle(tint)
                        .frame(width: 30)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tip.title)
                            .font(.system(.callout, design: .serif).weight(.semibold))
                        Text(tip.text)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .combine)
            }

            Button(action: dismiss) {
                Text("Alles klar!")
                    .font(.system(.body, design: .serif).weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(tint.gradient, in: .capsule)
            }
        }
        .padding(22)
        .background(.background, in: .rect(cornerRadius: 24))
        .shadow(color: .black.opacity(0.2), radius: 16, y: 8)
        .frame(maxWidth: 380)
    }

    private func dismiss() {
        if reduceMotion {
            onDismiss()
        } else {
            withAnimation(.smooth(duration: 0.25)) { appear = false }
            onDismiss()
        }
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground)
        GestureTutorialOverlay(tint: .orange) {}
    }
    .fontDesign(.serif)
}
