//
//  PantryView.swift
//  KiDSKiTCHEN
//
//  Created by Claude Fable 5 on 03.07.26.
//  Vorratsschrank: was habe ich zu Hause? Grundlage für „Was kann ich kochen?"
//  (Home-Filter) und für die Einkaufsliste (nur Fehlendes).
//
//  Weiterbau 4, Teil E — direkt vom `List` auf ein Kachelraster umgestellt (kein
//  Zwischenschritt): Zutaten als Kacheln in einem Magazin-Raster mit wechselnden
//  Größen. Vorlage: Kavsoft „CompositionalGridLayout" (Balaji Venkatesh),
//  s. KKCompositionalGrid. Kacheln sind bildbereit — die freigestellten
//  PNG-mit-Alpha-Bilder aus der macMini-Pipeline füllen später den Symbol-Slot
//  1:1, ohne Layout-Änderung.
//

import SwiftUI

struct PantryView: View {
    @State private var prefs: Preferences = .shared
    @State private var settings: ThemeSettings = .shared
    @State private var search = ""
    /// Aktive Kategorie-Filter (leer = alles zeigen). Mehrfachauswahl.
    @State private var selectedCategories: [IngredientCategory] = []
    /// Zutat, für die gerade die Menge bearbeitet wird (Mengen-Sheet, Einfach-Tap).
    @State private var amountTarget: Ingredient?
    /// Zutat, deren Groß-Bild-/Detailansicht offen ist (Doppel-Tap).
    @State private var detailTarget: Ingredient?
    /// Quell-Namespace für die Zoom-Überblendung Kachel → Groß-Bild.
    @Namespace private var zoomNS
    /// Koch-Vorschläge aus dem Vorrat anzeigen (Teil C).
    @State private var showCookable = false
    /// Gewähltes Ansicht-Layout (persistiert — Jays Wahl bleibt über App-Starts).
    @AppStorage("pantryLayout") private var layoutRaw = PantryLayout.grid.rawValue
    private var layout: PantryLayout { PantryLayout(rawValue: layoutRaw) ?? .grid }
    // Rückgängig/Wiederholen fürs Entfernen aus dem Vorrat (Jay 17.7.).
    @Environment(\.undoManager) private var undoManager

    // Klick-Verhalten der Kacheln (vereinheitlicht, Jay 12.7.):
    // 1× Tap → direkt die Mengen-Scala · 2× Tap → Groß-Bild mit Scala + Details.
    // Beide Wege gelten für ALLE vier Layouts gleich. Hinzufügen läuft jetzt über
    // die Scala („Sichern" legt implizit in den Vorrat), nicht mehr über 1× Tap.
    private func openAmount(_ ingredient: Ingredient) { amountTarget = ingredient }
    private func openDetail(_ ingredient: Ingredient) { detailTarget = ingredient }

    private var sections: [(category: IngredientCategory, items: [Ingredient])] {
        IngredientCategory.allCases.compactMap { category in
            let items = Ingredient.seed
                .filter { $0.category == category }
                .filter { search.isEmpty || $0.name.localizedStandardContains(search) }
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            return items.isEmpty ? nil : (category, items)
        }
    }

    /// Kategorien, die bei der aktuellen Suche tatsächlich vorkommen (echte Chips).
    private var presentCategories: [IngredientCategory] { sections.map(\.category) }

    /// Nach aktivem Kategorie-Filter eingeschränkte Abschnitte.
    private var visibleSections: [(category: IngredientCategory, items: [Ingredient])] {
        guard !selectedCategories.isEmpty else { return sections }
        return sections.filter { selectedCategories.contains($0.category) }
    }

