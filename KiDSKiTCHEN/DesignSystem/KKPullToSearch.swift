//
//  KKPullToSearch.swift
//  KiDSKiTCHEN
//
//  Verspielter Pull-to-Search-Einstieg: zieht man die Rezeptliste am oberen Rand
//  ein Stück nach unten, blendet sich ein Blur-Overlay mit fokussiertem Suchfeld ein
//  (Home). Die ECHTE Suche dahinter (dasselbe `search`-State wie das Nav-Suchfeld)
//  bleibt unverändert — die Ergebnisse laufen NICHT durch eine `List`, sondern durch
//  den selbstgebauten Container (KKCard-Zeilen), s. Home.pullSearchOverlay.
//
//  Muster nach Kavsoft „PullToSearch" (Balaji Venkatesh) portiert:
//  ~/z/Agents/Claude/xCode/kavsoft/PullToSearch. Übernommen wird hier nur der
//  Auslöse-Mechanismus (Scroll-Offset + Scroll-Ende-Geschwindigkeit); die Demo-
//  List für Dummy-Treffer ist bewusst durch KidsKitchens eigenen Container ersetzt.
//

import SwiftUI

/// Meldet die vertikale Wisch-Geschwindigkeit am Ende einer Scroll-Interaktion,
/// ohne das Scroll-Ziel selbst zu verändern (kein Snapping) — dadurch verträgt es
/// sich mit den gepinnten Kategorie-Headern von Home. Aus Kavsoft „PullToSearch".
struct OnScrollEnd: ScrollTargetBehavior {
    /// Rückgabe: vertikale Restgeschwindigkeit beim Loslassen.
    var onEnd: (CGFloat) -> Void

    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        let dy = context.velocity.dy
        DispatchQueue.main.async {
            onEnd(dy)
        }
    }
}
