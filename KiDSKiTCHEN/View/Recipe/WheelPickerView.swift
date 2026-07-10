//
//  WheelPickerView.swift
//  KiDSKiTCHEN
//
//  Gebogenes Auswahl-Rad (Ziffernblatt-Optik) für ganzzahlige Werte — hier für die
//  Portionswahl im Rezept-Detail.
//  UI-Muster nach Kavsoft „WheelPicker" portiert und an KidsKitchen angepasst
//  (deutsches Header-Label per ViewBuilder, Serifen-Tint über die Config).
//

import SwiftUI

struct WheelPickerView<Label: View>: View {
    var range: ClosedRange<Int>
    @Binding var selectedValue: Int
    var config: WheelPickerConfig = .init()
    @ViewBuilder var label: (Int) -> Label

    @State private var activePosition: Int?

    var body: some View {
        GeometryReader {
            let size = $0.size
            let width = size.width - config.strokeStyle.lineWidth
            let dia = min(max(width, size.height), width)
            let radius = dia / 2

            wheelPath(size, radius: radius)
                .stroke(config.strokeColor, style: config.strokeStyle)
                .overlay {
                    wheelPickerScrollView(size: size, radius: radius)
                }
                .compositingGroup()
                .offset(y: -config.strokeStyle.lineWidth / 2)
        }
        .frame(height: config.height)
        .task {
            try? await Task.sleep(for: .seconds(0))
            guard activePosition == nil else { return }
            activePosition = selectedValue
        }
        .onChange(of: activePosition) { _, newValue in
            if let newValue, selectedValue != newValue {
                selectedValue = newValue
            }
        }
        .onChange(of: selectedValue) { _, newValue in
            if activePosition != newValue {
                activePosition = newValue
            }
        }
        .onScrollPhaseChange { _, newPhase in
            if newPhase == .idle {
                Task {
                    activePosition = nil
                    try? await Task.sleep(for: .seconds(0))
                    withAnimation(.easeInOut(duration: 0.1)) {
                        activePosition = selectedValue
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func wheelPickerScrollView(size: CGSize, radius: CGFloat) -> some View {
        let wheelShape = wheelPath(size, radius: radius)
            .strokedPath(config.strokeStyle)

        ScrollView(.horizontal) {
            LazyHStack(spacing: config.gapBetweenTicks) {
                ForEach(ticks, id: \.self) { tick in
                    tickView(tick, size: size, radius: radius)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled(true)
        .safeAreaPadding(.horizontal, (size.width - 8) / 2)
        .scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByOne))
        .scrollPosition(id: $activePosition, anchor: .center)
        .clipShape(wheelShape)
        .contentShape(wheelShape)
        .overlay(alignment: .bottom) {
            let strokeWidth = config.strokeStyle.lineWidth
            VStack(spacing: -5) {
                Capsule()
                    .fill(config.activeTint)
                    .frame(width: 5, height: strokeWidth)
                Circle()
                    .fill(config.activeTint)
                    .frame(width: 10, height: 10)
            }
            .offset(y: -radius + strokeWidth / 2 + 5)
        }
        .overlay(alignment: .bottom) {
            if radius > 0 {
                label(activePosition ?? selectedValue)
                    .frame(
                        maxWidth: radius,
                        maxHeight: radius - (config.strokeStyle.lineWidth / 2)
                    )
            }
        }
    }

    @ViewBuilder
    private func tickView(_ value: Int, size: CGSize, radius: CGFloat) -> some View {
        let strokeWidth = config.strokeStyle.lineWidth
        let halfStrokeWidth = strokeWidth / 2
        let isLargeTick = ((ticks.firstIndex(of: value) ?? 0)) % config.largeTickFrequency == 0

        GeometryReader { proxy in
            let midX = proxy.frame(in: .scrollView(axis: .horizontal)).midX
            let minX = proxy.frame(in: .scrollView(axis: .horizontal)).minX
            let halfWidth = size.width / 2
            let progress = max(min(midX / halfWidth, 1), -1)
            let rotation = Angle(degrees: progress * 180)

            Capsule()
                .fill(config.inactiveTint)
                .offset(y: -radius + halfStrokeWidth)
                .rotationEffect(rotation, anchor: .bottom)
                .offset(x: -minX)
        }
        .frame(width: 3, height: strokeWidth * (isLargeTick ? config.largeTickRatio : config.smallTickRatio))
        .frame(width: 8, alignment: .leading)
    }

    private func wheelPath(_ size: CGSize, radius: CGFloat) -> Path {
        Path { path in
            path.addArc(
                center: .init(x: size.width / 2, y: size.height),
                radius: radius,
                startAngle: .degrees(180),
                endAngle: .degrees(0),
                clockwise: false
            )
        }
    }

    private var ticks: [Int] {
        stride(from: range.lowerBound, through: range.upperBound, by: 1).map { $0 }
    }

    struct WheelPickerConfig {
        var activeTint: Color = .primary
        var inactiveTint: Color = Color.gray.opacity(0.8)
        var largeTickFrequency: Int = 5
        var strokeStyle: StrokeStyle = .init(lineWidth: 44, lineCap: .round, lineJoin: .round)
        var strokeColor: Color = .black.opacity(0.06)
        var largeTickRatio: CGFloat = 0.65
        var smallTickRatio: CGFloat = 0.4
        var gapBetweenTicks: CGFloat = 6
        var height: CGFloat = 150
    }
}

#Preview {
    struct Demo: View {
        @State private var value = 2
        var body: some View {
            WheelPickerView(range: 1...12, selectedValue: $value) { value in
                Text("\(value)")
                    .font(.system(.title, design: .serif).bold())
            }
            .padding()
        }
    }
    return Demo()
}
