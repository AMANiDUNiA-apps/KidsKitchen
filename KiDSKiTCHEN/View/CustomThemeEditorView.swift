//
//  CustomThemeEditorView.swift
//  KiDSKiTCHEN
//
//  Kindgerechter Editor für ein eigenes Theme (BRIEF-kk-themes-eigene-vorlagen,
//  18.7., Team-Runde v2 #5–#8). Startet von einem eingebauten Theme, passt nur
//  Hintergrund/Karten/Akzent an — Textfarbe wird automatisch kontrastsicher
//  abgeleitet (RGBAColor.contrastingTextColor), keine RGBA-Begriffe im UI.
//  Live-Vorschau mit echten App-Elementen (Karte, Knopf, Text).
//  UI-Bauweise (Jay 10.7.): eigene Container statt `List` — nur native
//  ColorPicker/TextField/Toggle als Formularsteuerelemente.
//

import SwiftUI

struct CustomThemeEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var settings: ThemeSettings = .shared

    /// nil = Neuanlage, sonst Bearbeiten eines bestehenden eigenen Themes.
    private let editingID: String?

    @State private var name: String
    @State private var isDark: Bool
    @State private var background: Color
    @State private var card: Color
    @State private var accent: Color

    @State private var showDiscardConfirm = false
    @State private var showLimitAlert = false

    private let original: Snapshot

    private struct Snapshot: Equatable {
        var name: String
        var isDark: Bool
        var background: Color
        var card: Color
        var accent: Color
    }

    init(editing: CustomTheme? = nil) {
        editingID = editing?.id
        let start = editing.map { $0.asKKTheme() } ?? .storybook
        let startName = editing?.name ?? "Mein Thema \(ThemeSettings.shared.customThemes.count + 1)"
        _name       = State(initialValue: startName)
        _isDark     = State(initialValue: start.isDark)
        _background = State(initialValue: start.backgroundColors[0])
        _card       = State(initialValue: start.cardSurface)
        _accent     = State(initialValue: start.accent)
        original = Snapshot(name: startName, isDark: start.isDark,
                             background: start.backgroundColors[0], card: start.cardSurface, accent: start.accent)
    }

    private var current: Snapshot {
        Snapshot(name: name, isDark: isDark, background: background, card: card, accent: accent)
    }

    private var hasChanges: Bool { current != original }

    /// Gleiche Bereinigung wie beim Laden (CustomTheme.sanitizedName): trimmen + kappen.
    private var trimmedName: String {
        CustomTheme.sanitizedName(name) ?? ""
    }

    var body: some View {
        KKScroll {
            if editingID == nil {
                startThemeSection
            }
            colorsSection
            nameSection
            previewSection
        }
        .navigationTitle(editingID == nil ? "Eigenes Theme" : "Theme bearbeiten")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Abbrechen") { cancelTapped() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Speichern") { save() }
                    .disabled(trimmedName.isEmpty)
            }
        }
        .alert("Änderungen verwerfen?", isPresented: $showDiscardConfirm) {
            Button("Verwerfen", role: .destructive) { dismiss() }
            Button("Weiter bearbeiten", role: .cancel) {}
        } message: {
            Text("Du hast noch nicht gespeichert.")
        }
        .alert("Schon 3 eigene Themes", isPresented: $showLimitAlert) {
            Button("Verstanden", role: .cancel) {}
        } message: {
            Text("Du hast schon 3 eigene Themes angelegt. Lösche eines, um Platz für ein neues zu machen.")
        }
    }

    // MARK: Start-Theme (nur bei Neuanlage)
    private var startThemeSection: some View {
        KKSection(title: "Starte mit …", systemImage: "wand.and.stars") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(KKTheme.all) { start in
                        Button {
                            isDark = start.isDark
                            background = start.backgroundColors[0]
                            card = start.cardSurface
                            accent = start.accent
                        } label: {
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(start.backgroundColors[0])
                                    .frame(width: 40, height: 40)
                                    .overlay(Circle().stroke(start.accent, lineWidth: 2))
                                Text(start.name)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: Farben
    private var colorsSection: some View {
        KKSection(title: "Deine Farben", systemImage: "paintpalette") {
            ColorPicker("Hintergrund", selection: $background, supportsOpacity: false)
            ColorPicker("Deine Karten", selection: $card, supportsOpacity: false)
            ColorPicker("Knöpfe & Highlights", selection: $accent, supportsOpacity: false)
            Toggle("Dunkle Karten", isOn: $isDark)
            Text("Die Textfarbe passt sich automatisch an — immer gut lesbar.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    // MARK: Name
    private var nameSection: some View {
        KKSection(title: "Name", systemImage: "textformat") {
            TextField("Name deines Themes", text: $name)
                .textInputAutocapitalization(.words)
        }
    }

    // MARK: Live-Vorschau (echte App-Elemente: Karte, Knopf, Text)
    // Nutzt exakt dieselben Kontrast-Rollen wie die App: Kartentext aus der
    // ECHTEN Kartenfarbe (cardTextColor-Rolle), Knopftext aus der Akzentfarbe.
    private var previewSection: some View {
        let buttonTextColor = RGBAColor(accent).contrastingTextColor
        let cardTextColor = RGBAColor(card).contrastingTextColor

        return VStack(alignment: .leading, spacing: 8) {
            KKSectionHeader(title: "So sieht's aus", systemImage: "eye", tint: accent)
                .padding(.horizontal, 4)

            ZStack {
                background
                VStack(alignment: .leading, spacing: 10) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(card)
                        .frame(height: 64)
                        .overlay(
                            Text("Apfel-Zimt-Porridge")
                                .font(.system(.subheadline, design: .serif))
                                .foregroundStyle(cardTextColor)
                                .padding(.horizontal, 12),
                            alignment: .leading
                        )

                    Text(trimmedName.isEmpty ? "Dein Thema" : trimmedName)
                        .font(.system(.footnote, design: .serif).bold())
                        .foregroundStyle(accent)

                    Text("Los geht's")
                        .font(.subheadline.bold())
                        .foregroundStyle(buttonTextColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(accent, in: Capsule())
                }
                .padding(14)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(.black.opacity(0.08), lineWidth: 1))
        }
    }

    // MARK: Aktionen
    private func cancelTapped() {
        if hasChanges {
            showDiscardConfirm = true
        } else {
            dismiss()
        }
    }

    private func save() {
        guard !trimmedName.isEmpty else { return }

        let theme = CustomTheme(
            id: editingID ?? "\(CustomTheme.idPrefix)\(UUID().uuidString)",
            name: trimmedName,
            isDark: isDark,
            background: RGBAColor(background).clampedOrNil ?? RGBAColor(r: 1, g: 1, b: 1),
            card: RGBAColor(card).clampedOrNil ?? RGBAColor(r: 1, g: 1, b: 1),
            accent: RGBAColor(accent).clampedOrNil ?? RGBAColor(r: 0, g: 0, b: 0)
        )

        if editingID != nil {
            settings.updateCustomTheme(theme)
            dismiss()
        } else if settings.addCustomTheme(theme) {
            dismiss()
        } else {
            showLimitAlert = true
        }
    }
}

#Preview {
    NavigationStack { CustomThemeEditorView() }
}
