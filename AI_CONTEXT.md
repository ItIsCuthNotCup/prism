# Stillhue — AI Context Document

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
- **Font:** `.system(design: .rounded)` everywhere EXCEPT the "Stillhue" brand wordmark (which stays `.serif`)
- **Design system:** Iridescent/pearlescent theme — see `Views/IridescentTheme.swift`
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
│   ├── DailyPuzzleState.swift — Hue of the Day model (daily seeded puzzle)
│   ├── AdManager.swift        — Ad integration (guarded)
│   ├── AdPacingEngine.swift   — Ad frequency control
│   └── AdScheduler.swift      — DEAD CODE (unused)
├── Views/
│   ├── IridescentTheme.swift  — Design system: colors, backgrounds, pearlescent cards, dot grid
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
│   ├── AwardsContainerView.swift — Awards tab with achievements + daily stats
│   ├── RewardChestView.swift  — Rewarded ad chest UI
│   ├── RewardOfferView.swift  — "Watch ad for reward" offer
│   ├── DailyPuzzleView.swift  — Hue of the Day full-screen view
│   ├── TileBurstView.swift    — DEAD CODE (empty stub, delete from Xcode)
│   ├── ColorWheelView.swift   — DEAD CODE (empty stub, delete from Xcode)
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

### Mercy System (NEW — just added)
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
2. **Stats bar:** ROUND (left) | SCORE (center) | LIVES+HINT (right) — hint button tucked under teardrops
3. **Target swatch** with color name
4. **Formula** (e.g., "Blue + ?" using full color names)
5. **Thin separator**
6. **Grid** (5×5 LazyVGrid via GridView) with tutorial arrows overlay on round 1

**Top toast:** Notifications slide down from top (not bottom), auto-dismiss after 3s.

**Bottom nav bar** (5 icons, always visible):
- Daily (calendar) → Hue of the Day
- New (arrow.counterclockwise) → New Game
- Home (house.fill, center, larger) → Start screen
- Awards (trophy) → Achievements
- Share (square.and.arrow.up) → Share score card

**Settings gear** is floating overlay top-right of screen (20pt icon). Achievements removed from Settings (now in nav bar).

### Visual Effects
- **Chromatic aberration border:** RGB channel-separated strokes when multiplier active
- **Screen shake** on game over
- **Tunnel background** deepens with each round completed
- **Celebration cats** pop from screen bottom on milestone rounds

### Tutorial/Onboarding System (Rounds 1-3)
- **Round 1:** Always Orange = Red + Yellow (fixed puzzle). Clean tooltip "Tap both to mix" in target-colored pill above hinted tiles. Ingredient tiles glow via existing `isHinted` system. After success: "Perfect! You made Orange" celebration with extra pause.
- **Round 2:** Coach text "Nice! Mix this one" below target swatch. Tiles glow.
- **Round 3:** Coach text "Wrong mixes stay on the board" — teaches consequence.
- **Round 4+:** All coaching disappears. Regular "Tap two colors to mix" hint returns.
- **After failed blend (1/3 chance):** "A working combo is on the board"
- Tutorial tooltip uses `GentleBounce` modifier (gentle up/down oscillation)
- Glow + tooltip disappear on first tile tap; coach text stays until round ends

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

## Hue of the Day — Formula Mechanic (Daily Puzzle Mode)

A Wordle-style daily challenge accessible from the start screen and bottom nav bar.

### How It Works
- Player sees a **target color** (depth-2, needs 3 tiles to build)
- Pick **2 tiles** → they mix → formula bar shows the intermediate result
- Pick a **3rd tile** → it mixes with the intermediate → checks if result == target
- If wrong: grid shakes, attempt used, toast shows "You made X — not TARGET"
- **5 attempts** total. Previous attempts shown as compact history.
- The formula bar teaches color mixing as you play — no instructions needed.

### Formula Bar States
- 0 picks: `? + ? + ? = TARGET`
- 1 pick: `[Red] + ? + ? = TARGET`
- 2 picks: `[Red] + [Blue] = Purple. Purple + ? = TARGET` (two-line formula showing intermediate)
- 3 picks: auto-submits and checks

### Key Properties (DailyPuzzleState)
- `picks: [PrismColor]` — tiles picked this attempt (0-3)
- `pickPositions: [GridPosition]` — grid positions of current picks
- `intermediate: PrismColor?` — computed: mix(pick[0], pick[1]) when 2+ picks
- `attempts: [DailyAttempt]` — history of all attempts with tiles, intermediate, result, isCorrect
- `maxAttempts = 5`
- `solutionTiles: [PrismColor]` — the 3 tiles that solve: mix(mix(sol[0], sol[1]), sol[2]) == target

