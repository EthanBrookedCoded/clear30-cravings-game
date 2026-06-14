//
//  PushPullGame.swift
//  Clear30Sandbox
//
//  "A little" craving — the calm game. Swipe craving cues UP (push away),
//  resilience cues DOWN (pull close). Starts on Easy.
//
//  Difficulty scales by card count + swipe precision rather than speed —
//  a timer would fight the calm intent of the lowest-intensity game.
//  3 encouragement quotes pop up during each level. Push = slow shrink +
//  fade; Pull = grow toward you + fade.
//

import SwiftUI

struct PushPullCard: Identifiable, Equatable {
    enum Kind { case cannabis, resilience }
    enum Icon: Equatable {
        case sfSymbol(String)
        case asset(String)   // template-rendered image asset, tinted with the card gradient
    }
    let id = UUID()
    let kind: Kind
    let label: String
    let icon: Icon

    // Cannabis cues now use the imported cannabis icon set, tinted with the
    // orange symptom gradient. Labels re-themed to match each icon.
    static let cannabis: [PushPullCard] = [
        .init(kind: .cannabis, label: "Dispensary",   icon: .asset("CannabisDispensary")),
        .init(kind: .cannabis, label: "Bong",         icon: .asset("CannabisBong")),
        .init(kind: .cannabis, label: "Home grow",    icon: .asset("CannabisPlant")),
        .init(kind: .cannabis, label: "The stash",    icon: .asset("CannabisJar")),
        .init(kind: .cannabis, label: "CBD",          icon: .asset("CannabisCBD")),
        .init(kind: .cannabis, label: "Getting high", icon: .asset("CannabisPerson")),
        .init(kind: .cannabis, label: "Chasing it",   icon: .asset("CannabisSearch")),
        .init(kind: .cannabis, label: "The brand",    icon: .asset("CannabisBadge"))
    ]
    static let resilience: [PushPullCard] = [
        .init(kind: .resilience, label: "Career", icon: .sfSymbol("briefcase.fill")),
        .init(kind: .resilience, label: "Family", icon: .sfSymbol("person.2.fill")),
        .init(kind: .resilience, label: "Mental clarity", icon: .sfSymbol("brain.head.profile")),
        .init(kind: .resilience, label: "Health", icon: .sfSymbol("heart.fill")),
        .init(kind: .resilience, label: "Money saved", icon: .sfSymbol("dollarsign.circle.fill")),
        .init(kind: .resilience, label: "Better sleep", icon: .sfSymbol("moon.stars.fill")),
        .init(kind: .resilience, label: "Sharper focus", icon: .sfSymbol("scope")),
        .init(kind: .resilience, label: "Connection", icon: .sfSymbol("hands.sparkles.fill"))
    ]

    static func deck(count: Int) -> [PushPullCard] {
        var pool = (cannabis + resilience).shuffled()
        while pool.count < count { pool += (cannabis + resilience).shuffled() }
        return Array(pool.prefix(count))
    }
}

// MARK: - Engine

@Observable
final class PushPullEngine {

    var deck: [PushPullCard] = []
    var topOffset: CGSize = .zero
    var topScale: CGFloat = 1
    var topOpacity: Double = 1
    var feedbackText: String? = nil
    var correctCount: Int = 0
    var streak: Int = 0
    var maxStreak: Int = 0
    var startedAt = Date()
    var cleared = false

    var mode: GameMode = .level(1)
    var cardsToClear: Int = 10
    var threshold: CGFloat = 110

    // Quote popups (3 per level)
    var quoteText: String? = nil
    private var quoteMilestones: [Int] = []

    func start(mode: GameMode) {
        self.mode = mode
        let level = mode.isInfinite ? 6 : mode.levelValue
        cardsToClear = mode.isInfinite ? 999 : 8 + Int(GameLevels.fraction(level) * 6)
        threshold = 110 - GameLevels.fraction(level) * 30
        let deckSize = mode.isInfinite ? 40 : cardsToClear
        deck = PushPullCard.deck(count: deckSize)
        correctCount = 0; streak = 0; maxStreak = 0
        startedAt = Date(); cleared = false
        topOffset = .zero; topScale = 1; topOpacity = 1

        let target = mode.isInfinite ? 12 : cardsToClear
        quoteMilestones = [target / 4, target / 2, (target * 3) / 4].filter { $0 > 0 }
    }

    func restart() { start(mode: mode) }

    func onDragChanged(_ value: DragGesture.Value) {
        topOffset = CGSize(width: 0, height: value.translation.height)
    }

