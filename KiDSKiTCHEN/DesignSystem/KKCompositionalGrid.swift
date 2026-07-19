//
//  KKCompositionalGrid.swift
//  KiDSKiTCHEN
//
//  Magazin-Kachelraster mit wechselnden Kachelgrößen (vier alternierende Layouts).
//  Portiert aus Kavsoft „CompositionalGridLayout" (CompositionalLayout,
//  Balaji Venkatesh 05/08/24) — unverändert in der Layout-Logik, nur umbenannt.
//
//  Warum hier: der Vorratsschrank zeigt Zutaten-Kacheln. Die wechselnden Größen
//  wirken verspielt (kindgerecht) und sind bildbereit — sobald die freigestellten
//  PNG-mit-Alpha-Bilder aus der macMini-Pipeline da sind, füllen sie die Kacheln
//  1:1 ohne Layout-Änderung.
//

import SwiftUI

struct KKCompositionalGrid<Content: View>: View {
    var count: Int = 3
    var spacing: CGFloat = 8
    @ViewBuilder var content: Content
    @Namespace private var animation

    var body: some View {
        Group(subviews: content) { collection in
            let chunked = collection.chunked(count)

            ForEach(chunked) { chunk in
                switch chunk.layoutID {
                case 0: Layout1(chunk.collection)
                case 1: Layout2(chunk.collection)
                case 2: Layout3(chunk.collection)
                default: Layout4(chunk.collection)
                }
            }
        }
    }

    @ViewBuilder
    private func Layout1(_ collection: [SubviewsCollection.Element]) -> some View {
        GeometryReader {
            let width = $0.size.width - spacing

            HStack(spacing: spacing) {
                if let first = collection.first {
                    first
                        .matchedGeometryEffect(id: first.id, in: animation)
                }

                if collection.count != 1 {
                    VStack(spacing: spacing) {
                        ForEach(collection.dropFirst()) {
                            $0
                                .matchedGeometryEffect(id: $0.id, in: animation)
                                .frame(width: width * 0.33)
                        }
                    }
                }
            }
        }
        .frame(height: 200)
    }

    @ViewBuilder
    private func Layout2(_ collection: [SubviewsCollection.Element]) -> some View {
        HStack(spacing: spacing) {
            ForEach(collection) {
                $0
                    .matchedGeometryEffect(id: $0.id, in: animation)
            }
        }
        .frame(height: collection.count == 1 ? 200 : 100)
    }

    @ViewBuilder
    private func Layout3(_ collection: [SubviewsCollection.Element]) -> some View {
        GeometryReader {
            let width = $0.size.width - spacing

            HStack(spacing: spacing) {
                if collection.count == 4 {
                    HStack(spacing: spacing) {
                        VStack(spacing: spacing) {
                            ForEach(collection.prefix(2)) {
                                $0
                                    .matchedGeometryEffect(id: $0.id, in: animation)
                            }
                        }

                        VStack(spacing: spacing) {
                            ForEach(collection.dropFirst().dropFirst()) {
                                $0
                                    .matchedGeometryEffect(id: $0.id, in: animation)
                            }
                        }
                    }
                } else {
                    if let first = collection.first {
                        first
                            .matchedGeometryEffect(id: first.id, in: animation)
                            .frame(width: collection.count == 1 ? nil : width * 0.33)
                    }

                    if collection.count != 1 {
                        VStack(spacing: spacing) {
                            ForEach(collection.dropFirst()) {
                                $0
                                    .matchedGeometryEffect(id: $0.id, in: animation)
                            }
                        }
                    }
                }
            }
        }
        .frame(height: collection.count == 4 ? 300 : 200)
    }

    @ViewBuilder
    private func Layout4(_ collection: [SubviewsCollection.Element]) -> some View {
        HStack(spacing: spacing) {
            ForEach(collection) {
                $0
                    .matchedGeometryEffect(id: $0.id, in: animation)
            }
        }
        .frame(height: 230)
    }
}

private extension SubviewsCollection {
    func chunked(_ size: Int) -> [ChunkedCollection] {
        stride(from: 0, to: count, by: size).map {
            let collection = Array(self[$0..<Swift.min($0 + size, count)])
            let layoutID = ($0 / size) % 4
            return .init(layoutID: layoutID, collection: collection)
        }
    }

    struct ChunkedCollection: Identifiable {
        var id: UUID = .init()
        var layoutID: Int
        var collection: [SubviewsCollection.Element]
    }
}
