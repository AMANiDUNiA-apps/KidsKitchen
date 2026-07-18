//
//  KKThemeSettingsDebugCheck.swift
//  KiDSKiTCHEN
//
//  Selbst-Check für eigene Theme-Vorlagen + App-Erscheinung
//  (BRIEF-kk-themes-eigene-vorlagen, 18.7.). Kein XCTest-Target im Projekt —
//  DEBUG-Assert-Muster wie KKWeekKeyDebugCheck.swift. Zwei Gruppen:
//  1) reine Wert-Logik (CustomThemesCodec, AppearanceMode, KKTheme.all) — kein Store.
//  2) ThemeSettings-CRUD gegen eine ISOLIERTE UserDefaults-Suite (Terra-Lehre 18.7.:
//     NIE gegen UserDefaults.standard/echte Nutzerdaten schreiben) — am Ende
//     removePersistentDomain, fasst also nie den echten `.shared`-Store an.
//

import Foundation

#if DEBUG
enum KKThemeSettingsDebugCheck {
    static func run() {
        checkBuiltInsResolvable()
        checkAppearanceModeRoundTrip()
        checkCodecRoundTrip()
        checkCodecCapsAtThree()
        checkCodecRejectsCorruptJSON()
        checkCodecRejectsBuiltInIDCollision()
        checkIDValidationAndDuplicates()
        checkNameSanitizing()
        checkThemeSettingsCRUD()
    }

    // MARK: 1) Reine Wert-Logik

    /// Alle 8 eingebauten Themes bleiben unangetastet auflösbar.
    private static func checkBuiltInsResolvable() {
        assert(KKTheme.all.count == 8, "Erwartet 8 eingebaute Themes, war \(KKTheme.all.count)")
        for builtIn in KKTheme.all {
            assert(KKTheme.byID(builtIn.id).id == builtIn.id, "byID muss \(builtIn.id) unverändert auflösen")
        }
    }

    /// AppearanceMode-Rawvalue-Rundreise + unbekannter Wert → System.
    private static func checkAppearanceModeRoundTrip() {
        for mode in AppearanceMode.allCases {
            assert(AppearanceMode(rawValue: mode.rawValue) == mode,
                   "AppearanceMode-Rundreise gebrochen für \(mode)")
        }
        assert((AppearanceMode(rawValue: "bogus") ?? .system) == .system,
               "Unbekannter AppearanceMode-Rohwert muss auf .system fallen")
    }

    /// Persistenz-Rundreise: encode → decode liefert dasselbe Theme.
    private static func checkCodecRoundTrip() {
        let theme = makeTheme(id: "custom-\(UUID().uuidString)", name: "Testthema")
        guard let data = CustomThemesCodec.encode([theme]) else {
            assertionFailure("Encode darf nicht fehlschlagen"); return
        }
        let decoded = CustomThemesCodec.decode(data)
        assert(decoded.count == 1 && decoded.first?.id == theme.id, "Round-trip muss dasselbe Theme liefern")
    }

    /// 3er-Limit fachlich: ein 4. Eintrag im (z. B. manipulierten) JSON wird beim
    /// Laden gekappt, nicht nur im UI verhindert.
    private static func checkCodecCapsAtThree() {
        let themes = (1...4).map { makeTheme(id: "custom-\(UUID().uuidString)", name: "T\($0)") }
        guard let data = CustomThemesCodec.encode(themes) else {
            assertionFailure("Encode darf nicht fehlschlagen"); return
        }
        assert(CustomThemesCodec.decode(data).count == 3, "Mehr als 3 gültige Einträge im JSON müssen gekappt werden")
    }

    /// Beschädigtes JSON → leere Liste, kein Crash (ThemeSettings fällt danach auf storybook).
    private static func checkCodecRejectsCorruptJSON() {
        let garbage = Data("nicht-json{{{".utf8)
        assert(CustomThemesCodec.decode(garbage).isEmpty, "Kaputtes JSON muss zu leerer Liste führen")
    }

    /// ID-Kollision mit einem eingebauten Theme wird beim Laden verworfen.
    private static func checkCodecRejectsBuiltInIDCollision() {
        let collider = makeTheme(id: "storybook", name: "Böser Zwilling")
        guard let data = CustomThemesCodec.encode([collider]) else {
            assertionFailure("Encode darf nicht fehlschlagen"); return
        }
        assert(CustomThemesCodec.decode(data).isEmpty, "Custom-Theme mit eingebauter ID muss verworfen werden")
    }

    /// ID-Validierung (Terra #1): nur exakt custom-<UUID>; Duplikate werden
    /// beim Decode verworfen (erster gewinnt).
    private static func checkIDValidationAndDuplicates() {
        assert(!makeTheme(id: "custom-1", name: "T").hasValidID,
               "custom-1 (kein UUID-Suffix) muss ungültig sein")
        assert(makeTheme(id: "custom-\(UUID().uuidString)", name: "T").hasValidID,
               "custom-<UUID> muss gültig sein")

        let dupID = "custom-\(UUID().uuidString)"
        let dupes = [makeTheme(id: dupID, name: "Erster"), makeTheme(id: dupID, name: "Zweiter")]
        guard let data = CustomThemesCodec.encode(dupes) else {
            assertionFailure("Encode darf nicht fehlschlagen"); return
        }
        let decoded = CustomThemesCodec.decode(data)
        assert(decoded.count == 1 && decoded.first?.name == "Erster",
               "ID-Duplikate müssen beim Decode verworfen werden (erster gewinnt)")
    }

