//
//  PostGameView.swift
//  Clear30Sandbox
//
//  Single screen the user lands on after a game ends. Combines:
//   • encouragement headline + support line (intensity-tinted)
//   • all-time best row + "new best" banner overlay
//   • once-per-game-ever feedback monster rating card
//   • "Still craving?" Yes / A little / No row (Fred's "let them keep
//     going until it passes")
//   • per-game level grid with padlocks (post-game level picker)
//   • secondary actions: try another game · breathe · Claire · done
//
//  Marks the just-cleared level as complete in CravingStore on appear.
//

import SwiftUI

struct PostGameView: View {

    let result: GameResult
    var onRestartSameLevel: () -> Void
    var onPickLevel: (GameMode) -> Void
    var onTryAnother: () -> Void
    var onClaire: () -> Void
    var onBreathe: () -> Void
    var onDone:    () -> Void
    var onRate: (Int) -> Void

    @State private var rating: Int? = nil
    @State private var confetti: Int = 0
    @State private var bestConfetti: Int = 0

    @State private var showRating: Bool = false
    @State private var isNewBest: Bool = false
    @State private var bestScore: Int = 0
    @State private var showBestBanner: Bool = false

    @State private var maxUnlocked: Int = 1
    @State private var justUnlocked: Int? = nil   // for unlock animation on the next-level tile
    @State private var pulseGrid: Bool = false    // "A little" still-craving feedback

    private var headline: String {
        switch result.intensity {
        case .little:   return "Caught it early 🌳"
        case .moderate: return "Worked through it 💪"
        case .extreme:  return "You made it through 🔥"
        }
    }

    private var supportLine: String {
        switch result.intensity {
        case .little:   return "That's how it gets easier — every rep counts."
        case .moderate: return "The craving lost some bandwidth. That's the win."
        case .extreme:  return "You own what happens next. Cravings don't get a vote."
        }
    }

