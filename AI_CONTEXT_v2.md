# Stillhue — AI Context Document (April 2026)

## What Is This Game?

**Stillhue** (Xcode project name: "aberration") is an iOS color-mixing puzzle game built in SwiftUI. The player is given a target color and must tap two tiles on a 5×5 grid to mix them and match the target. The game has a cat mascot, a prismatic aesthetic, and an emphasis on keeping things fun and accessible.

**App subtitle:** "A color-mixing puzzle"

---

## Core Gameplay Loop

1. A **target color** is shown (e.g., "TEAL")
2. The player taps two colored tiles on the 5×5 grid
3. Those tiles **mix** using RYB color wheel midpoint blending
4. If the result matches the target → round complete, score earned, next round
5. If not → the result tile replaces one of the source tiles, player tries again
6. If no valid combinations remain → game over (player can spend a **life** to retry)

**The game never times out.** Timer is disabled ("zen mode"). No poison tiles either.

---

## Technical Stack

- **SwiftUI** with `@Observable` macro (Swift 5.9+), NOT `ObservableObject`
- **Font everywhere:** `.system(design: .serif)` — renders as New York on iOS
- **Ad guards:** `#if canImport(GoogleMobileAds)` on all ad-related code
- **Color extension:** `Color(hex:)` takes `UInt`, defined in Item.swift
- **All SFX:** Synthesized via AVAudioEngine — no audio files bundled
- **Grid:** `GridPosition.gridSize = 5` (5×5 grid)

---

## Project Structure

```
aberration/aberration/aberration/
├── ContentView.swift          — Main game view (PrismGameView), single unified card layout
├── Item.swift                 — PrismColor: 48-color RYB wheel, mixing, names, hex values
├── aberrationApp.swift        — App entry point
├── Models/
│   ├── GameState.swift        — Core game logic (@Observable), round management, bonuses, scoring
│   ├── GridPosition.swift     — Row/col struct, 5×5 grid
│   ├── CelebrationType.swift  — Cat celebration types
│   ├── AdManager.swift        — Ad integration (guarded)
│   ├── AdPacingEngine.swift   — Ad frequency control
│   └── AdScheduler.swift      — DEAD CODE (unused)
├── Views/
│   ├── GridView.swift         — LazyVGrid rendering of the 5×5 board
│   ├── TileView.swift         — Individual tile rendering
│   ├── FloatingPointsView.swift — Score feedback animation (bonus + total → zoom to score)
│   ├── BonusLabelView.swift   — DEAD CODE (merged into FloatingPointsView)
│   ├── GameOverOverlay.swift  — Game over screen with dynamic headers
│   ├── ChromaticAberrationBorder.swift — RGB channel-separated border effect for multiplier
│   ├── TunnelBackground.swift — Animated background that deepens with progress
│   ├── CatMascotView.swift    — Pixel art cat at top of card
│   ├── CelebrationCatView.swift, ChaseCatView.swift, etc. — Cat celebration animations
│   ├── AchievementsView.swift — Achievement gallery
│   ├── RewardChestView.swift  — Rewarded ad chest UI
│   ├── RewardOfferView.swift  — "Watch ad for reward" offer
│   └── ScoreView.swift, NextTilePreview.swift, ChromaHeader.swift
├── Utilities/
│   ├── SoundManager.swift     — AVAudioEngine synthesized SFX
│   ├── HapticManager.swift    — Taptic feedback
│   ├── MusicManager.swift     — Background music
│   ├── StatsManager.swift     — Persistent stats + achievements
│   ├── ShareImageRenderer.swift — Share card generation
│   └── ShareSheet.swift       — UIActivityViewController wrapper
```

---

## Color System (PrismColor — Item.swift)

- **48 colors** on an RYB wheel, 7.5° apart
- Each color has: `wheelIndex`, `name`, `shortName`, `hexValue`, `depth`
- **Depth 0:** Primaries — Red (0), Yellow (16), Blue (32)
- **Depth 1:** Secondaries — Orange (8), Green (24), Purple (40) + neighbors
- **Depth 2+:** Increasingly complex mixes
- **Mixing:** `PrismColor.mix(a, b)` → midpoint on the wheel
- **`directPair`:** Maps each target's wheelIndex → the two colors that mix to create it
- **`optimalIngredients`:** The best tiles to place for a given target
- **`targets(maxDepth:)`:** Returns all colors with `depth > 0 && depth <= maxDepth`

---

## Difficulty System (GameState.swift)

### Target Depth by Round
```
Round 1-10:   maxTargetDepth = 1  (secondaries only — two primaries → result)
Round 11-20:  maxTargetDepth = 2
Round 21-30:  maxTargetDepth = 3
Round 31+:    maxTargetDepth = 4  (full 48-color palette)
```

### Distractor Scaling
```
Round 1-2:   0 distractors
Round 3-5:   1 distractor
Round 6-10:  2 distractors
Round 11+:   scales further
```

### Mercy System (added April 2026)
If the player did NOT get a "Perfect Mix" (1-blend match) on the previous round, the next round's target depth is capped at 1 (two primaries → secondary). This makes the next round easy/winnable. **Active until round 50**, after which full difficulty always applies.

- `lastRoundWasPerfect: Bool` — tracked in GameState
- Set to `false` on life loss, set based on `blendsThisTarget == 1` on round complete
- Reset to `true` on new game

### Other Difficulty Helpers
- **Breather rounds:** ~20% chance after round 4, caps depth to 1, halves distractors
- **DDA (Dynamic Difficulty Adjustment):** After 2+ consecutive deaths, adds a helpful tile
- **Hint system:** Players earn hint tokens (from rewarded ads), which highlight the best pair

---

## Scoring System

