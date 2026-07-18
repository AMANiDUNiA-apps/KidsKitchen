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
    // Eltern-Freigabe fürs Umschalten der Sperre (gilt nur für diese Sheet-Sitzung).
    @State private var parentGateUnlocked = false
    @State private var showParentGate = false
    @State private var parentChallenge: ParentalGateChallenge = .generate()

    // Eigene Themes: Editor-Sheet + Lösch-Rückfrage + Limit-Hinweis.
    @State private var editorTarget: EditorTarget?
    @State private var deleteTarget: CustomTheme?
    @State private var showLimitAlert = false

    private enum EditorTarget: Identifiable {
        case new
        case edit(CustomTheme)
        var id: String {
            switch self {
            case .new: "new"
            case .edit(let theme): theme.id
            }
        }
    }

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        KKScroll {
            themeGrid
            appearanceSection
            glassSection
            loopSection
            radiusSection
            transitionSection
            parentalSection
        }
        .navigationTitle("Design")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $editorTarget) { target in
            NavigationStack {
                switch target {
                case .new: CustomThemeEditorView()
                case .edit(let theme): CustomThemeEditorView(editing: theme)
                }
            }
        }
        .alert("Schon 3 eigene Themes", isPresented: $showLimitAlert) {
            Button("Verstanden", role: .cancel) {}
        } message: {
            Text("Du hast schon 3 eigene Themes angelegt. Lösche eines, um Platz für ein neues zu machen.")
        }
        .alert(
            "Theme löschen?",
            isPresented: Binding(get: { deleteTarget != nil }, set: { if !$0 { deleteTarget = nil } }),
            presenting: deleteTarget
        ) { target in
            Button("Löschen", role: .destructive) {
                settings.deleteCustomTheme(id: target.id)
                deleteTarget = nil
            }
            Button("Abbrechen", role: .cancel) { deleteTarget = nil }
        } message: { target in
            Text(settings.themeID == target.id
                 ? "„\(target.name)\" löschen? Danach verwenden wir wieder Bücherei als Farbstyle."
                 : "„\(target.name)\" löschen? Das kannst du nicht rückgängig machen.")
        }
    }

    // MARK: Theme-Grid (8 eingebaute + bis zu 3 eigene, gleichberechtigt wählbar)
    private var themeGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            KKSectionHeader(title: "Farbstyle", systemImage: "paintpalette")
                .padding(.horizontal, 4)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(KKTheme.all) { theme in
                    ThemeCard(theme: theme, isSelected: settings.themeID == theme.id) {
                        select(theme.id)
                    }
                }
                ForEach(settings.customThemes) { custom in
                    ThemeCard(
                        theme: custom.asKKTheme(),
                        isSelected: settings.themeID == custom.id,
                        isCustom: true,
                        onEdit: { editorTarget = .edit(custom) },
                        onDelete: { deleteTarget = custom }
                    ) {
                        select(custom.id)
                    }
                }
            }

            if settings.customThemes.isEmpty {
                Text("Erstelle dein erstes eigenes Küchenthema — wähle Farben, gib ihm einen Namen. Bis zu 3 eigene Themes sind möglich.")
                    .font(.caption).foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }

            Button {
                if settings.customThemes.count >= 3 {
                    showLimitAlert = true
                } else {
                    editorTarget = .new
                }
            } label: {
                Label("Eigenes Theme erstellen", systemImage: "plus.circle.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(settings.theme.accent)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
            .padding(.horizontal, 4)
        }
    }

    private func select(_ id: String) {
        withAnimation(.spring(response: 0.3)) {
            settings.themeID = id
        }
    }

    // MARK: App-Erscheinung (System/Hell/Dunkel, getrennt von den Kartenfarben)
    private var appearanceSection: some View {
        KKSection(title: "App-Erscheinung", systemImage: "circle.lefthalf.filled") {
            Picker("App außen", selection: $settings.appearanceMode) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            Text("Regelt Hell/Dunkel rundherum. Dein Farbstyle behält seine eigenen Kartenfarben.")
                .font(.caption).foregroundStyle(.secondary)
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
    // Der Schalter selbst liegt hinter der Eltern-Freigabe (Rechenaufgabe) —
    // sonst könnte das Kind die Sperre hier einfach abschalten (Terra 18.7.).
    private var parentalSection: some View {
        KKSection(title: "Eltern-Kontrolle", systemImage: "lock.shield") {
            if parentGateUnlocked {
                Toggle("Rezept-Import sperren", isOn: $prefs.kidsControlEnabled)
                    .tint(settings.theme.accent)
            } else {
                HStack {
                    Text("Rezept-Import sperren")
                    Spacer(minLength: 8)
                    Text(prefs.kidsControlEnabled ? "Aktiv" : "Aus")
                        .foregroundStyle(.secondary)
                }
                if showParentGate {
                    ParentalGateOverlay(challenge: parentChallenge, settings: settings) {
                        parentGateUnlocked = true
                    } onFailed: {
                        parentChallenge = .generate()
                    }
                } else {
                    Button("Zum Ändern Eltern-Freigabe lösen") {
                        parentChallenge = .generate()
                        showParentGate = true
                    }
                    .font(.subheadline)
                    .tint(settings.theme.accent)
                }
            }
            Text("Wenn aktiv, erscheint vor dem Rezept-Import eine Rechenaufgabe als Freigabehürde (Apple Kids-Category-Anforderung für Webzugriff).")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}

// MARK: - ThemeCard
private struct ThemeCard: View {
    let theme: KKTheme
    let isSelected: Bool
    /// Eigenes Theme statt eingebautem — zeigt Kennzeichnung + Bearbeiten/Löschen
    /// (Team-Runde v2 #8: nur DORT anbieten, nicht bei den eingebauten Themes).
    var isCustom: Bool = false
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    let action: () -> Void

    @State private var settings: ThemeSettings = .shared

    var body: some View {
        let r = settings.cardCornerRadius

        VStack(spacing: 4) {
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

            VStack(spacing: 1) {
                Text(theme.name)
                    .font(.caption.bold())
                    .foregroundStyle(.primary)
                if isCustom {
                    Text("Eigenes Theme")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 4)
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.04 : 1)
        .animation(.spring(response: 0.28), value: isSelected)

        if isCustom {
            HStack(spacing: 20) {
                Spacer()
                Button { onEdit?() } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title3)
                        .foregroundStyle(theme.accent)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(theme.name) bearbeiten")

                KKDeleteButton(accessibilityLabel: "\(theme.name) löschen") { onDelete?() }
                Spacer()
            }
            .padding(.top, 2)
        }
        }
    }
}

#Preview {
    NavigationStack { ThemeSettingsView() }
}
