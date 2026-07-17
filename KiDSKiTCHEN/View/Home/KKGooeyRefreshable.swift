//
//  KKGooeyRefreshable.swift
//  KiDSKiTCHEN
//
//  Verspielter Pull-to-Refresh — Vorbild ist Kavsofts eigene Drag-Erkennung aus
//  „ChromePullEffect"/„PullToSearch" (nur bei scrollOffset == 0 aktiv, Fortschritt
//  aus der Drag-Übersetzung), hier auf einen einzelnen „Gooey"-Tropfen reduziert,
//  der beim Ziehen wächst und beim Loslassen verschmilzt (Canvas-Metaball via
//  Weichzeichnung + Alpha-Schwelle). Reduce Motion → einfacher Kreis/Spinner
//  ohne Verschmelz-Optik, Geste bleibt.
//
//  Einsatz in WeekPlanView: zieht die Rezeptliste (RecipeListViewModel.loadRecipes())
//  neu vom Server — eine echte Aktion, kein Attrappen-Refresh.
//

import SwiftUI

struct KKGooeyRefreshable: ViewModifier {
    var dragDistance: CGFloat = 90
    var action: () async -> Void

    @State private var scrollOffset: CGFloat = 0
    @GestureState private var isDragging: Bool = false
    @State private var initialOffset: CGFloat?
    @State private var pullProgress: CGFloat = 0
    @State private var isRefreshing: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: CGFloat.self, of: {
                $0.contentOffset.y + $0.contentInsets.top
            }, action: { _, newValue in
                scrollOffset = newValue
            })
            .onChange(of: isDragging) { _, dragging in
                initialOffset = dragging ? scrollOffset.rounded() : nil
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($isDragging) { _, out, _ in out = true }
                    .onChanged { value in
                        guard initialOffset == 0, !isRefreshing else { return }
                        let translation = max(0, value.translation.height)
                        pullProgress = min(translation / dragDistance, 1.4)
                    }
                    .onEnded { _ in
                        guard !isRefreshing, initialOffset == 0 else {
                            withAnimation(.easeInOut(duration: 0.2)) { pullProgress = 0 }
                            return
                        }
                        if pullProgress >= 1 {
                            isRefreshing = true
                            withAnimation(.easeInOut(duration: 0.2)) { pullProgress = 1 }
                            Task {
                                await action()
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    isRefreshing = false
                                    pullProgress = 0
                                }
                            }
                        } else {
                            withAnimation(.easeInOut(duration: 0.2)) { pullProgress = 0 }
                        }
                    },
                isEnabled: !isRefreshing
            )
            .background(alignment: .top) {
                KKGooeyBlob(progress: pullProgress, isRefreshing: isRefreshing, reduceMotion: reduceMotion)
                    .frame(height: dragDistance)
                    .opacity(pullProgress > 0 || isRefreshing ? 1 : 0)
            }
            .accessibilityAction(named: Text("Wochenplan aktualisieren")) {
                guard !isRefreshing else { return }
                isRefreshing = true
                Task {
                    await action()
                    isRefreshing = false
                }
            }
    }
}

/// Ein Tropfen, der beim Ziehen aus einem Blob emporwächst und sich beim Laden
/// wiegt — Metaball-Optik über Canvas-Weichzeichnung + Alpha-Schwelle.
private struct KKGooeyBlob: View {
    var progress: CGFloat
    var isRefreshing: Bool
    var reduceMotion: Bool
    @State private var wobble = false

    var body: some View {
        let clamped = min(max(progress, 0), 1.4)
        Group {
            if reduceMotion {
                if isRefreshing {
                    ProgressView().tint(.orange)
                } else {
                    Circle().fill(.orange.opacity(0.3)).frame(width: 22, height: 22)
                }
            } else {
                Canvas { context, size in
                    context.addFilter(.alphaThreshold(min: 0.5, color: .orange))
                    context.addFilter(.blur(radius: 7))
                    context.drawLayer { ctx in
                        let mainRadius = 14 + 9 * clamped
                        let centerX = size.width / 2
                        let baseY = size.height * 0.62
                        let mainRect = CGRect(x: centerX - mainRadius, y: baseY - mainRadius,
                                               width: mainRadius * 2, height: mainRadius * 2)
                        ctx.fill(Path(ellipseIn: mainRect), with: .color(.orange))

                        let dropRadius: CGFloat = 6 + (isRefreshing && wobble ? 3 : 0)
                        let dropY = baseY - mainRadius - mainRadius * clamped * 0.7
                        let dropRect = CGRect(x: centerX - dropRadius, y: dropY - dropRadius,
                                               width: dropRadius * 2, height: dropRadius * 2)
                        ctx.fill(Path(ellipseIn: dropRect), with: .color(.orange))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .onChange(of: isRefreshing) { _, refreshing in
            guard refreshing, !reduceMotion else { wobble = false; return }
            withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                wobble = true
            }
        }
    }
}

extension View {
    /// Gooey-artiger Pull-to-Refresh (s. Typ-Kommentar). `action` muss eine echte
    /// Aktion auslösen — kein Attrappen-Delay.
    func kkGooeyRefreshable(dragDistance: CGFloat = 90, action: @escaping () async -> Void) -> some View {
        modifier(KKGooeyRefreshable(dragDistance: dragDistance, action: action))
    }
}
