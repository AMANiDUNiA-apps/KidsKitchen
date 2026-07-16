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
//  KKAnimatedBackground liefert den rotierenden Gradient-Hintergrund; respektiert
//  accessibilityReduceMotion, scenePhase und LoopSpeed == .off.
//

import SwiftUI

// MARK: - KKAnimatedBackground
/// Animierter Gradient-Hintergrund, der sich aus dem aktiven KKTheme ableitet.
/// Stoppt automatisch bei Reduce Motion, Hintergrund-App oder LoopSpeed == .off.
struct KKAnimatedBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var settings: ThemeSettings = .shared

    private var isPaused: Bool {
        reduceMotion || settings.loopSpeed == .off || scenePhase != .active
    }

    var body: some View {
        let colors = settings.theme.backgroundColors

        TimelineView(.animation(paused: isPaused)) { context in
            let duration = settings.loopSpeed.duration
            let t: CGFloat = duration > 0
                ? CGFloat(context.date.timeIntervalSinceReferenceDate
                    .truncatingRemainder(dividingBy: duration) / duration)
                : 0

            let angle = Double(t) * 2 * Double.pi
            let cosA  = CGFloat(cos(angle))
            let sinA  = CGFloat(sin(angle))

            LinearGradient(
                colors: colors,
                startPoint: UnitPoint(x: 0.5 + 0.5 * cosA, y: 0.5 + 0.5 * sinA),
                endPoint:   UnitPoint(x: 0.5 - 0.5 * cosA, y: 0.5 - 0.5 * sinA)
            )
        }
    }
}

// MARK: - KKCard
/// Abgerundete Karten-Hülle (ersetzt die frühere List-Row + `.listRowBackground`).
/// Clippt den Inhalt bewusst NICHT — Elemente dürfen überstehen (z. B. das
/// Portionen-Rad, dessen runde Enden sonst an der Kante „abgehackt" wirkten).
/// Oberfläche richtet sich nach ThemeSettings.glassLevel:
///   none   → solide Kartenfarbe (theme.cardSurface) + Rand + Schatten
///   subtle → .ultraThinMaterial + Rand
///   medium → .thinMaterial     + Rand
///   strong → .regularMaterial  + Rand
struct KKCard<Content: View>: View {
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 18
    @ViewBuilder var content: Content

    @State private var settings: ThemeSettings = .shared

    var body: some View {
        let theme = settings.theme
        let glass = settings.glassLevel

        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(padding)
            .background {
                cardBackground(cornerRadius: cornerRadius, theme: theme, glass: glass)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(theme.cardStroke, lineWidth: 1.5)
            }
            .shadow(color: theme.shadowColor, radius: 5, x: 0, y: 2)
    }

    @ViewBuilder
    private func cardBackground(cornerRadius: CGFloat, theme: KKTheme, glass: GlassLevel) -> some View {
        switch glass {
        case .none:
            RoundedRectangle(cornerRadius: cornerRadius).fill(theme.cardSurface)
        case .subtle:
            RoundedRectangle(cornerRadius: cornerRadius).fill(.ultraThinMaterial)
        case .medium:
            RoundedRectangle(cornerRadius: cornerRadius).fill(.thinMaterial)
        case .strong:
            RoundedRectangle(cornerRadius: cornerRadius).fill(.regularMaterial)
        }
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
/// Hintergrund: KKAnimatedBackground (Theme-Farben + LoopSpeed).
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
    }
}

// MARK: - Transparente Navigationsleiste
extension View {
    /// Durchsichtige Navigationsleiste (Jay 11.7.): kein Balken-Hintergrund, der
    /// Inhalt läuft beim Scrollen sichtbar unter Zurück-Knopf & Co. durch.
    func kkTransparentNavBar() -> some View {
        toolbarBackground(.hidden, for: .navigationBar)
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
