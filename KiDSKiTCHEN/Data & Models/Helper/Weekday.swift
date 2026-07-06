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
