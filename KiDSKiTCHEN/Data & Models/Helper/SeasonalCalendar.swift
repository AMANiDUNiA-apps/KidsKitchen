//
//  SeasonalCalendar.swift
//  KiDSKiTCHEN
//
//  Saisonkalender — Gemüse & Obst mit Verfügbarkeit je Monat (frisch / Lagerware).
//  Allgemeines Saisonkalender-Wissen (Erzeugerkalender). Kein Netz-Call — offline-first.
//
//  Namensraum KKMonth / KKSeasonalItem vermeidet Konflikte mit Season.swift.
//

import Foundation

// MARK: - KKMonth
enum KKMonth: Int, CaseIterable, Identifiable {
    case jan = 1, feb, mar, apr, may, jun, jul, aug, sep, oct, nov, dec

    var id: Int { rawValue }

    var shortName: String {
        switch self {
        case .jan: return "Jan"; case .feb: return "Feb"; case .mar: return "Mär"
        case .apr: return "Apr"; case .may: return "Mai"; case .jun: return "Jun"
        case .jul: return "Jul"; case .aug: return "Aug"; case .sep: return "Sep"
        case .oct: return "Okt"; case .nov: return "Nov"; case .dec: return "Dez"
        }
    }

    var fullName: String {
        switch self {
        case .jan: return "Januar";   case .feb: return "Februar";  case .mar: return "März"
        case .apr: return "April";    case .may: return "Mai";      case .jun: return "Juni"
        case .jul: return "Juli";     case .aug: return "August";   case .sep: return "September"
        case .oct: return "Oktober";  case .nov: return "November"; case .dec: return "Dezember"
        }
    }

    static var current: KKMonth {
        KKMonth(rawValue: Calendar.current.component(.month, from: Date())) ?? .jan
    }
}

// MARK: - SeasonAvailability
enum SeasonAvailability {
    case fresh    // frisch aus heimischem Anbau
    case storage  // Lagerware aus heimischem Anbau

    var label: String {
        switch self {
        case .fresh:   return "Frisch"
        case .storage: return "Lagerware"
        }
    }

    var symbolName: String {
        switch self {
        case .fresh:   return "leaf.fill"
        case .storage: return "archivebox"
        }
    }
}

// MARK: - SeasonKind
enum SeasonKind {
    case vegetable
    case fruit

    var label: String {
        switch self {
        case .vegetable: return "Gemüse"
        case .fruit:     return "Obst"
        }
    }

    var symbolName: String {
        switch self {
        case .vegetable: return "carrot"
        case .fruit:     return "apple.logo"
        }
    }
}

// MARK: - KKSeasonalItem
struct KKSeasonalItem: Identifiable {
    let id = UUID()
    let name: String
    let kind: SeasonKind
    let availabilityByMonth: [KKMonth: SeasonAvailability]

    func availability(in month: KKMonth) -> SeasonAvailability? {
        availabilityByMonth[month]
    }
}

// MARK: - Seasonal Data
extension KKSeasonalItem {

