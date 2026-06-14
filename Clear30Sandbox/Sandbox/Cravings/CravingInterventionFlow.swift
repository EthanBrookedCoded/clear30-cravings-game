//
//  CravingInterventionFlow.swift
//  Clear30Sandbox
//
//  Coordinator for the cravings flow.
//  intensity → (game opens on Easy) → level complete → "still craving?"
//  Breathing tile bypasses games entirely.
//
//  SANDBOX: when copied into the real app, swap the analytics no-ops for
//  Logger.logEvent(...) and CravingStore for userInfo cached values.
//

import SwiftUI

// MARK: - Intensity (3 levels — one per game)

enum CravingIntensity: String, CaseIterable, Identifiable, Codable {
    case little
    case moderate
    case extreme

    var id: String { rawValue }

    var title: String {
        switch self {
        case .little:   return "A little"
        case .moderate: return "Moderate"
        case .extreme:  return "Extreme"
        }
    }

    var sfSymbol: String {
        switch self {
        case .little:   return "leaf.fill"
        case .moderate: return "circle.grid.2x2.fill"
        case .extreme:  return "flame.fill"
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .little:   return GlobalData.shared.clear30Gradient
        case .moderate: return GlobalData.shared.claireGradient
        case .extreme:  return GlobalData.shared.redGradient
        }
    }

    var gameName: String {
        switch self {
        case .little:   return "push_pull"
        case .moderate: return "pattern_repeat"
        case .extreme:  return "slice"
        }
    }
}

// MARK: - Game mode + level helpers

enum GameMode: Equatable {
    case level(Int)   // 1...12
    case infinite

    var levelValue: Int {
        if case .level(let n) = self { return n }
        return 0
    }
    var isInfinite: Bool { self == .infinite }
}

enum GameLevels {
    static let count = 12

    static func band(_ level: Int) -> String {
        switch level {
        case 1...4: return "Easy"
        case 5...8: return "Normal"
        default:    return "Hard"
        }
    }

    /// 0...1 difficulty fraction across the 12 levels.
    static func fraction(_ level: Int) -> Double {
        let clamped = max(1, min(count, level))
        return Double(clamped - 1) / Double(count - 1)
    }
}

// MARK: - Game Result

struct GameResult {
    let game: String
    let intensity: CravingIntensity
    let score: Int
    let durationSeconds: Double
    let maxStreak: Int
    let levelReached: Int
    let completed: Bool
    var wasInfinite: Bool = false
}

// MARK: - Session

@Observable
final class CravingSession {

    enum Step: Equatable {
        case intensity
        case playing(CravingIntensity, GameMode)
        case post(GameResult)
        case breathing(BreathingStyle)
        case breathingPicker

        static func == (lhs: Step, rhs: Step) -> Bool {
            switch (lhs, rhs) {
            case (.intensity, .intensity): return true
            case (.playing(let a, let am), .playing(let b, let bm)): return a == b && am == bm
            case (.post(let a), .post(let b)): return a.game == b.game && a.score == b.score && a.levelReached == b.levelReached
            case (.breathing(let a), .breathing(let b)): return a == b
            case (.breathingPicker, .breathingPicker): return true
            default: return false
            }
        }
    }

    var step: Step = .intensity
    let sessionID: String = UUID().uuidString
    let startedAt: Date = Date()

    /// Pick the starting mode for an intensity. Extreme resumes Slice at the highest unlocked level
    /// per Fred: maximum engagement when the user needs it most.
    func selectIntensity(_ intensity: CravingIntensity) {
        if intensity == .extreme {
            let unlocked = CravingStore.maxUnlockedLevel(for: intensity.gameName)
            step = .playing(intensity, .level(unlocked))
        } else {
            step = .playing(intensity, .level(1))
        }
    }

    func openBreathing() { step = .breathing(.circle) }

