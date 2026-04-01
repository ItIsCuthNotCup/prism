import Foundation

/// Fibonacci-based ad scheduler.
///
/// - First ad appears on game over #3 (game overs 1 & 2 are ad-free).
/// - After that, the gap between ads follows Fibonacci: 1, 1, 2, 3, 5, 8, 13, 21.
/// - Gap caps at 21 — once reached, ads show every 21 game overs forever.
/// - If the player hasn't played in 3+ days, everything resets.
class AdScheduler {
    static let shared = AdScheduler()

    private let defaults = UserDefaults.standard

    // UserDefaults keys
    private let gameOverCountKey = "ad_game_over_count"
    private let nextAdAtKey = "ad_next_at_game_over"
    private let fibIndexKey = "ad_fib_index"
    private let lastPlayedKey = "ad_last_played"

    // Reset the sequence if player hasn't played in this many days
    private let inactivityResetDays: Int = 3

    // Fibonacci gap never exceeds this
    private let maxGap: Int = 21

    // First ad fires on this game-over number
    private let firstAdAt: Int = 3

    private init() {
        checkInactivityReset()
    }

    /// Call this every time a game over occurs.
    /// Returns true if an ad should be shown now.
    func onGameOver() -> Bool {
        updateLastPlayed()

        let count = defaults.integer(forKey: gameOverCountKey) + 1
        defaults.set(count, forKey: gameOverCountKey)

        var nextAdAt = defaults.integer(forKey: nextAdAtKey)

        // First launch or after reset: schedule first ad at game over #3
        if nextAdAt == 0 {
            nextAdAt = firstAdAt
            defaults.set(nextAdAt, forKey: nextAdAtKey)
            defaults.set(0, forKey: fibIndexKey)
        }

        if count >= nextAdAt {
            // Show ad now. Advance to next threshold using Fibonacci gap.
            let fibIndex = defaults.integer(forKey: fibIndexKey)
            let rawGap = fibonacci(fibIndex)
            let gap = min(rawGap, maxGap)

            defaults.set(count + gap, forKey: nextAdAtKey)

            // Only advance the Fibonacci index if we haven't hit the cap
            if rawGap < maxGap {
                defaults.set(fibIndex + 1, forKey: fibIndexKey)
            }

            return true
        }

        return false
    }

    /// How many game overs until the next ad
    var gameOversUntilNextAd: Int {
        let count = defaults.integer(forKey: gameOverCountKey)
        let nextAt = defaults.integer(forKey: nextAdAtKey)
        return max(0, nextAt - count)
    }

    /// Reset everything (e.g. for testing or after purchase of "remove ads")
    func reset() {
        defaults.removeObject(forKey: gameOverCountKey)
        defaults.removeObject(forKey: nextAdAtKey)
        defaults.removeObject(forKey: fibIndexKey)
        defaults.removeObject(forKey: lastPlayedKey)
    }

    // MARK: - Private

    private func updateLastPlayed() {
        defaults.set(Date().timeIntervalSince1970, forKey: lastPlayedKey)
    }

    private func checkInactivityReset() {
        let lastPlayed = defaults.double(forKey: lastPlayedKey)
        guard lastPlayed > 0 else { return }

        let daysSince = (Date().timeIntervalSince1970 - lastPlayed) / 86400
        if daysSince >= Double(inactivityResetDays) {
            reset()
        }
    }

    /// Returns the nth Fibonacci number (0-indexed).
    /// fib(0)=1, fib(1)=1, fib(2)=2, fib(3)=3, fib(4)=5, fib(5)=8, fib(6)=13, fib(7)=21...
    private func fibonacci(_ n: Int) -> Int {
        guard n > 0 else { return 1 }
        var a = 1, b = 1
        for _ in 1...n {
            let temp = a + b
            a = b
            b = temp
        }
        return a
    }
}
