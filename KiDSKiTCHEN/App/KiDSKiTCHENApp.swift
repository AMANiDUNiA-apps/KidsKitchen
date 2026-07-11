//
//  KiDSKiTCHENApp.swift
//  KiDSKiTCHEN
//
//  Created by Joscha Amani Gaber on 10.01.26.
//

import SwiftUI

@main
struct KiDSKiTCHENApp: App {
    // Nav-Leiste transparent (Jay 11.7.): Inhalt läuft unter der Leiste durch,
    // kein Material/Hintergrund — gilt global für alle NavigationStacks.
    init() {
        let transparent = UINavigationBarAppearance()
        transparent.configureWithTransparentBackground()
        UINavigationBar.appearance().standardAppearance = transparent
        UINavigationBar.appearance().scrollEdgeAppearance = transparent
        UINavigationBar.appearance().compactAppearance = transparent
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Typo-Standard (Jay, 3.7.): Serifen global, Mono nur für IDs/Code
                .fontDesign(.serif)
        }
    }
}
