//
//  KKWeekKeyDebugCheck.swift
//  KiDSKiTCHEN
//
//  Selbst-Check für die wochendatierte Persistenz (kkWeekStart/weekKey). Das
//  Projekt hat kein Xcode-Testtarget (Weiterbau 18.7., BRIEF-kk-endstrecke) —
//  daher als DEBUG-Assert direkt beim App-Start statt XCTest/Swift Testing.
//  REINE Key-Rechnung, fasst KEINEN echten Store an (Terra-Review 18.7.:
//  kein Schreiben in Preferences.shared/Nutzerdaten). Der Praxis-Pfad
//  „nächste Woche darf nicht in der aktuellen landen" ist seitdem strukturell
//  gesichert: die mutierenden Plan-/Koch-Methoden haben keinen week-Default
//  mehr — jeder Aufrufer muss die Woche explizit nennen (Compiler erzwingt das).
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

        // 2) Unterschiedliche Wochen → unterschiedliche Persistenz-Keys.
        assert(Preferences.weekKey(thisWeek) != Preferences.weekKey(nextWeek),
               "Wochen-Keys dürfen sich nicht gleichen: \(Preferences.weekKey(thisWeek))")

        // 3) Key-Format bleibt „JJJJ-MM-TT" (10 Zeichen) — Plan-Keys hängen
        //    „|Tag" an dieses Präfix, ein Formatbruch würde Alt-Daten verwaisen.
        assert(Preferences.weekKey(nextWeek).count == 10,
               "weekKey-Format erwartet JJJJ-MM-TT, war: \(Preferences.weekKey(nextWeek))")
    }
}
#endif
