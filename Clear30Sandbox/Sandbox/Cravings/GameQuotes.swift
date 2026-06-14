//
//  GameQuotes.swift
//  Clear30Sandbox
//
//  Shared copy pools for the craving games. Reward quotes show on level
//  completion; encouragement quotes show inside Push & Pull during play;
//  intro lines show as a quick response when a game opens.
//
//  SANDBOX: in the real app these would likely be server-driven / remote
//  config so copy can change without an app release.
//

import Foundation

enum GameQuotes {

    // Shown on level completion (confetti moment).
    static let rewards: [String] = [
        "That's real growth 🌳",
        "You're building momentum ⚡️",
        "Every rep counts 💪",
        "Crushing it 🛠️",
        "Keep shining 🌟",
        "Effort adds up 🧩",
        "Look at you go 🚀",
        "Strong move 💚",
        "You showed up — that matters",
        "One step closer to clear"
    ]

    // Shown mid-game in Push & Pull (3 per session).
    static let encouragement: [String] = [
        "The urge fades. You don't.",
        "You're choosing the life you want.",
        "Future you is grateful right now.",
        "This feeling is temporary.",
        "You're stronger than the craving.",
        "Every 'no' rewires your brain.",
        "Clarity is worth the discomfort.",
        "You've got nothing to prove to a craving.",
        "Riding the wave — it always passes.",
        "Your goals are bigger than this moment."
    ]

    // Shown on the breathing reward overlay (calm, meditative tone).
    static let breathingRewards: [String] = [
        "Slower breath, clearer mind.",
        "That's your nervous system, reset.",
        "Calm is a skill — you just practiced it.",
        "You gave yourself this moment. It counts.",
        "The craving got quieter, didn't it?",
        "Stillness looks good on you.",
        "One steady breath at a time.",
        "You showed up for yourself today."
    ]

    // Quick response as a game opens, keyed loosely by intensity.
    static func intro(for intensity: CravingIntensity) -> String {
        switch intensity {
        case .little:   return "Catch it early — this'll be quick."
        case .moderate: return "Let's give your mind something to hold."
        case .extreme:  return "We've got this. Right now, together."
        }
    }

    static func randomReward() -> String { rewards.randomElement() ?? "Nice work" }
    static func randomEncouragement() -> String { encouragement.randomElement() ?? "Keep going" }
    static func randomBreathingReward() -> String { breathingRewards.randomElement() ?? "Nicely done" }
}
