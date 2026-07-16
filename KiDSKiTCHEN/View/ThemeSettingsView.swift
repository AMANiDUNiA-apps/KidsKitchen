//
//  ThemeSettingsView.swift
//  KiDSKiTCHEN
//
//  Design-Einstellungen: 8 Farbstyles × 4 Glassstufen × 4 Loop-Geschwindigkeiten.
//  Alle Änderungen wirken sofort (ThemeSettings.shared ist @Observable).
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
        }
        .navigationTitle("Design")
        .kkTransparentNavBar()
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

    // MARK: Glas-Stufe
    private var glassSection: some View {
        KKSection(title: "Karten-Oberfläche", systemImage: "square.on.square") {
            Picker("Glas-Stufe", selection: $settings.glassLevel) {
                ForEach(GlassLevel.allCases) { level in
                    Text(level.label).tag(level)
                }
            }
            .pickerStyle(.segmented)
            Text("Aus: solide Kartenfarbe · Stufen: Glasscheiben-Effekt")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: Loop-Geschwindigkeit
    private var loopSection: some View {
        KKSection(title: "Hintergrund-Bewegung", systemImage: "arrow.2.circlepath") {
            Picker("Loop-Geschwindigkeit", selection: $settings.loopSpeed) {
                ForEach(LoopSpeed.allCases) { speed in
                    Text(speed.label).tag(speed)
                }
            }
            .pickerStyle(.segmented)
            Text("Der Hintergrund-Gradient dreht sich sanft im Endlos-Loop.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - ThemeCard
private struct ThemeCard: View {
    let theme: KKTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                // Vorschau-Gradient
                LinearGradient(
                    colors: theme.backgroundColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
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
                RoundedRectangle(cornerRadius: 16)
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
