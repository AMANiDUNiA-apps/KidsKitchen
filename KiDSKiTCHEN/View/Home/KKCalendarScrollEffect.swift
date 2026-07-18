//
//  KKCalendarScrollEffect.swift
//  KiDSKiTCHEN
//
//  Kavsoft „CalendarScrollEffect" (Balaji Venkatesh), zweite Runde: KKStickySection
//  übernimmt bereits das Kleben/Kollabieren JE Wochentag (Kavsoft „WSSection"). Was
//  von CalendarScrollEffect noch fehlt, ist die fixe Kopfzeile, die sanft reagiert,
//  während der Inhalt darunter scrollt — hier auf den Wochenstreifen gelegt (NICHT
//  auf die Tages-Header, die kollabieren schon selbst): er schrumpft/verblasst
//  leicht, sobald der Wochenplan wegscrollt. Additiv, berührt KKStickySection nicht.
//  Reduce Motion → fix, kein Schrumpfen.
//

import SwiftUI

private struct KKCollapsingOnScroll: ViewModifier {
    var offset: CGFloat
    var distance: CGFloat = 60
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let progress = reduceMotion ? 0 : min(max(offset / distance, 0), 1)
        content
            .scaleEffect(1 - 0.08 * progress, anchor: .top)
            .opacity(1 - 0.35 * progress)
    }
}

extension View {
    /// Schrumpft/verblasst sanft mit dem Scroll-Offset des Wochenplans darunter.
    func kkCollapsingOnScroll(offset: CGFloat, distance: CGFloat = 60) -> some View {
        modifier(KKCollapsingOnScroll(offset: offset, distance: distance))
    }
}
