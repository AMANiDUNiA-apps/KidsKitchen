# KidsKitchen — Rebuild-Plan (kanonisch, entschieden 2026-07-19)

> **Branch:** `bau/rebuild-clean` · **Worktree:** `../KiDSKiTCHEN-wt-rebuild`
> Isoliert von `main`, `fix/detail-white-bars`, `bau/air-ui-release` (andere Sessions arbeiten dort).
> Im KidsKitchen-Repo NIE pushen (öffentlich, nur Jay).

## Entscheidung (Jay, 19.7. — „du entscheidest … lets go")
Grundlage: zwei unabhängige Plan-Subagents (Architektur + Feature/UX). Beide kamen zum
gleichen Befund: die App ist **nicht** durchweg chaotisch — Design-System, Theme-Engine,
Nährwert-Engine, Zutaten-Bilder, Screens sind **hochwertig**. Faul sind nur die **Fundamente**.

**Gewählter Weg — „Re-Founding", nicht „Re-Typing":**
1. **Re-Founding** — sauberes neues Architektur-Gerüst; die „Kronjuwelen" werden hineingeliftet
   und neu verdrahtet. Von Null neu gebaut wird nur, was wirklich faul ist.
2. **MVP-first, gestaffelt** — erst demofähiger Kern (Rezepte→Detail→Kochen, Seed offline),
   dann Haushalts-Loop, dann Supabase. AI-Import / Editor / Custom-Theme-Editor / Saisonkalender
   werden nach hinten gestaffelt.
3. **Clean Slate** — keine Migration alter UserDefaults-Daten (Pre-Launch). Neue Stores starten leer.

## Was faul ist (wird neu gebaut)
- `Preferences` = 500-Zeilen-Gott-Objekt (UserDefaults + **Namens-Strings als Join-Keys**).
- `.shared`-Singleton-Wildwuchs (Preferences, ThemeSettings, ThemeRepository, RecipeList/Editor/
  IngredientViewModel, KKCookingSession, SavedRecipeRepository) → **ein `AppEnvironment`-DI-Root**.
- `Ingredient` = mutable `@Observable`-Klasse mit UI-`isSelected` **im Datenmodell** → reiner `struct`.
- Zwei parallele Nährwert-Modelle (`Nutrition` vs `NutritionFacts`) → **ein** optionales Modell.
- Gemischte Persistenz → SwiftData für Nutzerdaten, `@AppStorage` für Skalare, structs fürs Katalog.
- Client-seitige Suche (bricht bei 32k) → Repository-Query (server-seitig für Supabase).
- Debug-Selbstchecks (`KKWeekKeyDebugCheck`, `KKThemeSettingsDebugCheck`) → echtes **Swift-Testing-Target**.

## Was geliftet wird (Kronjuwelen — verbatim + umverdrahten)
- Gesamtes `KK*`-UI-Kit + Theme-Engine (`KKTheme`, 8–11 Themes inkl. liquidGlass), `KKAnimatedBackground`.
- `KKContainer`/`KKCard`/`KKScroll`/`KKSection` — aber **`Color.red`-Diagnose in `KKScroll` raus**.
- Nährwert-Engine (`NutritionFacts`/`NutritionMath`/`NutrientExplainer`), Zutat-Detail mini/mid/full.
- 111 Zutaten-PNGs + Mapping (`IngredientImageCatalog`/`Mapping`/`View`), `IngredientMatch` (hinter Protokoll).
- Seed-Daten (`Recipe+Seed`, `Ingredient+Seed`), Repository-Protokoll + Offline-Guard, `RemoteRecipe`-DTO.
- Cooking-Mode, Onboarding-per-Ausschluss, Splash, alle Enums (Category/Unit/Season/Weekday/Diet).

