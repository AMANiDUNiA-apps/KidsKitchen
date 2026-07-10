//
//  AnimatedStateButton.swift
//  KiDSKiTCHEN
//
//  Zustands-Button für echte asynchrone Koch-Aktionen: läuft (Spinner) → fertig (✓).
//  UI-Muster nach Kavsoft „AnimatedStateButton" portiert und an KidsKitchen angepasst
//  (deutsche Texte, Serifen, Kategorie-Tint). Nur für ECHTE Zustände, keine Show-Animation.
//

import SwiftUI

struct AnimatedStateButton: View {
    var config: Config
    var shape: AnyShape = .init(.capsule)
    var onTap: () async -> Void

    @State private var isLoading = false

    var body: some View {
        Button {
            Task {
                isLoading = true
                await onTap()
                isLoading = false
            }
        } label: {
            HStack(spacing: 10) {
                if let symbolImage = config.symbolImage {
                    Image(systemName: symbolImage)
                        .font(.title3)
                        .contentTransition(.symbolEffect)
                        .transition(.blurReplace)
                } else if isLoading {
                    Spinner(tint: config.foregroundColor, lineWidth: 4)
                        .frame(width: 20, height: 20)
                        .transition(.blurReplace)
                }

                Text(config.title)
                    .font(.system(.body, design: .serif).weight(.semibold))
                    .contentTransition(.interpolate)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, config.hPadding)
            .padding(.vertical, config.vPadding)
            .foregroundStyle(config.foregroundColor)
            .background(config.background.gradient)
            .clipShape(shape)
            .contentShape(shape)
        }
        .disabled(isLoading)
        .buttonStyle(ScaleButtonStyle())
        .animation(config.animation, value: config)
        .animation(config.animation, value: isLoading)
    }

    struct Config: Equatable {
        var title: String
        var foregroundColor: Color
        var background: Color
        var symbolImage: String?
        var hPadding: CGFloat = 16
        var vPadding: CGFloat = 14
        var animation: Animation = .easeInOut(duration: 0.25)
    }
}

// MARK: - ScaleButtonStyle
private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .animation(.linear(duration: 0.2)) {
                $0.scaleEffect(configuration.isPressed ? 0.96 : 1)
            }
    }
}

// MARK: - Spinner
struct Spinner: View {
    var tint: Color
    var lineWidth: CGFloat = 4

    @State private var rotation: Double = 0
    @State private var extraRotation: Double = 0
    @State private var isAnimatedTriggered = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.3),
                        style: .init(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            Circle()
                .trim(from: 0, to: 0.3)
                .stroke(tint, style: .init(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                .rotationEffect(.degrees(rotation))
                .rotationEffect(.degrees(extraRotation))
        }
        .compositingGroup()
        .onAppear(perform: animate)
    }

    private func animate() {
        guard !isAnimatedTriggered else { return }
        isAnimatedTriggered = true
        withAnimation(.linear(duration: 0.7).speed(1.2).repeatForever(autoreverses: false)) {
            rotation += 360
        }
        withAnimation(.linear(duration: 1).speed(1.2).delay(1).repeatForever(autoreverses: false)) {
            extraRotation += 360
        }
    }
}

#Preview {
    AnimatedStateButton(config: .init(title: "Offline speichern",
                                      foregroundColor: .white,
                                      background: .orange,
                                      symbolImage: "arrow.down.circle.fill")) {
        try? await Task.sleep(for: .seconds(2))
    }
    .padding()
}