    static let vegetables: [KKSeasonalItem] = [
        .init(name: "Aubergine", kind: .vegetable, availabilityByMonth: [.jul: .fresh, .aug: .fresh, .sep: .fresh, .oct: .fresh]),
        .init(name: "Blumenkohl", kind: .vegetable, availabilityByMonth: [.may: .fresh, .jun: .fresh, .jul: .fresh, .aug: .fresh, .sep: .fresh, .oct: .fresh]),
        .init(name: "Bohnen (grün)", kind: .vegetable, availabilityByMonth: [.jul: .fresh, .aug: .fresh, .sep: .fresh, .oct: .fresh]),
        .init(name: "Brokkoli", kind: .vegetable, availabilityByMonth: [.jun: .fresh, .jul: .fresh, .aug: .fresh, .sep: .fresh, .oct: .fresh]),
        .init(name: "Butterrüben", kind: .vegetable, availabilityByMonth: [.jan: .storage, .feb: .storage, .mar: .storage, .apr: .storage, .aug: .fresh, .sep: .fresh, .oct: .fresh, .nov: .fresh, .dec: .fresh]),
        .init(name: "Champignons", kind: .vegetable, availabilityByMonth: Dictionary(uniqueKeysWithValues: KKMonth.allCases.map { ($0, .fresh) })),
        .init(name: "Erbsen", kind: .vegetable, availabilityByMonth: [.jun: .fresh, .jul: .fresh, .aug: .fresh]),
        .init(name: "Fenchel", kind: .vegetable, availabilityByMonth: [.jun: .fresh, .jul: .fresh, .aug: .fresh, .sep: .fresh, .oct: .fresh, .nov: .fresh]),
        .init(name: "Grünkohl", kind: .vegetable, availabilityByMonth: [.jan: .fresh, .feb: .fresh, .nov: .fresh, .dec: .fresh]),
        .init(name: "Gurke", kind: .vegetable, availabilityByMonth: [.jun: .fresh, .jul: .fresh, .aug: .fresh, .sep: .fresh, .oct: .fresh]),
        .init(name: "Kartoffeln", kind: .vegetable, availabilityByMonth: [.jan: .storage, .feb: .storage, .mar: .storage, .apr: .storage, .may: .storage, .jun: .fresh, .jul: .fresh, .aug: .fresh, .sep: .fresh, .oct: .fresh, .nov: .storage, .dec: .storage]),
        .init(name: "Kohlrabi", kind: .vegetable, availabilityByMonth: [.may: .fresh, .jun: .fresh, .jul: .fresh, .aug: .fresh, .sep: .fresh, .oct: .fresh]),
        .init(name: "Kürbis", kind: .vegetable, availabilityByMonth: [.jan: .storage, .feb: .storage, .aug: .fresh, .sep: .fresh, .oct: .fresh, .nov: .fresh, .dec: .storage]),
        .init(name: "Lauch", kind: .vegetable, availabilityByMonth: [.jan: .fresh, .feb: .fresh, .mar: .fresh, .apr: .fresh, .jul: .fresh, .aug: .fresh, .sep: .fresh, .oct: .fresh, .nov: .fresh, .dec: .fresh]),
        .init(name: "Frühlingszwiebeln", kind: .vegetable, availabilityByMonth: [.may: .fresh, .jun: .fresh, .jul: .fresh, .aug: .fresh, .sep: .fresh, .oct: .fresh]),
        .init(name: "Mais", kind: .vegetable, availabilityByMonth: [.aug: .fresh, .sep: .fresh, .oct: .fresh]),
        .init(name: "Mangold", kind: .vegetable, availabilityByMonth: [.may: .fresh, .jun: .fresh, .jul: .fresh, .aug: .fresh, .sep: .fresh, .oct: .fresh]),
        .init(name: "Paprika", kind: .vegetable, availabilityByMonth: [.jul: .fresh, .aug: .fresh, .sep: .fresh, .oct: .fresh]),
        .init(name: "Pastinaken", kind: .vegetable, availabilityByMonth: [.jan: .fresh, .feb: .fresh, .mar: .fresh, .apr: .storage, .sep: .fresh, .oct: .fresh, .nov: .fresh, .dec: .fresh]),
        .init(name: "Radieschen", kind: .vegetable, availabilityByMonth: [.may: .fresh, .jun: .fresh, .jul: .fresh, .aug: .fresh, .sep: .fresh, .oct: .fresh]),
        .init(name: "Rosenkohl", kind: .vegetable, availabilityByMonth: [.jan: .fresh, .feb: .fresh, .mar: .fresh, .oct: .fresh, .nov: .fresh, .dec: .fresh]),
        .init(name: "Rote Beete", kind: .vegetable, availabilityByMonth: [.jan: .storage, .feb: .storage, .mar: .storage, .apr: .storage, .jul: .fresh, .aug: .fresh, .sep: .fresh, .oct: .fresh, .nov: .fresh, .dec: .storage]),
        .init(name: "Rotkohl", kind: .vegetable, availabilityByMonth: [.jan: .storage, .feb: .storage, .mar: .storage, .apr: .storage, .may: .storage, .jun: .fresh, .jul: .fresh, .aug: .fresh, .sep: .fresh, .oct: .fresh, .nov: .fresh, .dec: .storage]),
        .init(name: "Spargel", kind: .vegetable, availabilityByMonth: [.apr: .fresh, .may: .fresh, .jun: .fresh]),
        .init(name: "Spinat", kind: .vegetable, availabilityByMonth: [.mar: .fresh, .apr: .fresh, .may: .fresh, .sep: .fresh, .oct: .fresh, .nov: .fresh]),
        .init(name: "Tomaten", kind: .vegetable, availabilityByMonth: [.jul: .fresh, .aug: .fresh, .sep: .fresh, .oct: .fresh]),
        .init(name: "Zucchini", kind: .vegetable, availabilityByMonth: [.jun: .fresh, .jul: .fresh, .aug: .fresh, .sep: .fresh, .oct: .fresh]),
        .init(name: "Zwiebeln", kind: .vegetable, availabilityByMonth: [.jan: .storage, .feb: .storage, .mar: .storage, .apr: .storage, .may: .storage, .jun: .storage, .jul: .fresh, .aug: .fresh, .sep: .fresh, .oct: .fresh, .nov: .storage, .dec: .storage]),
        // Nachgetragene Sorten
        .init(name: "Weißkohl", kind: .vegetable, availabilityByMonth: [.jan: .storage, .feb: .storage, .mar: .storage, .apr: .storage, .jun: .fresh, .jul: .fresh, .aug: .fresh, .sep: .fresh, .oct: .fresh, .nov: .fresh, .dec: .storage]),
        .init(name: "Wirsing", kind: .vegetable, availabilityByMonth: [.jan: .fresh, .feb: .fresh, .mar: .storage, .may: .fresh, .jun: .fresh, .jul: .fresh, .aug: .fresh, .sep: .fresh, .oct: .fresh, .nov: .fresh, .dec: .fresh]),
        .init(name: "Spitzkohl", kind: .vegetable, availabilityByMonth: [.may: .fresh, .jun: .fresh]),
        .init(name: "Staudensellerie", kind: .vegetable, availabilityByMonth: [.jul: .fresh, .aug: .fresh, .sep: .fresh, .oct: .fresh]),
        .init(name: "Steckrüben", kind: .vegetable, availabilityByMonth: [.jan: .storage, .feb: .storage, .mar: .storage, .sep: .fresh, .oct: .fresh, .nov: .fresh, .dec: .fresh]),
        .init(name: "Schwarzwurzeln", kind: .vegetable, availabilityByMonth: [.jan: .fresh, .feb: .fresh, .oct: .fresh, .nov: .fresh, .dec: .fresh]),
        .init(name: "Topinambur", kind: .vegetable, availabilityByMonth: [.jan: .fresh, .feb: .fresh, .mar: .fresh, .oct: .fresh, .nov: .fresh, .dec: .fresh]),
        .init(name: "Zuckerschoten", kind: .vegetable, availabilityByMonth: [.jun: .fresh, .jul: .fresh, .aug: .fresh]),
    ]