    func onDragEnded(_ value: DragGesture.Value, screenHeight: CGFloat) {
        guard let top = deck.first else { return }
        let dy = value.translation.height
        switch (top.kind, dy) {
        case (.cannabis, ..<(-threshold)):   commit(direction: .up, screenHeight: screenHeight)
        case (.resilience, threshold...):    commit(direction: .down, screenHeight: screenHeight)
        default:                             snapBack(card: top)
        }
    }

    private enum Direction { case up, down }

    private func commit(direction: Direction, screenHeight: CGFloat) {
        GlobalData.shared.lightImpact()
        feedbackText = nil
        correctCount += 1
        streak += 1
        maxStreak = max(maxStreak, streak)

        if quoteMilestones.contains(correctCount) {
            quoteText = GameQuotes.randomEncouragement()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { [weak self] in self?.quoteText = nil }
        }

        // Push = slow shrink + fade up; Pull = grow toward you + fade.
        let duration = 0.55
        withAnimation(.easeInOut(duration: duration)) {
            if direction == .up {
                topOffset = CGSize(width: 0, height: -screenHeight * 0.5)
                topScale = 0.4
            } else {
                topOffset = CGSize(width: 0, height: screenHeight * 0.2)
                topScale = 1.5
            }
            topOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            guard let self else { return }
            if !self.deck.isEmpty { self.deck.removeFirst() }
            self.topOffset = .zero; self.topScale = 1; self.topOpacity = 1
            // Infinite mode: refill the deck so cards never run out.
            if self.mode.isInfinite && self.deck.count < 5 {
                self.deck += PushPullCard.deck(count: 20)
            }
            // Level mode: clear when target reached or deck exhausted. Infinite never clears here.
            if !self.mode.isInfinite,
               self.correctCount >= self.cardsToClear || self.deck.isEmpty {
                GlobalData.shared.successHeavy()
                self.cleared = true
            }
        }
    }

    private func snapBack(card: PushPullCard) {
        GlobalData.shared.mediumImpact()
        streak = 0
        feedbackText = card.kind == .cannabis ? "Swipe up to push it away" : "Swipe down to pull it closer"
        withAnimation(GlobalData.shared.springAnimation) { topOffset = .zero; topScale = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in self?.feedbackText = nil }
    }

    func makeResult(intensity: CravingIntensity, completed: Bool) -> GameResult {
        GameResult(
            game: "push_pull",
            intensity: intensity,
            score: correctCount,
            durationSeconds: Date().timeIntervalSince(startedAt),
            maxStreak: maxStreak,
            levelReached: mode.levelValue,
            completed: completed,
            wasInfinite: mode.isInfinite
        )
    }
}

// MARK: - Card visual

struct PushPullCardView: View {
    let card: PushPullCard

    private var gradient: LinearGradient {
        card.kind == .cannabis ? GlobalData.shared.symptomCardGradient : GlobalData.shared.clear30Gradient
    }

    @ViewBuilder private var iconView: some View {
        switch card.icon {
        case .sfSymbol(let name):
            Image(systemName: name)
                .resizable().aspectRatio(contentMode: .fit)
                .frame(width: 44)
                .foregroundStyle(gradient)
        case .asset(let name):
            // White line-art asset rendered as a template so it picks up the
            // orange gradient, matching the SF-symbol look on the white circle.
            Image(name)
                .renderingMode(.template)
                .resizable().aspectRatio(contentMode: .fit)
                .frame(width: 46, height: 46)
                .foregroundStyle(gradient)
        }
    }

    var body: some View {
        VStack(spacing: GlobalData.shared.cardSpacing) {
            ZStack {
                Circle().fill(.white.opacity(0.25)).frame(width: 110, height: 110)
                Circle().fill(.white).frame(width: 90, height: 90)
                    .shadow(color: .white.opacity(0.5), radius: 8)
                    .overlay { iconView }
            }
            .padding(.top, GlobalData.shared.cardSpacing * 2)

            VStack(spacing: GlobalData.shared.cardSpacing / 2) {
                SmallText(text: card.label).foregroundColor(.white)
                TinyText(text: card.kind == .cannabis ? "Push it away" : "Pull it close")
                    .foregroundColor(.white.opacity(0.75))
            }
            .padding(.bottom, GlobalData.shared.cardSpacing * 2)
        }
        .frame(maxWidth: .infinity)
        .modifier(CardStyle(
            gradient: gradient,
            outlineGradient: GlobalData.shared.whiteGradient,
            outlineWidth: 2,
            outlineOpacity: 0.5
        ))
    }
}

// MARK: - Game

struct PushPullGameView: CravingGameView {

    let intensity: CravingIntensity
    let mode: GameMode
    var onLevelComplete: (GameResult) -> Void
    var onExit: (GameResult) -> Void

    @State private var engine = PushPullEngine()