    var body: some View {
        KKScroll {
            if !prefs.pantry.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text("\(prefs.pantry.count) im Vorrat")
                        .font(.subheadline.weight(.medium))
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 4)

                // Einstieg „Was kann ich kochen?" (Teil C) — Vorschläge aus dem Vorrat.
                Button {
                    showCookable = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles").font(.title3).foregroundStyle(settings.theme.accent)
                        Text("Was kann ich kochen?")
                            .font(.system(.subheadline, design: .serif).weight(.semibold))
                            .foregroundStyle(.primary)
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.right")
                            .font(.footnote.bold()).foregroundStyle(settings.theme.accent)
                    }
                    .padding(14)
                    .background(settings.theme.accent.opacity(0.10),
                                in: RoundedRectangle(cornerRadius: settings.cardCornerRadius))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 4)
                .accessibilityHint("Zeigt Rezepte, die zu deinem Vorrat passen")
            }

            // Kategorie-Filter — nur zeigen, wenn es mehr als eine Kategorie gibt.
            if presentCategories.count > 1 {
                CategoryFilterChips(categories: presentCategories) { selection in
                    selectedCategories = selection
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 4)
            }

            ForEach(visibleSections, id: \.category) { section in
                VStack(alignment: .leading, spacing: 8) {
                    KKSectionHeader(title: section.category.title,
                                    systemImage: section.category.symbolName,
                                    tint: section.category.color)
                        .padding(.horizontal, 4)

                    sectionItems(section.items)
                }
            }
        }
        .navigationTitle("Vorratsschrank")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                // „Ansicht ändern" — schaltet reihum durch die Layouts (Jay testet
                // am Gerät, welche Variante gewinnt). Aktuelles Layout im Label.
                Button {
                    withAnimation(.snappy) { layoutRaw = layout.next.rawValue }
                } label: {
                    Label(layout.title, systemImage: layout.symbol)
                        .labelStyle(.titleAndIcon)
                        .font(.footnote.weight(.semibold))
                }
                .accessibilityLabel("Ansicht ändern, aktuell \(layout.title)")
                .accessibilityHint("Schaltet zur nächsten Ansicht der Zutaten")
            }
            ToolbarItem(placement: .topBarTrailing) {
                KKUndoRedoButton(undoManager: undoManager)
            }
        }
        .searchable(text: $search, prompt: "Zutat suchen")
        .sheet(item: $amountTarget) { ingredient in
            PantryAmountSheet(ingredient: ingredient, prefs: prefs)
                .presentationDetents([.medium])
        }
        .fullScreenCover(item: $detailTarget) { ingredient in
            PantryDetailView(ingredient: ingredient, prefs: prefs, namespace: zoomNS)
        }
        .sheet(isPresented: $showCookable) {
            CookableSuggestionsView()
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Layout-abhängige Zutaten-Darstellung
    /// Wrapper: wendet die gewählte Übergangs-Animation an wenn das Layout wechselt.
    private func sectionItems(_ items: [Ingredient]) -> some View {
        sectionContent(items)
            .id(layout)
            .transition(settings.pantryTransition.transition)
            .animation(settings.pantryTransition.animation, value: layout)
    }

    @ViewBuilder
    private func sectionContent(_ items: [Ingredient]) -> some View {
        switch layout {
        case .grid:
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(items) { ingredient in
                    let inStock = prefs.pantry.contains(ingredient.name)
                    PantryTile(ingredient: ingredient, inStock: inStock,
                               amount: prefs.pantryAmount(ingredient.name),
                               onSingle: { openAmount(ingredient) },
                               onDouble: { openDetail(ingredient) })
                    .matchedTransitionSource(id: ingredient.id, in: zoomNS)
                    .frame(height: 150)
                }
            }

        case .cards:
            VStack(spacing: 12) {
                ForEach(items) { ingredient in
                    let inStock = prefs.pantry.contains(ingredient.name)
                    PantryBigCard(ingredient: ingredient, inStock: inStock,
                                  amount: prefs.pantryAmount(ingredient.name),
                                  onSingle: { openAmount(ingredient) },
                                  onDouble: { openDetail(ingredient) })
                    .matchedTransitionSource(id: ingredient.id, in: zoomNS)
                }
            }

        case .list:
            VStack(spacing: 4) {
                ForEach(items) { ingredient in
                    let inStock = prefs.pantry.contains(ingredient.name)
                    PantryListRow(ingredient: ingredient, inStock: inStock,
                                  amount: prefs.pantryAmount(ingredient.name),
                                  onSingle: { openAmount(ingredient) },
                                  onDouble: { openDetail(ingredient) })
                    .matchedTransitionSource(id: ingredient.id, in: zoomNS)
                }
            }

        case .gallery:
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(items) { ingredient in
                        let inStock = prefs.pantry.contains(ingredient.name)
                        PantryTile(ingredient: ingredient, inStock: inStock,
                                   amount: prefs.pantryAmount(ingredient.name),
                                   onSingle: { openAmount(ingredient) },
                                   onDouble: { openDetail(ingredient) })
                        .matchedTransitionSource(id: ingredient.id, in: zoomNS)
                        .frame(width: 140, height: 150)
                    }
                }
                .padding(.horizontal, 4)
            }
            // Galerie darf über den Seitenrand scrollen — Rand-Padding aufheben.
            .padding(.horizontal, -4)
        }
    }
}

// MARK: - PantryTile
/// Bildbereite Zutaten-Kachel. Der Symbol-Slot in der Mitte wird später vom
/// freigestellten PNG-mit-Alpha ersetzt (macMini-Pipeline) — Rahmen/Abstände
/// bleiben gleich. Tippen schaltet „im Vorrat" um (sichtbarer grüner Haken).
private struct PantryTile: View {
    let ingredient: Ingredient
    let inStock: Bool
    let amount: Int?
    let onSingle: () -> Void
    let onDouble: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var settings: ThemeSettings = .shared

