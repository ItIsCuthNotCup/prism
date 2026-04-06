import Foundation

/// Research-based adaptive ad pacing engine.
///
/// Based on 2022–2026 mobile game ad frequency studies:
/// - Rewarded video: 3–5 per session, opt-in, variable-ratio offering
/// - Interstitials: 1–2 per session, 3–5 min intervals, natural transitions only
/// - Player segmentation: new/regular/committed players get different pacing
/// - Peak-end rule: never force an ad at session end or after achievements
/// - Variable-ratio reinforcement: rewarded offers appear unpredictably
///
/// Replaces the old Fibonacci-based AdScheduler.
class AdPacingEngine {
    static let shared = AdPacingEngine()

    private let defaults = UserDefaults.standard

    // MARK: - Persisted Keys

    private let totalGamesKey = "adp_total_games"
    private let lastSessionKey = "adp_last_session"
    private let lifetimeRewardedKey = "adp_lifetime_rewarded"

    // MARK: - Session State (resets each app launch / new session)

    private var sessionStartTime: Date = Date()
    private var sessionGameOvers: Int = 0
    private var sessionInterstitialsShown: Int = 0
    private var sessionRewardedShown: Int = 0
    private var lastAdTime: Date? = nil
    private var lastRewardedOfferTime: Date? = nil
    /// Rolling counter used for variable-ratio reward offers
    private var rewardOfferCounter: Int = 0
    /// The threshold for next reward offer (randomized for variable ratio)
    private var nextRewardOfferAt: Int = 0

    // MARK: - Caps (per session)

    /// Max interstitials per session
    private let maxInterstitials = 2
    /// Max rewarded ads per session
    private let maxRewarded = 5
    /// Minimum seconds between ANY two ads
    private let minAdSpacingSeconds: TimeInterval = 120  // 2 min floor
    /// Game overs to skip at session start (ad-free grace period)
    private let gracePeriodGameOvers = 2

    // MARK: - Player Segments

    enum PlayerSegment {
        case new        // < 10 total games
        case regular    // 10–50 total games
        case committed  // 50+ total games

        /// Minimum seconds between interstitials
        var interstitialCooldown: TimeInterval {
            switch self {
            case .new:       return 300  // 5 min — protect new players
            case .regular:   return 210  // 3.5 min
            case .committed: return 150  // 2.5 min
            }
        }

        /// Minimum seconds between rewarded ad opportunities
        var rewardedCooldown: TimeInterval {
            switch self {
            case .new:       return 150  // 2.5 min
            case .regular:   return 120  // 2 min
            case .committed: return 90   // 1.5 min
            }
        }

        /// Range for variable-ratio reward offer spacing (in game overs)
        var rewardOfferRange: ClosedRange<Int> {
            switch self {
            case .new:       return 1...3  // offer frequently to teach the mechanic
            case .regular:   return 1...3
            case .committed: return 1...2
            }
        }
    }

    var playerSegment: PlayerSegment {
        let total = defaults.integer(forKey: totalGamesKey)
        if total < 10 { return .new }
        if total < 50 { return .regular }
        return .committed
    }

    var totalGamesPlayed: Int {
        defaults.integer(forKey: totalGamesKey)
    }

    // MARK: - Init

    private init() {
        checkSessionReset()
        rollNextRewardThreshold()
    }

    /// Call at app launch or when returning from background after long absence
    private func checkSessionReset() {
        let last = defaults.double(forKey: lastSessionKey)
        if last > 0 {
            let hoursSince = (Date().timeIntervalSince1970 - last) / 3600
            // New session if 30+ min gap
            if hoursSince > 0.5 {
                resetSession()
            }
        } else {
            resetSession()
        }
    }

    private func resetSession() {
        sessionStartTime = Date()
        sessionGameOvers = 0
        sessionInterstitialsShown = 0
        sessionRewardedShown = 0
        lastAdTime = nil
        lastRewardedOfferTime = nil
        rewardOfferCounter = 0
        rollNextRewardThreshold()
    }