- **Per blend:** +10 × scoreMultiplier
- **Round match bonus:** round × 50 × scoreMultiplier
- **Bonuses evaluated at round complete:**
  - `perfectBlend` — matched in exactly 1 blend → +150
  - `efficient` — matched at or under par → +100
  - `cleanStreak` — 3 rounds without undo → +75
  - `speedDemon` — completed in ≤5 seconds → +100
  - `untouchable` — 5+ rounds without dying → activates 5× multiplier
- **Golden tiles:** ~15% chance per round after round 3, activates 3× multiplier for 3 rounds

### Score Animation (FloatingPointsView.swift)
- Both bonus label and total score appear in **target tile color** (not black)
- Bonus drops in → total pops in below → bonus collapses into total → total pulses
- Then the whole thing **zooms upward (-120pt), shrinks to 0.3×, fades to 0** — as if absorbed into the score counter
- Without bonus: total pops in, holds, then zooms to score

---

## UI Layout (ContentView.swift — PrismGameView)

Single unified glass card containing (top to bottom):
1. **Cat mascot** (pixel art, top of card)
2. **Stats bar:** ROUND (left) | SCORE (center) | LIVES (right) — evenly spaced thirds
3. **Target swatch** with color name
4. **Formula** (e.g., "Blue + ?" using full color names)
5. **Notification banner** — auto-dismissing capsule (3s timeout) for tutorial hints
6. **Thin separator**
7. **Grid** (5×5 LazyVGrid via GridView) with tutorial arrows overlay on round 1
8. **Bottom buttons:** Undo | New Game | Hint — all flat text, consistent style

### Visual Effects
- **Chromatic aberration border:** RGB channel-separated strokes when multiplier active
- **Screen shake** on game over
- **Tunnel background** deepens with each round completed
- **Celebration cats** pop from screen bottom on milestone rounds

### Tutorial/Notification System
- **Round 1:** Notification "Tap both colors to create the target above" + arrow overlay pointing at hinted tiles
- **After failed blend (1/3 chance):** "A working combo is on the board"
- Arrows use `GentleBounce` modifier (gentle up/down oscillation)
- Arrows disappear on first tile tap (`showTutorialArrows = false` in `selectTile()`)

---

## Key State Properties (GameState.swift)

| Property | Type | Purpose |
|----------|------|---------|
| `grid` | `[[PrismColor?]]` | 5×5 board |
| `targetColor` | `PrismColor?` | Current target to match |
| `round` | `Int` | Current round number |
| `score` | `Int` | Current game score |
| `lives` | `Int` | Remaining lives (starts at 3) |
| `isGameOver` | `Bool` | Game over state |
| `selectedPosition` | `GridPosition?` | Currently selected tile |
| `hintPositions` | `Set<GridPosition>` | Tiles highlighted by hint system |
| `showTutorialArrows` | `Bool` | Whether to show round 1 arrows |
| `notificationText` | `String?` | Current notification banner text |
| `lastRoundWasPerfect` | `Bool` | Mercy system flag |
| `multiplierRoundsLeft` | `Int` | Rounds remaining with active multiplier |
| `scoreMultiplier` | `Int` | Current multiplier (1, 3, or 5) |
| `floatingPointsTrigger` | `Int` | Triggers score animation |
| `lastEarnedBonus` | `EarnedBonus?` | Most recent bonus for animation |

---

## Dead Code to Clean Up

- `BonusLabelView.swift` — functionality merged into FloatingPointsView
- `AdScheduler.swift` — unused, replaced by AdPacingEngine
- `proximityBadge` function in GridView.swift — proximity hints removed from grid

---

## Style Conventions

- **Font:** Always `.system(design: .serif)` — never sans-serif
- **Colors:** Use `Color(hex: UInt)` extension, dark text is `0x3A3A4A`, labels `0x888888`
- **No word "blend"** anywhere user-facing — always "mix"
- **Buttons:** Flat text style, no pill backgrounds, consistent sizing
- **Stats labels:** Size 10, weight semibold, color `0x888888`
- **Cards:** Single unified card with subtle glass effect
- **Cats:** Pixel art style, pop from bottom of screen

---

## Changes Made in April 5, 2026 Session

1. Merged two separate cards into one unified card
2. Removed "blend" terminology everywhere → "mix"
3. Reordered stats bar: ROUND left, SCORE center, LIVES right
4. Removed BEST stat from in-game display
5. Made all bottom buttons consistent flat text
6. Added chromatic aberration RGB border effect for multiplier (replaces flat glow)
7. Rewrote FloatingPointsView: bonus + total both in target color, combine → zoom to score
8. Added notification/tutorial system (banner + arrows on round 1)
9. Added mercy difficulty system (non-perfect → next round is easy, until round 50)
10. Shrank target swatch, reduced cat frame, tightened padding throughout
11. Formula uses full color names instead of abbreviations
12. Screen shake on game over
13. Dynamic game over headers ("New Record", "Incredible", "Great Run", etc.)
14. Celebration cats now properly pop from screen bottom (not mid-card)

---

## Pending Work / Known Issues

- **Build and test** all changes from the April 5 session (no Xcode in sandbox to verify)
- The `tutorialArrowsOverlay` arrow positioning may need fine-tuning if slightly off from LazyVGrid centering
- `BonusLabelView.swift` is dead code — safe to delete
- `AdScheduler.swift` is dead code — safe to delete
- `proximityBadge` in GridView.swift is dead code — safe to remove

---

## How to Build

Open `aberration/aberration.xcodeproj` in Xcode. Target: iOS 17+. Simulator: iPhone 16 Pro or similar. The Google Mobile Ads SDK is optional (guarded with `#if canImport`).
