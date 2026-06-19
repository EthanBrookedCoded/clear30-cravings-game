//
//  PatternRepeatGame.swift
//  Clear30Sandbox
//
//  "Some" craving — Simon-style memory. Starts on Easy (level 1).
//  Each level: reproduce a growing sequence up to the level's target
//  length, at the level's speed. Clear it → confetti + quote → "still
//  craving?". 12 levels (Easy/Normal/Hard) plus Infinite mode.
//

import SwiftUI

// Fixed gradient per pad position; the glyphs are picked at random from this pool each
// time the game opens, so the four tiles vary session to session.
private let padGradients: [LinearGradient] = [
    GlobalData.shared.clear30Gradient,
    GlobalData.shared.meditationGradient,
    GlobalData.shared.claireGradient,
    GlobalData.shared.symptomCardGradient
]

private let patternIconPool: [String] = [
    "leaf.fill", "drop.fill", "moon.fill", "sun.max.fill", "sparkles",
    "flame.fill", "snowflake", "cloud.fill", "bolt.fill", "star.fill",
    "heart.fill", "wind"
]

// MARK: - Engine

@Observable
final class PatternEngine {

    enum Phase: Equatable { case idle, watching, awaitingInput, levelCleared, failure }

    var phase: Phase = .idle
    var sequence: [Int] = []
    var inputIndex: Int = 0
    var activeCell: Int? = nil
    var wrongCell: Int? = nil
    var score: Int = 0
    var maxLength: Int = 0
    var startedAt = Date()
    var padSymbols: [String] = []     // the four glyphs for this session (random)
    var padColorOrder: [Int] = [0, 1, 2, 3]   // which gradient each pad uses (shuffled)

    var mode: GameMode = .level(1)
    var rewardQuote: String = ""

    let cellCount = 4
    private var playbackTask: Task<Void, Never>? = nil

    private var level: Int { mode.levelValue }

    /// Target sequence length that clears the current level.
    private var clearLength: Int { min(8, 3 + level / 2) }

    private var speed: Double {
        if mode.isInfinite {
            let ramp = min(1.0, Double(sequence.count) / 14.0)
            return max(0.18, 0.6 - ramp * 0.42)
        }
        return max(0.18, 0.6 - GameLevels.fraction(level) * 0.42)
    }

    func start(mode: GameMode) {
        self.mode = mode
        sequence = []; inputIndex = 0; score = 0; maxLength = 0
        startedAt = Date()
        // Re-randomize the glyphs AND the colours each start (so a failed retry looks fresh).
        padSymbols = Array(patternIconPool.shuffled().prefix(cellCount))
        padColorOrder = Array(0..<cellCount).shuffled()
        nextRound()
    }

    func restart() { start(mode: mode) }

    func nextRound() {
        sequence.append(Int.random(in: 0..<cellCount))
        inputIndex = 0
        phase = .watching
        playbackTask?.cancel()
        playbackTask = Task { await playSequence() }
    }

    func handleTap(_ index: Int) {
        guard phase == .awaitingInput, inputIndex < sequence.count else { return }
        if index == sequence[inputIndex] {
            GlobalData.shared.lightImpact()
            activeCell = index
            // Hold the highlight briefly; the view animates it in AND out (see padCell).
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) { [weak self] in
                guard let self else { return }
                if self.activeCell == index { self.activeCell = nil }
            }
            score += 10 * max(1, level)
            inputIndex += 1
            if inputIndex >= sequence.count {
                roundCompleted()
            }
        } else {
            GlobalData.shared.mediumImpact()
            wrongCell = index
            phase = .failure
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in self?.wrongCell = nil }
        }
    }

    private func roundCompleted() {
        maxLength = max(maxLength, sequence.count)
        if !mode.isInfinite && sequence.count >= clearLength {
            phase = .levelCleared
            rewardQuote = GameQuotes.randomReward()
            GlobalData.shared.successHeavy()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in self?.nextRound() }
        }
    }

    func makeResult(intensity: CravingIntensity, completed: Bool) -> GameResult {
        GameResult(
            game: "pattern_repeat",
            intensity: intensity,
            score: score,
            durationSeconds: Date().timeIntervalSince(startedAt),
            maxStreak: maxLength,
            levelReached: mode.levelValue,
            completed: completed,
            wasInfinite: mode.isInfinite
        )
    }

    private func playSequence() async {
        let s = speed
        try? await Task.sleep(nanoseconds: UInt64(0.4 * 1e9))
        for index in sequence {
            if Task.isCancelled { return }
            await MainActor.run { activeCell = index }
            try? await Task.sleep(nanoseconds: UInt64(s * 1e9))
            await MainActor.run { activeCell = nil }   // view animates the fade-out (see padCell)
            try? await Task.sleep(nanoseconds: UInt64(0.14 * 1e9))
        }
        if Task.isCancelled { return }
        await MainActor.run { phase = .awaitingInput }
    }

    func stop() { playbackTask?.cancel() }
}

