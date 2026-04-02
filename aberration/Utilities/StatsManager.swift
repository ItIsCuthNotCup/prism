//
//  StatsManager.swift
//  Chromatose
//
//  Persists lifetime stats and achievements in UserDefaults.
//

import Foundation

final class StatsManager {
    static let shared = StatsManager()
    private let defaults = UserDefaults.standard

    // MARK: - Keys

    private enum K {
        static let totalGames        = "chr_total_games"
        static let totalRounds       = "chr_total_rounds"
        static let totalBlends       = "chr_total_blends"
        static let perfectRounds     = "chr_perfect_rounds"
        static let parStreak         = "chr_par_streak"
        static let bestParStreak     = "chr_best_par_streak"
        static let discoveredColors  = "chr_discovered_colors"
        static let unlockedBadges    = "chr_unlocked_badges"
        static let bestRound         = "chr_best_round"
        static let bestScore         = "chr_best_score"
        static let underParCount     = "chr_under_par_count"
        static let poisonDeaths      = "chr_poison_deaths"
        static let undosUsed         = "chr_undos_used"
        static let multiTargetClears = "chr_multi_target_clears"
        static let goldenTilesUsed   = "chr_golden_tiles_used"
        static let livesUsed         = "chr_lives_used"
        static let bonusLivesEarned  = "chr_bonus_lives_earned"
    }

    // MARK: - Stat Accessors

    var totalGames: Int {
        get { defaults.integer(forKey: K.totalGames) }
        set { defaults.set(newValue, forKey: K.totalGames) }
    }
    var totalRounds: Int {
        get { defaults.integer(forKey: K.totalRounds) }
        set { defaults.set(newValue, forKey: K.totalRounds) }
    }
    var totalBlends: Int {
        get { defaults.integer(forKey: K.totalBlends) }
        set { defaults.set(newValue, forKey: K.totalBlends) }
    }
    var perfectRounds: Int {
        get { defaults.integer(forKey: K.perfectRounds) }
        set { defaults.set(newValue, forKey: K.perfectRounds) }
    }
    var bestParStreak: Int {
        get { defaults.integer(forKey: K.bestParStreak) }
        set { defaults.set(newValue, forKey: K.bestParStreak) }
    }
    var bestRound: Int {
        get { defaults.integer(forKey: K.bestRound) }
        set { defaults.set(newValue, forKey: K.bestRound) }
    }
    var bestScore: Int {
        get { defaults.integer(forKey: K.bestScore) }
        set { defaults.set(newValue, forKey: K.bestScore) }
    }
    var underParCount: Int {
        get { defaults.integer(forKey: K.underParCount) }
        set { defaults.set(newValue, forKey: K.underParCount) }
    }
    var poisonDeaths: Int {
        get { defaults.integer(forKey: K.poisonDeaths) }
        set { defaults.set(newValue, forKey: K.poisonDeaths) }
    }
    var undosUsed: Int {
        get { defaults.integer(forKey: K.undosUsed) }
        set { defaults.set(newValue, forKey: K.undosUsed) }
    }
    var multiTargetClears: Int {
        get { defaults.integer(forKey: K.multiTargetClears) }
        set { defaults.set(newValue, forKey: K.multiTargetClears) }
    }
    var goldenTilesUsed: Int {
        get { defaults.integer(forKey: K.goldenTilesUsed) }
        set { defaults.set(newValue, forKey: K.goldenTilesUsed) }
    }
    var livesUsed: Int {
        get { defaults.integer(forKey: K.livesUsed) }
        set { defaults.set(newValue, forKey: K.livesUsed) }
    }
    var bonusLivesEarned: Int {
        get { defaults.integer(forKey: K.bonusLivesEarned) }
        set { defaults.set(newValue, forKey: K.bonusLivesEarned) }
    }

