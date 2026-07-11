//
//  KKContainer.swift
//  KiDSKiTCHEN
//
//  Selbstgebautes Container-System statt Standard-`List` (Jay-Entscheid 10.7.,
//  Projekt-CLAUDE.md §UI-Bauweise). Grundbausteine für Home + Rezept-Detail:
//  ScrollView + LazyVStack tragen den Inhalt, KKCard/KKSection formen die Karten.
//  Bewusst schlicht gehalten — volle Gestaltungskontrolle, kein List-Verhalten.
//
//  Warum kein `List`: Jay will die Optik komplett selbst bestimmen (Karten,
//  Abstände, klebende Header) ohne die vorgegebenen List-Zellen/Trenner.
//

import SwiftUI

// MARK: - KKCard
/// Abgerundete Karten-Hülle (ersetzt die frühere List-Row + `.listRowBackground`).
/// Clippt den Inhalt bewusst NICHT — Elemente dürfen überstehen (z. B. das
/// Portionen-Rad, dessen runde Enden sonst an der Kante „abgehackt" wirkten).
struct KKCard<Content: View>: View {
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 18
    @ViewBuilder var content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(padding)
            .background(.background, in: RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
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
/// Konsequenz aus Jays Herz-Knopf-Entscheid 11.7.: sichtbare Bedienung statt
/// versteckter Geste. Gleiche Maße/Trefferfläche wie der Favoriten-Knopf (34×34,
/// runde contentShape), damit Kinderfinger sicher treffen. Immer mit VoiceOver-Label.
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
/// Für einfache, ungruppierte Listen (Rezept-Detail). Home nutzt eine eigene
/// Variante mit klebenden Section-Headern (`pinnedViews`).
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
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Transparente Navigationsleiste
extension View {
    /// Durchsichtige Navigationsleiste (Jay 11.7.): kein Balken-Hintergrund, der
    /// Inhalt läuft beim Scrollen sichtbar unter Zurück-Knopf & Co. durch.
    /// Muss pro View gesetzt werden — der globale UIKit-Appearance-Weg griff
    /// auf iOS 26 nicht (Gerätetest 11.7.).
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
