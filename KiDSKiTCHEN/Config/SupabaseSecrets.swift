//
//  SupabaseSecrets.swift
//  KiDSKiTCHEN
//
//  Der anon-Key wird aus einer Environment-Variable gelesen — steht so NICHT im Code/Git.
//  In Xcode setzen: Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables
//  → Name `SUPABASE_ANON_KEY`, Wert = anon-Key (Supabase: Project Settings → API).
//
//  Hinweis: Scheme-Env-Vars greifen nur bei Start AUS Xcode (Debug/Simulator), nicht im
//  Archive/Release. Für V1/Demo ausreichend; für einen Store-Build später anders lösen.
//

import Foundation

enum SupabaseSecrets {
    /// Projekt-URL (kein Geheimnis).
    static let url = "https://uezazosqfhdafnvptutl.supabase.co"

    /// anon / publishable Key aus der Environment-Variable. Fehlt sie → leer → API-Call
    /// schlägt fehl, die App zeigt die Seed-Rezepte (Fallback).
    static let anonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? ""
}
