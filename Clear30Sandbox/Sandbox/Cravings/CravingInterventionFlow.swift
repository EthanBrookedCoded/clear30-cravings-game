//
//  CravingInterventionFlow.swift
//  Clear30Sandbox
//
//  Coordinator for the cravings flow.
//
//  Navigation (redesign):
//    hub → (game) playing → post → hub
//    hub → meditation  : opens MeditationPlayerView as a STACKED SHEET
//    hub → breathwork  : opens BreathingView as a STACKED SHEET (pre-selected cadence)
//
//  The intensity question is gone — the hub surfaces Meditations / Breathwork / Games
//  directly. Each game still maps 1:1 to a CravingIntensity (kept as the game key so the
//  three existing game views need no changes).
//
//  SANDBOX: when copied into the real app, swap the analytics no-ops for
//  Logger.logEvent(...) and CravingStore for userInfo cached values. Meditations should
//  be backed by MeditationResources(kind: .craving) (see CravingResources.swift).
//

import SwiftUI

// MARK: - Game key (one per game)

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

    // Hub display
    var gameTitle: String {
        switch self {
        case .little:   return "Push & Pull"
        case .moderate: return "Pattern"
        case .extreme:  return "Slice"
        }
    }

    var gameTileSymbol: String {
        switch self {
        case .little:   return "arrow.left.arrow.right"
        case .moderate: return "square.grid.2x2.fill"
        case .extreme:  return "scissors"
        }
    }

    /// Order shown in the games grid (gentlest → strongest).
    static var hubOrder: [CravingIntensity] { [.little, .moderate, .extreme] }
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

    enum Step {
        case hub
        case playing(CravingIntensity, GameMode, Bool)   // Bool = show the pre-game intro
        case post(GameResult)
    }

    var step: Step = .hub
    let sessionID: String = UUID().uuidString
    let startedAt: Date = Date()

    func playGame(_ intensity: CravingIntensity, level: Int, showIntro: Bool) {
        step = .playing(intensity, .level(level), showIntro)
    }

    /// Both onLevelComplete and onExit-with-completion route here.
    func finishGame(_ result: GameResult) { step = .post(result) }

    func backToHub() { step = .hub }
}

// MARK: - Coordinator

struct CravingInterventionFlow: View {

    var onDismiss: () -> Void

    @State private var session = CravingSession()
    // Stacked sheets presented on top of the hub.
    @State private var activeMeditation: CravingMeditation? = nil
    @State private var breathworkCadence: BreathingCadence? = nil

    private var animation: Animation { GlobalData.shared.springAnimation.speed(0.9) }

    var body: some View {
        ZStack {
            Color.clear30Background.ignoresSafeArea()

            switch session.step {
            case .hub:
                CravingHubView(
                    onPlayMeditation: { activeMeditation = $0 },
                    onBreathe: { breathworkCadence = $0 },
                    onPlayGame: { intensity in
                        session.playGame(intensity, level: CravingStore.maxUnlockedLevel(for: intensity.gameName), showIntro: true)
                    }
                )
                .transition(.opacity)

            case .playing(let intensity, let mode, let showIntro):
                gameView(for: intensity, mode: mode, showIntro: showIntro)
                    .id(stepID(session.step))   // force fresh view on level/mode change
                    .transition(.opacity)

            case .post(let result):
                PostGameView(
                    result: result,
                    // Replaying / advancing from the post-game skips the intro.
                    onPlayLevel: { level in session.playGame(result.intensity, level: level, showIntro: false) },
                    onDone: { session.backToHub() }
                )
                .transition(.opacity)
            }
        }
        .animation(animation, value: stepID(session.step))
        // Meditation player — stacked sheet (mirrors the real MeditationResources flow).
        .sheet(item: $activeMeditation) { med in
            MeditationPlayerView(meditation: med)
                .presentationDragIndicator(.visible)
        }
        // Breathwork — stacked sheet, opened on the chosen cadence.
        .sheet(item: $breathworkCadence) { cadence in
            BreathingView(initialCadence: cadence)
                .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private func gameView(for intensity: CravingIntensity, mode: GameMode, showIntro: Bool) -> some View {
        let onLevelComplete: (GameResult) -> Void = { session.finishGame($0) }
        // Quitting a game returns to the hub (no celebration screen for an abandoned run).
        let onExit:          (GameResult) -> Void = { _ in session.backToHub() }

        switch intensity {
        case .little:
            PushPullGameView(intensity: intensity, mode: mode, showIntro: showIntro, onLevelComplete: onLevelComplete, onExit: onExit)
        case .moderate:
            PatternRepeatGameView(intensity: intensity, mode: mode, showIntro: showIntro, onLevelComplete: onLevelComplete, onExit: onExit)
        case .extreme:
            SliceGameView(intensity: intensity, mode: mode, showIntro: showIntro, onLevelComplete: onLevelComplete, onExit: onExit)
        }
    }

    private func stepID(_ step: CravingSession.Step) -> String {
        switch step {
        case .hub: return "hub"
        case .playing(let i, let m, _): return "playing_\(i.rawValue)_\(m.isInfinite ? "inf" : "\(m.levelValue)")"
        case .post(let r): return "post_\(r.game)_\(r.levelReached)_\(r.score)"
        }
    }
}

// MARK: - Game protocol

protocol CravingGameView: View {
    init(intensity: CravingIntensity,
         mode: GameMode,
         showIntro: Bool,
         onLevelComplete: @escaping (GameResult) -> Void,
         onExit: @escaping (GameResult) -> Void)
}
