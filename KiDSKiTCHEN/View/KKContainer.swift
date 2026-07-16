//
//  KKContainer.swift
//  KiDSKiTCHEN
//
//  Selbstgebautes Container-System statt Standard-`List` (Jay-Entscheid 10.7.,
//  Projekt-CLAUDE.md §UI-Bauweise). Grundbausteine für Home + Rezept-Detail:
//  ScrollView + LazyVStack tragen den Inhalt, KKCard/KKSection formen die Karten.
//  Bewusst schlicht gehalten — volle Gestaltungskontrolle, kein List-Verhalten.
//
//  Aufgabe 0 (16.7.): KKCard + KKScroll sind jetzt theme-aware (ThemeSettings.shared).
//  KKAnimatedBackground liefert einen MeshGradient-Hintergrund (8×8 = 64 Punkte).
//  Außenring (28 Punkte) ist immer fest — die 6×6 = 36 Innenpunkte driften mit
//  zwei überlagerten Sinus-Komponenten (Drift > Gitterabstand → Überlappungen).
//  Respektiert accessibilityReduceMotion, scenePhase und loopFactor == 0.
//

import SwiftUI

// MARK: - KKAnimatedBackground
/// MeshGradient-Hintergrund (8×8 = 64 Punkte). Außenring (28 Punkte) fest —
/// die 6×6 = 36 Innenpunkte driften mit zwei überlagerten Sinus-Komponenten
/// (irrrationales Frequenzverhältnis → quasi-periodisch). Drift-Amplitude 0,18
/// überschreitet den Gitterabstand 1/7 ≈ 0,143 bewusst → Überlappungen erzeugen
/// Falt- und Wirbelmuster. Stoppt bei Reduce Motion / Hintergrund / loopFactor == 0.
struct KKAnimatedBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var settings: ThemeSettings = .shared

    private var isPaused: Bool {
        reduceMotion || settings.isLoopPaused || scenePhase != .active
    }

    var body: some View {
        let theme  = settings.theme
        let colors = Self.meshColors(for: theme)

        TimelineView(.animation(paused: isPaused)) { context in
            let duration = settings.loopDuration
            let t = duration > 0
                ? context.date.timeIntervalSinceReferenceDate / duration * 2 * .pi
                : 0.0
            MeshGradient(
                width: 8, height: 8,
                points: Self.meshPoints(t: t),
                colors: colors
            )
        }
    }

    /// 64 Farben (8×8, zeilenweise).
    /// Außenring: Hintergrundfarben alternierend (bleibt ruhig, weil Punkte fix).
    /// 6×6 Inneres: 3×3 Patches à 2×2 Punkte, zyklisch Akzent / Sekundär / c2 —
    /// bei Überlappungen entsteht dynamische 3-Farb-Mischung.
    private static func meshColors(for theme: KKTheme) -> [Color] {
        let bg = theme.backgroundColors
        let c0 = bg[0]
        let c1 = bg.count > 1 ? bg[1] : bg[0]
        let c2 = bg.count > 2 ? bg[2] : c1
        let a  = theme.accent.opacity(theme.isDark ? 0.68 : 0.20)
        let s  = theme.secondary.opacity(theme.isDark ? 0.52 : 0.15)

        var colors = [Color]()
        colors.reserveCapacity(64)
        for row in 0 ... 7 {
            for col in 0 ... 7 {
                let color: Color
                if row == 0 || row == 7 || col == 0 || col == 7 {
                    // Außenring: c0/c1 alternierend
                    color = (row + col).isMultiple(of: 2) ? c0 : c1
                } else {
                    // 3×3 Patches (je 2×2 Punkte): (patch-Summe) % 3 → 3 Farben
                    let patch = ((row - 1) / 2 + (col - 1) / 2) % 3
                    color = patch == 0 ? a : (patch == 1 ? s : c2)
                }
                colors.append(color)
            }
        }
        return colors
    }

    /// 64 SIMD2<Float>-Punkte (8×8, zeilenweise). Gitterabstand 1/7 ≈ 0,143.
    /// Außenring (row 0/7, col 0/7) bleibt fix — kein Bildrand-Riss.
    /// 36 Innenpunkte: je Punkt vier einzigartige Frequenzen + Phasen via
    /// Goldener-Schnitt-Hash → keine sichtbare Wellenkorrelation zwischen
    /// Nachbarpunkten, wirkt wie unabhängige Zufallsbewegung.
    /// Drift 0,18 > Gitterabstand → bewusste Überlappungen.
    private static func meshPoints(t: Double) -> [SIMD2<Float>] {
        var pts = [SIMD2<Float>]()
        pts.reserveCapacity(64)
        let tf = Float(t)
        for row in 0 ... 7 {
            for col in 0 ... 7 {
                let baseX = Float(col) / 7
                let baseY = Float(row) / 7
                guard row >= 1 && row <= 6 && col >= 1 && col <= 6 else {
                    pts.append(SIMD2<Float>(baseX, baseY)); continue
                }
                let h = Float((row - 1) * 6 + (col - 1) + 1)
                // Goldener-Schnitt-Folge: frac(h · k) für irrationale k →
                // niedrige Diskrepanz, keine Korrelation zwischen Punkten.
                let fx1 = (h * 0.618034).truncatingRemainder(dividingBy: 1) * 1.4 + 0.3
                let fy1 = (h * 0.381966).truncatingRemainder(dividingBy: 1) * 1.4 + 0.3
                let fx2 = (h * 1.324718).truncatingRemainder(dividingBy: 1) * 1.0 + 0.9
                let fy2 = (h * 1.732051).truncatingRemainder(dividingBy: 1) * 1.0 + 0.9
                let px1 = (h * 2.236068).truncatingRemainder(dividingBy: 1) * (2 * .pi)
                let py1 = (h * 2.645751).truncatingRemainder(dividingBy: 1) * (2 * .pi)
                let px2 = (h * 3.162278).truncatingRemainder(dividingBy: 1) * (2 * .pi)
                let py2 = (h * 3.741657).truncatingRemainder(dividingBy: 1) * (2 * .pi)
                let drift: Float = 0.18
                let dx = (sin(tf * fx1 + px1) * 0.65 + sin(tf * fx2 + px2) * 0.35) * drift
                let dy = (cos(tf * fy1 + py1) * 0.65 + cos(tf * fy2 + py2) * 0.35) * drift
                pts.append(SIMD2<Float>(baseX + dx, baseY + dy))
            }
        }
        return pts
    }
}