    init(intensity: CravingIntensity, mode: GameMode,
         onLevelComplete: @escaping (GameResult) -> Void,
         onExit: @escaping (GameResult) -> Void) {
        self.intensity = intensity
        self.mode = mode
        self.onLevelComplete = onLevelComplete
        self.onExit = onExit
    }

    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .leading, spacing: 0) {
                GameTopBar(
                    title: "Push & Pull",
                    subtitle: mode.isInfinite ? "Endless · up = push, down = pull" : "\(GameLevels.band(mode.levelValue)) · up = push, down = pull",
                    mode: mode,
                    gradient: intensity.gradient,
                    onQuit: { onExit(engine.makeResult(intensity: intensity, completed: false)) }
                )
                .padding(.horizontal, GlobalData.shared.horizontalPadding)
                .padding(.bottom, GlobalData.shared.cardSpacing)

                progressDots
                    .padding(.horizontal, GlobalData.shared.horizontalPadding)
                    .padding(.bottom, GlobalData.shared.cardSpacing)

                Spacer(minLength: 0)

                ZStack {
                    behindCard
                    topCard(screenHeight: geo.size.height)
                }
                .padding(.horizontal, GlobalData.shared.horizontalPadding)
                .frame(maxWidth: .infinity)

                Spacer(minLength: 0)

                instructionPill
                    .padding(.horizontal, GlobalData.shared.horizontalPadding)
                    .padding(.bottom, GlobalData.shared.cardSpacing * 2)
            }
            .padding(.top, GlobalData.shared.headingTopPadding * 2)
        }
        .overlay { GameIntroOverlay(text: GameQuotes.intro(for: intensity)) }
        .overlay { quoteOverlay }
        .onAppear { engine.start(mode: mode) }
        .onChange(of: engine.cleared) { _, done in
            if done { onLevelComplete(engine.makeResult(intensity: intensity, completed: true)) }
        }
    }

    @ViewBuilder
    private var progressDots: some View {
        if !mode.isInfinite {
            HStack(spacing: 4) {
                ForEach(0..<engine.cardsToClear, id: \.self) { i in
                    Circle()
                        .fill(i < engine.correctCount ? Color.clear30Text.opacity(0.75) : Color.clear30Text.opacity(0.25))
                        .frame(width: 6, height: 6)
                }
            }
        } else {
            TinyText(text: "Cleared: \(engine.correctCount)").opacity(0.5)
        }
    }

    @ViewBuilder
    private var behindCard: some View {
        if engine.deck.count > 1 {
            PushPullCardView(card: engine.deck[1])
                .scaleEffect(0.94).opacity(0.5).offset(y: 12)
        }
    }

    @ViewBuilder
    private func topCard(screenHeight: CGFloat) -> some View {
        if let top = engine.deck.first {
            PushPullCardView(card: top)
                .scaleEffect(engine.topScale)
                .opacity(engine.topOpacity)
                .offset(engine.topOffset)
                .rotationEffect(.degrees(Double(engine.topOffset.height) / 30))
                .gesture(
                    DragGesture()
                        .onChanged { engine.onDragChanged($0) }
                        .onEnded { engine.onDragEnded($0, screenHeight: screenHeight) }
                )
                .overlay(alignment: .top) {
                    if let text = engine.feedbackText {
                        TinyText(text: text)
                            .foregroundColor(.white)
                            .padding(.vertical, GlobalData.shared.cardSpacing / 2)
                            .padding(.horizontal, GlobalData.shared.cardSpacing)
                            .background(RoundedRectangle(cornerRadius: GlobalData.shared.cornerRadius / 1.5).fill(Color.black.opacity(0.5)))
                            .offset(y: -GlobalData.shared.cardSpacing * 2)
                            .transition(.opacity)
                    }
                }
        }
    }

    @ViewBuilder
    private var quoteOverlay: some View {
        if let quote = engine.quoteText {
            VStack {
                Spacer()
                SmallText(text: quote)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, GlobalData.shared.cardSpacing)
                    .padding(.horizontal, GlobalData.shared.cardSpacing * 1.5)
                    .background(Capsule().fill(intensity.gradient))
                    .shadow(color: .clear30Shadow, radius: 16, y: 4)
                Spacer().frame(height: GlobalData.shared.cardSpacing * 6)
            }
            .allowsHitTesting(false)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(GlobalData.shared.springAnimation, value: engine.quoteText)
        }
    }

    private var instructionPill: some View {
        HStack(spacing: GlobalData.shared.cardSpacing / 2) {
            Image(systemName: "arrow.up").opacity(0.5)
            TinyText(text: "Push weed up · pull goals down").opacity(0.5)
            Image(systemName: "arrow.down").opacity(0.5)
        }
        .frame(maxWidth: .infinity)
    }
}