    /// Namens-Bereinigung beim Decode (Terra #4): leer/Whitespace verworfen,
    /// Überlänge gekappt.
    private static func checkNameSanitizing() {
        let blank = makeTheme(id: "custom-\(UUID().uuidString)", name: "   \n ")
        let long = makeTheme(id: "custom-\(UUID().uuidString)",
                             name: String(repeating: "A", count: 80))
        guard let data = CustomThemesCodec.encode([blank, long]) else {
            assertionFailure("Encode darf nicht fehlschlagen"); return
        }
        let decoded = CustomThemesCodec.decode(data)
        assert(decoded.count == 1, "Whitespace-Name muss verworfen werden")
        assert(decoded.first?.name.count == CustomTheme.maxNameLength,
               "Überlanger Name muss auf \(CustomTheme.maxNameLength) Zeichen gekappt werden")
    }

    // MARK: 2) ThemeSettings-CRUD (isolierte Suite)

    /// Auflösung + Lösch-Fallback + 3er-Limit gegen eine isolierte ThemeRepository-
    /// Instanz — NIE gegen ThemeSettings.shared / UserDefaults.standard.
    private static func checkThemeSettingsCRUD() {
        let suiteName = "kk.debug.themeSettings.selfcheck"
        guard let isolated = UserDefaults(suiteName: suiteName) else {
            assertionFailure("Isolierte UserDefaults-Suite konnte nicht erzeugt werden"); return
        }
        isolated.removePersistentDomain(forName: suiteName)
        defer { isolated.removePersistentDomain(forName: suiteName) }

        let repo = ThemeRepository(defaults: isolated)
        let settings = ThemeSettings(repo: repo)

        // Invariante: liefert immer ein gültiges Theme, auch ohne eigene Themes.
        assert(settings.theme.id == "storybook", "Frischer Store muss auf storybook stehen")

        let custom = makeTheme(id: "custom-\(UUID().uuidString)", name: "Mein Thema", isDark: true)
        assert(settings.addCustomTheme(custom), "Erstes eigenes Theme muss angelegt werden können")
        settings.themeID = custom.id
        assert(settings.theme.id == custom.id, "Eigenes Theme muss über themeID auflösbar sein")
        assert(settings.theme.isDark, "isDark muss vom eigenen Theme übernommen werden")

        // CRUD lehnt ungültige und doppelte IDs ab (Terra #1).
        assert(settings.addCustomTheme(makeTheme(id: "custom-1", name: "Ungültig")) == false,
               "addCustomTheme muss custom-1 (kein UUID-Suffix) ablehnen")
        assert(settings.addCustomTheme(custom) == false,
               "addCustomTheme muss ID-Duplikate ablehnen")

        // 3er-Limit fachlich durchgesetzt (nicht nur im UI-Knopf).
        _ = settings.addCustomTheme(makeTheme(id: "custom-\(UUID().uuidString)", name: "F1"))
        _ = settings.addCustomTheme(makeTheme(id: "custom-\(UUID().uuidString)", name: "F2"))
        assert(settings.customThemes.count == 3, "Nach 3 Anlagen müssen genau 3 eigene Themes bestehen")
        assert(settings.addCustomTheme(makeTheme(id: "custom-\(UUID().uuidString)", name: "F3")) == false,
               "4. eigenes Theme darf nicht angelegt werden")
        assert(settings.customThemes.count == 3, "Limit darf nicht überschritten werden")

        // Löschen des AKTIVEN Themes: themeID fällt auf storybook zurück UND wird
        // persistiert, danach erst das Theme entfernt (Team-Runde v2 #3).
        settings.deleteCustomTheme(id: custom.id)
        assert(settings.themeID == "storybook", "Aktives eigenes Theme löschen muss themeID auf storybook setzen")
        assert(settings.theme.id == "storybook", "Nach Löschen muss ein gültiges Theme (storybook) aufgelöst werden")
        assert(repo.themeID == "storybook", "Fallback muss persistiert sein, nicht nur im Speicher")
        assert(!settings.customThemes.contains { $0.id == custom.id }, "Gelöschtes Theme darf nicht mehr in der Liste stehen")
        assert(!CustomThemesCodec.decode(repo.customThemesData).contains { $0.id == custom.id },
               "Gelöschtes Theme darf auch in der persistierten Payload nicht mehr stehen")

        // Verwaiste themeID (z. B. aus einem alten Stand) → Auflösung fällt auf
        // storybook statt zu crashen (Risiko „byID-Fallback" aus dem Brief).
        settings.themeID = "custom-does-not-exist"
        assert(settings.theme.id == "storybook", "Unauflösbare custom-ID muss auf storybook fallen")
    }

    private static func makeTheme(id: String, name: String, isDark: Bool = false) -> CustomTheme {
        CustomTheme(
            id: id, name: name, isDark: isDark,
            background: RGBAColor(r: 0.5, g: 0.5, b: 0.5),
            card: RGBAColor(r: 0.9, g: 0.9, b: 0.9),
            accent: RGBAColor(r: 0.1, g: 0.1, b: 0.1)
        )
    }
}
#endif