// MARK: - KKCard
/// Abgerundete Karten-Hülle (ersetzt die frühere List-Row + `.listRowBackground`).
/// Clippt den Inhalt bewusst NICHT — Elemente dürfen überstehen (z. B. das
/// Portionen-Rad, dessen runde Enden sonst an der Kante „abgehackt" wirkten).
/// Oberfläche: theme.cardSurface mit stufenloser Deckkraft aus ThemeSettings.cardOpacity
///   (0 = Klar, Hintergrund scheint durch · 1 = Aus, solide Fläche).
struct KKCard<Content: View>: View {
    var padding: CGFloat = 16
    /// -1 = nutzt den Wert aus ThemeSettings.cardCornerRadius (Default). Nur für
    /// Sonderfälle überschreiben (z. B. sehr kleine Innen-Karten).
    var cornerRadius: CGFloat = -1
    @ViewBuilder var content: Content

    @State private var settings: ThemeSettings = .shared

    var body: some View {
        let theme   = settings.theme
        let opacity = settings.cardOpacity
        let r       = cornerRadius >= 0 ? cornerRadius : settings.cardCornerRadius

        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: r)
                    .fill(theme.cardSurface.opacity(opacity))
            }
            .overlay {
                RoundedRectangle(cornerRadius: r)
                    .stroke(theme.cardStroke.opacity(max(0.25, opacity)), lineWidth: 1.5)
            }
            .shadow(color: theme.shadowColor.opacity(opacity), radius: 5, x: 0, y: 2)
    }
}

