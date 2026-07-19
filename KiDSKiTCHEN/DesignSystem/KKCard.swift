//
//  KKCard.swift
//  KiDSKiTCHEN
//
//  Rebuild P4: aus KKContainer.swift herausgelöst (Plan-Zielstruktur
//  „KKContainer/KKCard/KKScroll/KKSection" — je Baustein eine Datei).
//

import SwiftUI

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
            // Zentrale cardTextColor-Rolle (Terra 18.7. #2, Team-Entscheid):
            // Karteninhalt rendert im colorScheme der ECHTEN Kartenfarbe
            // (Luminanz), damit .primary/.secondary immer kontrastsicher sind —
            // unabhängig von der App-Erscheinung außen.
            // ponytail: bei cardOpacity ≈ 0 (transparente Karte) sitzt der Text
            // auf dem App-Hintergrund; die Rolle folgt trotzdem der Kartenfarbe —
            // Hintergrund/Karte sind bei allen Themes gleich hell/dunkel.
            .environment(\.colorScheme, theme.hasDarkCard ? .dark : .light)
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
    /// Default = Theme-Accent (Terra 18.7.: hartes Orange brach Ernte/Nacht/Kakao).
    var tint: Color = ThemeSettings.shared.theme.accent

    var body: some View {
        HStack(spacing: 8) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.subheadline)
                    .foregroundStyle(tint)
            }
            Text(title)
                .font(KKFont.title3)
                .foregroundStyle(.primary)
            Spacer(minLength: 0)
        }
        .accessibilityAddTraits(.isHeader)
    }
}
