//
//  SplashScreenView.swift
//  KiDSKiTCHEN
//
//  Kurzer Splash beim Kaltstart (Jay-Wunsch: „coole Schrift" für „KiDS KiTCHEN"),
//  cremiger Theme-Hintergrund + kräftiger rounded Display-Schnitt — reine
//  System-Schrift, keine neue Font-Dependency. Keine Netz-Zugriffe: nur ein
//  Timer, kein Warten auf Rezept-Ladevorgänge (Kinder-App-Datenschutz).
//

import SwiftUI

struct SplashScreenView: View {
    @State private var settings: ThemeSettings = .shared
    @State private var scale: CGFloat = 0.85
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            LinearGradient(colors: settings.theme.backgroundColors,
                            startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 4) {
                Text("KiDS")
                    .font(.system(size: 46, weight: .black, design: .rounded))
                Text("KiTCHEN")
                    .font(.system(size: 54, weight: .black, design: .rounded))
            }
            .foregroundStyle(settings.theme.accent)
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1
                opacity = 1
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