// MARK: - KKSectionHeader
/// Serifen-Abschnittsüberschrift im Kids-Stil (optional mit Symbol + Tint).
struct KKSectionHeader: View {
    let title: String
    var systemImage: String? = nil
    var tint: Color = .orange

    var body: some View {
        HStack(spacing: 8) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.subheadline)
                    .foregroundStyle(tint)
            }
            Text(title)
                .font(.system(.title3, design: .serif).bold())
                .foregroundStyle(.primary)
            Spacer(minLength: 0)
        }
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - KKSection
/// Betitelter Abschnitt: Serifen-Header + Inhalt in einer KKCard, dazu optionaler
/// Fußtext. Ersetzt das `Section`-Muster der bisherigen Detail-`List`.
struct KKSection<Content: View>: View {
    var title: String? = nil
    var systemImage: String? = nil
    var tint: Color = .orange
    var footer: String? = nil
    var cardPadding: CGFloat = 16
    var contentSpacing: CGFloat = 12
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                KKSectionHeader(title: title, systemImage: systemImage, tint: tint)
                    .padding(.horizontal, 4)
            }
            KKCard(padding: cardPadding) {
                VStack(alignment: .leading, spacing: contentSpacing) {
                    content
                }
            }
            if let footer {
                Text(footer)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
        }
    }
}

// MARK: - KKDeleteButton
/// Sichtbarer, kindgerechter Lösch-Knopf (ersetzt den versteckten List-Swipe).
struct KKDeleteButton: View {
    var accessibilityLabel: String = "Löschen"
    let action: () -> Void

    var body: some View {
        Button(role: .destructive, action: action) {
            Image(systemName: "trash")
                .font(.title3)
                .foregroundStyle(.red)
                .frame(width: 34, height: 34)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - KKScroll
/// Vertikaler Grund-Container: ScrollView + LazyVStack mit einheitlichem Rand.
/// Hintergrund: KKAnimatedBackground (Theme-Farben + loopFactor).
struct KKScroll<Content: View>: View {
    var spacing: CGFloat = 16
    var horizontalPadding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            LazyVStack(spacing: spacing) {
                content
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, 12)
        }
        .background { KKAnimatedBackground().ignoresSafeArea() }
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

// MARK: - Transparente Navigationsleiste
extension View {
    /// Durchsichtige Navigationsleiste (Jay 11.7.): kein Balken-Hintergrund, der
    /// Inhalt läuft beim Scrollen sichtbar unter Zurück-Knopf & Co. durch.
    func kkTransparentNavBar() -> some View {
        toolbarBackground(.hidden, for: .navigationBar)
    }

    /// Gear-Button ganz rechts in der Navigationsleiste, öffnet ThemeSettingsView.
    /// Selbstständig: eigener @State, kein Binding erforderlich.
    func kkSettingsGear() -> some View {
        modifier(KKSettingsGearModifier())
    }
}

// MARK: - Settings-Gear-Modifier
private struct KKSettingsGearModifier: ViewModifier {
    @State private var showSettings = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                // .primaryAction = semantisch rechts außen → eigene Kapsel in iOS 26,
                // getrennt von .topBarTrailing-Items wie dem + Knopf.
                ToolbarItem(placement: .primaryAction) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Design-Einstellungen")
                }
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack { ThemeSettingsView() }
                    .presentationDragIndicator(.visible)
            }
    }
}

#Preview {
    KKScroll {
        KKSection(title: "Info", systemImage: "info.circle", tint: .orange) {
            Label("Frühstück", systemImage: "sun.max")
            Label("15 Minuten", systemImage: "clock")
        }
        KKSection(title: "Zutaten", tint: .green, footer: "je Portion") {
            Text("2 Äpfel")
            Text("100 g Haferflocken")
        }
        KKCard {
            Text("Freie Karte ohne Titel")
                .font(.system(.body, design: .serif))
        }
    }
}
