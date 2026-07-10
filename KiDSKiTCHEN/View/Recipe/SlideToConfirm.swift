//
//  SlideToConfirm.swift
//  KiDSKiTCHEN
//
//  Kindersichere „Slide zum Bestätigen"-Geste: verhindert versehentliches Antippen
//  beim Abhaken eines Kochschritts. Knopf muss bis ans Ende gezogen werden.
//  UI-Muster nach Kavsoft „SlideControl" portiert und an KidsKitchen angepasst
//  (inline/volle Breite statt Overlay, deutsche Texte, Serifen, Kategorie-Tint).
//

import SwiftUI

struct SlideToConfirm: View {
    var config: Config
    var onConfirm: () -> Void

    @State private var offsetX: CGFloat = 0
    @State private var isCompleted = false
    @State private var animateText = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let knobSize = size.height
            let maxLimit = size.width - knobSize
            let progress: CGFloat = isCompleted ? 1 : (maxLimit > 0 ? offsetX / maxLimit : 0)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.gray.opacity(0.22).shadow(.inner(color: .black.opacity(0.15), radius: 8)))

                Capsule()
                    .fill(config.tint.gradient)
                    .frame(width: knobSize + (size.width - knobSize) * progress, height: knobSize)

                shimmerText(size, progress: progress)

                knob(size, progress: progress, maxLimit: maxLimit)
            }
        }
        .frame(height: config.height)
        .frame(maxWidth: .infinity)
        .allowsHitTesting(!isCompleted)
        .accessibilityElement()
        .accessibilityLabel(config.idleText)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            // VoiceOver-Nutzer können ohne Zieh-Geste bestätigen.
            confirm()
        }
    }

    // MARK: Knopf
    private func knob(_ size: CGSize, progress: CGFloat, maxLimit: CGFloat) -> some View {
        Circle()
            .fill(.background)
            .padding(config.knobPadding)
            .frame(width: size.height, height: size.height)
            .overlay {
                ZStack {
                    Image(systemName: "chevron.right")
                        .opacity(1 - progress)
                        .blur(radius: progress * 10)
                    Image(systemName: "checkmark")
                        .opacity(progress)
                        .blur(radius: (1 - progress) * 10)
                }
                .font(.title3.bold())
                .foregroundStyle(config.tint)
            }
            .contentShape(.circle)
            .offset(x: isCompleted ? maxLimit : offsetX)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        guard !isCompleted else { return }
                        offsetX = min(max(value.translation.width, 0), maxLimit)
                    }
                    .onEnded { _ in
                        if offsetX >= maxLimit - 1 {
                            confirm()
                        } else {
                            withAnimation(.smooth) { offsetX = 0 }
                        }
                    }
            )
    }

    // MARK: Text mit Schimmer-Effekt
    private func shimmerText(_ size: CGSize, progress: CGFloat) -> some View {
        Text(config.idleText)
            .font(.system(.callout, design: .serif).weight(.semibold))
            .foregroundStyle(.secondary)
            .overlay {
                Rectangle()
                    .frame(height: 14)
                    .rotationEffect(.degrees(70))
                    .visualEffect { [animateText] content, proxy in
                        content
                            .offset(x: -proxy.size.width / 1.8)
                            .offset(x: animateText ? proxy.size.width * 1.2 : 0)
                    }
                    .mask(alignment: .leading) {
                        Text(config.idleText)
                            .font(.system(.callout, design: .serif).weight(.semibold))
                    }
                    .blendMode(.softLight)
            }
            .frame(maxWidth: .infinity)
            .padding(.trailing, size.height / 2)
            .mask {
                Rectangle().scale(x: 1 - progress, anchor: .trailing)
            }
            .frame(height: size.height)
            .task {
                guard !animateText, !reduceMotion else { return }
                withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                    animateText = true
                }
            }
    }

    private func confirm() {
        guard !isCompleted else { return }
        animateText = false
        withAnimation(.smooth) { isCompleted = true }
        onConfirm()
    }

    struct Config {
        var idleText: String
        var tint: Color
        var height: CGFloat = 56
        var knobPadding: CGFloat = 5
    }
}

#Preview {
    SlideToConfirm(config: .init(idleText: "Schritt geschafft — zieh mich!", tint: .orange)) {}
        .padding()
}