    var body: some View {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 8) {
                    // Bild-Slot: fotorealistisches Zutat-PNG (Alpha), Fallback = Kategorie-Symbol.
                    IngredientImageView(ingredient: ingredient, size: 56)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    Text(ingredient.name)
                        .font(.system(.subheadline, design: .serif).weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    // Gesetzte Menge (nur wenn hinterlegt) — echte Einheit der Zutat
                    if let amount {
                        Text(ingredient.unit.formattedAmount(amount))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(ingredient.category.color)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    inStock ? ingredient.category.color.opacity(0.18)
                            : settings.theme.cardSurface,
                    in: RoundedRectangle(cornerRadius: settings.cardCornerRadius)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: settings.cardCornerRadius)
                        .strokeBorder(
                            inStock ? ingredient.category.color : settings.theme.cardStroke,
                            lineWidth: inStock ? 2 : 1
                        )
                }

                // Immer vorhanden, nur ein-/ausgeblendet — so löst der Wechsel
                // inStock=true den Symbol-Bounce zuverlässig aus (Teil D, „NewSymbolEffect").
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
                    .padding(8)
                    .opacity(inStock ? 1 : 0)
                    .scaleEffect(inStock ? 1 : 0.5)
                    .symbolEffect(.bounce, value: reduceMotion ? false : inStock)
                    .animation(.spring(response: 0.3), value: inStock)
            }
            .pantryTapGestures(onSingle: onSingle, onDouble: onDouble)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(ingredient.name)
            .accessibilityValue(pantryValueDescription)
            .accessibilityHint("Einmal tippen für die Menge, zweimal für die Details")
    }

    private var pantryValueDescription: String {
        guard inStock else { return "nicht im Vorrat" }
        if let amount { return "im Vorrat, \(amount) \(ingredient.unit.title)" }
        return "im Vorrat"
    }
}

// MARK: - Kachel-Gesten (vereinheitlicht)
extension View {
    /// 1× Tap → Menge · 2× Tap → Detail. Der Doppel-Tap MUSS vor dem Einfach-Tap
    /// stehen, sonst frisst der Einfach-Tap alles (SwiftUI-Gotcha). Eine kleine
    /// systembedingte Auslöse-Verzögerung beim Einfach-Tap ist akzeptiert.
    func pantryTapGestures(onSingle: @escaping () -> Void,
                           onDouble: @escaping () -> Void) -> some View {
        contentShape(Rectangle())
            .onTapGesture(count: 2, perform: onDouble)
            .onTapGesture(count: 1, perform: onSingle)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(named: "Details anzeigen", onDouble)
    }
}

// MARK: - PantryAmountControls
/// Wiederverwendbare Mengen-Scala: Wert-Anzeige + analoger Strich-Picker
/// (Kavsoft `TickPicker`) + Buttons „Aus dem Vorrat"/„Sichern". Schreibt echte
/// Werte in der KANONISCHEN Einheit der Zutat (g/ml/Stück …) — keine Umrechnung.
/// Genutzt im Mengen-Sheet (Einfach-Tap) UND in der Detailansicht (Doppel-Tap).
struct PantryAmountControls: View {
    let ingredient: Ingredient
    @Bindable var prefs: Preferences
    /// Nach „Sichern"/„Aus dem Vorrat" aufgerufen (Sheet/Cover schließen).
    var onFinish: () -> Void = {}
    // Rückgängig fürs Entfernen aus dem Vorrat (Jay 17.7., „essentiell").
    @Environment(\.undoManager) private var undoManager

    private var unit: IngredientUnit { ingredient.unit }
    private var step: Int { unit.pantryStep }
    private var maxTicks: Int { unit.pantryMaxValue / unit.pantryStep }

    @State private var tick: Int = 0
    private var value: Int { tick * step }