## Ziel-Architektur (Ordner = Module; ganze `KiDSKiTCHEN/` ist EIN Sync-Root → neue Dateien auto im Target)
```
KiDSKiTCHEN/
├── App/            KiDSKiTCHENApp, AppRoot, AppEnvironment (Composition-Root/DI)
├── DesignSystem/   KKTheme, KKFont (Serif-Token), KKCard/KKScroll/KKSection, KKGlassTabBar, KK* …
├── Domain/         reine value types + Logik, KEIN SwiftUI/SwiftData
│   ├── Models/     Recipe, Ingredient(struct), RecipeIngredient, Instruction, Nutrition, Enums
│   ├── Nutrition/  NutritionMath, NutrientExplainer
│   ├── Pantry/     PantryCycle, Shortfall, Cookable (pure functions)
│   └── Matching/   IngredientMatch + IngredientMatching-Protokoll (FoundationModels-Seam)
├── Data/
│   ├── Store/      SwiftData @Model (PantryEntry, PlanEntry, ShoppingItem, SavedRecipe, Favorite) + Container
│   ├── Repositories/ RecipeRepository(+Seed/Supabase), UserDataStore
│   ├── Remote/     RemoteRecipe, SupabaseClient
│   └── Seed/       Recipe+Seed, Ingredient+Seed
├── Features/       je Screen: View + lokales @Observable-Model
│   ├── Home/ Recipe/ Pantry/ WeekPlan/ Shopping/ Onboarding/ Settings/
├── AI/             FoundationModels-Matcher/Textgen (später)
└── Support/        Extensions, Formatter, Locale
```
Abhängigkeitsrichtung: **Features → Data → Domain ← DesignSystem**. Domain importiert nichts App-spezifisches.
Keine SPM-Pakete (Ordner-Konvention reicht; matcht die manuelle Target-Pflege). `@Observable` + async/await, kein Combine.

## Phasen (jede endet mit GRÜNEM Build via CLI)
Build: `DEVELOPER_DIR=/Applications/Xcode-beta.app xcodebuild -scheme KiDSKiTCHEN -destination 'generic/platform=iOS Simulator' build`
Jede Swift-Datei vor Phasenabschluss durch swiftui-pro / swiftdata-pro / swift-concurrency-pro.

- **P1 Foundation** — Ordnergerüst, `AppEnvironment`-Root, `AppRoot` (TabView + KKGlassTabBar, Platzhalter),
  Serif/de_DE/Appearance, Splash. Grüner leerer Shell.
- **P2 Domain** — reine Modelle (Ingredient als struct!), Enums, unified Nutrition, pure Pantry/Plan/Match-Logik.
  **Swift-Testing-Target** anlegen, Pantry-Zyklus + Matcher testen. Grün + grüne Tests.
- **P3 Data** — SwiftData-Stores + Container, UserDataStore (ersetzt Preferences), RecipeRepository (Seed/
  Supabase/Offline-Guard), RemoteRecipe. In AppEnvironment verdrahten. ID-basierte Joins. Grün.
- **P4 Design-System** — KK* re-homen, KKContainer splitten, rote Diagnose raus, `KKFont`-Serif-Skala, ThemeStore injiziert.
- **P5 Kern-Screens (MVP)** — Home-Liste, Rezept-Detail, Zutat-Detail mini/mid/full, typisierte Navigation per ID.
  **Nordstern: Nichte tippt Apfel-Zimt-Porridge, sieht es schön, kann kochen.**
- **P6 Vorrat + Zutaten** — PantryView, Bild-Mapping, „Was kann ich kochen?", (Saisonkalender später).
- **P7 Planung** — WeekPlan, Shopping, voller Vorrats-Zyklus, Favoriten. Höchste Logikdichte → nutzt P2-Tests.
- **P8 Authoring** — NewRecipe-Editor neu (lokaler Selektions-State), Offline-Speichern. (post-MVP)
- **P9 Politur + AI-Seam** — Onboarding, Cooking-Mode-Feinschliff, FoundationModels-Matcher, A11y (Dynamic Type/VoiceOver).

## Offene Entscheidungen für Jay (nicht blockierend, später)
- Abgeleitete vs. gespeicherte Rezept-Nährwerte (Empfehlung: gespeichert wenn vorhanden, sonst aus BLS ableiten).
- Supabase Paging/Server-Suche für 32k (aktuell hartes 40-Zeilen-Limit) — Design ab P3 dafür auslegen.
- Braucht die Kinder-App den manuellen Rezept-Editor überhaupt? (aktuell → post-MVP/Eltern-Werkzeug)

## Eiserne Regeln (aus CLAUDE.md)
Ordnernamen der Originale NIE ändern (hier im Worktree aber freie Reorg erlaubt, isoliert) · keine Secrets in Git ·
KEIN push im KidsKitchen-Repo · Verifikation via Device Hub (nicht raten) · iOS/Xcode-beta-Toolchain, XcodeBuildMCP unbrauchbar.
