//
//  NutrientExplainer.swift
//  KiDSKiTCHEN
//
//  Statische Erklär-Texte je Nährstoff in drei Ebenen (Kids / Eltern / Wissenschaft).
//  Allgemeines Ernährungslehre-Wissen, keine Heilversprechen oder medizinische Beratung.
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
            kids: "Kalorien sind der Treibstoff für deinen Körper — so wie Akku-Ladung für dein Tablet. Ohne genug davon hast du keine Kraft zum Toben, Lernen und Wachsen.",
            adults: "Kalorien geben an, wie viel Energie ein Lebensmittel liefert. Der Körper verbraucht sie im Ruhezustand (Atmen, Herzschlag), beim Wachsen und bei Bewegung. Isst man dauerhaft mehr, als verbraucht wird, legt der Körper den Rest als Fettreserve an.",
            scientific: "Die kcal-Angabe folgt dem Atwater-Schema, das den physiologischen Energiegehalt aus den Makronährstoffen hochrechnet: Eiweiß und Kohlenhydrate liefern rund 4 kcal/g, Fett rund 9 kcal/g. Der tatsächliche Brennwert liegt wegen unverdaulicher Anteile etwas darunter."
        ),

        "protein": NutrientEntry(
            kids: "Eiweiß ist das Baumaterial für Muskeln, Haut, Haare und Fingernägel — wie Bausteine für deinen Körper. Eier, Fleisch und Bohnen liefern besonders viel davon.",
            adults: "Proteine setzen sich aus Aminosäuren zusammen und übernehmen im Körper viele Aufgaben — als Enzym, Hormon oder Baustoff von Gewebe. Einen Teil dieser Aminosäuren (etwa Leucin, Isoleucin, Valin) kann der Körper nicht selbst herstellen, sie müssen mit der Nahrung kommen.",
            scientific: "Proteine sind Ketten aus bis zu 20 verschiedenen Aminosäuren, die über Peptidbindungen verknüpft sind. Nicht selbst synthetisierbar (essenziell) sind Histidin, Isoleucin, Leucin, Lysin, Methionin, Phenylalanin, Threonin, Tryptophan und Valin. Die biologische Wertigkeit beschreibt, wie gut sich ein Nahrungsprotein in körpereigenes Protein umsetzen lässt."
        ),

        "fat": NutrientEntry(
            kids: "Fett wärmt dich, schützt deine Organe wie ein Polster und hilft, manche Vitamine überhaupt erst aufzunehmen. Öl, Nüsse und Butter enthalten viel davon.",
            adults: "Fette liefern Fettsäuren, die der Körper braucht, und sind Voraussetzung dafür, dass die fettlöslichen Vitamine A, D, E und K aufgenommen werden können. Außerdem sind sie Baustoff für Zellmembranen und Hormone.",
            scientific: "Zu den Lipiden zählen Triglyceride, Phospholipide und Sterine. Triglyceride — drei Fettsäuren an einem Glycerin-Grundgerüst — dienen als Hauptenergiespeicher. Fettsäuren unterscheiden sich in Kettenlänge und Sättigungsgrad; ob eine Doppelbindung cis- oder trans-konfiguriert ist, verändert die biologische Wirkung deutlich."
        ),

        "carbs": NutrientEntry(
            kids: "Kohlenhydrate füllen deinen Energiespeicher schnell wieder auf — wie Strom, der dein Handy auflädt. Brot, Nudeln, Reis und Obst stecken voll davon.",
            adults: "Kohlenhydrate werden im Körper zu Traubenzucker (Glukose) umgewandelt, dem wichtigsten Energielieferanten für Gehirn und Muskeln. Komplexe Kohlenhydrate wie Stärke oder Ballaststoffe halten den Blutzucker stabiler, einfache lassen ihn schnell ansteigen.",
            scientific: "Kohlenhydrate — Einfach-, Zweifach- und Vielfachzucker — werden durch Amylasen und Disaccharidasen im Darm gespalten. Die freigesetzte Glukose gelangt über GLUT-Transporter ins Blut. Der glykämische Index setzt die Blutzuckerwirkung eines Lebensmittels ins Verhältnis zu reiner Glukose."
        ),

        "sugar": NutrientEntry(
            kids: "Zucker liefert ganz schnell Energie — die aber auch schnell wieder verpufft. Und zu viel davon schadet den Zähnen! In Obst steckt natürlicher Zucker, in Süßigkeiten sehr viel zugesetzter.",
            adults: "Zucker zählt zu den einfachen Kohlenhydraten — als Einfachzucker wie Traubenzucker und Fruchtzucker oder als Zweifachzucker wie Haushaltszucker. Wer dauerhaft viel davon isst, erhöht sein Risiko für Karies, Übergewicht und eine gestörte Insulinwirkung.",
            scientific: "Als „freie Zucker“ gelten nach WHO-Definition zugesetzte Mono- und Disaccharide sowie die natürlich enthaltenen Zucker in Honig, Sirup und Fruchtsaft. Fruktose wird in der Leber insulinunabhängig verstoffwechselt; bei hohem Konsum kann das die körpereigene Fettneubildung (De-novo-Lipogenese) ankurbeln."
        ),

        "fiber": NutrientEntry(
            kids: "Ballaststoffe wirken wie ein Besen für deinen Bauch — sie sorgen dafür, dass die Verdauung in Schwung bleibt. Vollkornbrot, Äpfel und Gemüse liefern reichlich davon.",
            adults: "Ballaststoffe sind Kohlenhydrate, die der Körper nicht verdauen kann. Sie regen die Darmbewegung an, ernähren die Darmbakterien, senken den Cholesterinspiegel und helfen, den Blutzucker im Gleichgewicht zu halten. Als Richtwert gelten mindestens 30 g pro Tag.",
            scientific: "Nahrungsfasern wie Cellulose, Hemicellulose, Pektin, Inulin oder resistente Stärke werden im Dickdarm von der Mikrobiota fermentiert. Dabei entstehen kurzkettige Fettsäuren (Butyrat, Propionat, Acetat), die die Darmschleimhaut mit Energie versorgen. Wasserunlösliche Fasern beschleunigen vor allem die Darmpassage, wasserlösliche wirken stärker auf Cholesterin- und Glukosewerte."
        ),

        "sodium": NutrientEntry(
            kids: "Natrium steckt im Salz und hilft deinen Nerven, Signale weiterzugeben — wie ein Kabel für Strom. Zu viel Salz belastet aber das Herz.",
            adults: "Natrium steuert den Flüssigkeitshaushalt, die Weiterleitung von Nervenreizen und den Blutdruck. Wird dauerhaft zu viel gegessen, steigt das Risiko für Bluthochdruck. Als Richtwert gelten weniger als 6 g Kochsalz pro Tag.",
            scientific: "Na⁺ ist das dominierende Kation im Extrazellularraum (etwa 138–142 mmol/l). Die Na⁺/K⁺-ATPase hält das Ruhemembranpotenzial der Zellen aufrecht. Bei chronisch hoher Zufuhr kann das Renin-Angiotensin-Aldosteron-System die Natriumbilanz nicht mehr ausreichend ausgleichen, was langfristig zu Bluthochdruck beiträgt."
        ),

        "calcium": NutrientEntry(
            kids: "Calcium macht Knochen und Zähne fest — wie Zement, der ein Haus stabil hält. Milch, Joghurt und Käse liefern besonders viel davon.",
            adults: "Calcium ist unverzichtbar für den Knochenaufbau, für die Muskelkontraktion und für die Blutgerinnung. Vitamin D verbessert, wie gut es aus dem Darm aufgenommen wird. Richtwerte liegen bei etwa 1000 mg täglich für Erwachsene, ab 65 Jahren etwas höher.",
            scientific: "Rund 99 % des Körpercalciums liegen als Hydroxylapatit im Skelett gespeichert. Der Calciumspiegel im Blutserum wird eng über Parathormon, Calcitriol und Calcitonin reguliert. Intrazelluläres Ca²⁺ fungiert als Second Messenger und steuert unter anderem Muskelkontraktion, Vesikel-Ausschüttung und Genaktivität."
        ),

        "iron": NutrientEntry(
            kids: "Eisen bringt Sauerstoff mit dem Blut in jeden Winkel deines Körpers — wie ein kleiner Lieferwagen für Luft. Fleisch, Spinat und Hülsenfrüchte enthalten Eisen.",
            adults: "Eisen ist Baustein von Hämoglobin, das Sauerstoff im Blut transportiert, und von Myoglobin in den Muskeln. Fehlt es, kann eine Blutarmut entstehen. Eisen aus pflanzlichen Quellen wird vom Körper schlechter aufgenommen als Eisen aus tierischen Lebensmitteln.",
            scientific: "Häm-Eisen (Fe²⁺) wird mit einer Absorptionsrate von 20–30 % deutlich effizienter resorbiert als Non-Häm-Eisen (Fe³⁺, 2–10 %). Vitamin C reduziert Fe³⁺ zu Fe²⁺ und verbessert so die Aufnahme. Das Hormon Hepcidin steuert über den Eisentransporter Ferroportin, wie viel Eisen aus der Darmschleimhaut ins Blut abgegeben wird."
        ),

        "magnesium": NutrientEntry(
            kids: "Magnesium ist der Entspannungsknopf für deine Muskeln — bei einem Krampf fehlt oft genau das. Nüsse und Bananen sind gute Magnesium-Quellen.",
            adults: "Magnesium wird von über 300 Enzymen im Körper gebraucht. Es unterstützt die Muskelentspannung, die Energiegewinnung in den Zellen und die Nervenfunktion. Als Richtwert gelten etwa 300–350 mg täglich.",
            scientific: "Mg²⁺ bildet mit ATP einen stabilen Komplex und ist damit an nahezu jeder ATP-abhängigen Reaktion beteiligt, unter anderem bei DNA-Polymerasen und der Na⁺/K⁺-ATPase. Der intrazelluläre Mg²⁺-Spiegel beeinflusst auch NMDA-Rezeptoren im Nervensystem. Erhöhte renale Verluste treten etwa bei Diabetes, Alkoholkonsum oder bestimmten Diuretika auf."
        ),

        "potassium": NutrientEntry(
            kids: "Kalium hält deinen Herzschlag im Takt und hilft deinen Muskeln beim Arbeiten — Bananen und Kartoffeln liefern reichlich davon!",
            adults: "Kalium ist der Gegenspieler von Natrium und wichtig für die Zellspannung, den Blutdruck und einen gleichmäßigen Herzrhythmus. Richtwerte liegen bei 3500–4000 mg täglich; eine ausreichende Zufuhr wird mit einem geringeren Schlaganfallrisiko in Verbindung gebracht.",
            scientific: "K⁺ ist das wichtigste intrazelluläre Kation (rund 140 mmol/l innerhalb, 3,5–5 mmol/l außerhalb der Zelle). Dieses Konzentrationsgefälle erzeugt das Ruhemembranpotenzial erregbarer Zellen (rund −70 mV). Ein Kaliummangel (Hypokaliämie) kann durch veränderte Repolarisation Herzrhythmusstörungen auslösen."
        ),

        "vitaminC": NutrientEntry(
            kids: "Vitamin C hilft deinem Körper, sich gegen Erkältungen zu wehren — wie ein Schutzschild. Paprika, Erdbeeren und Zitrusfrüchte stecken voller Vitamin C.",
            adults: "Vitamin C (Ascorbinsäure) wirkt als Antioxidans, unterstützt die Bildung von Kollagen im Bindegewebe, verbessert die Eisenaufnahme aus der Nahrung und stärkt das Immunsystem. Richtwerte liegen bei rund 95–110 mg täglich.",
            scientific: "L-Ascorbinsäure ist ein wasserlösliches Antioxidans und dient als Elektronendonor für Hydroxylasen, die bei der Kollagen-Tripelhelix-Bildung Prolin und Lysin hydroxylieren. Als Reduktionsmittel regeneriert es außerdem oxidiertes Vitamin E. Sehr hohe Dosen (über 1 g/Tag) begünstigen die Oxalatbildung und damit das Risiko für Nierensteine."
        ),

        "vitaminB12": NutrientEntry(
            kids: "Vitamin B12 hält deine Nerven fit und hilft, neues Blut zu bilden. Es steckt vor allem in Fleisch, Fisch und Milchprodukten — wer darauf verzichtet, braucht es als Ergänzung.",
            adults: "Vitamin B12 (Cobalamin) wird für den Aufbau der Nervenhüllen und für die Blutbildung gebraucht. Ein Mangel kann Nervenschäden und eine besondere Form von Blutarmut verursachen. Es kommt praktisch ausschließlich in tierischen Lebensmitteln vor.",
            scientific: "Die Cobalamin-Formen Methylcobalamin und Adenosylcobalamin sind Cofaktoren der Methionin-Synthase (Umwandlung von Homocystein zu Methionin) sowie der L-Methylmalonyl-CoA-Mutase. Bei einem Mangel reichert sich neurotoxisches Methylmalonyl-CoA an, und der Homocysteinspiegel steigt. Die intestinale Aufnahme setzt intrinsischen Faktor aus den Belegzellen des Magens voraus."
        ),
    ]

    /// Gibt die Erklärung eines Nährstoffs in der gewünschten Ebene zurück.
    static func explain(_ key: String, mode: NutritionMode) -> String? {
        entries[key]?.text(for: mode)
    }
}