### Files
- `Models/DailyPuzzleState.swift` — `@Observable` model: seeded RNG, formula puzzle generation, pick-2-then-1 logic, attempt tracking, persistence, share text
- `Views/DailyPuzzleView.swift` — Full-screen view: target swatch, formula bar, attempt history, 5×5 grid with multi-select, win/fail overlays, share, how-to-play
- `Views/ColorWheelView.swift` — DEAD CODE (delete from Xcode)
- Start screen in `ContentView.swift` — "Mix 3 tiles to match today's color"

### Puzzle Generation
1. `DailyRNG` creates a deterministic seed from `year * 10000 + month * 100 + day`
2. Picks a random depth-2 color as target
3. `findSolution()`: target = mix(P1, P2), decompose P1 or P2 → 3 tiles [A, B, C] where mix(mix(A,B), C) == target
4. Places 3 solution tiles randomly on the 5×5 grid, fills remaining 22 slots with distractors
5. **Test mode** (`DailyPuzzleState.testMode = true`): random puzzle each launch, no persistence

### Scoring Tiers
- 1 attempt: Genius | 2: Brilliant | 3: Great | 4: Good | 5: Close one

### Share Format
```
Stillhue 🎨 #93
🟩🟥🟨🟩 — 3/5
```
Emojis: 🟩 correct, 🟨 close (result within 4 wheel steps of target), 🟥 far

### Design Notes
- Same pearlescent card style, iridescent dot grid background, and rounded font as main game
- Attempts shown as teardrops (same as lives in main game)
- Formula bar uses mini swatches (24×24pt) with short name labels
- Previous attempts shown as compact rows with tiny swatches
- Grid tiles highlight when selected (scale up + white border glow)
- Can deselect last pick by tapping it again. Clear button resets all picks.
- "Back to Menu" dismiss button, not a full navigation stack

### Start Screen
- NYT Games-style layout: branding at top, two game mode cards
- Hue of the Day card: blue calendar icon, "Navigate the color wheel to today's hue", red dot if not played today

---

## Dead Code to Clean Up

- `BonusLabelView.swift` — functionality merged into FloatingPointsView
- `AdScheduler.swift` — unused, replaced by AdPacingEngine
- `ColorWheelView.swift` — emptied stub, delete from Xcode project navigator
- `TileBurstView.swift` — emptied stub, delete from Xcode project navigator
- `proximityBadge` function in GridView.swift — proximity hints removed from grid

---

## Iridescent Design System (Views/IridescentTheme.swift)

The entire app uses a calm, modern iridescent/pearlescent visual language. Frosted glass surfaces with subtle color shifts (cyan, violet, soft gold, rose) along edges. Never loud — luminous and refined.

### Color Palette (Iridescent enum)
- **Background:** top `0xF7F6FA` (faint lavender), bottom `0xF2F0F0` (warm neutral)
- **Accent colors:** cyan `0x7EC8E3`, violet `0xB8A0E0`, gold `0xE0D0A0`, rose `0xE0A0B8`
- **Card fill:** white at 0.78-0.85 opacity + material blur
- **Shadows:** violet-tinted `0x8878A8` at 0.08-0.12 opacity (not pure black)
- **Empty cells:** `cellTop 0xE8E6F0`, `cellBottom 0xE2E0EC`, `cellBorder 0xCEC8DA`

### Card Components
- **PearlescentCard** — main game card: dual-layer border (blurred glow at 0.6 intensity + crisp 1.5pt line), white 0.78 + thinMaterial
- **PearlescentMenuCard** — start screen cards: lighter treatment, 1pt crisp border
- **PearlescentOverlayCard** — game over/solved/failed overlays: white 0.85 + ultraThinMaterial, 5pt glow
- **PearlescentSettingsCard** — stats/settings/achievement detail cards

### Shared Elements
- **IridescentBackground** — full-screen ZStack: base gradient + 3 radial color washes (cyan top-left, violet bottom-right, gold center-bottom)
- **IridescentDotGrid** — Canvas dot grid with position-based hue variation (blue-violet-cyan range)
- **borderGradient()** — AngularGradient with cyan/violet/gold/rose, peak opacity 0.40
- **navDividerGradient** — horizontal LinearGradient for divider lines throughout the app

