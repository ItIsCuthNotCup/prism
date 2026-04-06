# Chromatose — Full Project Handoff

## Before You Do Anything

**Read every `.swift` file in the project before making changes.** The game has tightly coupled systems (blend logic, par/combo scoring, procedural backgrounds, stats tracking, achievements) and changes in one file often affect others. Build in Xcode after every edit to catch issues early.

The project is at: `aberration/aberration/aberration/`
Xcode scheme: `aberration`
Target: iOS 17.0+, SwiftUI, `@Observable` macro (not ObservableObject)

---

## What Chromatose Is

A color-blending puzzle game. You have a 5×5 grid of colored tiles. Each round gives you a target color. You blend two adjacent tiles together (their colors mix on a 24-color wheel) to eventually produce the target. As rounds progress, the game adds distractors, poison tiles, multi-target rounds, and tighter board space. The background generates a unique procedural pattern every game (like Minecraft world generation). The mascot is a cat that throws up rainbows.

---

## File Map

```
aberration/aberration/aberration/
├── aberrationApp.swift          — App entry point
├── ContentView.swift            — Main game view (PrismGameView), start screen, settings sheet
├── Item.swift                   — PrismColor model (24-color wheel, mixing logic, Color(hex:) extension)
│
├── Models/
│   ├── GameState.swift          — Core game logic (@Observable): grid, blending, rounds, scoring, game over, undo, par/combo, poison, multi-target, stats hooks
│   └── GridPosition.swift       — Grid coordinate struct (row/col, gridSize = 5)
│
├── Utilities/
│   ├── HapticManager.swift      — Haptic feedback triggers
│   ├── ShareImageRenderer.swift — Generates 1080×1920 share card image (UIGraphicsImageRenderer)
│   ├── ShareSheet.swift         — UIActivityViewController wrapper for sharing
│   ├── SoundManager.swift       — Sound effects (blend tones, round complete, game over, milestone)
│   └── StatsManager.swift       — Lifetime stats persistence (UserDefaults) + 25 achievements
│
├── Views/
│   ├── AchievementsView.swift   — 5×5 achievement grid with cat-face tiles, stats footer
│   ├── CatMascotView.swift      — Animated cat sprite (96 frames at 12fps) for start screen
│   ├── ChromaHeader.swift       — Animated color orbs header
│   ├── GameOverOverlay.swift    — Game over screen (score, near-miss, share button, achievements button, play again)
│   ├── GridView.swift           — 5×5 tile grid rendering
│   ├── NextTilePreview.swift    — Preview of blend result
│   ├── ScoreView.swift          — Score/round/high score display
│   ├── TileView.swift           — Individual tile rendering with glass effect
│   ├── TunnelBackground.swift   — Procedural animated background (WorldSeed: random shape/palette/motion per game)
│   └── WalkingCatView.swift     — Walking cat animation (NOT used anywhere currently, legacy file)
│
├── Resources/CatSprites/        — 96 PNG frames (cat_0000.png–cat_0095.png)
└── Assets.xcassets/             — 96 imagesets + AppIcon + AccentColor
```

---

## Core Systems

### 1. Color Wheel (Item.swift)
- 24 colors: Red, Scarlet, Vermillion, Tangerine, Orange, Amber, Gold, Lemon, Yellow, Lime, Chartreuse, Mint, Green, Jade, Teal, Cerulean, Blue, Azure, Indigo, Violet, Purple, Plum, Magenta, Crimson
- Each color has a `wheelIndex` (0–23)
- `PrismColor.mix(a, b)` averages wheel indices (handles wraparound)
- `PrismColor.optimalIngredients[wheelIndex]` — the intended ingredient list for each target
- `PrismColor.primaries` — the base colors spawned as ingredients
- `PrismColor.targets(maxDepth:)` — valid target colors at a given difficulty

### 2. Game Logic (GameState.swift)
- **Grid**: 5×5 optional PrismColor array
- **Round flow**: `startNewRound()` → pick target(s) → spawn ingredients → spawn distractors → spawn poison tiles
- **Blending**: `selectTile(at:)` → `performBlend()` — merges two tiles, checks for target match
- **Par/Combo**: Each target has a `par` (optimal blend count). At-par = +100 bonus, under-par = +200. Streak tracking.
- **Multi-target rounds**: After round 15, rounds have 2+ targets in sequence (`pendingTargets` array)
- **Poison tiles**: After round 10, touching one = instant game over
- **Difficulty scaling**: `maxDepth` (blend complexity), `distractorCount`, `poisonTileCount` all increase with round number
- **Game over**: Triggers when board can't produce the target (`canStillWin()` does exhaustive search with memo + node limit)
- **Undo**: One undo per round (saves/restores grid + score snapshot)
- **`gameID`**: Increments on `newGame()`, drives `TunnelBackground` re-roll

