//
//  KKWeekKeyDebugCheck.swift
//  KiDSKiTCHEN
//
//  Selbst-Check für die wochendatierte Persistenz (planKey/kkWeekStart). Das
//  Projekt hat kein Xcode-Testtarget (Weiterbau 18.7., BRIEF-kk-endstrecke) —
//  daher als DEBUG-Assert direkt beim App-Start statt XCTest/Swift Testing.
//  Prüft den im Brief benannten Risikofall: eine für „nächste Woche" geplante
//  Mahlzeit muss unter dem Key der NÄCHSTEN Woche landen, nicht der aktuellen
//  (bool-/Default-Falle bei `week:`-Parametern mit Default).
//

import Foundation

#if DEBUG
enum KKWeekKeyDebugCheck {
    static func run() {
        let thisWeek = Date.kkWeekStart(offset: 0)
        let nextWeek = Date.kkWeekStart(offset: 1)

        // 1) Nächste Woche liegt exakt 7 Tage nach der aktuellen.
        let days = Calendar.current.dateComponents([.day], from: thisWeek, to: nextWeek).day
        assert(days == 7, "kkWeekStart(offset: 1) sollte 7 Tage nach offset: 0 liegen, war \(String(describing: days))")

        // 2) Unterschiedliche Wochen-Keys für denselben Tag.
        let keyThisWeek = Preferences.weekKey(thisWeek)
        let keyNextWeek = Preferences.weekKey(nextWeek)
        assert(keyThisWeek != keyNextWeek, "Wochen-Keys dürfen sich nicht gleichen: \(keyThisWeek)")

        // 3) Praxis-Fall: für „nächste Woche" geplantes Rezept landet NICHT
        //    unter dem Key der aktuellen Woche.
        let prefs = Preferences.shared
        let probeRecipe = "__kkWeekKeyDebugCheck__"
        prefs.addToPlan(probeRecipe, day: .mon, week: nextWeek)
        defer { prefs.removeFromPlan(probeRecipe, day: .mon, week: nextWeek) }

        assert(!prefs.plannedRecipes(.mon, week: thisWeek).contains(probeRecipe),
               "Für nächste Woche geplantes Rezept ist fälschlich in der aktuellen Woche gelandet")
        assert(prefs.plannedRecipes(.mon, week: nextWeek).contains(probeRecipe),
               "Für nächste Woche geplantes Rezept fehlt unter dem Key der nächsten Woche")
    }
}
#endif
