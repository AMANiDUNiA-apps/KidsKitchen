//
//  InlineToast.swift
//  KiDSKiTCHEN
//
//  Inline-Meldungen (z. B. „Zur Einkaufsliste hinzugefügt") — schieben sich in den
//  Layout-Fluss statt als Overlay den Inhalt zu verdecken.
//  UI-Muster nach Kavsoft „InlineToasts" portiert und an KidsKitchen angepasst
//  (deutsche Texte, Serifen-Titel, abgerundet mit Schatten).
//

import SwiftUI

// MARK: - Config
struct InlineToastConfig: Equatable {
    var icon: String
    var title: String
    var subTitle: String = ""
    var tint: Color
    var anchor: Anchor = .top

    enum Anchor { case top, bottom }
}

// MARK: - Modifier
extension View {
    /// Blendet einen Inline-Toast ober- (anchor .top) oder unterhalb (anchor .bottom)
    /// dieser View ein, ohne Inhalt zu überdecken.
    func inlineToast(config: InlineToastConfig, isPresented: Bool) -> some View {
        VStack(spacing: 10) {
            if config.anchor == .bottom {
                self.frame(maxWidth: .infinity)
            }

            if isPresented {
                InlineToastView(config: config)
                    .transition(ToastTransition(anchor: config.anchor))
                    .padding(.horizontal, 16)
            }

            if config.anchor == .top {
                self.frame(maxWidth: .infinity)
            }
        }
        .clipped()
    }
}

// MARK: - Transition
private struct ToastTransition: Transition {
    var anchor: InlineToastConfig.Anchor
    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .opacity(phase.isIdentity ? 1 : 0)
            .visualEffect { [phase] content, proxy in
                content.offset(y: offset(proxy, phase: phase))
            }
            .clipped()
    }

    nonisolated func offset(_ proxy: GeometryProxy, phase: TransitionPhase) -> CGFloat {
        let height = proxy.size.height + 10
        return anchor == .top
            ? (phase.isIdentity ? 0 : -height)
            : (phase.isIdentity ? 0 : height)
    }
}

// MARK: - Toast View
struct InlineToastView: View {
    var config: InlineToastConfig

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: config.icon)
                .font(.title2)
                .foregroundStyle(config.tint)

            VStack(alignment: .leading, spacing: 3) {
                Text(config.title)
                    .font(.system(.callout, design: .serif).weight(.semibold))
                    .foregroundStyle(.primary)
                if !config.subTitle.isEmpty {
                    Text(config.subTitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 14).fill(.background)
                RoundedRectangle(cornerRadius: 14).fill(config.tint.opacity(0.12))
                Rectangle().fill(config.tint).frame(width: 5)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
        .lineLimit(1)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack {
        Color.clear
            .frame(height: 40)
            .inlineToast(
                config: .init(icon: "cart.badge.plus",
                              title: "Zur Einkaufsliste hinzugefügt",
                              subTitle: "3 Zutaten",
                              tint: .green),
                isPresented: true
            )
        Spacer()
    }
    .padding()
}
