//
//  KKCookingModeView.swift
//  KiDSKiTCHEN
//
//  Kochmodus-Vollansicht (Jay-Entscheid: „Landscape pinned sheet für beim
//  Kochen"). Hochformat: ein Schritt groß, volle Fläche. Querformat: der
//  Schritt sitzt als gepinntes, inhaltshöhen-großes Sheet unten (Muster nach
//  Kavsoft „DynamicHeightSheet", hier über KKDynamicSheet.swift wiederverwendet),
//  darüber bleibt Fläche für Rezeptname/-symbol. Hält den Bildschirm wach,
//  solange diese Ansicht offen ist (kein Sperren mitten im Rezept).
//

import SwiftUI

struct KKCookingModeView: View {
    let session: KKCookingSession
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var showEndConfirm = false
    @State private var sheetUp = false

    private var isLandscape: Bool { verticalSizeClass == .compact }
    private var tint: Color { session.recipe?.category?.color ?? .orange }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            hero
            if !isLandscape {
                stepCard
                    .padding(20)
            }
            closeButton
        }
        .background(tint.opacity(0.12).ignoresSafeArea())
        .sheet(isPresented: $sheetUp) {
            stepCard
                .modifier(KKDynamicSheetContent())
        }
        .onChange(of: isLandscape, initial: true) { _, landscape in
            sheetUp = landscape
        }
        .confirmationDialog("Kochmodus beenden?", isPresented: $showEndConfirm) {
            Button("Beenden", role: .destructive) { session.stop() }
            Button("Weiterkochen", role: .cancel) {}
        }
        // Bildschirm-Wachhalten: nur solange diese Ansicht sichtbar ist.
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }

    // MARK: Hintergrund (Rezeptname + Symbol statt Foto — keine Bild-Anbindung vorhanden)
    private var hero: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: session.recipe?.category?.symbolName ?? "flame.fill")
                .font(.system(size: 64))
                .foregroundStyle(tint)
            Text(session.recipe?.name ?? "")
                .font(.system(.title2, design: .serif).bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            if isLandscape { Spacer(minLength: 160) } // Platz für das gepinnte Sheet
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var closeButton: some View {
        Button {
            showEndConfirm = true
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.title)
                .foregroundStyle(.secondary, .background)
        }
        .padding()
        .accessibilityLabel("Kochmodus beenden")
    }

    // MARK: Schritt-Karte (Hoch- und Querformat gleich, nur die Hülle unterscheidet sich)
    private var stepCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Schritt \(session.stepIndex + 1) von \(session.totalSteps)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            ProgressView(value: Double(session.stepIndex + 1), total: Double(max(session.totalSteps, 1)))
                .tint(tint)

            Text(session.currentStep?.text ?? "")
                .font(.system(.title3, design: .serif))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                Button {
                    session.back()
                } label: {
                    Label("Zurück", systemImage: "chevron.left")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(session.stepIndex == 0)

                Button {
                    session.next()
                } label: {
                    Label(session.isLastStep ? "Fertig" : "Weiter",
                          systemImage: session.isLastStep ? "checkmark" : "chevron.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(tint)
            }
            .controlSize(.large)
            .font(.system(.body, design: .serif))
        }
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.1), radius: 12, y: -2)
    }
}

/// Bindet den Sheet-Inhalt an KKDynamicSheet (inhaltshöhen-großes, gepinntes Sheet)
/// und verhindert das versehentliche Wegwischen im Kochmodus.
private struct KKDynamicSheetContent: ViewModifier {
    func body(content: Content) -> some View {
        KKDynamicSheet(animation: .smooth) { content }
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(true)
    }
}

#Preview {
    let session = KKCookingSession.shared
    session.start(.mock)
    return KKCookingModeView(session: session)
}