    var body: some View {
        VStack(spacing: 20) {
            Text(unit.formattedAmount(value))
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
                .animation(.snappy, value: value)

            TickPicker(
                count: maxTicks,
                config: TickConfig(activeTint: ingredient.category.color),
                selection: $tick
            )

            HStack(spacing: 12) {
                // „Aus dem Vorrat" nur, wenn die Zutat wirklich im Vorrat ist —
                // sonst würde togglePantry sie versehentlich HINZUFÜGEN.
                if prefs.hasInPantry(ingredient.name) {
                    Button(role: .destructive) {
                        let previousAmount = prefs.pantryAmount(ingredient.name)
                        prefs.togglePantry(ingredient.name)
                        registerPantryRestoreUndo(previousAmount: previousAmount)
                        onFinish()
                    } label: {
                        Label("Aus dem Vorrat", systemImage: "xmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                Button {
                    prefs.setPantryAmount(value, for: ingredient.name)
                    onFinish()
                } label: {
                    Label("Sichern", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .task {
            // Auf gespeicherten Wert vorpositionieren (auf Einheiten-Raster gerundet)
            let saved = prefs.pantryAmount(ingredient.name) ?? 0
            tick = min(max(Int((Double(saved) / Double(step)).rounded()), 0), maxTicks)
        }
    }

    // MARK: Rückgängig/Wiederholen fürs Entfernen aus dem Vorrat
    // Symmetrisch registriert (Kavsoft „UndoHelper"-Prinzip): jede Rückgängig-
    // Aktion registriert beim Ausführen gleich wieder ihr Gegenstück, sonst
    // würde Wiederholen (Redo) nach einem Undo nicht mehr funktionieren.
    private func registerPantryRestoreUndo(previousAmount: Int?) {
        undoManager?.registerUndo(withTarget: prefs) { target in
            if let previousAmount, previousAmount > 0 {
                target.setPantryAmount(previousAmount, for: ingredient.name)
            } else {
                target.togglePantry(ingredient.name)
            }
            registerPantryRemoveUndo()
        }
        undoManager?.setActionName("Aus dem Vorrat entfernen")
    }

    private func registerPantryRemoveUndo() {
        undoManager?.registerUndo(withTarget: prefs) { target in
            let previousAmount = target.pantryAmount(ingredient.name)
            target.togglePantry(ingredient.name)
            registerPantryRestoreUndo(previousAmount: previousAmount)
        }
    }
}

// MARK: - PantryAmountSheet (Einfach-Tap)
/// Kompaktes Sheet mit der Mengen-Scala — Bild, Name, Scala.
private struct PantryAmountSheet: View {
    let ingredient: Ingredient
    @Bindable var prefs: Preferences
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 6) {
                IngredientImageView(ingredient: ingredient, size: 64)
                Text(ingredient.name)
                    .font(.system(.title2, design: .serif).weight(.semibold))
            }
            .padding(.top, 24)

            PantryAmountControls(ingredient: ingredient, prefs: prefs) { dismiss() }
                .padding(.horizontal)

            Spacer(minLength: 0)
        }
        .fontDesign(.serif)
    }
}

// MARK: - PantryDetailView (Doppel-Tap)
/// Groß-Bild-Animation der Zutat mit integrierter Mengen-Scala UND weiteren
/// Details (Kategorie/Badge + Nährwerte aus der IngredientDetailView-Schicht).
/// Öffnet als Zoom-Überblendung aus der angetippten Kachel (`namespace`).
private struct PantryDetailView: View {
    let ingredient: Ingredient
    @Bindable var prefs: Preferences
    let namespace: Namespace.ID
    @Environment(\.dismiss) private var dismiss
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            KKScroll {
                // Groß-Bild + Kopf (Kategorie/Badge)
                KKCard {
                    VStack(spacing: 12) {
                        IngredientImageView(ingredient: ingredient, size: 200)
                            .scaleEffect(appeared ? 1 : 0.6)
                            .animation(.spring(response: 0.5, dampingFraction: 0.75), value: appeared)
                            // Zum Vergrößern tippen (Jay 17.7.), s. KKZoomableImage.swift.
                            .kkZoomable()

                        Text(ingredient.name)
                            .font(.system(.largeTitle, design: .serif).weight(.bold))
                            .multilineTextAlignment(.center)

                        HStack(spacing: 6) {
                            Text(ingredient.category.title)
                                .foregroundStyle(ingredient.category.color)
                            if let badge = dietBadge {
                                Text(badge)
                                    .padding(.horizontal, 8).padding(.vertical, 2)
                                    .background(.green.opacity(0.15), in: Capsule())
                                    .foregroundStyle(.green)
                            }
                        }
                        .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity)
                }

                // Integrierte Mengen-Scala (gleiche Bedienung wie im Sheet)
                KKSection(title: "Menge", systemImage: "ruler", tint: ingredient.category.color) {
                    PantryAmountControls(ingredient: ingredient, prefs: prefs) { dismiss() }
                }

                // Weitere Details: Nährwerte + „Gut zu wissen"
                IngredientFactsSections(ingredient: ingredient)
            }
            .navigationTitle(ingredient.name)
            .navigationBarTitleDisplayMode(.inline)
            .fontDesign(.serif)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Schließen")
                }
            }
        }
        .navigationTransition(.zoom(sourceID: ingredient.id, in: namespace))
        .onAppear { appeared = true }
    }

    private var dietBadge: String? {
        switch ingredient.category {
        case .fruit, .vegetable, .cereals, .nuts, .herbs, .spices: "Vegan"
        case .dairy: "Vegetarisch"
        default: nil
        }
    }
}

#Preview {
    NavigationStack { PantryView() }
}
