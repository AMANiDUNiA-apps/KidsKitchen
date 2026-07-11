//
//  IngredientImageMapping.swift
//  KiDSKiTCHEN
//
//  Persistierter Mapping-Store (Zutaten-Mapping 11.7.): Zutat-Name → Bild-Asset.
//  Löst lazy/on-demand auf (pro Zeile beim Erscheinen) und cacht das Ergebnis —
//  NICHT bei jedem Scroll neu rechnen. Zwei Ebenen:
//    • memo  — deterministische Treffer (IngredientMatch), rein im Speicher, billig.
//    • overrides — von der on-device-FoundationModels-Stufe verfeinerte/bestätigte
//      Treffer, auf Platte persistiert (JSON in Application Support), damit teure
//      Modell-Aufrufe Neustarts überleben.
//
//  On-device only: die FoundationModels-Stufe ruft NIE in die Cloud. Sie ist hinter
//  dem Compile-Flag `KK_FOUNDATION_MODELS_MATCH` gekapselt (siehe modelPick), weil die
//  exakte iOS-26-API in der Bau-Session nicht gegen das SDK verifiziert werden konnte
//  und der aktuelle Seed 0 unsichere Fälle hat. Ohne Flag bleibt der beste
//  deterministische Kandidat stehen — kein Regressionsrisiko für den Build.
//

import Foundation

@MainActor
@Observable
final class IngredientImageMapping {

    static let shared = IngredientImageMapping()

    /// Vom Modell bestätigte/verfeinerte Treffer (persistiert). "" = sicher kein Bild.
    var overrides: [String: String] = [:]

    /// Deterministischer Cache (nicht beobachtet, nicht persistiert). "" = kein Bild.
    @ObservationIgnored private var memo: [String: String] = [:]
    @ObservationIgnored private var inFlight: Set<String> = []

    init() { load() }

    // MARK: - Auflösen (sync, lazy)
    /// Asset-Stamm für einen Zutat-Namen oder nil (→ Kategorie-Symbol-Fallback).
    /// Reihenfolge: bestätigter Override → Memo → deterministische Match-Schicht.
    /// Unsichere Fälle liefern sofort den besten Kandidaten und stoßen im Hintergrund
    /// die FoundationModels-Verfeinerung an (Ergebnis landet in `overrides`).
    func assetKey(for name: String) -> String? {
        if let o = overrides[name] { return o.isEmpty ? nil : o }
        if let m = memo[name] { return m.isEmpty ? nil : m }

        let result = IngredientMatch.resolve(name)
        let key = result.assetKey ?? (result.tier == .uncertain ? (result.candidates.first ?? "") : "")
        memo[name] = key
        if result.tier == .uncertain {
            scheduleRefine(name: name, candidates: result.candidates)
        }
        return key.isEmpty ? nil : key
    }

    // MARK: - FoundationModels-Verfeinerung (Hintergrund, on-device)
    private func scheduleRefine(name: String, candidates: [String]) {
        guard !inFlight.contains(name), !candidates.isEmpty else { return }
        inFlight.insert(name)
        Task { [weak self] in await self?.refine(name: name, candidates: candidates) }
    }

    private func refine(name: String, candidates: [String]) async {
        defer { inFlight.remove(name) }
        guard let picked = await Self.modelPick(name: name, candidates: candidates) else { return }
        // picked == "" ist ein gültiges Ergebnis („keins passt") und wird persistiert.
        overrides[name] = picked
        persist()
    }

    /// On-device-Auswahl des besten Assets aus den Kandidaten. Ohne aktiviertes
    /// Flag ein No-op (nil = deterministischer Kandidat bleibt stehen).
    static func modelPick(name: String, candidates: [String]) async -> String? {
        #if canImport(FoundationModels) && KK_FOUNDATION_MODELS_MATCH
        if #available(iOS 26.0, *) {
            return await foundationModelPick(name: name, candidates: candidates)
        }
        #endif
        return nil
    }

    // MARK: - Persistenz (Application Support)
    private static var fileURL: URL? {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("ingredient-image-mapping.json")
    }

    private func persist() {
        guard let url = Self.fileURL else { return }
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(overrides).write(to: url, options: .atomic)
        } catch {
            // Cache ist reproduzierbar — Schreibfehler sind nicht fatal.
        }
    }

    private func load() {
        guard let url = Self.fileURL,
              let data = try? Data(contentsOf: url),
              let dict = try? JSONDecoder().decode([String: String].self, from: data)
        else { return }
        overrides = dict
    }
}

// MARK: - FoundationModels-Stufe (geflaggt)
#if canImport(FoundationModels) && KK_FOUNDATION_MODELS_MATCH
import FoundationModels

@available(iOS 26.0, *)
extension IngredientImageMapping {
    /// Wählt on-device den besten Asset-Stamm aus den Kandidaten oder "" (keiner passt).
    /// Läuft NUR bei verfügbarem Apple-Intelligence-Modell; sonst nil (Kandidat bleibt).
    static func foundationModelPick(name: String, candidates: [String]) async -> String? {
        guard SystemLanguageModel.default.availability == .available else { return nil }
        let list = candidates.joined(separator: ", ")
        let session = LanguageModelSession(instructions: """
            Du ordnest deutsche Koch-Zutaten einem Bild-Dateinamen zu. Antworte nur mit \
            genau einem Wort aus der Kandidatenliste, oder mit "keins", wenn keiner passt. \
            Keine Erklärung.
            """)
        let prompt = "Zutat: \(name). Kandidaten: \(list)."
        do {
            let answer = try await session.respond(to: prompt)
                .content.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if candidates.contains(answer) { return answer }
            if answer.contains("kein") { return "" }
            return nil
        } catch {
            return nil
        }
    }
}
#endif
