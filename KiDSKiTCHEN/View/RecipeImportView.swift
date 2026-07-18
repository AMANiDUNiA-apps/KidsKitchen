//
//  RecipeImportView.swift
//  KiDSKiTCHEN
//
//  Aufgabe 2 — Rezept-Import per Apple Intelligence (FoundationModels, on-device).
//
//  🤖 SPIKE-ERGEBNIS (16.7.):
//  Die Dokumentation erwähnt Extensions NICHT explizit. Rate-Limiting deutet auf
//  App-Ebene hin (nicht Prozess), was Extensions zugänglich macht — aber der
//  Extension-Sandbox-Zugriff auf SystemLanguageModel ist ungeprüft. V1 daher
//  vollständig in der Haupt-App (URL-Eingabe → Extraktion). Share Extension kann
//  später als dünner Wrapper nachgerüstet werden, der nur die URL weitergibt.
//
//  📋 JAY: SO LEGST DU EINE SHARE EXTENSION AN (für später)
//  1. Xcode → File → New → Target → Share Extension → Name: „KidsKitchenShare"
//  2. Deployment Target: iOS 26.1 · Language: Swift
//  3. In ShareViewController.swift: NSExtensionItem aus context.inputItems holen,
//     NSItemProvider mit kUTTypeURL laden, dann App per URL-Scheme öffnen:
//     UIApplication.shared.open(URL(string: "kidskitchen://import?url=<encoded>")!)
//  4. In KiDSKiTCHENApp.swift: .onOpenURL { url in … } → RecipeImportView(importURL: url)
//  5. Info.plist der Extension: NSExtensionActivationRule = TRUEPREDICATE (zum Testen)
//     später präzisieren: Webpages / public.url
//  Dann in dieser View-Datei: var importURL: URL? hinzufügen und .task aufrufen.
//
//  Kein Scraping, keine Netz-Calls außer dem Nutzer-Link (Kids-Category-Datenschutz).
//

import FoundationModels
import SwiftUI

// MARK: - Extrahiertes Rezept (FoundationModels @Generable)
@Generable
struct ExtractedRecipe {
    @Guide(description: "Name or title of the recipe in German if possible")
    var title: String
    @Guide(description: "List of ingredient strings as they appear, e.g. '200 g Mehl'")
    var ingredientLines: [String]
    @Guide(description: "Cooking or preparation steps in order, each as a full sentence")
    var steps: [String]
    @Guide(description: "Total cooking and preparation time in minutes, 0 if not mentioned")
    var totalMinutes: Int
    @Guide(description: "Number of servings or portions, 1 if not mentioned")
    var servings: Int
}

// MARK: - ViewModel
@MainActor
@Observable
final class RecipeImportViewModel {
    enum ImportState {
        case idle
        case fetching
        case extracting
        case done(ExtractedRecipe)
        case error(String)
    }

    var urlText = ""
    var state: ImportState = .idle

    private let model = SystemLanguageModel.default

    var canImport: Bool {
        validImportURL != nil && model.availability == .available
    }

    var modelUnavailable: Bool { model.availability != .available }

    private let maxImportBytes = 1_000_000

    private var validImportURL: URL? {
        let trimmed = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host?.isEmpty == false else {
            return nil
        }
        return url
    }