    static let fruits: [KKSeasonalItem] = [
        .init(name: "Apfel", kind: .fruit, availabilityByMonth: [.jan: .storage, .feb: .storage, .mar: .storage, .apr: .storage, .may: .storage, .aug: .fresh, .sep: .fresh, .oct: .fresh, .nov: .fresh, .dec: .storage]),
        .init(name: "Aprikose", kind: .fruit, availabilityByMonth: [.jul: .fresh, .aug: .fresh]),
        .init(name: "Birne", kind: .fruit, availabilityByMonth: [.aug: .fresh, .sep: .fresh, .oct: .fresh, .nov: .storage, .dec: .storage]),
        .init(name: "Blaubeeren", kind: .fruit, availabilityByMonth: [.jun: .fresh, .jul: .fresh, .aug: .fresh, .sep: .fresh]),
        .init(name: "Brombeeren", kind: .fruit, availabilityByMonth: [.jul: .fresh, .aug: .fresh, .sep: .fresh]),
        .init(name: "Erdbeeren", kind: .fruit, availabilityByMonth: [.jun: .fresh, .jul: .fresh]),
        .init(name: "Himbeeren", kind: .fruit, availabilityByMonth: [.jun: .fresh, .jul: .fresh, .aug: .fresh]),
        .init(name: "Holunderbeeren", kind: .fruit, availabilityByMonth: [.sep: .fresh, .oct: .fresh]),
        .init(name: "Johannisbeeren", kind: .fruit, availabilityByMonth: [.jun: .fresh, .jul: .fresh, .aug: .fresh]),
        .init(name: "Kirschen", kind: .fruit, availabilityByMonth: [.jun: .fresh, .jul: .fresh, .aug: .fresh]),
        .init(name: "Mirabellen", kind: .fruit, availabilityByMonth: [.jul: .fresh, .aug: .fresh]),
        .init(name: "Pflaumen", kind: .fruit, availabilityByMonth: [.aug: .fresh, .sep: .fresh, .oct: .fresh]),
        .init(name: "Quitten", kind: .fruit, availabilityByMonth: [.oct: .fresh, .nov: .fresh]),
        .init(name: "Rhabarber", kind: .fruit, availabilityByMonth: [.apr: .fresh, .may: .fresh, .jun: .fresh]),
        .init(name: "Sanddorn", kind: .fruit, availabilityByMonth: [.aug: .fresh, .sep: .fresh, .oct: .fresh]),
        .init(name: "Stachelbeeren", kind: .fruit, availabilityByMonth: [.jun: .fresh, .jul: .fresh, .aug: .fresh]),
        .init(name: "Trauben", kind: .fruit, availabilityByMonth: [.sep: .fresh, .oct: .fresh]),
        .init(name: "Zwetschgen", kind: .fruit, availabilityByMonth: [.aug: .fresh, .sep: .fresh]),
    ]

    /// Alle Einträge (Gemüse + Obst) kombiniert.
    static let all: [KKSeasonalItem] = vegetables + fruits

    /// Einträge, die im angegebenen Monat Saison haben.
    static func inSeason(_ month: KKMonth, kinds: Set<SeasonKind>? = nil) -> [KKSeasonalItem] {
        all.filter { item in
            item.availabilityByMonth[month] != nil
            && (kinds?.contains(item.kind) ?? true)
        }
    }

    /// Frische Einträge im angegebenen Monat (kein Lagerware).
    static func freshInSeason(_ month: KKMonth, kinds: Set<SeasonKind>? = nil) -> [KKSeasonalItem] {
        all.filter { item in
            item.availabilityByMonth[month] == .fresh
            && (kinds?.contains(item.kind) ?? true)
        }
    }
}
