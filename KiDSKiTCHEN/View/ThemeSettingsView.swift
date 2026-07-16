//
//  ThemeSettingsView.swift
//  KiDSKiTCHEN
//
//  Design-Einstellungen: 8 Farbstyles + vier stufenlose/wählbare Regler
//  (Karten-Deckkraft / Hintergrund-Bewegung / Ecken-Radius / Übergangs-Animation).
//  Alle Änderungen wirken sofort (ThemeSettings.shared @Observable).
//

import SwiftUI

struct ThemeSettingsView: View {
    @State private var settings: ThemeSettings = .shared
    @State private var prefs: Preferences = .shared

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        KKScroll {
            themeGrid
            glassSection
            loopSection
            radiusSection
            transitionSection
            parentalSection
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
    // Toggle an/aus + Slider für die Loop-Dauer in echten Sekunden (21–86 s).
    // 21 s = schnell · 86 s = sehr sanft. Reduce Motion schaltet automatisch ab.
    private var loopSection: some View {
        KKSection(title: "Hintergrund-Bewegung", systemImage: "arrow.2.circlepath") {
            Toggle("Bewegung aktiv", isOn: $settings.animationEnabled)
                .tint(settings.theme.accent)

            if settings.animationEnabled {
                Divider()
                Slider(value: $settings.animationSeconds, in: 21...86)
                    .tint(settings.theme.accent)
                HStack {
                    Text("Schnell (21 s)").font(.caption2.bold()).foregroundStyle(.secondary)
                    Spacer()
                    Text("Sanft (86 s)").font(.caption2.bold()).foregroundStyle(.secondary)
                }
                Text("Aktuell: \(Int(settings.animationSeconds)) s pro Zyklus.")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                Text("Hintergrund bleibt statisch. Auch automatisch aus bei reduzierter Bewegung.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Ecken-Radius
    // Links = Eckig (8 pt) · Rechts = Pillen (36 pt).
    // DEMO Design-Token: diesen Regler ändern → Radius wirkt auf ALLE Screens gleichzeitig.
    private var radiusSection: some View {
        KKSection(title: "Ecken-Radius", systemImage: "rectangle.roundedtop") {
            Slider(value: Binding(
                get: { Double(settings.cardCornerRadius) },
                set: { settings.cardCornerRadius = CGFloat($0) }
            ), in: 8...36)
                .tint(settings.theme.accent)
            HStack {
                Text("Eckig (8)").font(.caption2.bold()).foregroundStyle(.secondary)
                Spacer()
                Text("Pillen (36)").font(.caption2.bold()).foregroundStyle(.secondary)
            }
            Text("Wirkt zentral auf alle Karten und Innen-Elemente.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    // MARK: Übergangs-Animation (Zutaten-Übersicht)
    private var transitionSection: some View {
        KKSection(title: "Übergangs-Animation (Zutaten)", systemImage: "wand.and.sparkles") {
            Picker("Stil", selection: $settings.pantryTransition) {
                ForEach(PantryTransitionStyle.allCases) { style in
                    Text(style.label).tag(style)
                }
            }
            .pickerStyle(.segmented)
            Text("Animation beim Einblenden der Zutaten-Kacheln in der Vorratsschrank-Übersicht.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    // MARK: Eltern-Kontrolle
    private var parentalSection: some View {
        KKSection(title: "Eltern-Kontrolle", systemImage: "lock.shield") {
            Toggle("Rezept-Import sperren", isOn: $prefs.kidsControlEnabled)
                .tint(settings.theme.accent)
            Text("Wenn aktiv, erscheint vor dem Rezept-Import eine Rechenaufgabe als Freigabehürde (Apple Kids-Category-Anforderung für Webzugriff).")
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
                LinearGradient(
                    colors: theme.backgroundColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: r))
                .frame(height: 100)

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

                Image(systemName: theme.decoSymbol)
                    .font(.title)
                    .foregroundStyle(theme.accent.opacity(0.35))
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 12)

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
