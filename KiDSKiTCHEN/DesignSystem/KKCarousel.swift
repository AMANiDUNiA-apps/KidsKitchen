//
//  KKCarousel.swift
//  KiDSKiTCHEN
//
//  Selbst-scrollendes, endloses Paging-Karussell. Portiert aus Kavsoft
//  „AutoScrollCarousel" (CustomCarousel, Balaji Venkatesh 27/09/24) und für
//  KidsKitchen angepasst: sanfterer Auto-Scroll-Takt (kindgerecht), Pause sobald
//  ein Finger auf dem Karussell liegt (aus der Vorlage übernommen).
//
//  Verwendung: die Inhalte als Kind-Views übergeben; `activeIndex` spiegelt die
//  sichtbare Seite (für einen Punkt-Indikator). Der Rotations-INHALT wird vom
//  Aufrufer ehrlich bestimmt (hier: deterministisch nach Kalenderwoche) — dieses
//  View kümmert sich nur um die Darstellung/Bewegung.
//

import SwiftUI
import Combine

struct KKCarousel<Content: View>: View {
    @Binding var activeIndex: Int
    private let autoScrollDuration: CGFloat
    private let content: Content

    @State private var scrollPosition: Int?
    @State private var offsetBasedPosition: Int = 0
    @State private var isSettled: Bool = false
    @State private var isScrolling: Bool = false
    @GestureState private var isHoldingScreen: Bool = false
    @State private var timer: Publishers.Autoconnect<Timer.TimerPublisher>

    init(activeIndex: Binding<Int>,
         autoScrollDuration: CGFloat = 3.5,
         @ViewBuilder content: () -> Content) {
        self._activeIndex = activeIndex
        self.autoScrollDuration = autoScrollDuration
        self.content = content()
        self._timer = State(initialValue: Timer.publish(every: autoScrollDuration,
                                                         on: .main, in: .default).autoconnect())
    }

    var body: some View {
        GeometryReader {
            let size = $0.size

            Group(subviews: content) { collection in
                ScrollView(.horizontal) {
                    HStack(spacing: 0) {
                        // Klon des letzten Elements vorne + des ersten hinten → nahtloser Loop.
                        if let lastItem = collection.last {
                            lastItem
                                .frame(width: size.width, height: size.height)
                                .id(-1)
                        }

                        ForEach(collection.indices, id: \.self) { index in
                            collection[index]
                                .frame(width: size.width, height: size.height)
                                .id(index)
                        }

                        if let firstItem = collection.first {
                            firstItem
                                .frame(width: size.width, height: size.height)
                                .id(collection.count)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollPosition(id: $scrollPosition)
                .scrollTargetBehavior(.paging)
                .scrollIndicators(.hidden)
                .onScrollPhaseChange { _, newPhase in
                    isScrolling = newPhase.isScrolling

                    if !isScrolling && scrollPosition == -1 {
                        scrollPosition = collection.count - 1
                    }
                    if !isScrolling && scrollPosition == collection.count && !isHoldingScreen {
                        scrollPosition = 0
                    }
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0).updating($isHoldingScreen) { _, out, _ in
                        out = true
                    }
                )
                .onChange(of: isHoldingScreen) { _, newValue in
                    if newValue {
                        timer.upstream.connect().cancel()
                    } else {
                        if isSettled && scrollPosition != offsetBasedPosition {
                            scrollPosition = offsetBasedPosition
                        }
                        timer = Timer.publish(every: autoScrollDuration, on: .main, in: .default).autoconnect()
                    }
                }
                .onReceive(timer) { _ in
                    guard !isHoldingScreen && !isScrolling else { return }
                    let nextIndex = (scrollPosition ?? 0) + 1
                    withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                        scrollPosition = (nextIndex == collection.count + 1) ? 0 : nextIndex
                    }
                }
                .onChange(of: scrollPosition) { _, newValue in
                    if let newValue {
                        if newValue == -1 {
                            activeIndex = collection.count - 1
                        } else if newValue == collection.count {
                            activeIndex = 0
                        } else {
                            activeIndex = max(min(newValue, collection.count - 1), 0)
                        }
                    }
                }
                .onScrollGeometryChange(for: CGFloat.self) {
                    $0.contentOffset.x
                } action: { _, newValue in
                    let index = size.width > 0 ? Int((newValue / size.width).rounded() - 1) : 0
                    isSettled = size.width > 0 ? (Int(newValue) % Int(size.width) == 0) : false
                    offsetBasedPosition = index

                    if isSettled && (scrollPosition != index || index == collection.count)
                        && !isScrolling && !isHoldingScreen {
                        scrollPosition = index == collection.count ? 0 : index
                    }
                }
            }
            .onAppear { scrollPosition = 0 }
        }
    }
}
