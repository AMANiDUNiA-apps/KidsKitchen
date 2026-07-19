//
//  RecipeRoute.swift
//  KiDSKiTCHEN
//
//  Rebuild P5: typisierte Navigation per ID statt Wert-Kopie im NavigationLink.
//  Der Ziel-Screen löst die ID gegen die aktuelle Rezeptliste auf (env.recipes) —
//  bleibt so korrekt, auch wenn die Liste sich zwischenzeitlich ändert (z. B.
//  Supabase-Nachladen ersetzt die Seed-Rezepte), statt eine veraltete Kopie
//  durch den Navigations-Stack zu tragen.
//

import Foundation

enum RecipeRoute: Hashable {
    case detail(Recipe.ID)
}
