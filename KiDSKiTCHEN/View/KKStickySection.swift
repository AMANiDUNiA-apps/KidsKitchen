//
//  KKStickySection.swift
//  KiDSKiTCHEN
//
//  Klebender Abschnitt mit Voll- und Minimiert-Header (Jay: „StickySection ist
//  super für Kalender und Rezepte" — hier zunächst nur der Wochenplan). Technik
//  angelehnt an Kavsoft „WSSection" (Balaji Venkatesh, ScrollGeometry +
//  visualEffect): der Header blendet beim Wegscrollen zum Minimiert-Header über,
//  der Abschnitt schrumpft/verblasst sanft am unteren Rand. Eigene, an KK
//  angepasste Fassung — @ViewBuilder statt der Vorlage @ContentBuilder (beide
//  bauen nur `some View` zusammen), KKTheme-Hintergrund statt Vorlagenfarben.
//

import SwiftUI

struct KKStickySection<Content: View, Header: View, MinimisedHeader: View>: View {
    var config: Config = .init()
    var spacing: CGFloat = 8
    @ViewBuilder var content: Content
    @ViewBuilder var header: Header
    @ViewBuilder var minimisedHeader: MinimisedHeader
    /// Für die Höhe des Voll-Headers, um Minimiert-Header und Maske korrekt zu platzieren.
    @State private var headerSize: CGSize = .zero

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            header
                .visualEffect { content, proxy in
                    let rect = proxy.frame(in: .named("KKSECTION"))
                    let minY = max(rect.minY - config.sectionPadding, 0)
                    let progress = max(min(minY / config.headerFadeDistance, 1), 0)
                    return content.opacity(1 - progress)
                }
                .background {
                    minimisedHeader
                        .frame(maxHeight: .infinity)
                        .offset(y: config.minimisedHeaderOffset / 2)
                        .visualEffect { content, proxy in
                            let rect = proxy.frame(in: .named("KKSECTION"))
                            let minY = max(rect.minY - config.sectionPadding - config.headerFadeDistance, 0)
                            let progress = max(min(minY / config.headerFadeDistance, 1), 0)
                            return content.opacity(progress)
                        }
                }
                .padding([.horizontal, .top], config.sectionPadding)
                .onGeometryChange(for: CGSize.self) { $0.size } action: { headerSize = $0 }

            content
                .padding([.horizontal, .bottom], config.sectionPadding)
                .visualEffect { content, proxy in
                    let rect = proxy.frame(in: .named("KKSECTION"))
                    let scrollMinY = proxy.frame(in: .scrollView(axis: .vertical)).minY
                    let minY = max(rect.minY - scrollMinY, 0)
                    return content.offset(y: -minY)
                }
                .clipped()
        }
        .mask {
            GeometryReader { proxy in
                let rect = proxy.frame(in: .named("KKSECTION"))
                let viewHeight = proxy.size.height
                let headerHeight = headerSize.height + config.sectionPadding + config.minimisedHeaderOffset
                let bottomPadding = min(max(rect.minY, 0), viewHeight - headerHeight)
                RoundedRectangle(cornerRadius: config.cornerRadius)
                    .padding(.bottom, bottomPadding)
            }
        }
        .background {
            GeometryReader { proxy in
                let rect = proxy.frame(in: .named("KKSECTION"))
                let viewHeight = proxy.size.height
                let headerHeight = headerSize.height + config.sectionPadding + config.minimisedHeaderOffset
                let bottomPadding = min(max(rect.minY, 0), viewHeight - headerHeight)
                RoundedRectangle(cornerRadius: config.cornerRadius)
                    .fill(config.background)
                    .padding(.bottom, bottomPadding)
            }
        }
        .compositingGroup()
        .visualEffect { [headerSize] content, proxy in
            let rect = proxy.frame(in: .scrollView(axis: .vertical))
            let minY = rect.minY
            let headerHeight = headerSize.height + config.sectionPadding + config.minimisedHeaderOffset
            let cutoffHeight = proxy.size.height - headerHeight
            let distance = abs(min(cutoffHeight + minY, 0))
            let progress = max(min(distance / config.fadeDistance, 1), 0)
            let scale = 1 - (progress * config.fadeScale)
            let opacity = 1 - progress
            return content
                .scaleEffect(scale, anchor: .top)
                .opacity(opacity)
                .offset(y: minY < 0 ? -minY : 0)
        }
        .coordinateSpace(.named("KKSECTION"))
    }

    struct Config {
        var sectionPadding: CGFloat = 14
        var cornerRadius: CGFloat = 18
        var background: AnyShapeStyle = AnyShapeStyle(.background)
        /// Minimiert-Header ggf. leicht höher/tiefer versetzen.
        var minimisedHeaderOffset: CGFloat = -10
        var headerFadeDistance: CGFloat = 15
        var fadeDistance: CGFloat = 45
        var fadeScale: CGFloat = 0.05
    }
}

#Preview {
    ScrollView {
        LazyVStack(spacing: 12) {
            ForEach(1...3, id: \.self) { i in
                KKStickySection {
                    Text("Inhalt \(i)").padding(.vertical, 10)
                } header: {
                    Text("Abschnitt \(i)").font(.headline)
                } minimisedHeader: {
                    Text("ABSCHNITT \(i)").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding(15)
        .padding(.bottom, 400)
    }
}