    func startImport() async {
        guard let url = validImportURL else { return }
        state = .fetching
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 20
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode) else {
                state = .error("Die Seite konnte nicht geladen werden. Bitte pruefe die URL.")
                return
            }
            if http.expectedContentLength > Int64(maxImportBytes) || data.count > maxImportBytes {
                state = .error("Die Seite ist zu gross fuer den Import. Bitte nutze eine kompaktere Rezeptseite.")
                return
            }
            let raw = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) ?? ""
            guard isRecipePage(raw) else {
                state = .error("Diese Seite scheint kein Rezept zu enthalten. Bitte eine Rezept-URL einfügen.")
                return
            }
            let text = stripHTML(raw).prefix(8000).description  // Kontextfenster schonen
            state = .extracting
            let extracted = try await extract(pageText: text)
            state = .done(extracted)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    /// Einfache Heuristik: JSON-LD @type:Recipe oder mind. 3 Rezept-Schlüsselwörter.
    private func isRecipePage(_ html: String) -> Bool {
        let lower = html.lowercased()
        if lower.contains("\"@type\":\"recipe\"") || lower.contains("\"@type\": \"recipe\"") {
            return true
        }
        let keywords = ["zutaten", "ingredients", "zubereitungszeit", "preparation time",
                        "rezept", "recipe", "kochzeit", "portionen", "servings", "zubereitung"]
        return keywords.filter { lower.contains($0) }.count >= 3
    }

    private func extract(pageText: String) async throws -> ExtractedRecipe {
        let session = LanguageModelSession {
            Instructions {
                "Du bist ein Koch-Assistent. Extrahiere das Rezept aus dem Seitentext."
                "Antworte auf Deutsch. Wenn kein vollstaendiges Rezept erkennbar, schreibe Titel 'Unbekannt' und leere Listen."
                "Zutaten-Mengenangaben im Format '200 g Mehl' beibehalten."
            }
        }
        let response = try await session.respond(
            to: "Extrahiere das Rezept aus diesem Seitentext:\n\n\(pageText)",
            generating: ExtractedRecipe.self
        )
        return response.content
    }

    private func stripHTML(_ html: String) -> String {
        var result = html
        // Entferne Script und Style-Blöcke
        let scriptPattern = "<(script|style)[^>]*>[\\s\\S]*?</(script|style)>"
        if let regex = try? NSRegularExpression(pattern: scriptPattern, options: [.caseInsensitive]) {
            result = regex.stringByReplacingMatches(
                in: result, range: NSRange(result.startIndex..., in: result), withTemplate: " ")
        }
        // Entferne alle HTML-Tags
        let tagPattern = "<[^>]+>"
        if let regex = try? NSRegularExpression(pattern: tagPattern) {
            result = regex.stringByReplacingMatches(
                in: result, range: NSRange(result.startIndex..., in: result), withTemplate: " ")
        }
        // Normalisiere Leerzeichen
        return result.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

// MARK: - View
struct RecipeImportView: View {
    @State private var vm = RecipeImportViewModel()
    @State private var showSaveSheet = false
    @State private var settings: ThemeSettings = .shared
    @State private var prefs: Preferences = .shared
    @State private var gateUnlocked = false
    @State private var challenge: ParentalGateChallenge = .generate()

    var body: some View {
        KKScroll {
            if prefs.kidsControlEnabled && !gateUnlocked {
                ParentalGateOverlay(challenge: challenge, settings: settings) {
                    gateUnlocked = true
                } onFailed: {
                    challenge = .generate()
                }
            } else {
                if vm.modelUnavailable {
                    KKCard {
                        Label(
                            "Apple Intelligence ist auf diesem Gerät nicht verfügbar.",
                            systemImage: "exclamationmark.triangle"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }

                KKSection(title: "Rezept-URL einfügen", systemImage: "link") {
                    TextField("https://www.chefkoch.de/rezepte/…", text: $vm.urlText)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                statusSection
            }
        }
        // Jay 18.7.: beide Aktions-Knöpfe FEST am unteren Rand, unabhängig von der
        // Scroll-Position — vorher scrollten sie mit und landeten unter der
        // Glas-Tab-Bar (nicht klickbar). safeAreaInset stapelt sich automatisch
        // ÜBER die Tab-Bar-Zone (ContentView-Inset) und schiebt zugleich den
        // Scroll-Inhalt frei, sodass der letzte Text nicht darunter verschwindet.
        .safeAreaInset(edge: .bottom, spacing: 8) {
            if !(prefs.kidsControlEnabled && !gateUnlocked) {
                actionButtons
            }
        }
        .navigationTitle("Rezept importieren")
        .kkTransparentNavBar()
        .sheet(isPresented: $showSaveSheet) {
            if case .done(let recipe) = vm.state {
                NewRecipe(newRecipe: recipe.toRecipeDraft())
            }
        }
    }

    /// Beide Aktions-Knöpfe fest am unteren Rand (Jay 18.7.).
    /// „Als Entwurf speichern" erscheint erst mit fertigem Extrakt darüber.
    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button {
                Task { await vm.startImport() }
            } label: {
                Label("Rezept importieren", systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(settings.theme.accent)
            .disabled(!vm.canImport)

            if case .done = vm.state {
                Button {
                    showSaveSheet = true
                } label: {
                    Label("Als Entwurf speichern", systemImage: "tray.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(settings.theme.cta)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }

    @ViewBuilder
    private var statusSection: some View {
        switch vm.state {
        case .idle:
            EmptyView()

        case .fetching:
            KKCard {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Seite wird geladen …").foregroundStyle(.secondary)
                }
            }

        case .extracting:
            KKCard {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Apple Intelligence extrahiert das Rezept …").foregroundStyle(.secondary)
                }
            }

        case .done(let recipe):
            KKSection(title: recipe.title.isEmpty ? "Rezept" : recipe.title,
                      systemImage: "fork.knife") {
                if !recipe.ingredientLines.isEmpty {
                    Text("Zutaten").font(.caption.bold()).foregroundStyle(.secondary)
                    ForEach(recipe.ingredientLines, id: \.self) { line in
                        Text("• \(line)").font(.caption)
                    }
                }
                if !recipe.steps.isEmpty {
                    Divider()
                    Text("Schritte").font(.caption.bold()).foregroundStyle(.secondary)
                    ForEach(Array(recipe.steps.enumerated()), id: \.offset) { i, step in
                        Text("\(i + 1). \(step)").font(.caption)
                    }
                }
                if recipe.totalMinutes > 0 {
                    Divider()
                    Label("\(recipe.totalMinutes) min · \(recipe.servings) Port.",
                          systemImage: "clock").font(.caption).foregroundStyle(.secondary)
                }
            }

        case .error(let message):
            KKCard {
                Label("Fehler: \(message)", systemImage: "xmark.octagon")
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
    }
}

// MARK: - Mapping → Recipe-Entwurf
private extension ExtractedRecipe {
    func toRecipeDraft() -> Recipe {
        let ingredients: [RecipeIngredient] = ingredientLines.compactMap { line in
            let parts        = line.split(separator: " ", maxSplits: 2)
            // Erstes Token nur abtrennen, wenn es WIRKLICH eine Zahl ist —
            // „etwas Salz" / „½ Zitrone" bleiben sonst komplett als Name erhalten.
            let amountParsed = parts.count >= 1
                ? Double(String(parts[0]).replacingOccurrences(of: ",", with: ".")) : nil
            let amount       = amountParsed ?? 0
            // Zweites Token nur als Menge-Einheit werten, wenn es eine bekannte IngredientUnit ist
            // (z. B. "g", "Stück") — sonst gehört es zum Namen, z. B. "2 Eier" statt "2 Stück 2 Eier".
            let knownUnit = (amountParsed != nil && parts.count >= 2)
                ? IngredientUnit(rawValue: String(parts[1])) : nil
            let unit      = knownUnit ?? .piece
            let name: String
            if knownUnit != nil {
                name = parts.count >= 3 ? String(parts[2]) : ""
            } else if amountParsed != nil, parts.count >= 2 {
                name = parts[1...].joined(separator: " ")
            } else {
                name = line
            }
            return RecipeIngredient(
                ingredient: Ingredient(name: name, category: .other),
                amount: amount,
                unit: unit
            )
        }
        return Recipe(
            name:         title.isEmpty ? "Importiertes Rezept" : title,
            ingredients:  ingredients,
            instructions: steps.map { RecipeInstruction(text: $0) },
            servings:     max(1, servings),
            prepTime:     totalMinutes
        )
    }
}

// MARK: - Parental Gate (Apple Kids-Category-Anforderung)
// Freigabehürde vor dem Webzugriff: Rechenaufgabe, die nur Erwachsene sicher lösen können.
struct ParentalGateChallenge {
    let a: Int
    let b: Int
    var answer: Int { a + b }

    static func generate() -> ParentalGateChallenge {
        ParentalGateChallenge(a: Int.random(in: 23...67), b: Int.random(in: 23...67))
    }
}

// Nicht private: auch ThemeSettingsView legt das Umschalten der Eltern-Sperre
// hinter dieselbe Freigabehürde (Terra-Befund 18.7.).
struct ParentalGateOverlay: View {
    let challenge: ParentalGateChallenge
    let settings: ThemeSettings
    let onSuccess: () -> Void
    let onFailed: () -> Void

    @State private var input = ""
    @State private var showWrong = false

    var body: some View {
        KKCard {
            VStack(spacing: 16) {
                Image(systemName: "lock.shield.fill")
                    .font(.largeTitle)
                    .foregroundStyle(settings.theme.accent)

                Text("Eltern-Freigabe")
                    .font(.system(.title3, design: .serif).bold())

                Text("Löse diese Aufgabe, um fortzufahren:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Text("\(challenge.a) + \(challenge.b) = ?")
                    .font(.system(.title, design: .rounded).bold())
                    .foregroundStyle(settings.theme.accent)

                TextField("Antwort", text: $input)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.title2.bold())
                    .padding(10)
                    .background(Color.primary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: settings.cardInnerRadius))

                if showWrong {
                    Text("Falsche Antwort – neue Aufgabe.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Button {
                    if let value = Int(input.trimmingCharacters(in: .whitespaces)),
                       value == challenge.answer {
                        onSuccess()
                    } else {
                        showWrong = true
                        input = ""
                        onFailed()
                    }
                } label: {
                    Text("Entsperren")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(settings.theme.accent)
                .disabled(input.isEmpty)
            }
            .padding(.vertical, 8)
        }
    }
}

#Preview {
    NavigationStack { RecipeImportView() }
}
