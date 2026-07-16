//
//  ThemeSettingsView.swift
//  KiDSKiTCHEN
//
//  Design-Einstellungen: 8 Farbstyles + drei stufenlose Regler
//  (Karten-Deckkraft / Hintergrund-Bewegung / Ecken-Radius).
//  Alle Änderungen wirken sofort (ThemeSettings.shared @Observable).
//

import SwiftUI

struct ThemeSettingsView: View {
    @State private var settings: ThemeSettings = .shared

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        KKScroll {
            themeGrid
            glassSection
            loopSection
            radiusSection
        }
        .navigationTitle("Design")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: Theme-Grid (8 Karten)
    private var themeGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            KKSectionHeader(title: "Farbstyle", systemImage: "paintpalette")
                .padding(.horizontal, 4)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(KKTheme.all) { theme in
                    ThemeCard(
                        theme: theme,
                        isSelected: settings.themeID == theme.id
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            settings.themeID = theme.id
                        }
                    }
                }
            }
        }
    }

    // MARK: Karten-Oberfläche
    // Links = Klar (0, Hintergrund sichtbar) · Rechts = Aus (1, solide Karte).
    private var glassSection: some View {
        KKSection(title: "Karten-Oberfläche", systemImage: "square.on.square") {
            Slider(value: $settings.cardOpacity, in: 0...1)
                .tint(settings.theme.accent)
            HStack {
                Text("Klar").font(.caption2.bold()).foregroundStyle(.secondary)
                Spacer()
                Text("Aus").font(.caption2.bold()).foregroundStyle(.secondary)
            }
            Text("Klar: Hintergrund scheint durch · Aus: solide Karte ohne Durchblick")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    // MARK: Hintergrund-Bewegung
    // Links = Aus (0, statisch) · Rechts = Lebhaft (1, 30s Drift).
    private var loopSection: some View {
        KKSection(title: "Hintergrund-Bewegung", systemImage: "arrow.2.circlepath") {
            Slider(value: $settings.loopFactor, in: 0...1)
                .tint(settings.theme.accent)
            HStack {
                Text("Aus").font(.caption2.bold()).foregroundStyle(.secondary)
                Spacer()
                Text("Lebhaft").font(.caption2.bold()).foregroundStyle(.secondary)
            }
            Text("Aus: statischer Hintergrund · Lebhaft: schnelle Drift-Bewegung")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    // MARK: Ecken-Radius
    // Links = Eckig (8 pt) · Rechts = Pillen (36 pt).
    private var radiusSection: some View {
        KKSection(title: "Ecken-Radius", systemImage: "rectangle.roundedtop") {
            Slider(value: Binding(
                get: { Double(settings.cardCornerRadius) },
                set: { settings.cardCornerRadius = CGFloat($0) }
            ), in: 8...36)
                .tint(settings.theme.accent)
            HStack {
                Text("Eckig").font(.caption2.bold()).foregroundStyle(.secondary)
                Spacer()
                Text("Pillen").font(.caption2.bold()).foregroundStyle(.secondary)
            }
            Text("Wirkt auf alle Karten und Innen-Elemente.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}

// MARK: - ThemeCard
private struct ThemeCard: View {
    let theme: KKTheme
    let isSelected: Bool
    let action: () -> Void

    @State private var settings: ThemeSettings = .shared

    var body: some View {
        let r = settings.cardCornerRadius

        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                // Vorschau-Gradient
                LinearGradient(
                    colors: theme.backgroundColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: r))
                .frame(height: 100)

                // Akzent-Streifen unten
                VStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Circle().fill(theme.accent).frame(width: 14, height: 14)
                        Circle().fill(theme.secondary).frame(width: 14, height: 14)
                        Circle().fill(theme.cta).frame(width: 14, height: 14)
                    }
                    .padding(.bottom, 8)
                    .padding(.leading, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Deko-Symbol
                Image(systemName: theme.decoSymbol)
                    .font(.title)
                    .foregroundStyle(theme.accent.opacity(0.35))
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 12)

                // Auswahl-Haken
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .shadow(radius: 2)
                        .padding(8)
                }
            }
            .frame(height: 100)
            .overlay {
                RoundedRectangle(cornerRadius: r)
                    .stroke(isSelected ? theme.accent : Color.clear, lineWidth: 3)
            }
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

            Text(theme.name)
                .font(.caption.bold())
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 4)
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.04 : 1)
        .animation(.spring(response: 0.28), value: isSelected)
    }
}

#Preview {
    NavigationStack { ThemeSettingsView() }
}
