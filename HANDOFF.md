# Stillhue — Complete AI Agent Handoff

## What This App Is

**Stillhue** is an iOS color-mixing puzzle game. The Xcode project is named **"aberration"** (that's the original/internal name — the user-facing name is "Stillhue"). The user's name is **Cuth** (Jacob Cuthbertson).

The game targets **relaxed older players**. The vibe is **zen/chill** — not arcade. Every design decision should reinforce calm, minimal, quiet aesthetics.

### Core Gameplay
- A 6x6 grid of cells. Player taps an empty cell to place a colored tile.
- A **target color** is shown (e.g., "GREEN"). The player must blend two adjacent tiles to create that target color.
- Each round has a "par" number of blends. Fewer blends = more points.
- When the grid fills up with no valid blends remaining, the game is over ("Out of moves").
- Players have **lives** (displayed as teardrops) that let them retry a round.
- Achievements unlock based on gameplay milestones.

---

## Project Structure

All source code lives at:
```
/sessions/peaceful-trusting-cerf/mnt/aberration/aberration/aberration/
```

### Key Files

| File | Purpose |
|------|---------|
| `aberrationApp.swift` | App entry point. Initializes Google Ads SDK (conditional), preloads AdManager, starts theme music via MusicManager. Main view is `PrismGameView()`. |
| `ContentView.swift` (~856 lines) | **The main game UI.** Contains `PrismGameView` — the entire game screen including start screen, stats bar, target display, grid, overlays for round complete/milestone/game over. This is the most-modified file. |
| `Models/GameState.swift` (~1054 lines) | Game logic. Uses `@Observable` macro (Swift 5.9). Manages grid, scoring, rounds, lives, color matching, combo system, achievements. |
| `Models/AdManager.swift` | Google Mobile Ads interstitial ad management. Uses `#if canImport(GoogleMobileAds)` guards everywhere. |
| `Models/AdScheduler.swift` | Fibonacci-based ad scheduling — decides when to show ads. |
| `Models/GridPosition.swift` | Grid coordinate model. `GridPosition.gridSize` = 6. |
| `Utilities/SoundManager.swift` (~462 lines) | All sound effects synthesized via `AVAudioEngine` — no audio files for SFX. Uses `AVAudioPlayerNode` with separate music and SFX nodes. Contains `makeMeow()` for achievement sound. |
| `Utilities/MusicManager.swift` | Plays `theme_intro.wav` as background music. |
| `Utilities/HapticManager.swift` | Haptic feedback. |
| `Utilities/StatsManager.swift` | Persistent stats tracking (UserDefaults). |
| `Utilities/ShareImageRenderer.swift` | Renders a share image for the share sheet. |
| `Utilities/ShareSheet.swift` | UIActivityViewController wrapper. |
| `Views/GameOverOverlay.swift` (~282 lines) | Game over screen. Shows animated cat, score, near-miss message, retry button, play again button. |
| `Views/AnimatedCatView.swift` (27 lines) | Frame-by-frame pixel art cat animation. Cycles through `go_cat_01`…`go_cat_32` at 8fps. |
| `Views/GridView.swift` | The 6x6 game grid. |
| `Views/TileView.swift` | Individual colored tile rendering. |
| `Views/AchievementsView.swift` | Achievement gallery with pixel art cat icons. |
| `Views/CatMascotView.swift` | (May be legacy — the start screen cat is currently an `Image("cat_0095")` in ContentView) |
| `Views/WalkingCatView.swift` | Animated walking cat (used somewhere in UI). |
| `Views/TunnelBackground.swift` | Animated background effect behind the game grid. |
| `Views/ChromaHeader.swift` | Header component. |
| `Views/NextTilePreview.swift` | Shows what color tile comes next. |
| `Views/ScoreView.swift` | Score display component. |

### Asset Catalog
Located at: `Assets.xcassets/`

- **`cat_0000` through `cat_0095`** (96 frames) — Start screen cat animation. Currently only `cat_0095` is used as a static mascot image on the start screen.
- **`go_cat_01` through `go_cat_32`** (32 frames) — Game over cat animation. Pixel art Siamese cat extracted from `Game over cat.mp4`. Background removed (transparent PNG). These are displayed by `AnimatedCatView.swift`.
- **`ach_*`** (35 images) — Achievement badge icons (pixel art cats in costumes).
- **`AccentColor`**, **`AppIcon`** — Standard Xcode assets.

### Audio
- `theme_intro.wav` — The only audio file. Played as ambient background music at **volume 0.08** (barely audible). This is intentional — the user explicitly asked for "barely any music."

---

## Critical Design Decisions (DO NOT CHANGE without asking Cuth)

### Fonts
- **Everything uses `.system(design: .serif)`** — which renders as **New York** on iOS. This is the zen/chill vibe font. Do not switch to default SF Pro or any other font.

### Color Palette
- Background: `0xF5F5F7` (warm off-white)
- Primary text: `0x2A2A2A` or `0x3A3A4A` (near-black, warm)
- Secondary text: `0x6A6A7A` or `0xBBBBBB` (gray tones)
- Accent: `0x8D99AE` (steel blue — used for near-miss text, hints, "How to Play" items)
- Success: `0x2A9D8F` (teal green — checkmarks, combo messages)
- Warning/record: `0xF59E0B` (amber gold — "NEW RECORD" badge)
- Buttons: `0x2A2A2A` fill with white text (bold black pill style via `Capsule()`)

### Terminology
- "blends" not "steps" (e.g., "1 blend" / "3 blends")
- "Out of moves" not "GAME OVER"
- "LIVES" not "HEALTH" — displayed as teardrop icons
- "Play" / "Play Again" / "New Game" — button labels

### Sound
- **All SFX are synthesized** via AVAudioEngine — there are no sound effect audio files. Don't add audio files for SFX.
- **Achievement sound** = `makeMeow()` — a short (0.22s), quiet (volume 0.12), warm "mew" sound. It was explicitly made quieter after user feedback that the original was "obnoxious."
- **Music volume = 0.08** — User said "there should be barely any music." Don't raise this.

### Ads
- Google Mobile Ads SDK v11.13.0 (GAD-prefixed APIs)
- **All ad code is wrapped in `#if canImport(GoogleMobileAds)`** so the app compiles without the SDK.
- Ads are triggered on **Play Again tap** (not on game over trigger). This was explicitly moved so the player sees their score before any ad.
- Fibonacci-based scheduling via `AdScheduler` — not every game over shows an ad.

### Game Over Screen
- Shows `AnimatedCatView` (the sleeping pixel cat animation) at the top
- "Out of moves" title (not "GAME OVER")
- Large score with gradient text
- Near-miss Zeigarnik hook message in steel blue (e.g., "Just 50 points from your record")
- Retry with life button (if lives > 0)
- Share / Achievements / Play Again buttons at bottom
- Play Again = bold black pill button

### Start Screen
- Static cat mascot (`cat_0095`) peeking over the top of the stats card
- Two modes toggled by `showHowToPlay`:
  - **Main**: Cat, "Stillhue" title, "A color-blending puzzle" subtitle, Play button (black pill), "How to Play" text link
  - **How to Play**: 5 rules with SF Symbol icons in steel blue, serif text, Play button at bottom
- Transitions use `.opacity` with `.easeInOut(duration: 0.25)`

### Round Complete Overlays
- **Normal round**: Minimal — teal checkmark icon, "Round X" text, combo message if applicable. No score breakdown.
- **Milestone round** (every 5th): Sparkles icon, "Round X", "Milestone" subtitle. No "AMAZING!" or score breakdown.
- **Sub-target**: "Next color..." with serif font.
- All overlays use a glass card background (`glassCard(cornerRadius: 24)`).

---

## Technical Gotchas

### Swift Version & Observable
- Uses `@Observable` macro (Swift 5.9+). `GameState` is `@Observable class`, NOT `ObservableObject`. States in views use `@State private var game = GameState()`, NOT `@StateObject`.

### Xcode Build Quirks
- Xcode objectVersion 77 (latest project format)
- **SIGSTOP debugger pause**: When stopping a running build via the Stop button, the debugger sometimes pauses on `mach_msg2_trap` with "Thread 1: signal SIGSTOP." Fix: Click Continue (play button in debugger bar) first, then Stop, then Rebuild.
- Xcode is **"click" tier** for computer-use (can click buttons but cannot type). Simulator is **"full" tier**.

### Pixel Art Rendering
- All pixel art images use `.interpolation(.none)` to stay crisp. Never use default interpolation on pixel art — it will blur.

### Color Model
- `PrismColor` is the game's color type. Has `.name`, `.color` (SwiftUI Color), `.highlightColor`.
- `Color(hex:)` extension is used throughout for hex color codes.

---

## What Has Been Done (Recent Session Work)

1. **UX Audit & Polish**: Softened all copy, removed arcade energy, added zen feel
2. **Stats hierarchy**: SCORE is hero stat (30pt black), ROUND/BEST are secondary (16pt)
3. **Button styling**: All primary buttons are bold black pills (Capsule + 0x2A2A2A)
4. **Round overlays simplified**: Removed score breakdowns, made minimal
5. **Background music**: Enabled at 0.08 volume
6. **Ad timing moved**: From game-over trigger to Play Again button callback
7. **Achievement sound**: Rewritten as quiet, short cat "mew"
8. **Start screen redesigned**: Play + "How to Play" toggle, clean layout
9. **Game over cat animation**: Extracted 32 frames from user's video, removed white background, added to asset catalog as `go_cat_01`–`go_cat_32`, created `AnimatedCatView.swift`, integrated into `GameOverOverlay.swift`

---

## Known Future Work (acknowledged but not started)

1. **Daily Puzzle Mode** — Cuth said "I like the Daily Puzzle bit. It can be a separate button and page. Let's come back to that." This was identified as the highest-leverage feature for reaching $15M ARR. Should be a separate button on the start screen and a separate game mode page.

2. **Start screen cat could be animated** — Currently uses static `cat_0095`. The 96-frame animation (`cat_0000`–`cat_0095`) exists in the asset catalog but isn't being animated on the start screen. Could reuse the `AnimatedCatView` pattern.

3. **Start screen not fully verified** — The redesigned start screen with "How to Play" hasn't been visually confirmed in simulator (app loads with previous game state, bypassing start screen).

---

## How to Work on This Project

1. **Read files before editing** — Always read the current state of a file before making changes.
2. **Respect the vibe** — Zen, chill, minimal. No loud colors, no arcade language, no aggressive UI.
3. **Test in simulator** — Build via Xcode (Product > Run or the play button). Use iPhone 17 Pro simulator.
4. **Don't add audio files for SFX** — Everything is synthesized.
5. **Wrap ad code** — Always use `#if canImport(GoogleMobileAds)` guards.
6. **Use serif fonts** — `.system(design: .serif)` everywhere.
7. **Pixel art = `.interpolation(.none)`** — Always.

---

## File Paths Quick Reference

```
Project root:     /sessions/peaceful-trusting-cerf/mnt/aberration/
Xcode project:    /sessions/peaceful-trusting-cerf/mnt/aberration/aberration/aberration.xcodeproj
Source code:       /sessions/peaceful-trusting-cerf/mnt/aberration/aberration/aberration/
Assets:            /sessions/peaceful-trusting-cerf/mnt/aberration/aberration/aberration/Assets.xcassets/
Cat video source:  /sessions/peaceful-trusting-cerf/mnt/aberration/aberration/Game over cat.mp4
```

---

After reading this document, the next agent should say: **"I understand and am ready to go"**

If anything is unclear, ask Cuth before making changes.
