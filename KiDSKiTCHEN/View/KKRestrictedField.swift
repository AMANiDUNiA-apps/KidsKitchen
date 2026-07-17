//
//  KKRestrictedField.swift
//  KiDSKiTCHEN
//
//  Zahlen-only-Mengenfeld: lässt nur gültige Zahl-Zeichen zu (Ziffern + de_DE-Komma).
//  Robustheit gegen Einfügen/Hardware-Tastatur — die Bildschirmtastatur (decimalPad)
//  begrenzt bereits, hier kommt die harte Filterung dazu, ohne die Menge-Logik
//  (Double?) zu ändern.
//
//  RestrictedTextField portiert aus Kavsoft „RestrictedTF" (Balaji Venkatesh),
//  ~/z/Agents/Claude/xCode/kavsoft/RestrictedTF — Filter-Logik unverändert. `characters`
//  ist eine Sperr-Menge; die erlaubten Zeichen ergeben sich als deren Invertierung
//  (genau wie in der Vorlage). KKNumberField setzt darauf auf und übersetzt zwischen
//  Text (de_DE) und dem `Double?`-Wert. Fokus-Glow (Jay 17.7.): `.kkFocusBeam()`,
//  s. KKFocusBeam.swift.
//

import SwiftUI

// MARK: - RestrictedTextField (Kavsoft „RestrictedTF", unverändert)
struct RestrictedTextField<Content: View>: View {
    var hint: String
    var characters: CharacterSet
    @Binding var value: String
    @ViewBuilder var content: (TextField<Text>, String) -> Content
    @State private var errorMessage: String = ""

    var body: some View {
        content(
            TextField(hint, text: $value),
            errorMessage
        )
        .onChange(of: value) { oldValue, newValue in
            let restrictedCharacters = newValue.unicodeScalars.filter { characters.contains($0) }
            if !restrictedCharacters.isEmpty {
                value.unicodeScalars.removeAll(where: { characters.contains($0) })
                errorMessage = "\(restrictedCharacters)"
            } else {
                if !oldValue.unicodeScalars.contains(where: { characters.contains($0) }) {
                    errorMessage = ""
                }
            }
        }
    }
}

// MARK: - KKNumberField
/// Kompaktes Mengen-Textfeld über RestrictedTextField: erlaubt nur Ziffern und das
/// de_DE-Dezimalkomma und spiegelt den Wert als `Double?` (nil = leer). Ersetzt ein
/// nacktes `TextField(value:format:)`, ohne dessen Verhalten zu ändern — nur die
/// Eingabe wird auf gültige Zahl-Zeichen beschränkt.
struct KKNumberField: View {
    @Binding var value: Double?
    var hint: String = "Menge"
    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    /// Erlaubt sind Ziffern + Komma; alles andere wird herausgefiltert (Sperr-Menge
    /// = Invertierung der erlaubten Zeichen — Vorlagen-Muster).
    private let blocked = CharacterSet(charactersIn: "0123456789,").inverted

    var body: some View {
        RestrictedTextField(hint: hint, characters: blocked, value: $text) { field, _ in
            field
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .focused($isFocused)
        }
        .kkFocusBeam(isActive: isFocused, cornerRadius: 8)
        .onChange(of: text) { _, newValue in
            value = Self.parse(newValue)
        }
        .onChange(of: value) { _, newValue in
            // Nur zurückschreiben, wenn der Wert von außen kam (nicht durch Tippen) —
            // sonst würde das Reformatieren die laufende Eingabe („1," → „1") stören.
            if Self.parse(text) != newValue {
                text = Self.format(newValue)
            }
        }
        .task {
            if text.isEmpty { text = Self.format(value) }
        }
    }

    /// de_DE-Text → Zahl. „1,5" → 1.5; leer/ungültig → nil.
    private static func parse(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        return Double(trimmed.replacingOccurrences(of: ",", with: "."))
    }

    /// Zahl → de_DE-Text. nil → ""; ganze Zahl ohne Nachkomma, sonst mit Komma.
    private static func format(_ value: Double?) -> String {
        guard let value else { return "" }
        return formatter.string(from: value as NSNumber) ?? ""
    }

    private static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.numberStyle = .decimal
        f.usesGroupingSeparator = false
        f.maximumFractionDigits = 3
        return f
    }()
}