    /// Variable-ratio: pick a random threshold for the next reward offer
    private func rollNextRewardThreshold() {
        let range = playerSegment.rewardOfferRange
        nextRewardOfferAt = Int.random(in: range)
    }

    // MARK: - Public API

    /// Call every game over. Returns whether an interstitial should show.
    func onGameOver() -> Bool {
        defaults.set(Date().timeIntervalSince1970, forKey: lastSessionKey)

        let total = defaults.integer(forKey: totalGamesKey) + 1
        defaults.set(total, forKey: totalGamesKey)

        sessionGameOvers += 1
        rewardOfferCounter += 1

        // Grace period: no interstitials for first N game overs in a session
        guard sessionGameOvers > gracePeriodGameOvers else { return false }

        // Cap check
        guard sessionInterstitialsShown < maxInterstitials else { return false }

        // Cooldown check
        if let lastAd = lastAdTime {
            let elapsed = Date().timeIntervalSince(lastAd)
            guard elapsed >= playerSegment.interstitialCooldown else { return false }
        }

        // Minimum spacing from ANY ad (interstitial or rewarded)
        if let lastAd = lastAdTime {
            let elapsed = Date().timeIntervalSince(lastAd)
            guard elapsed >= minAdSpacingSeconds else { return false }
        }

        // Show interstitial
        sessionInterstitialsShown += 1
        lastAdTime = Date()
        return true
    }

    /// Whether a rewarded ad offer should be presented this game over.
    /// Uses variable-ratio reinforcement — not every game over gets an offer.
    func shouldOfferReward() -> Bool {
        // Cap check
        guard sessionRewardedShown < maxRewarded else { return false }

        // Cooldown from last rewarded
        if let lastRewarded = lastRewardedOfferTime {
            let elapsed = Date().timeIntervalSince(lastRewarded)
            guard elapsed >= playerSegment.rewardedCooldown else { return false }
        }

        // Minimum spacing from any ad
        if let lastAd = lastAdTime {
            let elapsed = Date().timeIntervalSince(lastAd)
            guard elapsed >= minAdSpacingSeconds else { return false }
        }

        // Variable-ratio gate
        guard rewardOfferCounter >= nextRewardOfferAt else { return false }

        return true
    }

    /// Call when a rewarded ad is actually shown (user opted in).
    func onRewardedAdShown() {
        sessionRewardedShown += 1
        lastAdTime = Date()
        lastRewardedOfferTime = Date()
        rewardOfferCounter = 0
        rollNextRewardThreshold()

        let lifetime = defaults.integer(forKey: lifetimeRewardedKey) + 1
        defaults.set(lifetime, forKey: lifetimeRewardedKey)
    }

    /// Call when user declines the reward offer.
    func onRewardDeclined() {
        // Don't reset counter — they'll get offered again next eligible game over
        // But do set the cooldown timer so we don't re-offer immediately
        lastRewardedOfferTime = Date()
    }

    /// Call when an interstitial is shown (via the old flow).
    func onInterstitialShown() {
        // Already tracked in onGameOver, but this is for manual tracking if needed
    }

    // MARK: - Debug

    var debugInfo: String {
        """
        Segment: \(playerSegment) | Total: \(totalGamesPlayed)
        Session: \(sessionGameOvers) GOs, \(sessionInterstitialsShown) ints, \(sessionRewardedShown) rew
        Reward counter: \(rewardOfferCounter)/\(nextRewardOfferAt)
        """
    }

    /// Reset all state (for testing or "remove ads" purchase)
    func reset() {
        defaults.removeObject(forKey: totalGamesKey)
        defaults.removeObject(forKey: lastSessionKey)
        defaults.removeObject(forKey: lifetimeRewardedKey)
        resetSession()
    }
}
