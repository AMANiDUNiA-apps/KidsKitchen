//
//  KKAnimatedBackground.swift
//  KiDSKiTCHEN
//
//  Rebuild P4: aus KKContainer.swift herausgelöst (Plan-Zielstruktur
//  „KKContainer/KKCard/KKScroll/KKSection" — je Baustein eine Datei).
//
//  Aufgabe 0 (16.7.): KKAnimatedBackground liefert einen MeshGradient-
//  Hintergrund (8×8 = 64 Punkte). Außenring (28 Punkte) ist immer fest — die
//  6×6 = 36 Innenpunkte driften mit zwei überlagerten Sinus-Komponenten
//  (Drift > Gitterabstand → Überlappungen). Respektiert accessibilityReduceMotion,
//  scenePhase und loopFactor == 0.
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
        // Gierig füllen (wie `Color`): sonst dehnt sich der Verlauf auf gepushten
        // Views NICHT in die Safe-Area — es blieben weiße Balken oben/unten (nur dort,
        // Wurzel-Tabs waren ok). Diagnose 19.7. am Simulator: `Color.red` füllte randlos,
        // der TimelineView/MeshGradient-Verbund nicht → explizit maximale Fläche fordern.
        // (Weiße-Balken-Fix, von main d9e23ad geliftet, Rebuild P4.)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Opake Theme-Grundfarbe HINTER dem Mesh: die inneren Akzent-/Sekundär-
        // Punkte tragen Alpha (0,20 / 0,15) — ohne opake Basis komponieren sie bei
        // hellem Theme + System-Dunkelmodus gegen das schwarze Fenster → dunkle,
        // fotoartige Flecken (Jays „hässlicher Bug", Sim-Dark 21.7.). Mit Basis
        // mischen die transluzenten Wirbel wie gedacht auf der Creme-Fläche.
        .background(theme.backgroundColors.first ?? Color.clear)
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