    // Intensity-tinted achievement badge — anchors the header and ties the
    // screen to the craving's intensity (matches the breathing reward medallion).
    private var headerBadge: some View {
        Image(systemName: "checkmark")
            .font(.system(size: 26, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 60, height: 60)
            .background(Circle().fill(result.intensity.gradient))
            .overlay(Circle().strokeBorder(.white.opacity(0.5), lineWidth: 2))
            .shadow(color: .clear30Shadow, radius: 8, y: 4)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: GlobalData.shared.cardSpacing) {
                    headerBadge
                    VStack(alignment: .leading, spacing: GlobalData.shared.cardSpacing / 2) {
                        Heading2(text: headline)
                        SmallText(text: supportLine).opacity(0.5)
                    }
                }
                .padding(.bottom, GlobalData.shared.cardSpacing * 1.5)

                bestScoreRow
                    .padding(.bottom, GlobalData.shared.cardSpacing * 1.5)

                if showRating {
                    ratingCard
                        .padding(.bottom, GlobalData.shared.cardSpacing * 1.5)
                        .transition(.scale.combined(with: .opacity))
                }

                stillCravingRow
                    .padding(.bottom, GlobalData.shared.cardSpacing * 1.5)

                levelsPanel
                    .padding(.bottom, GlobalData.shared.cardSpacing * 2)

                actionButtons
            }
            .padding(.horizontal, GlobalData.shared.horizontalPadding)
            .padding(.top, GlobalData.shared.headingTopPadding * 2)
            .padding(.bottom, GlobalData.shared.cardSpacing * 3)
        }
        .overlay(alignment: .top) { newBestBanner }
        .modifier(ConfettiPop(confetti: $confetti))
        .modifier(ConfettiCheckIn(num: 70, radius: 300, confetti: $bestConfetti))
        .onAppear(perform: setup)
    }

    // MARK: - Setup (run once on appear)

    private func setup() {
        // Mark the just-cleared level complete BEFORE reading best/unlock,
        // so the grid + display reflect the newly-unlocked level immediately.
        let previousUnlocked = CravingStore.maxUnlockedLevel(for: result.game)
        if result.completed && !result.wasInfinite {
            let newMax = CravingStore.markLevelComplete(result.levelReached, for: result.game)
            if newMax > previousUnlocked { justUnlocked = newMax }
        }
        maxUnlocked = CravingStore.maxUnlockedLevel(for: result.game)

        // Best score: read previous, write new, reflect immediately if higher.
        let previousBest = CravingStore.bestScore(for: result.game)
        let recordedNewBest = CravingStore.recordScore(result.score, for: result.game)
        bestScore = max(previousBest, result.score)
        isNewBest = recordedNewBest   // only true when there was a prior best to beat

        showRating = !CravingStore.hasShownRating(for: result.game)
        if showRating { CravingStore.markRatingShown(for: result.game) }

        if result.completed {
            confetti += 1
            GlobalData.shared.successHeavy()
        }

        if isNewBest {
            withAnimation(GlobalData.shared.springAnimation) { showBestBanner = true }
            bestConfetti += 1
            GlobalData.shared.successHeavy()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(GlobalData.shared.springAnimation) { showBestBanner = false }
            }
        }
    }

    // MARK: - All-time best row

    private var bestScoreRow: some View {
        HStack(spacing: GlobalData.shared.cardSpacing) {
            Image(systemName: "trophy.fill")
                .resizable().aspectRatio(contentMode: .fit).frame(width: 16)
                .foregroundStyle(GlobalData.shared.clear30Gradient)
            HStack(spacing: GlobalData.shared.cardSpacing / 4) {
                TinyText(text: "This session").opacity(0.5)
                SmallText(text: "\(result.score)")
            }
            Spacer()
            HStack(spacing: GlobalData.shared.cardSpacing / 4) {
                TinyText(text: "Best").opacity(0.5)
                SmallText(text: "\(bestScore)")
                    .foregroundStyle(GlobalData.shared.clear30Gradient)
            }
        }
        .padding(.vertical, GlobalData.shared.cardSpacing / 1.5)
        .padding(.horizontal, GlobalData.shared.cardSpacing)
        .background(
            RoundedRectangle(cornerRadius: GlobalData.shared.cornerRadius / 1.5)
                .fill(Color.clear30Button)
        )
        .overlay(
            RoundedRectangle(cornerRadius: GlobalData.shared.cornerRadius / 1.5)
                .strokeBorder(GlobalData.shared.clear30Gradient, lineWidth: 1)
                .opacity(0.25)
        )
    }

    // MARK: - New best banner

    @ViewBuilder
    private var newBestBanner: some View {
        if showBestBanner {
            HStack(spacing: GlobalData.shared.cardSpacing / 2) {
                Image(systemName: "trophy.fill").foregroundColor(.white)
                SmallText(text: "New all-time best! 🏆").foregroundColor(.white)
            }
            .padding(.vertical, GlobalData.shared.cardSpacing / 2)
            .padding(.horizontal, GlobalData.shared.cardSpacing * 1.5)
            .background(Capsule().fill(GlobalData.shared.clear30Gradient))
            .shadow(color: Color.clear30Green.opacity(0.5), radius: 24)
            .padding(.top, GlobalData.shared.cardSpacing)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: - Still craving? row

    private var stillCravingRow: some View {
        VStack(alignment: .leading, spacing: GlobalData.shared.cardSpacing / 2) {
            TinyText(text: "Still craving?").opacity(0.5)
            HStack(spacing: GlobalData.shared.cardSpacing / 2) {
                stillCravingButton(text: "Yes", icon: "arrow.clockwise", filled: true) {
                    GlobalData.shared.mediumImpact()
                    onRestartSameLevel()
                }
                stillCravingButton(text: "A little", icon: "circle.lefthalf.filled", filled: false) {
                    GlobalData.shared.lightImpact()
                    pulseLevelsPanel()
                }
                stillCravingButton(text: "No", icon: "checkmark", filled: false) {
                    GlobalData.shared.mediumImpact()
                    onDone()
                }
            }
        }
    }

    private func stillCravingButton(text: String, icon: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: GlobalData.shared.cardSpacing / 4) {
                Image(systemName: icon)
                SmallText(text: text)
            }
            .foregroundColor(filled ? .white : .clear30Text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, GlobalData.shared.cardSpacing)
            .background(
                RoundedRectangle(cornerRadius: GlobalData.shared.cornerRadius / 1.5)
                    .fill(filled ? AnyShapeStyle(result.intensity.gradient) : AnyShapeStyle(Color.clear30Button))
            )
            .overlay {
                if !filled {
                    RoundedRectangle(cornerRadius: GlobalData.shared.cornerRadius / 1.5)
                        .strokeBorder(result.intensity.gradient, lineWidth: 1)
                        .opacity(0.25)
                }
            }
        }
        .modifier(DefaultButtonStyle(shadow: false))
    }

    private func pulseLevelsPanel() {
        withAnimation(.easeOut(duration: 0.2)) { pulseGrid = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeIn(duration: 0.3)) { pulseGrid = false }
        }
    }

    // MARK: - Levels panel

    private var levelsPanel: some View {
        VStack(alignment: .leading, spacing: GlobalData.shared.cardSpacing / 2) {
            HStack {
                TinyText(text: "\(gameTitle) levels").opacity(0.5)
                Spacer()
                if maxUnlocked < CravingStore.maxLevel {
                    TinyText(text: "Unlocked: \(maxUnlocked) / \(CravingStore.maxLevel)").opacity(0.5)
                } else {
                    TinyText(text: "Mastered ✨").foregroundStyle(GlobalData.shared.clear30Gradient)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: GlobalData.shared.cardSpacing / 2), count: 4),
                      spacing: GlobalData.shared.cardSpacing / 2) {
                ForEach(1...CravingStore.maxLevel, id: \.self) { level in
                    levelCell(level)
                }
                if CravingStore.isInfiniteUnlocked(for: result.game) {
                    infiniteCell
                }
            }
            .scaleEffect(pulseGrid ? 1.04 : 1.0)
            .animation(GlobalData.shared.springAnimation, value: pulseGrid)
        }
    }

    private var gameTitle: String {
        switch result.game {
        case "push_pull":      return "Push & Pull"
        case "pattern_repeat": return "Pattern"
        case "slice":          return "Slice"
        default:               return "Game"
        }
    }

    private func levelCell(_ level: Int) -> some View {
        let unlocked = level <= maxUnlocked
        let isCurrent = level == result.levelReached
        let isJustUnlocked = justUnlocked == level
        return Button {
            guard unlocked else { return }
            GlobalData.shared.lightImpact()
            onPickLevel(.level(level))
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: GlobalData.shared.cornerRadius / 2)
                    .fill(isCurrent
                          ? AnyShapeStyle(result.intensity.gradient)
                          : AnyShapeStyle(Color.clear30Button))
                if unlocked {
                    Text("\(level)")
                        .font(.custom("Lexend", size: 17).weight(.medium))
                        .foregroundColor(isCurrent ? .white : .clear30Text)
                } else {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.clear30Text.opacity(0.25))
                }
            }
            .frame(height: GlobalData.shared.cardSpacing * 3.5)
            .overlay {
                if isJustUnlocked {
                    RoundedRectangle(cornerRadius: GlobalData.shared.cornerRadius / 2)
                        .strokeBorder(GlobalData.shared.clear30Gradient, lineWidth: 2)
                } else if unlocked && !isCurrent {
                    RoundedRectangle(cornerRadius: GlobalData.shared.cornerRadius / 2)
                        .strokeBorder(GlobalData.shared.clear30Gradient, lineWidth: 1)
                        .opacity(0.25)
                }
            }
            .opacity(unlocked ? 1 : 0.5)
            .scaleEffect(isJustUnlocked ? 1.05 : 1.0)
            .animation(GlobalData.shared.springAnimation, value: isJustUnlocked)
        }
        .modifier(DefaultButtonStyle(shadow: false, transition: false))
        .disabled(!unlocked)
    }

    private var infiniteCell: some View {
        Button {
            GlobalData.shared.mediumImpact()
            onPickLevel(.infinite)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: GlobalData.shared.cornerRadius / 2)
                    .fill(GlobalData.shared.clear30Gradient)
                Image(systemName: "infinity").foregroundColor(.white)
            }
            .frame(height: GlobalData.shared.cardSpacing * 3.5)
        }
        .modifier(DefaultButtonStyle(shadow: false, transition: false))
    }

    // MARK: - Action buttons (bottom)

    private var actionButtons: some View {
        VStack(spacing: GlobalData.shared.cardSpacing) {
            GradientActionButton(
                text: "Try a different game",
                sfSymbol: "square.grid.2x2.fill",
                gradient: GlobalData.shared.claireGradient
            ) {
                GlobalData.shared.lightImpact()
                onTryAnother()
            }

            HStack(spacing: GlobalData.shared.cardSpacing) {
                secondary(text: "Breathe", icon: "wind", iconGradient: GlobalData.shared.meditationGradient) {
                    GlobalData.shared.lightImpact()
                    onBreathe()
                }
                secondary(text: "Claire", icon: "sparkles", iconGradient: GlobalData.shared.claireGradient) {
                    GlobalData.shared.mediumImpact()
                    onClaire()
                }
            }

            secondary(text: "I'm done", icon: "checkmark", iconGradient: GlobalData.shared.clear30Gradient) {
                GlobalData.shared.mediumImpact()
                onDone()
            }
        }
    }

    private func secondary(text: String, icon: String, iconGradient: LinearGradient, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: GlobalData.shared.cardSpacing / 2) {
                Image(systemName: icon)
                    .foregroundStyle(iconGradient)
                SmallText(text: text)
            }
            .frame(maxWidth: .infinity)
            .modifier(CardStyle(
                color: .clear30Button,
                outlineGradient: iconGradient,
                outlineWidth: 1.5,
                outlineOpacity: 0.25
            ))
        }
        .modifier(DefaultButtonStyle(shadow: false))
    }

    // MARK: - Rating card

    private var ratingCard: some View {
        HStack(alignment: .center, spacing: GlobalData.shared.cardSpacing) {
            Image(rating == nil ? "FeedbackMonsterHungry" : "FeedbackMonsterFull")
                .resizable().aspectRatio(contentMode: .fit).frame(width: 72)
                .transition(.opacity)
                .animation(GlobalData.shared.springAnimation, value: rating)

            VStack(alignment: .leading, spacing: GlobalData.shared.cardSpacing / 2) {
                speechBubble(text: rating == nil ? "I LOVE feedback!" : "Yum! Thanks 💛")
                starRow
            }

            Spacer(minLength: 0)
        }
        .modifier(CardStyle(
            color: .clear30Button,
            shadowColor: .clear30Shadow,
            outlineGradient: GlobalData.shared.clear30Gradient,
            outlineWidth: 1.5,
            outlineOpacity: 0.5
        ))
    }

    private var starRow: some View {
        HStack(spacing: GlobalData.shared.cardSpacing / 2) {
            ForEach(1...5, id: \.self) { value in
                let filled = (rating ?? 0) >= value
                Button {
                    GlobalData.shared.lightImpact()
                    withAnimation(GlobalData.shared.springAnimation) { rating = value }
                    onRate(value)
                } label: {
                    Image(systemName: filled ? "star.fill" : "star")
                        .resizable().aspectRatio(contentMode: .fit).frame(width: 26)
                        .foregroundStyle(filled
                                         ? AnyShapeStyle(GlobalData.shared.clear30Gradient)
                                         : AnyShapeStyle(Color.clear30Text.opacity(0.25)))
                        .scaleEffect(filled ? 1.0 : 0.9)
                }
                .modifier(DefaultButtonStyle(shadow: false))
            }
        }
    }

    private func speechBubble(text: String) -> some View {
        SmallText(text: text)
            .foregroundColor(.clear30Text)
            .padding(.vertical, GlobalData.shared.cardSpacing / 2)
            .padding(.horizontal, GlobalData.shared.cardSpacing)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: GlobalData.shared.cornerRadius / 1.5)
                        .fill(Color.clear30Button)
                    RoundedRectangle(cornerRadius: GlobalData.shared.cornerRadius / 1.5)
                        .strokeBorder(Color.clear30OpacityGray, lineWidth: 1)
                }
            )
            .overlay(alignment: .bottomLeading) {
                Triangle()
                    .fill(Color.clear30Button)
                    .frame(width: 14, height: 10)
                    .offset(x: -6, y: 6)
                    .overlay(
                        Triangle()
                            .stroke(Color.clear30OpacityGray, lineWidth: 1)
                            .frame(width: 14, height: 10)
                            .offset(x: -6, y: 6)
                    )
            }
            .shadow(color: .clear30Shadow, radius: 8, y: 2)
    }
}

// MARK: - Speech bubble tail

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX + 4, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