### Where Applied
- All screens use `IridescentBackground()` instead of flat grey
- All dividers use `Iridescent.navDividerGradient` variants
- Empty grid cells use `Iridescent.cellTop`/`cellBottom`/`cellBorder`
- GridView glass container uses iridescent accent colors instead of RGB chromatic traces
- Picker backgrounds use `Iridescent.cellTop.opacity(0.7)`

---

## Style Conventions

- **Font:** `.system(design: .rounded)` everywhere. Only exception: "Stillhue" brand wordmark uses `.serif`
- **Colors:** Use `Color(hex: UInt)` extension, dark text is `0x3A3A4A`, labels `0x888888`
- **No word "blend"** anywhere user-facing — always "mix"
- **Buttons:** Flat text style, no pill backgrounds, consistent sizing
- **Stats labels:** Size 10, weight semibold, color `0x888888`
- **Cards:** Pearlescent frosted glass with iridescent border sheen (see IridescentTheme.swift)
- **Cats:** Pixel art style, pop from bottom of screen
- **Settings gear:** Floating overlay, top-right of ZStack, 20pt icon, 10pt padding
- **Achievement toasts:** `.padding(.horizontal, 48)` — narrow enough to not block settings gear

---

## Development Phases

### Phase 1: Tutorial Overhaul — COMPLETE
Fixed round 1 to always be Orange (Red+Yellow). Clean tooltip pill. Graduated coaching rounds 1-3. "That's it! Red + Yellow = Orange" celebration.

### Phase 2: Hue of the Day — COMPLETE
Daily puzzle mode with formula mechanic (pick 3 tiles, 5 attempts). Seeded RNG. Stats tracking. Share results.

### Phase 3: $1.99 IAP Remove Ads — PENDING
Not yet started.

### Phase 4: Late-Game Mechanics + Save Game — PENDING
Not yet started.

### Phase 5: Document Remaining Items — PENDING
Not yet started.

---

## Recent Changes (Latest Session)

### Iridescent Visual Redesign (entire app)
- Created `Views/IridescentTheme.swift` — complete design system with pearlescent cards, iridescent backgrounds, dot grid, color palette
- Replaced all flat grey backgrounds with `IridescentBackground()`
- Replaced all inline glass card code with `PearlescentCard`/`PearlescentMenuCard`/`PearlescentOverlayCard`/`PearlescentSettingsCard`
- All dividers now use `Iridescent.navDividerGradient` variants
- Empty grid cells use iridescent cell colors instead of flat grey
- GridView glass container uses iridescent accent colors (cyan/violet/gold) instead of RGB chromatic traces
- Picker backgrounds use `Iridescent.cellTop.opacity(0.7)`

### Typography Overhaul
- ALL `.serif` → `.rounded` across every file
- Only exception: "Stillhue" brand wordmark on start screen (~line 880 ContentView.swift)

### HUD Fixes
- HStack alignment changed to `.top` with fixed `.frame(height: 32)` on all value texts
- Label color darkened from `0xAAAAAA` → `0x888888` to match bottom nav

### Layout Adjustments
- Settings gear moved to floating overlay top-right of ZStack (20pt icon, 10pt padding)
- Achievement toasts narrowed with `.padding(.horizontal, 48)` to avoid blocking settings
- ROUND stat value bumped from 17pt → 22pt

### Previous Session Changes
1. Merged two separate cards into one unified card
2. Removed "blend" terminology → "mix"
3. Reordered stats bar: ROUND left, SCORE center, LIVES right
4. Removed BEST stat from in-game display
5. Bottom nav bar added (Daily, New, Home, Awards, Share)
6. Chromatic aberration RGB border effect for multiplier
7. FloatingPointsView rewrite: bonus + total in target color, zoom to score
8. Mercy difficulty system (non-perfect → next round is easy, until round 50)
9. Formula uses full color names
10. Screen shake on game over
11. Dynamic game over headers
12. Celebration cats pop from screen bottom
13. Toast moved to top (slides down), auto-dismiss 3s
14. Start screen redesigned as NYT-style game mode cards

---

## How to Build

Open `aberration/aberration.xcodeproj` in Xcode. Target: iOS 17+. Simulator: iPhone 16 Pro or similar. The Google Mobile Ads SDK is optional (guarded with `#if canImport`).

**Xcode project format:** `objectVersion = 77` (Xcode 16) with `PBXFileSystemSynchronizedRootGroup`. Files are auto-discovered from disk — do NOT add manual PBXFileReference/PBXBuildFile entries. Just create the `.swift` file in the right directory and Xcode picks it up.

**GitHub:** User pushed before the iridescent redesign — that commit is a revert point if needed.
