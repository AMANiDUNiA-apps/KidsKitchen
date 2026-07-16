//
//  NutrientExplainer.swift
//  KiDSKiTCHEN
//
//  Statische Erklär-Texte je Nährstoff in drei Ebenen (Kids / Eltern / Wissenschaft).
//  Quelle: ChatGPT-Export Gespräch 37 + 43 (docs/material/01-naehrstoff-texte.md).
//  Keine Netz-Calls (Kids-Category-Datenschutz). Lücken bei Mineralstoffen/
//  Fettsäuren-Untertypen / Aminosäuren: als offen an Jay gemeldet.
//

import Foundation

// MARK: - NutritionMode
enum NutritionMode: String, CaseIterable, Identifiable {
    case kids        = "Kinder"
    case adults      = "Eltern"
    case scientific  = "Profi"
    var id: Self { self }
}

// MARK: - NutrientEntry
struct NutrientEntry {
    let kids: String
    let adults: String
    let scientific: String

    func text(for mode: NutritionMode) -> String {
        switch mode {
        case .kids:       return kids
        case .adults:     return adults
        case .scientific: return scientific
        }
    }
}

// MARK: - NutrientExplainer
/// Statisches Nachschlagewerk: NutritionFacts-Feldname → Erklär-Text.
/// Schlüssel entsprechen den Eigenschaften in NutritionFacts.swift.
enum NutrientExplainer {