### 3. Procedural Background (TunnelBackground.swift)
- Private `WorldSeed` struct with randomized: shape (7 types), palette (6 HSL strategies), motion style (5 types), grid spacing, angle offset, rotation speed, wave amplitude/frequency
- Re-rolls on `.onChange(of: gameID)`
- SwiftUI `Canvas` with `TimelineView(.animation)` for 60fps rendering
- Intensity scales with `depth` (rounds completed)

### 4. Stats & Achievements (StatsManager.swift)
- Singleton, persists to UserDefaults with `chr_` prefixed keys
- Tracks: totalGames, totalRounds, totalBlends, perfectRounds, bestParStreak, bestRound, bestScore, underParCount, poisonDeaths, undosUsed, multiTargetClears, discoveredColors (Set<String>)
- **25 achievements** in a 5×5 grid, each with a cat-face expression (e.g. `^.^`, `x.x`, `◉.◉`)
- Categories: Getting Started (games played), Rounds (best round), Blending (lifetime blends + par), Streaks/Combos (par streaks + multi-target), Discovery/Special (colors found, score milestones, poison deaths)
- Hooked into GameState at: every game over (3 locations), every round/sub-target completion (2 locations), every undo

### 5. Sharing (ShareImageRenderer.swift + ShareSheet.swift)
- Renders a 1080×1920 image: random triadic dot background, white card, "CHROMATOSE" title, score (gold if record), stats row, CTA text
- `UIActivityViewController` for Instagram Stories / Twitter / Facebook / etc.
- Share + Achievements buttons on GameOverOverlay

### 6. Navigation Flow
- App launches → `startScreenView` (fullScreenCover) with cat animation + Play button
- Play → main game (PrismGameView) with grid, scores, tunnel background
- Settings gear → sheet with color labels toggle + Achievements button
- Game over → GameOverOverlay with share, achievements, play again
- Achievements → AchievementsView sheet (5×5 grid of cat-face tiles)

---

## Things That Will Break If You're Not Careful

1. **`@Observable` not `ObservableObject`** — GameState uses the Swift 5.9 macro. Don't add `@Published` or `ObservableObject` conformance.
2. **Xcode 16 file sync** — The project uses `PBXFileSystemSynchronizedRootGroup`. New files in the directory auto-appear in Xcode. Don't manually edit the pbxproj.
3. **WorldSeed is private** — The entire procedural generation system is inside TunnelBackground.swift. Don't try to access it from outside.
4. **`canStillWin()` is expensive** — It does an exhaustive search with a 50k node limit. Don't call it more than necessary.
5. **Sprite frames are in the asset catalog** — `UIImage(named: "cat_XXXX")` loads from the imageset, not from Resources/CatSprites directly. Both copies exist.
6. **StatsManager hooks are in GameState** — There are 3 game-over locations, 2 round-complete locations, and 1 undo location. If you add a new game-over path, add the stats call too.
7. **Color(hex:) extension** — Defined in Item.swift. It takes a `UInt`, not a `String`. Usage: `Color(hex: 0x457B9D)`.
8. **WalkingCatView.swift is dead code** — It exists but isn't used in any view. Don't wire it in without redesigning the animation.

---

## What's Been Done (Complete History)

1. Built the core color-blending puzzle game from scratch
2. Extracted 96-frame cat sprite animation from user's video, flood-fill background removal preserving white cat body
3. Created CatMascotView for start screen animation (12fps sprite cycle)
4. Renamed app from "Blent" to "Chromatose" (display name only, not structural)
5. Built procedural background system (WorldSeed) — unique shape/color/motion every game
6. Multiple UI iterations: button centering (ZStack approach), visibility fixes, removed grid container border
7. Created and removed WalkingCatView from game screen (didn't work, kept file)
8. Built share-to-social pipeline (1080×1920 card image + UIActivityViewController)
9. Built StatsManager with 25 cat-themed achievements and lifetime stat tracking
10. Created AchievementsView — 5×5 grid of colored tiles with cat-face expressions
11. Hooked stats into all GameState events (game over, round complete, undo)
12. Wired achievements into Settings sheet and GameOverOverlay

## What Could Be Done Next

- Daily Challenge mode (same seed for all players each day)
- Mystery/wild tile rounds
- App Store link in share text (once published)
- Achievement unlock notification toast during gameplay
- Onboarding tutorial improvements
- Sound design polish
- App icon design