    /// Both onLevelComplete and onExit from games route here — post-game is now the
    /// single destination, and PostGameView handles the "still craving?" + level grid UX.
    func finishGame(_ result: GameResult) { step = .post(result) }

    /// "Yes — restart same level" from the post-game still-craving row.
    func restartSameLevel(after result: GameResult) {
        if result.wasInfinite {
            step = .playing(result.intensity, .infinite)
        } else {
            step = .playing(result.intensity, .level(result.levelReached))
        }
    }

    /// Picking a specific level/Infinite tile from the post-game grid.
    func playLevel(_ mode: GameMode, intensity: CravingIntensity) {
        step = .playing(intensity, mode)
    }

    func tryAnother() { step = .intensity }
    func showBreathingPicker() { step = .breathingPicker }
}

// MARK: - Coordinator

struct CravingInterventionFlow: View {

    var onDismiss: () -> Void
    var onOpenClaire: (String) -> Void

    @State private var session = CravingSession()

    private var animation: Animation { GlobalData.shared.springAnimation.speed(0.9) }

    var body: some View {
        ZStack {
            Color.clear30Background.ignoresSafeArea()

            switch session.step {
            case .intensity:
                IntensitySelectView(
                    onSelect: { session.selectIntensity($0) },
                    onBreathe: { session.openBreathing() }
                )
                .transition(.opacity)

            case .playing(let intensity, let mode):
                gameView(for: intensity, mode: mode)
                    .id(stepID(.playing(intensity, mode)))   // force fresh view on level/mode change
                    .transition(.opacity)

            case .post(let result):
                PostGameView(
                    result: result,
                    onRestartSameLevel: { session.restartSameLevel(after: result) },
                    onPickLevel: { mode in session.playLevel(mode, intensity: result.intensity) },
                    onTryAnother: { session.tryAnother() },
                    onClaire: {
                        let prompt = "I just used the craving tool. My craving was \(result.intensity.title). Can we talk through it?"
                        onOpenClaire(prompt)
                    },
                    onBreathe: { session.openBreathing() },
                    onDone: { onDismiss() },
                    onRate: { _ in }
                )
                .transition(.opacity)

            case .breathing(let style):
                BreathingView(
                    style: style,
                    onDone: { session.showBreathingPicker() }
                )
                .transition(.opacity)

            case .breathingPicker:
                BreathingPickerView(
                    onPick: { session.step = .breathing($0) },
                    onDone: { onDismiss() }
                )
                .transition(.opacity)
            }
        }
        .animation(animation, value: stepID(session.step))
    }

    @ViewBuilder
    private func gameView(for intensity: CravingIntensity, mode: GameMode) -> some View {
        let onLevelComplete: (GameResult) -> Void = { session.finishGame($0) }
        let onExit:          (GameResult) -> Void = { session.finishGame($0) }

        switch intensity {
        case .little:
            PushPullGameView(intensity: intensity, mode: mode, onLevelComplete: onLevelComplete, onExit: onExit)
        case .moderate:
            PatternRepeatGameView(intensity: intensity, mode: mode, onLevelComplete: onLevelComplete, onExit: onExit)
        case .extreme:
            SliceGameView(intensity: intensity, mode: mode, onLevelComplete: onLevelComplete, onExit: onExit)
        }
    }

    private func stepID(_ step: CravingSession.Step) -> String {
        switch step {
        case .intensity: return "intensity"
        case .playing(let i, let m): return "playing_\(i.rawValue)_\(m.isInfinite ? "inf" : "\(m.levelValue)")"
        case .post(let r): return "post_\(r.game)_\(r.levelReached)_\(r.score)"
        case .breathing(let s): return "breathing_\(s.rawValue)"
        case .breathingPicker: return "breathingPicker"
        }
    }
}

// MARK: - Game protocol

protocol CravingGameView: View {
    init(intensity: CravingIntensity,
         mode: GameMode,
         onLevelComplete: @escaping (GameResult) -> Void,
         onExit: @escaping (GameResult) -> Void)
}
