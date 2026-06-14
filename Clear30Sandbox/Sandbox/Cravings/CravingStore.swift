//
//  CravingStore.swift
//  Clear30Sandbox
//
//  Small persistence layer for the cravings flow, backed by UserDefaults.
//
//  SANDBOX: in the real Clear30 app, swap these for
//  userInfo.getCachedBool / setCachedBool / getCachedInt / setCachedInt
//  (or a Supabase-backed store) so best scores sync across devices.
//

import Foundation

enum CravingStore {

    private static let ratingPrefix    = "craving_rating_shown_"
    private static let bestPrefix      = "craving_best_score_"
    private static let unlockedPrefix  = "craving_max_unlocked_"
    static let maxLevel = 12

    // MARK: - Rating: once per game type

    static func hasShownRating(for game: String) -> Bool {
        UserDefaults.standard.bool(forKey: ratingPrefix + game)
    }

    static func markRatingShown(for game: String) {
        UserDefaults.standard.set(true, forKey: ratingPrefix + game)
    }

    // MARK: - All-time best per game type

    static func bestScore(for game: String) -> Int {
        UserDefaults.standard.integer(forKey: bestPrefix + game)
    }

    /// Records the score if it beats the stored best.
    /// Returns true when a new all-time best was set (and there was a prior best to beat).
    static func recordScore(_ score: Int, for game: String) -> Bool {
        let key = bestPrefix + game
        let previous = UserDefaults.standard.integer(forKey: key)
        let hadPrevious = UserDefaults.standard.object(forKey: key) != nil

        guard score > previous else { return false }
        UserDefaults.standard.set(score, forKey: key)
        return hadPrevious && previous > 0
    }

    // MARK: - Unlock progression (per game)

    /// Highest level unlocked for `game`. L1 is always unlocked.
    static func maxUnlockedLevel(for game: String) -> Int {
        let stored = UserDefaults.standard.integer(forKey: unlockedPrefix + game)
        return max(1, stored)
    }

    /// Records a level completion; bumps maxUnlocked to clearedLevel + 1 (capped at maxLevel).
    /// Returns the new maxUnlocked. Caller can compare to previous to detect "new unlock."
    @discardableResult
    static func markLevelComplete(_ clearedLevel: Int, for game: String) -> Int {
        let key = unlockedPrefix + game
        let previous = max(1, UserDefaults.standard.integer(forKey: key))
        let next = min(maxLevel, max(previous, clearedLevel + 1))
        UserDefaults.standard.set(next, forKey: key)
        return next
    }

    /// True if the user has cleared L12 for this game (i.e., infinite is unlocked).
    static func isInfiniteUnlocked(for game: String) -> Bool {
        maxUnlockedLevel(for: game) >= maxLevel
    }
}
