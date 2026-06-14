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

struct PatternPad {
    let gradient: LinearGradient
    let sfSymbol: String
}

private let pads: [PatternPad] = [
    PatternPad(gradient: GlobalData.shared.clear30Gradient,    sfSymbol: "leaf.fill"),
    PatternPad(gradient: GlobalData.shared.claireGradient,     sfSymbol: "sparkles"),
    PatternPad(gradient: GlobalData.shared.meditationGradient, sfSymbol: "moon.stars.fill"),
    PatternPad(gradient: GlobalData.shared.symptomCardGradient,sfSymbol: "sun.max.fill")
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in self?.activeCell = nil }
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
            await MainActor.run { activeCell = nil }
            try? await Task.sleep(nanoseconds: UInt64(0.1 * 1e9))
        }
        if Task.isCancelled { return }
        await MainActor.run { phase = .awaitingInput }
    }

    func stop() { playbackTask?.cancel() }
}

// MARK: - Pad

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
        let pad = pads[index]
        let active = engine.activeCell == index
        let wrong = engine.wrongCell == index
        return Button {
            engine.handleTap(index)
        } label: {
            ZStack {
                Circle().fill(.white.opacity(active ? 0.75 : 0.25))
                Circle().fill(pad.gradient).padding(GlobalData.shared.cardSpacing / 2)
                Circle().fill(.white).padding(GlobalData.shared.cardSpacing * 1.5)
                    .shadow(color: .white.opacity(active ? 0.75 : 0), radius: 18)
                    .overlay {
                        Image(systemName: pad.sfSymbol)
                            .resizable().aspectRatio(contentMode: .fit)
                            .padding(GlobalData.shared.cardSpacing * 2.5)
                            .foregroundStyle(pad.gradient)
                    }
            }
            .frame(width: size, height: size)
            .scaleEffect(active ? 1.08 : (wrong ? 0.95 : 1.0))
            .animation(.easeOut(duration: 0.18), value: active)
            .animation(.easeOut(duration: 0.18), value: wrong)
        }
        .modifier(DefaultButtonStyle(shadow: false))
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

    init(intensity: CravingIntensity, mode: GameMode,
         onLevelComplete: @escaping (GameResult) -> Void,
         onExit: @escaping (GameResult) -> Void) {
        self.intensity = intensity
        self.mode = mode
        self.onLevelComplete = onLevelComplete
        self.onExit = onExit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GameTopBar(
                title: "Pattern",
                subtitle: mode.isInfinite ? "Endless · watch then repeat" : "\(GameLevels.band(mode.levelValue)) · watch then repeat",
                mode: mode,
                gradient: intensity.gradient,
                onQuit: { engine.stop(); onExit(engine.makeResult(intensity: intensity, completed: false)) }
            )
            .padding(.horizontal, GlobalData.shared.horizontalPadding)
            .padding(.bottom, GlobalData.shared.cardSpacing)

            statusRow
                .padding(.horizontal, GlobalData.shared.horizontalPadding)
                .padding(.bottom, GlobalData.shared.cardSpacing * 2)

            ZStack {
                PatternPadView(engine: engine)
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
        .overlay { GameIntroOverlay(text: GameQuotes.intro(for: intensity)) }
        .onAppear { engine.start(mode: mode) }
        .onDisappear {
            levelCompleteTask?.cancel()
            engine.stop()
        }
        .onChange(of: engine.phase) { _, phase in
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

    private var statusRow: some View {
        HStack(spacing: GlobalData.shared.cardSpacing) {
            VStack(alignment: .leading, spacing: 2) {
                TinyText(text: "Score").opacity(0.5)
                Text("\(engine.score)")
                    .font(.custom("Lexend", size: 25).weight(.medium))
                    .contentTransition(.numericText())
                    .foregroundStyle(intensity.gradient)
                    .animation(.snappy, value: engine.score)
            }
            Spacer()
            phaseChip
        }
    }

    @ViewBuilder
    private var phaseChip: some View {
        switch engine.phase {
        case .idle, .watching: chip("eye", "Watch")
        case .awaitingInput:   chip("hand.tap", "Your turn")
        case .levelCleared:    chip("checkmark.seal.fill", "Cleared!")
        case .failure:         chip("exclamationmark.circle", "Retry")
        }
    }

    private func chip(_ icon: String, _ text: String) -> some View {
        HStack(spacing: GlobalData.shared.cardSpacing / 2) {
            Image(systemName: icon)
            TinyText(text: text)
        }
        .foregroundColor(.clear30Text)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.clear30Button))
    }

    @ViewBuilder
    private var footer: some View {
        if engine.phase == .failure {
            HStack(spacing: GlobalData.shared.cardSpacing) {
                pill("Try again", filled: true) { GlobalData.shared.lightImpact(); engine.restart() }
                pill("End", filled: false) {
                    GlobalData.shared.mediumImpact()
                    engine.stop()
                    onExit(engine.makeResult(intensity: intensity, completed: false))
                }
            }
        } else {
            pill("I'm good — end", filled: false) {
                GlobalData.shared.mediumImpact()
                engine.stop()
                onExit(engine.makeResult(intensity: intensity, completed: false))
            }
        }
    }

    private func pill(_ text: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            SmallText(text: text)
                .foregroundColor(filled ? .white : .clear30Text)
                .frame(maxWidth: .infinity)
                .modifier(CardStyle(
                    color: filled ? .clear : .clear30Button,
                    shadowColor: .clear,
                    gradient: filled ? intensity.gradient : nil
                ))
        }
        .modifier(DefaultButtonStyle(shadow: false))
    }
}
