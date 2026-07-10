//
//  ExpandableText.swift
//  KiDSKiTCHEN
//
//  „Mehr anzeigen"-Helfer für lange Texte (Rezept-Beschreibungen können aus der
//  API sehr lang sein). Inspiriert von Kavsoft „TruncationEffect" (Balaji
//  Venkatesh) — bewusst schlank umgesetzt: sichtbarer Umschalt-Knopf statt des
//  aufwändigen TextRenderer-Blur-Reveals, weil die Ausklapp-Interaktion in dieser
//  Umgebung nicht per Klick-Automation verifizierbar ist. Der Knopf erscheint nur,
//  wenn der Text im eingeklappten Zustand tatsächlich abgeschnitten würde.
//

import SwiftUI

struct ExpandableText: View {
    let text: String
    var collapsedLineLimit: Int = 4

    @State private var expanded = false
    @State private var isTruncated = false
    @State private var limitedHeight: CGFloat = 0
    @State private var fullHeight: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(text)
                .lineLimit(expanded ? nil : collapsedLineLimit)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(truncationMeasurer)

            if isTruncated {
                Button(expanded ? "weniger anzeigen" : "mehr anzeigen") {
                    withAnimation(.snappy(duration: 0.25)) { expanded.toggle() }
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.orange)
                .accessibilityHint(expanded ? "Text einklappen" : "Ganzen Text anzeigen")
            }
        }
    }

    // Misst verdeckt die Höhe des eingeklappten vs. vollständigen Textes und
    // blendet den Knopf nur ein, wenn wirklich etwas abgeschnitten ist.
    private var truncationMeasurer: some View {
        ZStack {
            Text(text)
                .lineLimit(collapsedLineLimit)
                .fixedSize(horizontal: false, vertical: true)
                .background(GeometryReader { proxy in
                    Color.clear.preference(key: LimitedHeightKey.self, value: proxy.size.height)
                })
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
                .background(GeometryReader { proxy in
                    Color.clear.preference(key: FullHeightKey.self, value: proxy.size.height)
                })
        }
        .hidden()
        .allowsHitTesting(false)
        .onPreferenceChange(LimitedHeightKey.self) { limitedHeight = $0; updateTruncation() }
        .onPreferenceChange(FullHeightKey.self) { fullHeight = $0; updateTruncation() }
    }

    private func updateTruncation() {
        // 1pt Toleranz gegen Rundungsflackern.
        isTruncated = fullHeight > limitedHeight + 1
    }
}

private struct LimitedHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

private struct FullHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}
