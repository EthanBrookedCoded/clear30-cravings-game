//
//  PostGameView.swift
//  Clear30Sandbox
//
//  Shown after a game ends. Redesign:
//   • Centered "Level N complete" hero (the one clear thing)
//   • A compact horizontal level carousel right under it — the cleared level is the
//     highlighted hero; earlier cleared levels carry a check; locked levels show a padlock
//   • Completion choreography: a checkmark pops onto the cleared level, then the next
//     level fades up from locked and becomes the selection
//   • Actions pinned to the bottom: primary "Next level" (forward by default) + "I'm all good"
//
//  Marks the cleared level complete in CravingStore on appear.
//

import SwiftUI

struct PostGameView: View {

    let result: GameResult
    var onPlayLevel: (Int) -> Void
    var onDone: () -> Void

    @State private var unlocked: Int = 1
    @State private var selected: Int = 1
    @State private var showCheck: Bool = false
    @State private var revealed: Bool = false
    @State private var confetti: Int = 0

    private var level: Int { result.levelReached }
    private var nextLevel: Int? { level < CravingStore.maxLevel ? level + 1 : nil }

    private var gameTitle: String {
        switch result.game {
        case "push_pull":      return "Push & Pull"
        case "pattern_repeat": return "Pattern"
        case "slice":          return "Slice"
        default:               return "Game"
        }
    }

    private var tint: Color {
        switch result.intensity {
        case .little:   return .clear30Blue
        case .moderate: return Color(hex: "#6B6CF4")
        case .extreme:  return Color(hex: "#F65555")
        }
    }

    private var primaryLabel: String {
        if let next = nextLevel, selected == next { return "Next level" }
        if selected == level { return "Play again" }
        return "Play level \(selected)"
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: GlobalData.shared.cardSpacing)

            hero

            levelCarousel
                .padding(.top, GlobalData.shared.cardSpacing * 1.5)

            Spacer(minLength: GlobalData.shared.cardSpacing)

            actions
                .padding(.horizontal, GlobalData.shared.horizontalPadding)
                .padding(.bottom, GlobalData.shared.cardSpacing * 2.5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, GlobalData.shared.headingTopPadding * 2)
        .modifier(ConfettiCheckIn(num: 60, radius: 280, confetti: $confetti))
        .onAppear(perform: setup)
    }

    // MARK: - Setup + choreography

    private func setup() {
        let previous = CravingStore.maxUnlockedLevel(for: result.game)
        if result.completed && !result.wasInfinite {
            CravingStore.markLevelComplete(level, for: result.game)
        }
        _ = CravingStore.recordScore(result.score, for: result.game)
        unlocked = max(previous, CravingStore.maxUnlockedLevel(for: result.game))
        selected = level

        if result.completed {
            confetti += 1
            GlobalData.shared.successHeavy()
        }

        // 1) checkmark pops onto the cleared level
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(GlobalData.shared.springAnimation) { showCheck = true }
        }
        // 2) the next level fades up and becomes the selection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
            withAnimation(GlobalData.shared.springAnimation) {
                revealed = true
                selected = nextLevel ?? level
            }
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: GlobalData.shared.cardSpacing) {
            Image(systemName: "checkmark")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 64, height: 64)
                .background(Circle().fill(result.intensity.gradient))
                .overlay(Circle().strokeBorder(.white.opacity(0.5), lineWidth: 2))
                .shadow(color: .clear30Shadow, radius: 8, y: 4)

            VStack(spacing: GlobalData.shared.cardSpacing / 2) {
                Heading2(text: "Level \(level) complete 🎉")
                SmallText(text: "\(gameTitle) · scored \(result.score)").opacity(0.5)
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, GlobalData.shared.horizontalPadding)
    }

    // MARK: - Level carousel

    private var levelCarousel: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: GlobalData.shared.cardSpacing / 1.4) {
                    ForEach(1...CravingStore.maxLevel, id: \.self) { lvl in
                        levelCell(lvl).id(lvl)
                    }
                }
                .padding(.horizontal, GlobalData.shared.horizontalPadding)
                .padding(.vertical, GlobalData.shared.cardSpacing)
            }
            .onAppear {
                DispatchQueue.main.async {
                    withAnimation(.none) { proxy.scrollTo(level, anchor: .center) }
                }
            }
        }
    }

    private func levelCell(_ lvl: Int) -> some View {
        let isSelected = lvl == selected
        let isCleared  = lvl <= level
        let isNext     = lvl == nextLevel
        let locked     = lvl > unlocked
        let dimNext    = isNext && !revealed
        let showBadge  = (lvl == level) ? showCheck : (isCleared && !isSelected)
        let cellOpacity: Double = dimNext ? 0.35 : (locked ? 0.5 : 1)

        return Button {
            guard !locked && !dimNext else { return }
            GlobalData.shared.lightImpact()
            withAnimation(GlobalData.shared.springAnimation) { selected = lvl }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(isSelected ? AnyShapeStyle(result.intensity.gradient) : AnyShapeStyle(Color.clear30Button))
                    .overlay {
                        if !isSelected {
                            RoundedRectangle(cornerRadius: 15)
                                .strokeBorder(isCleared ? tint.opacity(0.4) : Color.clear30OpacityGray, lineWidth: 1)
                        }
                    }

                if locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.clear30Text.opacity(0.3))
                } else {
                    Text("\(lvl)")
                        .font(.custom("Lexend", size: 17).weight(.semibold))
                        .foregroundColor(isSelected ? .white : .clear30Text)
                }
            }
            .frame(width: 52, height: 52)
            .scaleEffect(isSelected ? 1.12 : 1)
            .shadow(color: isSelected ? .clear30Shadow : .clear, radius: 8, y: 4)
            .opacity(cellOpacity)
            .overlay(alignment: .topTrailing) {
                if showBadge {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(.white)
                        .frame(width: 17, height: 17)
                        .background(Circle().fill(tint))
                        .offset(x: 5, y: -5)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .modifier(DefaultButtonStyle(shadow: false, transition: false))
        .disabled(locked || dimNext)
    }

    // MARK: - Actions

    private var actions: some View {
        VStack(spacing: GlobalData.shared.cardSpacing) {
            Button {
                GlobalData.shared.mediumImpact()
                onPlayLevel(selected)
            } label: {
                SmallText(text: primaryLabel)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .modifier(CardStyle(gradient: result.intensity.gradient))
            }
            .modifier(DefaultButtonStyle(shadow: false))

            Button {
                GlobalData.shared.mediumImpact()
                onDone()
            } label: {
                HStack(spacing: GlobalData.shared.cardSpacing / 2) {
                    Image(systemName: "checkmark").foregroundStyle(GlobalData.shared.clear30Gradient)
                    SmallText(text: "I'm all good")
                }
                .frame(maxWidth: .infinity)
                .modifier(CardStyle(
                    color: .clear30Button,
                    outlineGradient: GlobalData.shared.clear30Gradient,
                    outlineWidth: 1.5,
                    outlineOpacity: 0.25
                ))
            }
            .modifier(DefaultButtonStyle(shadow: false))
        }
    }
}
