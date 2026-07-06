<img width="1024" height="1024" alt="image" src="https://github.com/user-attachments/assets/372c2da2-03fd-44cb-b1e7-5bcf23f7ddab" />

# KidsKitchen

![2024–2026](https://img.shields.io/badge/2024–2026-white?style=flat)
![iOS 26](https://img.shields.io/badge/iOS-26-blue?style=flat&logo=apple&logoColor=white)
![Swift](https://img.shields.io/badge/Swift-orange?style=flat&logo=swift&logoColor=white)
![SwiftUI](https://img.shields.io/badge/SwiftUI-blue?style=flat&logo=swift&logoColor=white)
![SwiftData](https://img.shields.io/badge/SwiftData-blue?style=flat)
![MVVM](https://img.shields.io/badge/MVVM%20+%20Repository-blue?style=flat)

Eine Koch-App für Kinder (SwiftUI, deutsch). Kinder sollen spielerisch lernen zu
kochen — und dabei ein bisschen mehr über Ernährung mitnehmen, ganz ohne
Bevormundung.

> Die Idee kam mir im Gespräch mit meiner Nichte. Sie möchte gerne kochen lernen
> und hat mich gefragt, ob ich eine App dafür kenne. Ich habe keine gefunden — also
> baue ich eine. Bei der Überlegung ist mir aufgefallen, wie wenig ich selbst über
> Ernährung weiß, und so beschäftige ich mich seitdem auch selbst mehr damit.

Ursprünglich mein **Abschlussprojekt** im iOS-Modul der Weiterbildung zum
App-Entwickler am [Syntax Institut](https://www.syntax-institut.de) (Berlin, 2024) —
seither weitergebaut.

## Aktueller Stand

- **Architektur:** MVVM + Repository-Pattern. Feature-getrennte ViewModels
  (`RecipeListViewModel` fürs Anzeigen, `RecipeEditorViewModel` fürs Erstellen).
- **API-Anbindung:** Rezepte werden über ein Repository von einem
  [Supabase](https://supabase.com)-Backend geladen; offline fällt die App auf
  handkuratierte Seed-Rezepte zurück.
- **Persistenz (SwiftData):** Rezepte lassen sich offline speichern — inkl. Bild als
  `externalStorage`-Blob. SwiftData liegt bewusst **hinter** dem Repository.
- **Features:** Kids-Rezeptliste mit Kategorien & Suche · Rezept-Detail mit
  Nährwertbalken, Zutaten (mit Kategorie-Icons) und Zubereitungsschritten ·
  Favoriten · Einkaufsliste · Wochenplaner · Vorratsschrank · Diät-/Ausschlussfilter
  · eigene Rezepte anlegen · deutsche Lokalisierung (Serifen-Typografie).

## Abschluss-Anforderungen (V1) — erfüllt

| Kriterium | Umsetzung |
| --- | --- |
| mindestens 3 Screens | Rezepte · Wochenplan · Einkaufen · Mehr · Detailansichten ✅ |
| vertikale & horizontale Navigation | `TabView`, `NavigationStack`, `NavigationLink`, Sheet ✅ |
| Dynamische Daten | Listen / `ForEach` über Rezepte & Zutaten ✅ |
| Datenpersistenz | **SwiftData** (offline gespeicherte Rezepte) ✅ |
| API-Anbindung | Rezept-Repository gegen Supabase ✅ |
| MVVM | durchgängig, feature-getrennte ViewModels ✅ |

## Tech-Stack

SwiftUI · Swift Concurrency (`async/await`) · SwiftData · MVVM + Repository ·
Supabase (PostgREST) · Apple Vision (Freistellung der Zutaten-Bilder).

## Setup & Start

1. Repo klonen und `KiDSKiTCHEN.xcodeproj` in **Xcode 26+** öffnen.
2. Ein iOS-**26**-Ziel wählen (Simulator oder Gerät) und ▶︎ Run.

Die App läuft direkt — ohne Konfiguration zeigt sie die handkuratierten
**Seed-Rezepte** offline an. Für die Live-Rezepte aus dem Backend braucht es den
Supabase-anon-Key als Umgebungsvariable:

- **Product → Scheme → Edit Scheme… → Run → Arguments → Environment Variables**
- Name `SUPABASE_ANON_KEY`, Wert = anon-Key (Supabase: *Project Settings → API*).

Fehlt der Key, fällt die App still auf die Seed-Rezepte zurück. Die Projekt-URL
steht (als kein Geheimnis) in `KiDSKiTCHEN/Config/SupabaseSecrets.swift`; der Key
selbst liegt bewusst **nicht** im Code.

> Hinweis: Scheme-Env-Variablen greifen nur beim Start aus Xcode (Debug/Simulator),
> nicht im Archive/Release-Build.

## Zu meiner Person

Ich bin Joscha aus Berlin. Nach 20 Jahren in der Gastronomie, habe ich mich 
beim Syntax Institut zum App-Entwickler "weiterbilden" lassen. Boot Camp trifft es wahrscheinlich eher. 
— im Programmieren von Apps habe ich meine Passion gefunden. Dieses Projekt zeigt meine Arbeitsweise und meinen
Anspruch an sauberen, aktuellen Code. Hmmm naja ... bleiben wir ehrlich, claude hat fast alles weitergeschrieben.

## Recherche & Quellen

Websites und APIs, die während der Konzeption geholfen haben:
[Familienküche](https://familienkueche.de/rezepte/) ·
[GEOlino Kinderrezepte](https://www.geo.de/geolino/kinderrezepte/) ·
[Nährwertrechner](https://www.naehrwertrechner.de) ·
[TheMealDB](https://www.themealdb.com/api.php) ·
[OpenFoodFacts](https://world.openfoodfacts.org/) ·
[Edamam](https://developer.edamam.com/edamam-recipe-api).

## Lizenz

**MIT** — siehe [LICENSE](LICENSE). Nutz den Code gerne. Wenn er jemandem hilft, der
ihn braucht, umso besser.
