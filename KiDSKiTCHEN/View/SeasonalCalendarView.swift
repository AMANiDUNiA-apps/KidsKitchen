//
//  SeasonalCalendarView.swift
//  KiDSKiTCHEN
//
//  „Was hat gerade Saison?" — deutsches Saisonkalender-View.
//  Daten aus SeasonalCalendar.swift (statisch, kein Netz-Call).
//  Zutaten-PNGs werden wiederverwendet, wo Namen matchen (IngredientImageView).
//

import SwiftUI

struct SeasonalCalendarView: View {
    @State private var selectedMonth: KKMonth = .current
    @State private var availabilityFilter: SeasonAvailabilityFilter = .all
    @State private var kindFilter: SeasonKindFilter = .all

    private var items: [KKSeasonalItem] {
        let kinds: Set<SeasonKind>? = kindFilter.asSet
        return KKSeasonalItem.all.filter { item in
            guard item.availabilityByMonth[selectedMonth] != nil else { return false }
            if let kinds, !kinds.contains(item.kind) { return false }
            if availabilityFilter == .freshOnly,
               item.availabilityByMonth[selectedMonth] != .fresh { return false }
            if availabilityFilter == .storageOnly,
               item.availabilityByMonth[selectedMonth] != .storage { return false }
            return true
        }
        .sorted { $0.name < $1.name }
    }

    private let gridColumns = [
        GridItem(.adaptive(minimum: 100, maximum: 140), spacing: 12)
    ]

    var body: some View {
        KKScroll(spacing: 16) {
            monthStrip
            filterRow
            itemGrid
        }
        .navigationTitle("Saisonkalender")
        .kkTransparentNavBar()
    }

    // MARK: Monats-Streifen
    private var monthStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(KKMonth.allCases) { month in
                    MonthChip(
                        month: month,
                        isSelected: selectedMonth == month,
                        count: KKSeasonalItem.inSeason(month).count
                    ) {
                        withAnimation(.spring(response: 0.25)) { selectedMonth = month }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
    }

    // MARK: Filter-Zeile
    private var filterRow: some View {
        VStack(spacing: 8) {
            Picker("Verfügbarkeit", selection: $availabilityFilter) {
                ForEach(SeasonAvailabilityFilter.allCases) { f in
                    Text(f.label).tag(f)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)

            Picker("Kategorie", selection: $kindFilter) {
                ForEach(SeasonKindFilter.allCases) { f in
                    Text(f.label).tag(f)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
        }
    }

    // MARK: Artikel-Grid
    @ViewBuilder
    private var itemGrid: some View {
        if items.isEmpty {
            KKCard {
                ContentUnavailableView(
                    "Nichts in Saison",
                    systemImage: "leaf",
                    description: Text("Für \(selectedMonth.fullName) wurden keine Einträge mit diesem Filter gefunden.")
                )
            }
            .padding(.top, 40)
        } else {
            KKCard(padding: 12) {
                LazyVGrid(columns: gridColumns, spacing: 12) {
                    ForEach(items) { item in
                        SeasonItemCell(item: item, month: selectedMonth)
                    }
                }
            }
        }
    }
}

// MARK: - Hilfsenums (View-intern)

private enum SeasonAvailabilityFilter: String, CaseIterable, Identifiable {
    case all, freshOnly, storageOnly
    var id: Self { self }
    var label: String {
        switch self {
        case .all:         return "Alle"
        case .freshOnly:   return "Frisch"
        case .storageOnly: return "Lager"
        }
    }
}

private enum SeasonKindFilter: String, CaseIterable, Identifiable {
    case all, vegetable, fruit
    var id: Self { self }
    var label: String {
        switch self {
        case .all:       return "Alle"
        case .vegetable: return "Gemüse"
        case .fruit:     return "Obst"
        }
    }
    var asSet: Set<SeasonKind>? {
        switch self {
        case .all:       return nil
        case .vegetable: return [.vegetable]
        case .fruit:     return [.fruit]
        }
    }
}

// MARK: - MonthChip
private struct MonthChip: View {
    let month: KKMonth
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    @State private var settings: ThemeSettings = .shared

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(month.shortName)
                    .font(.caption.bold())
                Text("\(count)")
                    .font(.caption2)
                    .foregroundStyle(isSelected ? settings.theme.chipTextColor.opacity(0.8) : .secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected ? settings.theme.accent : Color.secondary.opacity(0.1),
                in: Capsule()
            )
            .foregroundStyle(isSelected ? settings.theme.chipTextColor : .primary)
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.06 : 1)
        .animation(.spring(response: 0.25), value: isSelected)
    }
}

// MARK: - SeasonItemCell
private struct SeasonItemCell: View {
    let item: KKSeasonalItem
    let month: KKMonth
    @State private var settings: ThemeSettings = .shared

    private var availability: SeasonAvailability? { item.availabilityByMonth[month] }

    var body: some View {
        VStack(spacing: 6) {
            // Zutaten-PNG wo vorhanden, sonst Kategorie-Symbol
            IngredientImageView(
                ingredient: Ingredient(name: item.name, category: kindToCategory(item.kind)),
                size: 56
            )
            .frame(width: 64, height: 64)

            Text(item.name)
                .font(.caption.bold())
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity)

            if let av = availability {
                Text(av.label)
                    .font(.caption2)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(
                        av == .fresh
                            ? settings.theme.accent.opacity(0.15)
                            : Color.orange.opacity(0.15),
                        in: Capsule()
                    )
                    .foregroundStyle(
                        av == .fresh ? settings.theme.accent : .orange
                    )
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }

    private func kindToCategory(_ kind: SeasonKind) -> IngredientCategory {
        switch kind {
        case .vegetable: return .vegetable
        case .fruit:     return .fruit
        }
    }
}

#Preview {
    NavigationStack { SeasonalCalendarView() }
}
