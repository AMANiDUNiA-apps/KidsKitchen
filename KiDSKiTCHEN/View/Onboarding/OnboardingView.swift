//
//  OnboardingView.swift
//  KiDSKiTCHEN
//
//  Erst-Start-Onboarding: wenige kindgerechte Seiten, letzte Seite = Diät-/Ausschluss-
//  Auswahl über die existierenden Filter-Modelle (wirkt danach direkt auf die Rezeptliste).
//  UI-Muster nach Kavsoft „CustomIntroPage" portiert und an KidsKitchen angepasst:
//  Fortschritts-Kapseln + Vor/Zurück übernommen; die Scatter-Swap-Physik der Vorlage
//  bewusst zu einer ruhigen Icon-Transition reduziert (Kinder-App, „keine Effekt-Show",
//  Reduce-Motion beachtet). Einmalig via AppStorage, aus „Mehr" erneut aufrufbar.
//

import SwiftUI

struct OnboardingView: View {
    /// Wird aufgerufen, wenn das Onboarding abgeschlossen ist.
    var onFinish: () -> Void

    @State private var index = 0
    @State private var prefs = Preferences.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pages = OnboardingPage.pages
    private var page: OnboardingPage { pages[index] }
    private var isLast: Bool { index == pages.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            backButton

            // Flexibler Bereich: Illustration oder Diät-/Ausschluss-Auswahl.
            ZStack {
                if page.isPreferences {
                    preferencesArea
                        .transition(.opacity)
                } else {
                    illustration
                        .transition(reduceMotion ? .opacity
                                    : .scale(scale: 0.85).combined(with: .opacity))
                        .id(page.id)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            footer
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    // MARK: Zurück-Knopf
    private var backButton: some View {
        Button {
            guard index > 0 else { return }
            move(to: index - 1)
        } label: {
            Image(systemName: "chevron.left")
                .font(.title3.bold())
                .foregroundStyle(page.tint.gradient)
                .contentShape(.rect)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
        .opacity(index > 0 ? 1 : 0)
        .disabled(index == 0)
        .accessibilityLabel("Zurück")
    }

    // MARK: Illustration (Icon-Karte)
    private var illustration: some View {
        Image(systemName: page.symbol)
            .font(.system(size: 88))
            .foregroundStyle(.white)
            .frame(width: 150, height: 150)
            .background(page.tint.gradient, in: .rect(cornerRadius: 36))
            .background {
                RoundedRectangle(cornerRadius: 40)
                    .fill(.background)
                    .shadow(color: .primary.opacity(0.15), radius: 10, y: 6)
                    .padding(-6)
            }
            .accessibilityHidden(true)
    }

    // MARK: Diät-/Ausschluss-Auswahl (letzte Seite)
    private var preferencesArea: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ernährung")
                        .font(.system(.headline, design: .serif))
                    Picker("Ernährung", selection: $prefs.diet) {
                        ForEach(DietMode.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Weglassen")
                        .font(.system(.headline, design: .serif))
                    Text("Tipp an, was raus soll — du kannst das später jederzeit ändern.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 110), spacing: 10)],
                        spacing: 10
                    ) {
                        ForEach(ExclusionPreset.all) { preset in
                            presetChip(preset)
                        }
                    }
                }
            }
            .padding(.top, 8)
        }
    }

    private func presetChip(_ preset: ExclusionPreset) -> some View {
        let isOn = preset.ingredientNames.allSatisfy { prefs.excluded.contains($0) }
        return Button {
            prefs.setExcluded(preset.ingredientNames, excluded: !isOn)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isOn ? "checkmark.circle.fill" : preset.symbol)
                Text(preset.label)
                    .font(.system(.subheadline, design: .serif).weight(.semibold))
                Spacer(minLength: 0)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .foregroundStyle(isOn ? .white : .primary)
            .background(isOn ? AnyShapeStyle(page.tint.gradient)
                             : AnyShapeStyle(Color(.secondarySystemGroupedBackground)),
                        in: .rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: Fußzeile (Fortschritt + Titel + Weiter)
    private var footer: some View {
        VStack(spacing: 14) {
            HStack(spacing: 4) {
                ForEach(pages.indices, id: \.self) { i in
                    Capsule()
                        .fill((i == index ? page.tint : .gray).gradient)
                        .frame(width: i == index ? 24 : 5, height: 5)
                }
            }

            Text(page.title)
                .font(.system(.title2, design: .serif).bold())
                .multilineTextAlignment(.center)

            Text(page.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                if isLast { onFinish() } else { move(to: index + 1) }
            } label: {
                Text(isLast ? "Los geht's!" : "Weiter")
                    .font(.system(.body, design: .serif).weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(page.tint.gradient, in: .capsule)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: 360)
        .frame(maxWidth: .infinity)
    }

    private func move(to newIndex: Int) {
        guard pages.indices.contains(newIndex) else { return }
        if reduceMotion {
            index = newIndex
        } else {
            withAnimation(.bouncy(duration: 0.5)) { index = newIndex }
        }
    }
}

#Preview {
    OnboardingView {}
        .fontDesign(.serif)
}