// MARK: - Pad

// Immediate press feedback (scales down the instant a finger lands) — much more responsive
// feeling than a tap gesture, and Button registers taps reliably.
private struct PadButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1)
            .animation(.easeOut(duration: 0.10), value: configuration.isPressed)
    }
}

struct PatternPadView: View {
    @Bindable var engine: PatternEngine

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let cell = (side - GlobalData.shared.cardSpacing) / 2
            VStack(spacing: GlobalData.shared.cardSpacing) {
                HStack(spacing: GlobalData.shared.cardSpacing) { padCell(0, cell); padCell(1, cell) }
                HStack(spacing: GlobalData.shared.cardSpacing) { padCell(2, cell); padCell(3, cell) }
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func padCell(_ index: Int, _ size: CGFloat) -> some View {
        let colorIndex = index < engine.padColorOrder.count ? engine.padColorOrder[index] : index
        let gradient = padGradients[colorIndex]
        let symbol = index < engine.padSymbols.count ? engine.padSymbols[index] : "circle.fill"
        let active = engine.activeCell == index
        let wrong = engine.wrongCell == index
        // Inactive tiles are dimmed back (faded); the highlighted tile is full opacity with a
        // white sheen so it lights up. Both animate in AND out via the token.
        let awake = engine.phase == .awaitingInput
        let cellOpacity: Double = (active || awake) ? 1 : 0.4
        let animToken = [engine.activeCell ?? -1, engine.wrongCell ?? -1, awake ? 1 : 0]

        return Button {
            engine.handleTap(index)
        } label: {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(gradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(LinearGradient(colors: [.white.opacity(0.35), .clear],
                                             startPoint: .top, endPoint: .center))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .strokeBorder(.white.opacity(0.4), lineWidth: 1.5)
                )
                // White sheen that lights up the active tile (animates in/out).
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(.white)
                        .opacity(active ? 0.35 : 0)
                )
                .overlay(
                    Image(systemName: symbol)
                        .font(.system(size: size * 0.3, weight: .semibold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                )
                .frame(width: size, height: size)
                .scaleEffect(active ? 1.06 : (wrong ? 0.94 : 1.0))
                .opacity(cellOpacity)
                .shadow(color: active ? .white.opacity(0.6) : .clear30Shadow,
                        radius: active ? 20 : 8, y: active ? 0 : 4)
                .animation(.easeInOut(duration: 0.22), value: animToken)
        }
        .buttonStyle(PadButtonStyle())
        .disabled(engine.phase != .awaitingInput)
    }
}

// MARK: - Game

struct PatternRepeatGameView: CravingGameView {

    let intensity: CravingIntensity
    let mode: GameMode
    var onLevelComplete: (GameResult) -> Void
    var onExit: (GameResult) -> Void

    @State private var engine = PatternEngine()
    @State private var confetti = 0
    @State private var levelCompleteTask: Task<Void, Never>?
    @State private var started = false
    @State private var currentMode: GameMode
    @State private var showLevelPicker = false
    @State private var padScale: CGFloat = 1
    let showIntro: Bool

    init(intensity: CravingIntensity, mode: GameMode, showIntro: Bool,
         onLevelComplete: @escaping (GameResult) -> Void,
         onExit: @escaping (GameResult) -> Void) {
        self.intensity = intensity
        self.mode = mode
        self.showIntro = showIntro
        self.onLevelComplete = onLevelComplete
        self.onExit = onExit
        _currentMode = State(initialValue: mode)
        _started = State(initialValue: !showIntro)
    }

    var body: some View {
        ZStack {
            gameContent

            if !started {
                GameIntroView(
                    title: "Pattern",
                    symbol: "square.grid.2x2.fill",
                    blurb: "A memory game — watch, then tap it back.",
                    lines: [
                        .init(icon: "eye", text: "Watch the tiles light up in order"),
                        .init(icon: "hand.tap", text: "Repeat the sequence from memory"),
                        .init(icon: "chart.line.uptrend.xyaxis", text: "It grows each round — clear the level to win")
                    ],
                    gradient: intensity.gradient
                ) { startGame() }
                .transition(.opacity)
            }
        }
        .onAppear { if !showIntro { startGame() } }
        .sheet(isPresented: $showLevelPicker) {
            LevelPickerSheet(
                gameTitle: "Pattern",
                gameName: "pattern_repeat",
                current: currentMode.levelValue,
                gradient: intensity.gradient
            ) { picked in
                currentMode = .level(picked)
                engine.start(mode: currentMode)
            }
        }
        .onDisappear {
            levelCompleteTask?.cancel()
            engine.stop()
        }
        .onChange(of: engine.phase) { _, phase in
            if phase == .awaitingInput { pulsePads() }
            if phase == .levelCleared {
                confetti += 1
                levelCompleteTask?.cancel()
                levelCompleteTask = Task {
                    try? await Task.sleep(nanoseconds: 2_200_000_000)
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        onLevelComplete(engine.makeResult(intensity: intensity, completed: true))
                    }
                }
            }
        }
    }

    private func startGame() {
        withAnimation(GlobalData.shared.springAnimation) { started = true }
        engine.start(mode: currentMode)
    }

    // Dip the whole pad grid and spring it back — the "it's your turn" cue.
    private func pulsePads() {
        withAnimation(.easeIn(duration: 0.16)) { padScale = 0.9 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.5)) { padScale = 1 }
        }
    }

    private var gameContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                ScoreBadge(score: engine.score, gradient: intensity.gradient)
                Spacer()
                LevelChip(mode: currentMode, onSelect: currentMode.isInfinite ? nil : { showLevelPicker = true })
                GameQuitButton { engine.stop(); onExit(engine.makeResult(intensity: intensity, completed: false)) }
            }
            .padding(.horizontal, GlobalData.shared.horizontalPadding)
            .padding(.bottom, GlobalData.shared.cardSpacing * 2)

            ZStack {
                // When it's the user's turn the whole grid dips and springs back up — a
                // motion cue that it's time to tap (replaces the old "Your turn" tag).
                PatternPadView(engine: engine)
                    .scaleEffect(padScale)
                    .padding(.horizontal, GlobalData.shared.horizontalPadding)

                if engine.phase == .levelCleared {
                    LevelRewardOverlay(quote: engine.rewardQuote)
                }
            }
            .frame(maxHeight: .infinity)
            .modifier(ConfettiPop(num: 50, radius: 220, confetti: $confetti))

            footer
                .padding(.horizontal, GlobalData.shared.horizontalPadding)
                .padding(.vertical, GlobalData.shared.cardSpacing * 2)
        }
        .padding(.top, GlobalData.shared.headingTopPadding * 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // Always present (so failing doesn't shift the board) — just fades in on failure.
    // Quitting is handled by the X in the top bar.
    private var footer: some View {
        Button {
            GlobalData.shared.lightImpact()
            engine.restart()
        } label: {
            SmallText(text: "Try again")
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .modifier(CardStyle(gradient: intensity.gradient))
        }
        .modifier(DefaultButtonStyle(shadow: false))
        .opacity(engine.phase == .failure ? 1 : 0)
        .allowsHitTesting(engine.phase == .failure)
        .animation(.easeInOut(duration: 0.2), value: engine.phase)
    }
}