    /// Current par streak (resets on non-par round)
    var currentParStreak: Int {
        get { defaults.integer(forKey: K.parStreak) }
        set {
            defaults.set(newValue, forKey: K.parStreak)
            if newValue > bestParStreak { bestParStreak = newValue }
        }
    }

    /// Set of color names matched at least once
    var discoveredColors: Set<String> {
        get { Set(defaults.stringArray(forKey: K.discoveredColors) ?? []) }
        set { defaults.set(Array(newValue), forKey: K.discoveredColors) }
    }

    /// Set of unlocked achievement IDs
    var unlockedBadges: Set<String> {
        get { Set(defaults.stringArray(forKey: K.unlockedBadges) ?? []) }
        set { defaults.set(Array(newValue), forKey: K.unlockedBadges) }
    }

    // MARK: - Event Recording

    func recordGameOver(round: Int, blends: Int, score: Int, diedToPoison: Bool) {
        totalGames += 1
        totalRounds += round
        totalBlends += blends
        if score > bestScore { bestScore = score }
        if round > bestRound { bestRound = round }
        if diedToPoison { poisonDeaths += 1 }
        currentParStreak = 0  // reset streak on game end
        checkAchievements()
    }

    func recordRoundComplete(colorName: String, blendsUsed: Int, par: Int, isMultiTarget: Bool) {
        // Track color discovery
        var colors = discoveredColors
        colors.insert(colorName)
        discoveredColors = colors

        // Track perfect (at or under par)
        if blendsUsed <= par {
            perfectRounds += 1
            currentParStreak += 1
            if blendsUsed < par {
                underParCount += 1
            }
        } else {
            currentParStreak = 0
        }

        if isMultiTarget {
            multiTargetClears += 1
        }

        checkAchievements()
    }

    func recordUndo() {
        undosUsed += 1
    }

    func recordGoldenTileUsed() {
        goldenTilesUsed += 1
        checkAchievements()
    }

    func recordLifeUsed() {
        livesUsed += 1
        checkAchievements()
    }

    func recordBonusLifeEarned() {
        bonusLivesEarned += 1
        checkAchievements()
    }

    // MARK: - Achievements (35 total, 7x5 grid)

    struct Achievement: Identifiable {
        let id: String
        let name: String
        let description: String
        /// Asset catalog image name for the achievement sprite
        let imageName: String
        /// Background hue (0-1) for the achievement tile
        let hue: Double
    }

