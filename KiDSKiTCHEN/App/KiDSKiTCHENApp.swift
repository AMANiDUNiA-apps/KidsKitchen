//
//  KiDSKiTCHENApp.swift
//  KiDSKiTCHEN
//
//  Created by Joscha Amani Gaber on 10.01.26.
//

import SwiftUI

@main
struct KiDSKiTCHENApp: App {
    /// Einzige Quelle fürs Splash-Ausblenden — ein Timer, kein Wettlauf mit
    /// Datenladen (Rezepte stehen sofort aus dem Seed bereit, s. RecipeListViewModel).
    @State private var showSplash = true
    @State private var settings: ThemeSettings = .shared

    init() {
        // iOS 26: NavigationBar komplett transparent — kein Frosted-Hintergrund,
        // der animierte MeshGradient scheint vollständig durch.
        let clear = UINavigationBarAppearance()
        clear.configureWithTransparentBackground()
        clear.shadowColor = .clear
        UINavigationBar.appearance().standardAppearance   = clear
        UINavigationBar.appearance().compactAppearance    = clear
        UINavigationBar.appearance().scrollEdgeAppearance = clear

        #if DEBUG
        // Selbst-Check Wochen-Key „nächste Woche" (kein Testtarget im Projekt, s. Datei).
        KKWeekKeyDebugCheck.run()
        // Selbst-Check eigene Themes + App-Erscheinung (BRIEF-kk-themes-eigene-vorlagen).
        KKThemeSettingsDebugCheck.run()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                if showSplash {
                    SplashScreenView()
                        .transition(.opacity)
                }
            }
            .task {
                // Abgebrochener Task (Scene weg) darf showSplash nicht mehr anfassen —
                // `try?` würde die CancellationError schlucken und trotzdem ausblenden.
                guard (try? await Task.sleep(for: .seconds(1.2))) != nil else { return }
                withAnimation(.easeInOut(duration: 0.4)) { showSplash = false }
            }
            // Typo-Standard (Jay, 3.7.): Serifen global, Mono nur für IDs/Code
            .fontDesign(.serif)
            // App-Erscheinung außen (System/Hell/Dunkel) — echter App-Root
            // (Team-Runde v2 #7). Default System (nil = folgt dem Gerät).
            .preferredColorScheme(settings.appearanceMode.colorScheme)
        }
    }
}
