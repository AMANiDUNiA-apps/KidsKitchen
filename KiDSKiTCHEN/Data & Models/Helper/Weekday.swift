//
//  Weekday.swift
//  KiDSKiTCHEN
//
//  Created by Claude Fable 5 on 03.07.26.
//  Wochentage für den Wochenplaner (Mo–So, deutsche Reihenfolge).
//

import Foundation

enum Weekday: String, CaseIterable, Identifiable, Codable {
    case mon = "Montag", tue = "Dienstag", wed = "Mittwoch", thu = "Donnerstag"
    case fri = "Freitag", sat = "Samstag", sun = "Sonntag"

    var id: Self { self }
    var short: String { String(rawValue.prefix(2)) }

    /// Heutiger Wochentag (für Hervorhebung im Plan).
    static var today: Weekday {
        // Calendar: 1=So … 7=Sa → auf Mo-basierte Reihenfolge mappen
        let c = Calendar(identifier: .gregorian).component(.weekday, from: Date())
        switch c {
        case 2: return .mon; case 3: return .tue; case 4: return .wed; case 5: return .thu
        case 6: return .fri; case 7: return .sat; default: return .sun
        }
    }
}

// MARK: - Wochenstart (echte Wochen-Navigation, 18.7.)
extension Date {
    /// Montag 00:00 der Woche mit Versatz (0 = aktuelle Woche). Eine Quelle für
    /// WeekPlanView UND die Persistenzschlüssel in Preferences.
    static func kkWeekStart(offset: Int = 0) -> Date {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        // Calendar.weekday: 1=So … 7=Sa. Tage seit Montag:
        let daysSinceMon = (cal.component(.weekday, from: today) - 2 + 7) % 7
        let monday = cal.date(byAdding: .day, value: -daysSinceMon, to: today) ?? today
        return cal.date(byAdding: .weekOfYear, value: offset, to: monday) ?? monday
    }
}