    // 35 achievements — 7 rows × 5 columns, each with a unique pixel-art cat sprite
    static let allAchievements: [Achievement] = [
        // Row 1: Getting Started
        Achievement(id: "first_game",       name: "Kitten Steps",      description: "Complete your first round",             imageName: "ach_kitten_steps",    hue: 0.10),
        Achievement(id: "play_10",          name: "Curious Cat",       description: "Play 10 games",                         imageName: "ach_curious_cat",     hue: 0.08),
        Achievement(id: "play_100",         name: "Cat Royale",        description: "Play 100 games",                        imageName: "ach_cat_royale",      hue: 0.85),
        Achievement(id: "play_500",         name: "If I Fits",         description: "Play 500 games",                        imageName: "ach_if_i_fits",       hue: 0.12),
        Achievement(id: "play_1000",        name: "Catnip Addict",     description: "Play 1,000 games",                      imageName: "ach_catnip_addict",   hue: 0.00),

        // Row 2: Rounds
        Achievement(id: "round_10",         name: "Bookworm",          description: "Reach Round 10",                        imageName: "ach_bookworm",        hue: 0.08),
        Achievement(id: "round_25",         name: "In The Zone",       description: "Reach Round 25",                        imageName: "ach_in_the_zone",     hue: 0.60),
        Achievement(id: "round_50",         name: "One Small Step",    description: "Reach Round 50",                        imageName: "ach_one_small_step",  hue: 0.65),
        Achievement(id: "round_75",         name: "Shadow Blade",      description: "Reach Round 75",                        imageName: "ach_shadow_blade",    hue: 0.70),
        Achievement(id: "round_100",        name: "Moonlit",           description: "Reach Round 100",                       imageName: "ach_moonlit",         hue: 0.75),

        // Row 3: Mixing Mastery
        Achievement(id: "blend_100",        name: "Sous Chef",         description: "100 lifetime mixes",                    imageName: "ach_sous_chef",       hue: 0.08),
        Achievement(id: "blend_1000",       name: "Ramen Master",      description: "1,000 lifetime mixes",                  imageName: "ach_ramen_master",    hue: 0.05),
        Achievement(id: "blend_5000",       name: "Caffeine Fueled",   description: "5,000 lifetime mixes",                  imageName: "ach_caffeine_fueled", hue: 0.00),
        Achievement(id: "perfect_par",      name: "Bullseye",          description: "Match a target at par",                 imageName: "ach_bullseye",        hue: 0.08),
        Achievement(id: "under_par_10",     name: "Kickflip",          description: "Finish under par 10 times",             imageName: "ach_kickflip",        hue: 0.08),

        // Row 4: Streaks & Combos
        Achievement(id: "streak_3",         name: "Lucky Charm",       description: "3 par matches in a row",                imageName: "ach_lucky_charm",     hue: 0.00),
        Achievement(id: "streak_5",         name: "Surf's Up",         description: "5 par matches in a row",                imageName: "ach_surfs_up",        hue: 0.55),
        Achievement(id: "streak_10",        name: "Untouchable",       description: "10 par matches in a row",               imageName: "ach_untouchable",     hue: 0.70),
        Achievement(id: "multi_5",          name: "Button Masher",     description: "Clear 5 multi-target rounds",           imageName: "ach_button_masher",   hue: 0.10),
        Achievement(id: "multi_25",         name: "Retro Gamer",       description: "Clear 25 multi-target rounds",          imageName: "ach_retro_gamer",     hue: 0.00),

        // Row 5: Discovery & Special
        Achievement(id: "half_spectrum",    name: "Study Hall",        description: "Discover 24 different colors",          imageName: "ach_study_hall",      hue: 0.60),
        Achievement(id: "full_spectrum",    name: "Full Heart",        description: "Discover all 48 colors",                imageName: "ach_full_heart",      hue: 0.30),
        Achievement(id: "score_5k",         name: "Sushi Roll",        description: "Score 5,000 in one game",               imageName: "ach_sushi_roll",      hue: 0.02),
        Achievement(id: "score_10k",        name: "Big Love",          description: "Score 10,000 in one game",              imageName: "ach_big_love",        hue: 0.95),
        Achievement(id: "poison_5",         name: "Dark Side",         description: "Die to poison 5 times",                 imageName: "ach_dark_side",       hue: 0.80),

        // ── Row 6–7: Tier 4+ Mastery (require bestRound ≥ 40) ──────

        // Row 6: Deep Expertise
        Achievement(id: "artiste",          name: "Artiste",           description: "Discover 42 different colors",          imageName: "ach_artiste",         hue: 0.08),
        Achievement(id: "drop_the_beat",    name: "Drop the Beat",     description: "10,000 lifetime mixes",                 imageName: "ach_drop_the_beat",   hue: 0.70),
        Achievement(id: "green_thumb",      name: "Green Thumb",       description: "Complete 1,000 total rounds",           imageName: "ach_green_thumb",     hue: 0.35),
        Achievement(id: "rock_star",        name: "Rock Star",         description: "Score 50,000 in one game",              imageName: "ach_rock_star",       hue: 0.00),
        Achievement(id: "purrito",          name: "Purrito",           description: "Reach Round 150",                       imageName: "ach_purrito",         hue: 0.08),

        // Row 7: Legendary
        Achievement(id: "rescue_cat",       name: "Rescue Cat",        description: "Use 10 lives total",                    imageName: "ach_rescue_cat",      hue: 0.02),
        Achievement(id: "robocat",          name: "Robocat",           description: "100 perfect rounds at par",             imageName: "ach_robocat",         hue: 0.60),
        Achievement(id: "hocus_pocus",      name: "Hocus Pocus",       description: "Use 50 golden tiles",                   imageName: "ach_hocus_pocus",     hue: 0.80),
        Achievement(id: "valhalla",         name: "Valhalla",          description: "15 par matches in a row",               imageName: "ach_valhalla",        hue: 0.10),
        Achievement(id: "guardian_angel",   name: "Guardian Angel",    description: "Earn 5 bonus lives",                    imageName: "ach_guardian_angel",   hue: 0.55),
    ]