    static let entries: [String: NutrientEntry] = [

        "kcal": NutrientEntry(
            kids: "Kalorien sind Energie für deinen Körper — wie Benzin für ein Auto! Davon brauchst du jeden Tag, damit du spielen, denken und wachsen kannst.",
            adults: "Kalorien beschreiben den Energiegehalt eines Lebensmittels. Der Körper nutzt sie für Grundumsatz (Atmung, Herzschlag), Wachstum und Aktivität. Ein Überschuss wird als Fett gespeichert.",
            scientific: "Kilokalorienangaben (kcal) messen den physiologischen Brennwert nach dem Atwater-System. Protein und Kohlenhydrate liefern je 4 kcal/g, Fett 9 kcal/g. Differenz zum physikalischen Brennwert entsteht durch unverdauliche Anteile."
        ),

        "protein": NutrientEntry(
            kids: "Eiweiß baut Muskeln, Haut, Haare und Nägel — es ist der LEGO-Baustein deines Körpers! Ei, Fleisch und Bohnen haben viel davon.",
            adults: "Proteine bestehen aus Aminosäuren und dienen als Enzyme, Hormone und Strukturproteine. Essenzielle Aminosäuren (Leucin, Isoleucin, Valin …) müssen über die Nahrung zugeführt werden.",
            scientific: "Proteine sind Polymere aus bis zu 20 Aminosäuren, verknüpft durch Peptidbindungen. Essenziell: Histidin, Isoleucin, Leucin, Lysin, Methionin, Phenylalanin, Threonin, Tryptophan, Valin. Biologische Wertigkeit gibt an, wie effizient das Nahrungsprotein in körpereigenes Protein umgewandelt wird."
        ),

        "fat": NutrientEntry(
            kids: "Fett hält dich warm, schützt deine Organe und hilft, bestimmte Vitamine aufzunehmen — wie eine Winterjacke für deinen Körper! Öl, Nüsse und Butter haben viel davon.",
            adults: "Fette liefern essenzielle Fettsäuren, ermöglichen die Aufnahme fettlöslicher Vitamine (A, D, E, K) und sind strukturelle Bestandteile von Zellmembranen und Hormonen.",
            scientific: "Lipide umfassen Triglyceride, Phospholipide und Sterole. Triglyceride (3 Fettsäuren + Glycerin) sind die Hauptspeicherform. Fettsäuren unterscheiden sich durch Kettenlänge und Sättigungsgrad; die Konfiguration (cis/trans) beeinflusst biologische Aktivität wesentlich."
        ),

        "carbs": NutrientEntry(
            kids: "Kohlenhydrate laden deinen Körper-Akku schnell auf — so wie Strom für ein Handy! Brot, Nudeln, Reis und Obst stecken voller Kohlenhydrate.",
            adults: "Kohlenhydrate werden zu Glukose verstoffwechselt, dem primären Energieträger für Gehirn und Muskulatur. Komplexe Kohlenhydrate (Stärke, Ballaststoffe) stabilisieren den Blutzucker; einfache führen zu schnellen Anstiegen.",
            scientific: "Kohlenhydrate (Mono-, Di- und Polysaccharide) werden durch Amylasen und intestinale Glukosidasen hydrolysiert. Glukose wird via GLUT-Transporter absorbiert. Der glykämische Index beschreibt die Blutzuckerantwort im Verhältnis zu Referenzglukose."
        ),

        "sugar": NutrientEntry(
            kids: "Zucker gibt dir sehr schnell Energie — aber auch wieder weg. Zu viel Zucker schadet den Zähnen! Obst hat natürlichen Zucker, Süßigkeiten haben sehr viel davon.",
            adults: "Zucker sind einfache Kohlenhydrate (Monosaccharide wie Glukose/Fruktose, Disaccharide wie Saccharose). Hoher Konsum erhöht das Risiko für Karies, Übergewicht und Insulinresistenz.",
            scientific: "Freie Zucker nach WHO-Definition umfassen Mono- und Disaccharide, die Nahrungsmitteln zugesetzt wurden, plus natürliche Zucker in Honig, Sirup und Fruchtsäften. Fruktose wird hepatisch ohne Insulinstimulation metabolisiert und kann bei Exzess die De-novo-Lipogenese steigern."
        ),

        "fiber": NutrientEntry(
            kids: "Ballaststoffe sind wie ein Besen in deinem Bauch — sie helfen, dass alles gut läuft! Vollkornbrot, Äpfel und Gemüse haben viel davon.",
            adults: "Ballaststoffe sind unverdauliche Kohlenhydrate. Sie fördern die Darmbewegung, unterstützen die Darmflora, senken Cholesterin und regulieren den Blutzucker. Die DGE empfiehlt ≥30 g/Tag.",
            scientific: "Nahrungsfasern (Cellulose, Hemicellulose, Pektin, Inulin, resistente Stärke) werden im Kolon von Mikrobiota fermentiert. Kurzkettige Fettsäuren (Butyrat, Propionat, Acetat) entstehen dabei und stärken die Kolonozyten-Funktion. Wasserunlösliche Fasern fördern vorwiegend Motilität, wasserlösliche den Cholesterin- und Glukosestoffwechsel."
        ),

        "sodium": NutrientEntry(
            kids: "Natrium (Salz) hilft deinen Nerven, Signale zu senden — wie ein Stromkabel! Aber zu viel Salz ist nicht gut für das Herz.",
            adults: "Natrium reguliert den Flüssigkeitshaushalt, Nervenimpulse und den Blutdruck. Zu hohe Zufuhr erhöht das Risiko für Bluthochdruck. Die DGE empfiehlt <6 g Kochsalz pro Tag.",
            scientific: "Na⁺ ist das wichtigste extrazelluläre Kation (138–142 mmol/l). Na⁺/K⁺-ATPase hält das Membranpotenzial aufrecht. Chronisch erhöhte Natriumzufuhr hemmt Renin-Angiotensin-Aldosteron-System nicht ausreichend, was zu persistierender Hypertonie führt."
        ),

        "calcium": NutrientEntry(
            kids: "Calcium macht Knochen und Zähne stark — wie Zement beim Hausbau! Milch, Joghurt und Käse enthalten besonders viel davon.",
            adults: "Calcium ist entscheidend für Knochenmineralisierung, Muskelkontraktion und Blutgerinnung. Vitamin D verbessert die Aufnahme. Empfehlung: 1000 mg/Tag (Erwachsene), 1200 mg/Tag (>65 Jahre).",
            scientific: "99 % des Körpercalciums sind als Hydroxylapatit [Ca₁₀(PO₄)₆(OH)₂] im Skelett gespeichert. Serumcalcium (2,2–2,6 mmol/l) wird streng durch PTH, Calcitriol und Calcitonin reguliert. Intrazelluläres Ca²⁺ als Second Messenger steuert Muskelkontraktion, Exozytose und Genexpression."
        ),

        "iron": NutrientEntry(
            kids: "Eisen macht dein Blut stark, damit der Sauerstoff durch deinen ganzen Körper reisen kann — wie ein Taxi für Luft! Fleisch, Spinat und Hülsenfrüchte liefern Eisen.",
            adults: "Eisen ist Bestandteil von Hämoglobin (O₂-Transport) und Myoglobin (Muskeln). Eisenmangel führt zu Anämie. Pflanzliches Eisen (Non-Häm) wird schlechter aufgenommen als tierisches (Häm-Eisen).",
            scientific: "Fe²⁺ (Häm-Eisen, Absorptionsrate 20–30 %) und Fe³⁺ (Non-Häm, 2–10 %) werden unterschiedlich resorbiert. Vitamin C reduziert Fe³⁺ zu Fe²⁺ und steigert Absorption. Hepcidin reguliert Ferroportin und damit die intestinale Eisenabgabe ins Plasma."
        ),

        "magnesium": NutrientEntry(
            kids: "Magnesium ist der Entspannungs-Knopf für deine Muskeln — wenn du einen Krampf hast, fehlt oft Magnesium! Nüsse und Bananen haben viel davon.",
            adults: "Magnesium ist Cofaktor von über 300 Enzymen. Wichtig für Muskelentspannung, Energiestoffwechsel (ATP-Synthese) und Nervenfunktion. Empfehlung: 300–350 mg/Tag.",
            scientific: "Mg²⁺ stabilisiert ATP als Mg-ATP-Komplex, ist essenziell für DNA-Polymerase, Ribosomen-Funktion und Na⁺/K⁺-ATPase. Interzellulärer Mg²⁺-Spiegel reguliert NMDA-Rezeptoren. Renaler Verlust steigt bei Diabetes, Alkohol und bestimmten Diuretika."
        ),

        "potassium": NutrientEntry(
            kids: "Kalium hält dein Herz im richtigen Takt und hilft deinen Muskeln — Bananen und Kartoffeln sind super Kalium-Lieferanten!",
            adults: "Kalium reguliert Zellspannung, Blutdruck und Herzrhythmus. Es ist der Gegenspieler von Natrium. Empfehlung: 3500–4000 mg/Tag. Hohe Zufuhr senkt das Schlaganfall-Risiko.",
            scientific: "K⁺ ist das Haupt-Intrazellularkation (140 mmol/l intrazellulär vs. 3,5–5 mmol/l extrazellulär). Dieses Konzentrationsgefälle erzeugt das Ruhemembranpotenzial (~−70 mV) in erregbaren Zellen. Hypokaliämie führt zu Arrhythmien durch veränderte Repolarisationsphase."
        ),

        "vitaminC": NutrientEntry(
            kids: "Vitamin C ist dein Schutzschild gegen Erkältungen! Es hilft deinem Körper, sich zu wehren. Orangen, Paprika und Erdbeeren stecken voller Vitamin C.",
            adults: "Vitamin C (Ascorbinsäure) wirkt antioxidativ, unterstützt die Kollagensynthese, verbessert die Eisenresorption und stärkt das Immunsystem. Empfehlung: 95–110 mg/Tag.",
            scientific: "L-Ascorbinsäure ist ein wasserlösliches Antioxidans und Elektronendonor für Hydroxylasen (Prokollagen-Hydroxylierung → Kollagen-Tripelhelix). Als Reduktionsmittel regeneriert es α-Tocopherol (Vitamin E). Hohe Dosen (>1 g/Tag) fördern Oxalat-Bildung und erhöhen das Nierenstein-Risiko."
        ),

        "vitaminB12": NutrientEntry(
            kids: "Vitamin B12 hält deine Nerven fit und hilft beim Blutbilden — es steckt vor allem in Fleisch, Fisch und Milch. Wer kein tierisches Essen isst, braucht es als Zusatz.",
            adults: "Vitamin B12 (Cobalamin) ist essenziell für die Myelinsynthese und Blutbildung. Ein Mangel verursacht neurologische Schäden und megaloblastäre Anämie. Vorkommen: ausschließlich in tierischen Produkten.",
            scientific: "Cobalamine (Methylcobalamin, Adenosylcobalamin) sind Cofaktoren der Methionin-Synthase (Homocystein → Methionin) und L-Methylmalonyl-CoA-Mutase. Mangel akkumuliert Methylmalonyl-CoA (neurotoxisch) und erhöht Homocystein (kardiovaskuläres Risiko). Intrinsic Factor (Magenparietalzellen) ist für intestinale Absorption obligat."
        ),
    ]

    /// Gibt die Erklärung eines Nährstoffs in der gewünschten Ebene zurück.
    static func explain(_ key: String, mode: NutritionMode) -> String? {
        entries[key]?.text(for: mode)
    }
}
