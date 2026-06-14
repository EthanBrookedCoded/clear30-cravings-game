//
//  IntensitySelectView.swift
//  Clear30Sandbox
//
//  Step 1. Three intensity tiles (A little / Moderate / Extreme) — one
//  per game — and a separate "Just breathe" tile below. Mirrors the
//  hero-card pattern from Support2.cravingHero (white-circle icon on a
//  gradient card, second-person subtitle).
//

import SwiftUI

struct IntensitySelectView: View {

    var onSelect: (CravingIntensity) -> Void
    var onBreathe: () -> Void

    // Strongest at top, closest to thumb.
    private let order: [CravingIntensity] = [.extreme, .moderate, .little]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Heading3(text: "How strong is the craving?")
                    .padding(.bottom, GlobalData.shared.cardSpacing / 2)
                SmallText(text: "Tap one. There's no wrong answer.")
                    .opacity(0.5)
                    .padding(.bottom, GlobalData.shared.cardSpacing * 2)

                VStack(spacing: GlobalData.shared.cardSpacing) {
                    ForEach(order) { intensity in
                        tile(intensity)
                    }
                }

                sectionDivider
                    .padding(.top, GlobalData.shared.cardSpacing * 2)
                    .padding(.bottom, GlobalData.shared.cardSpacing)

                breatheTile
            }
            .padding(.horizontal, GlobalData.shared.horizontalPadding)
            .padding(.top, GlobalData.shared.headingTopPadding * 4)
            .padding(.bottom, GlobalData.shared.cardSpacing * 3)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var sectionDivider: some View {
        HStack(spacing: GlobalData.shared.cardSpacing) {
            Rectangle()
                .fill(Color.clear30Text.opacity(0.25))
                .frame(height: 1)
            TinyText(text: "Or, just slow down").opacity(0.5)
            Rectangle()
                .fill(Color.clear30Text.opacity(0.25))
                .frame(height: 1)
        }
    }

    private func tile(_ intensity: CravingIntensity) -> some View {
        Button {
            switch intensity {
            case .extreme:  GlobalData.shared.heavyImpact()
            case .moderate: GlobalData.shared.mediumImpact()
            case .little:   GlobalData.shared.lightImpact()
            }
            onSelect(intensity)
        } label: {
            HStack(spacing: GlobalData.shared.cardSpacing) {
                iconCircle(symbol: intensity.sfSymbol, gradient: intensity.gradient)
                VStack(alignment: .leading, spacing: 2) {
                    SmallText(text: intensity.title)
                    TinyText(text: subtitle(for: intensity)).opacity(0.75)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 12)
                    .foregroundColor(.white.opacity(0.75))
            }
            .modifier(CardStyle(gradient: intensity.gradient))
        }
        .modifier(DefaultButtonStyle(shadow: false))
    }

    private func subtitle(for intensity: CravingIntensity) -> String {
        switch intensity {
        case .little:   return "Catch it early"
        case .moderate: return "Work through it"
        case .extreme:  return "Right now — push past it"
        }
    }

    private var breatheTile: some View {
        Button {
            GlobalData.shared.lightImpact()
            onBreathe()
        } label: {
            HStack(spacing: GlobalData.shared.cardSpacing) {
                iconCircle(symbol: "lungs.fill", gradient: GlobalData.shared.meditationGradient)
                VStack(alignment: .leading, spacing: 2) {
                    SmallText(text: "Just breathe")
                    TinyText(text: "No game — slow it down").opacity(0.75)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 12)
                    .foregroundColor(.white.opacity(0.75))
            }
            .modifier(CardStyle(gradient: GlobalData.shared.meditationGradient))
        }
        .modifier(DefaultButtonStyle(shadow: false))
    }

    private func iconCircle(symbol: String, gradient: LinearGradient) -> some View {
        ZStack {
            Circle().fill(.white.opacity(0.25)).frame(width: 56, height: 56)
            Circle().fill(.white).frame(width: 48, height: 48)
                .shadow(color: .white.opacity(0.5), radius: 5)
                .shadow(color: .white.opacity(0.25), radius: 11)
                .overlay {
                    Image(systemName: symbol)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 22)
                        .foregroundStyle(gradient)
                }
        }
    }
}