    /// Check and unlock any newly earned achievements
    func checkAchievements() {
        var badges = unlockedBadges

        // ── Row 1: Games played ──
        if totalGames >= 1    { badges.insert("first_game") }
        if totalGames >= 10   { badges.insert("play_10") }
        if totalGames >= 100  { badges.insert("play_100") }
        if totalGames >= 500  { badges.insert("play_500") }
        if totalGames >= 1000 { badges.insert("play_1000") }

        // ── Row 2: Best round reached ──
        if bestRound >= 10  { badges.insert("round_10") }
        if bestRound >= 25  { badges.insert("round_25") }
        if bestRound >= 50  { badges.insert("round_50") }
        if bestRound >= 75  { badges.insert("round_75") }
        if bestRound >= 100 { badges.insert("round_100") }

        // ── Row 3: Blending ──
        if totalBlends >= 100  { badges.insert("blend_100") }
        if totalBlends >= 1000 { badges.insert("blend_1000") }
        if totalBlends >= 5000 { badges.insert("blend_5000") }
        if perfectRounds >= 1  { badges.insert("perfect_par") }
        if underParCount >= 10 { badges.insert("under_par_10") }

        // ── Row 4: Streaks & combos ──
        if bestParStreak >= 3  { badges.insert("streak_3") }
        if bestParStreak >= 5  { badges.insert("streak_5") }
        if bestParStreak >= 10 { badges.insert("streak_10") }
        if multiTargetClears >= 5  { badges.insert("multi_5") }
        if multiTargetClears >= 25 { badges.insert("multi_25") }

        // ── Row 5: Discovery & special ──
        if discoveredColors.count >= 24 { badges.insert("half_spectrum") }
        if discoveredColors.count >= 48 { badges.insert("full_spectrum") }
        if bestScore >= 5000  { badges.insert("score_5k") }
        if bestScore >= 10000 { badges.insert("score_10k") }
        if poisonDeaths >= 5  { badges.insert("poison_5") }

        // ── Rows 6–7: Tier 4+ mastery (all gated behind bestRound ≥ 40) ──
        if bestRound >= 40 {
            if discoveredColors.count >= 42 { badges.insert("artiste") }
            if totalBlends >= 10000         { badges.insert("drop_the_beat") }
            if totalRounds >= 1000          { badges.insert("green_thumb") }
            if bestScore >= 50000           { badges.insert("rock_star") }
            if bestRound >= 150             { badges.insert("purrito") }
            if livesUsed >= 10              { badges.insert("rescue_cat") }
            if perfectRounds >= 100         { badges.insert("robocat") }
            if goldenTilesUsed >= 50        { badges.insert("hocus_pocus") }
            if bestParStreak >= 15          { badges.insert("valhalla") }
            if bonusLivesEarned >= 5        { badges.insert("guardian_angel") }
        }

        unlockedBadges = badges
    }

    /// Newly unlocked achievements (call to check and return new ones)
    func newlyUnlocked() -> [Achievement] {
        let before = unlockedBadges
        checkAchievements()
        let after = unlockedBadges
        let newIDs = after.subtracting(before)
        return Self.allAchievements.filter { newIDs.contains($0.id) }
    }
}
