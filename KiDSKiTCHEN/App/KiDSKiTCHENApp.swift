//
//  KiDSKiTCHENApp.swift
//  KiDSKiTCHEN
//
//  Created by Joscha Amani Gaber on 10.01.26.
//

import SwiftUI

@main
struct KiDSKiTCHENApp: App {

    init() {
        // iOS 26: NavigationBar komplett transparent — kein Frosted-Hintergrund,
        // der animierte MeshGradient scheint vollständig durch.
        let clear = UINavigationBarAppearance()
        clear.configureWithTransparentBackground()
        clear.shadowColor = .clear
        UINavigationBar.appearance().standardAppearance   = clear
        UINavigationBar.appearance().compactAppearance    = clear
        UINavigationBar.appearance().scrollEdgeAppearance = clear
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Typo-Standard (Jay, 3.7.): Serifen global, Mono nur für IDs/Code
                .fontDesign(.serif)
        }
    }
}
