//
//  CookableSuggestionsView.swift
//  KiDSKiTCHEN
//
//  Weiterbau 8, Teil C — „Was kann ich heute kochen?". Reines Set-Matching gegen
//  den Vorrat (KEIN LLM, deterministisch, offline): Rezepte nach „alles da / 1 fehlt
//  / 2 fehlen" sortiert, fehlende Zutaten benannt.
//
//  Zwei Einstiege teilen sich diese Ansicht:
//   • Aus dem Wochenplan mit `day` → Antippen ordnet das Rezept dem Tag zu (addToPlan).
//   • Aus dem Vorratsschrank ohne `day` → Antippen öffnet die Rezept-Detailansicht.
//
//  Theme-aware (16.7.): KKAnimatedBackground, KKCard-Stil für Zeilen.
//

import SwiftUI

struct CookableSuggestionsView: View {
    /// Zieltag, falls aus dem Wochenplan geöffnet — dann ordnet ein Tippen zu.
    var day: Weekday?
    @State private var prefs: Preferences = .shared
    @State private var viewModel: RecipeListViewModel = .shared
    @State private var settings: ThemeSettings = .shared
    @Environment(\.dismiss) private var dismiss

    private var matches: [CookableMatch] {
        var all = prefs.cookableSuggestions(from: viewModel.recipes)
        if let day {
            let planned = Set(prefs.plannedRecipes(day))
            all = all.filter { !planned.contains($0.recipe.name) }
        }
        return all
    }

    var body: some View {
        NavigationStack {
            ZStack {
                KKAnimatedBackground().ignoresSafeArea()

                if prefs.pantry.isEmpty {
                    empty("Vorrat ist leer",
                          "Leg zuerst etwas in den Vorratsschrank — dann schlage ich passende Rezepte vor.")
                } else if matches.isEmpty {
                    empty("Nichts Passendes",
                          "Für kein Rezept fehlen höchstens zwei Zutaten. Fülle den Vorrat weiter auf.")
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(matches) { match in row(match) }
                        }
                        .padding(16)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationTitle("Was kann ich kochen?")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }
                }
            }
        }
    }

    // MARK: Zeile — je nach Einstieg Zuordnen-Knopf oder Detail-Link
    @ViewBuilder
    private func row(_ match: CookableMatch) -> some View {
        if let day {
            Button {
                withAnimation(.snappy(duration: 0.2)) {
                    prefs.addToPlan(match.recipe.name, day: day)
                }
                dismiss()
            } label: {
                rowContent(match, trailing: "plus.circle.fill")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(match.recipe.name) zu \(day.rawValue) hinzufügen. \(statusText(match))")
        } else {
            NavigationLink {
                Rezepte(recipe: match.recipe)
            } label: {
                rowContent(match, trailing: "chevron.right")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(match.recipe.name). \(statusText(match))")
        }
    }

    private func rowContent(_ match: CookableMatch, trailing: String) -> some View {
        let color = match.recipe.category?.color ?? .orange
        return HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: settings.cardInnerRadius)
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: match.recipe.category?.symbolName ?? "fork.knife")
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(match.recipe.name)
                    .font(.system(.body, design: .serif).weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                statusBadge(match)
            }
            Spacer(minLength: 8)
            Image(systemName: trailing)
                .font(match.missingCount == 0 ? .title3 : .footnote.bold())
                .foregroundStyle(color)
        }
        .padding(12)
        .background(settings.theme.cardSurface,
                    in: RoundedRectangle(cornerRadius: settings.cardCornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: settings.cardCornerRadius)
                .strokeBorder(settings.theme.cardStroke, lineWidth: 1)
        }
        .shadow(color: settings.theme.shadowColor, radius: 3, y: 1)
        .contentShape(Rectangle())
    }

    // MARK: Status „alles da / 1 fehlt: … / 2 fehlen: …"
    @ViewBuilder
    private func statusBadge(_ match: CookableMatch) -> some View {
        if match.missingCount == 0 {
            Label("alles da", systemImage: "checkmark.circle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.green)
        } else {
            Label(statusText(match), systemImage: "cart.badge.plus")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private func statusText(_ match: CookableMatch) -> String {
        switch match.missingCount {
        case 0: return "alles da"
        case 1: return "1 fehlt: \(match.missingNames[0])"
        default: return "\(match.missingCount) fehlen: \(match.missingNames.joined(separator: ", "))"
        }
    }

    private func empty(_ title: String, _ message: String) -> some View {
        ContentUnavailableView {
            Label(title, systemImage: "sparkles")
        } description: {
            Text(message)
        }
    }
}

#Preview {
    CookableSuggestionsView(day: .mon)
}
