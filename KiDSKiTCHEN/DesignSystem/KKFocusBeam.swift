//
//  KKFocusBeam.swift
//  KiDSKiTCHEN
//
//  Dezenter Fokus-Rand für Texteingaben: ein sanft rotierender Farbschimmer um
//  den Rahmen, nur sichtbar während die Eingabe aktiv ist (Jay 17.7.: „für
//  Texteingabe super auch bei KK"). Ersetzt keinen System-Fokusring, ergänzt
//  ihn nur um etwas Kindgerechtes im KKTheme-Ton (Standard Orange, wie
//  `.tint(.orange)` in App/ContentView.swift).
//
//  Technik nach Kavsoft „BorderBeam" portiert (Balaji Venkatesh),
//  ~/z/Agents/Claude/xCode/kavsoft/BorderBeam — der KeyframeAnimator-Rotations-
//  Ansatz für den umlaufenden Schimmer ist übernommen. Eigene, vereinfachte
//  Umsetzung: EIN Ton statt Mehrfarb-Beam-Gradient (dezent statt bunt) und an
//  `isActive` (Fokus) gekoppelt statt Dauer-Deko.
//

import SwiftUI

extension View {
    /// Fokus-Glow im KKTheme-Ton — z. B. `.kkFocusBeam(isActive: isFocused)`.
    func kkFocusBeam(isActive: Bool, tint: Color = .orange, cornerRadius: CGFloat = 14) -> some View {
        modifier(KKFocusBeamEffect(isActive: isActive, tint: tint, cornerRadius: cornerRadius))
    }
}

private struct KKFocusBeamEffect: ViewModifier {
    var isActive: Bool
    var tint: Color
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay {
                if isActive { beam }
            }
            .animation(.easeInOut(duration: 0.2), value: isActive)
    }

    private var beam: some View {
        KeyframeAnimator(initialValue: 0.0, repeating: true) { value in
            let rotation = value * 360
            let gradient = AngularGradient(
                colors: [.clear, tint, .clear],
                center: .center,
                startAngle: .degrees(140 + rotation),
                endAngle: .degrees(270 + rotation)
            )
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(gradient, lineWidth: 2)
        } keyframes: { _ in
            LinearKeyframe(1, duration: 2.2)
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        Text("Fokussiert")
            .padding()
            .background(.background, in: RoundedRectangle(cornerRadius: 14))
            .kkFocusBeam(isActive: true)
        Text("Nicht fokussiert")
            .padding()
            .background(.background, in: RoundedRectangle(cornerRadius: 14))
            .kkFocusBeam(isActive: false)
    }
    .padding()
    .background(.gray.opacity(0.2))
}
