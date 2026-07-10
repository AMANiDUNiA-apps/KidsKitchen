//
//  StaggeredView.swift
//  KiDSKiTCHEN
//
//  Lässt die enthaltenen Zeilen leicht nacheinander (gestaffelt) einschweben.
//  Hier für die Zutatenliste im Rezept-Detail — bewusst reduziert (kleiner Versatz,
//  kurze Verzögerung; Kinder-App, keine Effekt-Show). Reduce-Motion wird an der
//  Aufrufstelle beachtet (dort wird ganz auf die Staffelung verzichtet).
//  UI-Muster nach Kavsoft „StaggeredAnimation" portiert und an KidsKitchen angepasst.
//

import SwiftUI

struct StaggeredView<Content: View>: View {
    var config: StaggeredConfig = .init()
    @ViewBuilder var content: Content

    var body: some View {
        Group(subviews: content) { collection in
            ForEach(collection.indices, id: \.self) { index in
                collection[index]
                    .transition(CustomStaggeredTransition(index: index, config: config))
            }
        }
    }
}

private struct CustomStaggeredTransition: Transition {
    var index: Int
    var config: StaggeredConfig

    func body(content: Content, phase: TransitionPhase) -> some View {
        let animationDelay = min(Double(index) * config.delay, config.maxDelay)
        let isIdentity = phase == .identity
        let y = config.offset.height

        content
            .opacity(isIdentity ? 1 : 0)
            .blur(radius: isIdentity ? 0 : config.blurRadius)
            .compositingGroup()
            .offset(y: isIdentity ? 0 : y)
            .animation(config.animation.delay(animationDelay), value: phase)
    }
}

// MARK: - Config
struct StaggeredConfig {
    var delay: Double = 0.045
    var maxDelay: Double = 0.3
    var blurRadius: CGFloat = 4
    var offset: CGSize = .init(width: 0, height: 22)
    var animation: Animation = .smooth(duration: 0.4)
}
