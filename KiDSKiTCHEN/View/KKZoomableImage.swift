//
//  KKZoomableImage.swift
//  KiDSKiTCHEN
//
//  Bild in der Zutat-Detailansicht per Tippen groß aufziehen — Vollbild mit
//  Pinch-Zoom, Doppel-Tap und Verschieben (Jay 17.7.: „Bilder in Groß bezogen
//  auf Lebensmittel/Rezepte").
//
//  Technik nach Kavsoft „ResizableView" portiert (Balaji Venkatesh),
//  ~/z/Agents/Claude/xCode/kavsoft/ResizableView — dort ein Editor mit vier
//  Ecken-Ziehpunkten zum Größenverändern/Verschieben eines Views. Hier bewusst
//  vereinfacht auf reines Betrachten (Pinch/Doppel-Tap/Wischen im Vollbild),
//  keine Ecken-Ziehpunkte — Kinder sollen groß angucken, nicht zuschneiden.
//

import SwiftUI

extension View {
    /// Macht dieses Bild bei Tippen groß aufziehbar (Vollbild, Pinch-Zoom,
    /// Doppel-Tap zum Reinzoomen). Z. B. `IngredientImageView(...).kkZoomable()`.
    func kkZoomable() -> some View {
        modifier(KKZoomableModifier())
    }
}

private struct KKZoomableModifier: ViewModifier {
    @State private var isPresented = false

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .onTapGesture { isPresented = true }
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Zum Vergrößern tippen")
            .fullScreenCover(isPresented: $isPresented) {
                KKZoomedImage { isPresented = false } content: { content }
            }
    }
}

private struct KKZoomedImage<Content: View>: View {
    var onClose: () -> Void
    @ViewBuilder var content: () -> Content

    /// Natürliche Größe des Inhalts (z. B. der feste 200×200-Slot von
    /// IngredientImageView) — daraus wird die Basis-Vergrößerung berechnet,
    /// die das Bild schon beim Öffnen groß zeigt (nicht erst nach Pinch).
    @State private var naturalSize: CGSize = .init(width: 100, height: 100)
    @State private var pinchScale: CGFloat = 1
    @State private var lastPinchScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            let fitScale = naturalSize.width > 0 && naturalSize.height > 0
                ? min(geo.size.width * 0.85 / naturalSize.width,
                      geo.size.height * 0.7 / naturalSize.height,
                      6)
                : 1
            ZStack {
                Color.black.ignoresSafeArea()

                content()
                    .onGeometryChange(for: CGSize.self, of: { $0.size }) { naturalSize = $0 }
                    .scaleEffect(fitScale * pinchScale)
                    .offset(offset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                pinchScale = max(1, min(lastPinchScale * value, 4))
                            }
                            .onEnded { _ in
                                lastPinchScale = pinchScale
                                if pinchScale == 1 { offset = .zero; lastOffset = .zero }
                            }
                    )
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                guard pinchScale > 1 else { return }
                                offset = CGSize(width: lastOffset.width + value.translation.width,
                                                 height: lastOffset.height + value.translation.height)
                            }
                            .onEnded { _ in lastOffset = offset }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            pinchScale = pinchScale > 1 ? 1 : 2.5
                            lastPinchScale = pinchScale
                            if pinchScale == 1 { offset = .zero; lastOffset = .zero }
                        }
                    }
            }
        }
        .overlay(alignment: .topTrailing) {
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white, .black.opacity(0.4))
            }
            .padding()
            .accessibilityLabel("Schließen")
        }
    }
}

#Preview {
    Image(systemName: "carrot.fill")
        .resizable()
        .scaledToFit()
        .frame(width: 80, height: 80)
        .foregroundStyle(.orange)
        .kkZoomable()
}
