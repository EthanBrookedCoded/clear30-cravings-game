//
//  CravingHubView.swift
//  Clear30Sandbox
//
//  The cravings hub. Replaces the old "How strong is the craving?" intensity step.
//  Surfaces the three techniques up front, each with its OWN visual language so
//  nothing reads like the red Cravings button on the Support tab:
//    • Meditations → a horizontal audio rail
//    • Breathwork  → a soft feature panel (cadence chosen via chips, not cards)
//    • Games       → a playful 2-up tile grid
//
//  Meditations and breathwork open as stacked sheets (see CravingInterventionFlow);
//  games swap into the flow's playing/post steps.
//

import SwiftUI

struct CravingHubView: View {

    var onPlayMeditation: (CravingMeditation) -> Void
    var onBreathe: (BreathingCadence) -> Void
    var onPlayGame: (CravingIntensity) -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, GlobalData.shared.horizontalPadding)

                meditationsSection
                    .padding(.top, GlobalData.shared.cardSpacing * 2)

                breathworkPanel
                    .padding(.horizontal, GlobalData.shared.horizontalPadding)
                    .padding(.top, GlobalData.shared.cardSpacing * 2)

                gamesSection
                    .padding(.horizontal, GlobalData.shared.horizontalPadding)
                    .padding(.top, GlobalData.shared.cardSpacing * 2)
            }
            .padding(.top, GlobalData.shared.headingTopPadding * 2)
            .padding(.bottom, GlobalData.shared.cardSpacing * 3)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: GlobalData.shared.cardSpacing / 2) {
            Heading2(text: "Cravings")
            SmallText(text: "This will pass. Pick what helps right now.").opacity(0.5)
        }
    }

    // MARK: - Meditations (audio rail)

    private var meditationsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: GlobalData.shared.cardSpacing / 2) {
                Image(systemName: "headphones").foregroundColor(.meditation1)
                SmallText(text: "Meditations")
            }
            .padding(.horizontal, GlobalData.shared.horizontalPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: GlobalData.shared.cardSpacing) {
                    ForEach(CravingMeditationLibrary.all) { med in
                        meditationCard(med)
                    }
                }
                .padding(.horizontal, GlobalData.shared.horizontalPadding)
            }
            .padding(.top, GlobalData.shared.cardSpacing)
        }
    }

    private func meditationCard(_ med: CravingMeditation) -> some View {
        Button {
            GlobalData.shared.lightImpact()
            onPlayMeditation(med)
        } label: {
            VStack(alignment: .leading, spacing: GlobalData.shared.cardSpacing / 2) {
                RoundedRectangle(cornerRadius: 18)
                    .fill(med.gradient)
                    .frame(width: 144, height: 144)
                    .overlay {
                        Image(systemName: "play.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                    .shadow(color: .clear30Shadow, radius: 8, y: 4)
                SmallText(text: med.title)
                    .frame(width: 144, alignment: .leading)
            }
        }
        .modifier(DefaultButtonStyle(shadow: false))
    }

    // MARK: - Breathwork (feature panel)
    //
    // Tapping the panel opens breathwork on the default (Calm) cadence; tapping a
    // specific cadence chip opens it pre-selected to that cadence.

    private var breathworkPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: GlobalData.shared.cardSpacing / 2) {
                Image(systemName: "wind")
                SmallText(text: "Breathwork").bold()
            }
            .padding(.bottom, GlobalData.shared.cardSpacing / 1.5)

            Heading3(text: "Slow it down")
            TinyText(text: "Guided breathing · pick your cadence")
                .opacity(0.75)
                .padding(.top, 2)

            HStack(spacing: GlobalData.shared.cardSpacing / 2) {
                ForEach(BreathingCadence.allCases) { cadence in
                    Button {
                        GlobalData.shared.lightImpact()
                        onBreathe(cadence)
                    } label: {
                        MiniText(text: "\(cadence.title) \(cadence.pattern)")
                            .foregroundColor(.white)
                            .padding(.horizontal, 11).padding(.vertical, 6)
                            .background(
                                Capsule().fill(.white.opacity(0.15))
                                    .overlay(Capsule().strokeBorder(.white.opacity(0.5), lineWidth: 1))
                            )
                    }
                    .modifier(DefaultButtonStyle(shadow: false))
                }
            }
            .padding(.top, GlobalData.shared.cardSpacing)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background {
            ZStack {
                GlobalData.shared.meditationGradient
                // concentric "breathing" motif, clipped to the card
                Circle().strokeBorder(.white.opacity(0.35), lineWidth: 2)
                    .frame(width: 160, height: 160).offset(x: 150, y: -70)
                Circle().strokeBorder(.white.opacity(0.5), lineWidth: 2)
                    .frame(width: 100, height: 100).offset(x: 135, y: -55)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .meditation1.opacity(0.3), radius: 10, y: 6)
        .contentShape(RoundedRectangle(cornerRadius: 22))
        .onTapGesture {
            GlobalData.shared.lightImpact()
            onBreathe(.calm)
        }
    }

    // MARK: - Games (2-up tile grid)

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    private var gamesSection: some View {
        VStack(alignment: .leading, spacing: GlobalData.shared.cardSpacing) {
            HStack(spacing: GlobalData.shared.cardSpacing / 2) {
                Image(systemName: "gamecontroller.fill").foregroundColor(Color(hex: "#FF8C59"))
                SmallText(text: "Games")
                Spacer()
                TinyText(text: "Ride out the urge").opacity(0.5)
            }

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(CravingIntensity.hubOrder) { intensity in
                    gameTile(intensity)
                }
            }
        }
    }

    private func gameTile(_ intensity: CravingIntensity) -> some View {
        let unlocked = CravingStore.maxUnlockedLevel(for: intensity.gameName)
        return Button {
            GlobalData.shared.mediumImpact()
            onPlayGame(intensity)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11)
                        .fill(.white.opacity(0.22))
                        .frame(width: 36, height: 36)
                    Image(systemName: intensity.gameTileSymbol)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                Spacer(minLength: GlobalData.shared.cardSpacing)
                TinyText(text: intensity.gameTitle)
                    .bold()
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                MiniText(text: "Lvl \(unlocked)/\(CravingStore.maxLevel)").opacity(0.75)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 116, alignment: .topLeading)
            .padding(13)
            .background(intensity.gradient)
            .clipShape(RoundedRectangle(cornerRadius: GlobalData.shared.cornerRadius))
            .shadow(color: .clear30Shadow, radius: 7, y: 4)
        }
        .modifier(DefaultButtonStyle(shadow: false))
    }
}
