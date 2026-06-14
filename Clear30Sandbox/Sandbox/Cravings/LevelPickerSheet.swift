//
//  LevelPickerSheet.swift
//  Clear30Sandbox
//
//  Shared in-game chrome reused by all three games:
//   • GameTopBar       — title + read-only level chip + quit button
//   • GameIntroOverlay — quick-response capsule that fades in/out on open
//   • LevelRewardOverlay — confetti card shown on level completion
//
//  Level selection itself happens on the post-game screen now; the dedicated
//  picker sheet that used to live here was removed.
//

import SwiftUI

// MARK: - Shared in-game top bar (level shown as read-only chip + quit)

struct GameTopBar: View {

    let title: String
    let subtitle: String
    let mode: GameMode
    let gradient: LinearGradient
    var onQuit: () -> Void

    var body: some View {
        HStack(spacing: GlobalData.shared.cardSpacing) {
            VStack(alignment: .leading, spacing: 2) {
                SmallText(text: title)
                TinyText(text: subtitle).opacity(0.5)
            }
            Spacer()

            // Read-only level chip — level selection now happens on the post-game screen.
            HStack(spacing: GlobalData.shared.cardSpacing / 4) {
                Image(systemName: mode.isInfinite ? "infinity" : "flag.fill")
                TinyText(text: mode.isInfinite ? "Endless" : "Lvl \(mode.levelValue)")
            }
            .foregroundColor(.clear30Text)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.clear30Button))

            Button {
                GlobalData.shared.lightImpact()
                onQuit()
            } label: {
                Image(systemName: "xmark")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 14)
                    .foregroundColor(.clear30Text.opacity(0.5))
            }
            .modifier(DefaultButtonStyle(shadow: false))
        }
    }
}

// MARK: - Quick-response intro overlay (fades in/out on game open)

struct GameIntroOverlay: View {

    let text: String
    @State private var visible = false

    var body: some View {
        VStack {
            if visible {
                SmallText(text: text)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, GlobalData.shared.cardSpacing)
                    .padding(.horizontal, GlobalData.shared.cardSpacing * 1.5)
                    .background(Capsule().fill(GlobalData.shared.clear30Gradient))
                    .shadow(color: .clear30Shadow, radius: 16, y: 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, GlobalData.shared.cardSpacing * 4)
            }
            Spacer()
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(GlobalData.shared.springAnimation) { visible = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(GlobalData.shared.springAnimation) { visible = false }
            }
        }
    }
}

// MARK: - Per-level reward overlay (confetti + quote)

struct LevelRewardOverlay: View {

    let quote: String

    var body: some View {
        VStack(spacing: GlobalData.shared.cardSpacing) {
            Image(systemName: "checkmark.seal.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 64)
                .foregroundStyle(GlobalData.shared.clear30Gradient)
            Heading3(text: quote)
                .multilineTextAlignment(.center)
        }
        .padding(GlobalData.shared.cardSpacing * 2)
        .frame(maxWidth: .infinity)
        .modifier(CardStyle(
            color: .clear30Button,
            outlineGradient: GlobalData.shared.clear30Gradient,
            outlineWidth: 1.5,
            outlineOpacity: 0.5
        ))
        .padding(.horizontal, GlobalData.shared.horizontalPadding)
        .transition(.scale.combined(with: .opacity))
    }
}
