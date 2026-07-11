//
//  KKDynamicSheet.swift
//  KiDSKiTCHEN
//
//  Sheet, dessen Höhe sich an den Inhalt anpasst (kompakt statt Vollbild). Für
//  „Rezept zu Tag hinzufügen" im Wochenplaner: wenig Inhalt → niedriges Sheet,
//  mehr Inhalt → wächst, gedeckelt auf knapp Bildschirmhöhe.
//
//  Muster nach Kavsoft „DynamicHeightSheet" (Balaji Venkatesh) portiert:
//  ~/z/Agents/Claude/xCode/kavsoft/DynamicHeightSheet. Logik unverändert, nur an
//  KK-Namensschema (KKDynamicSheet) angepasst und der Fensterhöhen-Zugriff
//  gegen einen Fallback abgesichert.
//

import SwiftUI

struct KKDynamicSheet<Content: View>: View {
    var animation: Animation
    @ViewBuilder var content: Content
    @State private var sheetHeight: CGFloat = 0

    var body: some View {
        ZStack {
            content
                // Fixiert die vertikale Eigengröße, damit sie gemessen werden kann.
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGSize.self) {
                    $0.size
                } action: { newValue in
                    let capped = min(newValue.height, windowHeight - 110)
                    if sheetHeight == .zero {
                        sheetHeight = capped
                    } else {
                        withAnimation(animation) { sheetHeight = capped }
                    }
                }
        }
        .modifier(SheetHeightModifier(height: sheetHeight))
    }

    /// Fensterhöhe zur Deckelung — mit Fallback, falls keine Szene auflösbar ist.
    private var windowHeight: CGFloat {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
            .screen.bounds.height ?? 812
    }
}

private struct SheetHeightModifier: ViewModifier, Animatable {
    var height: CGFloat
    var animatableData: CGFloat {
        get { height }
        set { height = newValue }
    }
    func body(content: Content) -> some View {
        content
            .presentationDetents(height == .zero ? [.medium] : [.height(height)])
    }
}
