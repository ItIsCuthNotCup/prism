# Chromatose (Blent) — Game Design Reference

## Purpose of This Document

This document describes every mechanic in Chromatose precisely enough that a research AI can reason about difficulty scaling, identify balance problems, and propose improvements without access to the source code. Every rule is stated; nothing is left implicit.

---

## 1. The Board

A 5×5 grid. Each cell is either empty or contains one colored tile. Maximum capacity: 25 tiles.

The board resets to empty at the start of each round. Tiles do not carry over between rounds.

---

## 2. The Color System

There are exactly 24 colors arranged in a circular wheel (like a clock face, positions 0–23). The wheel follows an RYB (Red-Yellow-Blue) model, not RGB.

### 2.1 The 24 Colors (in wheel order)

| Index | Name        | Depth |
|-------|-------------|-------|
| 0     | Red         | 0 (primary) |
| 1     | Scarlet     | 3 |
| 2     | Vermillion  | 2 |
| 3     | Tangerine   | 3 |
| 4     | Orange      | 1 |
| 5     | Amber       | 3 |
| 6     | Gold        | 2 |
| 7     | Lemon       | 3 |
| 8     | Yellow      | 0 (primary) |
| 9     | Lime        | 3 |
| 10    | Chartreuse  | 2 |
| 11    | Mint        | 3 |
| 12    | Green       | 1 |
| 13    | Jade        | 3 |
| 14    | Teal        | 2 |
| 15    | Cerulean    | 3 |
| 16    | Blue        | 0 (primary) |
| 17    | Azure       | 3 |
| 18    | Indigo      | 2 |
| 19    | Violet      | 3 |
| 20    | Purple      | 1 |
| 21    | Plum        | 3 |
| 22    | Magenta     | 2 |
| 23    | Crimson     | 3 |

### 2.2 Primaries

Red (0), Yellow (8), Blue (16). These are the building blocks — they can never be a blend target.

### 2.3 Depth

Depth = minimum number of blend steps from primaries to produce this color.

- **Depth 0**: The 3 primaries.
- **Depth 1**: Orange (Red+Yellow), Green (Yellow+Blue), Purple (Red+Blue). The 3 secondaries. Require 1 blend.
- **Depth 2**: Vermillion, Gold, Chartreuse, Teal, Indigo, Magenta. The 6 tertiaries. Require 2 blends from primaries, but the game provides a 2-tile recipe (see 2.5) so the player only makes 1 blend.
- **Depth 3**: Scarlet, Tangerine, Amber, Lemon, Lime, Mint, Jade, Cerulean, Azure, Violet, Plum, Crimson. The 12 quaternaries. Require 3+ blends from primaries, but the game provides a 2-tile recipe so the player makes 1 blend.

### 2.4 Mixing Rule

Mixing any two tiles produces the color at the **midpoint of the shorter arc** between them on the 24-position wheel.

Examples:
- Red (0) + Yellow (8) → Orange (4) — midpoint of 8-step arc
- Red (0) + Blue (16) → Purple (20) — shorter arc wraps through 20-24-0, midpoint = 20
- Red (0) + Orange (4) → Vermillion (2) — midpoint of 4-step arc

If two colors are exactly opposite (12 apart), a deterministic tiebreaker is used: `(lower_index + 6) % 24`.

Key property: **mixing is deterministic, commutative, and position-independent.** Any two tiles of the same colors produce the same result regardless of where they are on the board.

### 2.5 Recipes (What the Game Spawns)

Every non-primary target has a hand-curated "direct pair" — exactly 2 tiles that mix to produce it. Examples:
- Vermillion (2): Red (0) + Orange (4)
- Tangerine (3): Vermillion (2) + Orange (4)
- Purple (20): Red (0) + Blue (16)
- Crimson (23): Red (0) + Magenta (22)

When a round begins, the game spawns these 2 ingredient tiles on the board. The player's job is to find them and blend them together.

Par for any target = (number of ingredient tiles) - 1 = always 1, since exactly 2 ingredients are always spawned.

---

## 3. Round Structure

### 3.1 Round Flow

1. Board is cleared (all tiles removed).
2. Target color is chosen (not a primary, not already on the board).
3. The 2 ingredient tiles for the target are spawned at random empty positions.
4. Distractor tiles (random primaries) are spawned at random empty positions.
5. Poison tiles (random non-primaries) are spawned at random empty positions (round 11+).
6. Player blends tiles to produce the target.
7. When the target is matched, the matched tile is removed, and the round advances.

### 3.2 Multi-Target Rounds

Some rounds require the player to match multiple targets sequentially within the same round:

| Rounds | Targets per round |
|--------|-------------------|
| 1–14   | 1 |
| 15–24  | 2 |
| 25–39  | 3 |
| 40+    | 4 |

When a sub-target is matched, the matched tile is removed, new ingredients for the next target are spawned into the remaining board, and the player continues. The board is NOT cleared between sub-targets — only at the start of the round.

This is critical: in a 3-target round, leftover tiles from sub-target 1 and 2 are still on the board when working on sub-target 3. The board accumulates within a round.

### 3.3 Ingredient Placement

- **Rounds 1–2**: Ingredients are placed in a connected cluster (adjacent cells) so new players see they're related.
- **Round 3+**: Ingredients are scattered randomly, avoiding positions that were just emptied by the last match.

---

## 4. Player Actions

### 4.1 Blending

The player taps two tiles in sequence. The first tile is replaced with the blend result; the second tile is removed (freeing one cell). Net effect: tile count decreases by 1, one new color appears.

### 4.2 Undo

One undo per round. Reverts the last blend (restores both tiles and the score). Once used, no further undos are available until the next round.

### 4.3 Deselect

Tapping an already-selected tile deselects it.

---

## 5. Difficulty Levers (Current Implementation)

### 5.1 Target Depth (maxDepth)

Controls which colors can appear as targets:

| Rounds | Max Depth | Eligible Targets |
|--------|-----------|------------------|
| 1–3    | 1         | 3 colors (the secondaries: Orange, Green, Purple) |
| 4–9    | 2         | 9 colors (secondaries + tertiaries) |
| 10+    | 3         | 21 colors (everything except primaries) |

### 5.2 Distractor Count

Extra primary tiles spawned alongside ingredients, cluttering the board:

| Rounds | Distractors |
|--------|-------------|
| 1–2    | 0 |
| 3–5    | 1 |
| 6–10   | 2 |
| 11–15  | 3 |
| 16–20  | 4 |
| 21–30  | 5 |
| 31+    | 6–8 (grows by 1 every 10 rounds, capped at 8) |

Distractors are always **primaries** (Red, Yellow, or Blue). They can be useful — the player can blend them to create needed colors — but they occupy space and create confusion.

### 5.3 Poison Tiles

Appear starting at round 11. Tapping a poison tile = instant game over.

| Rounds | Poison tiles |
|--------|-------------|
| 1–10   | 0 |
| 11–15  | 1 |
| 16–20  | 2 |
| 21–25  | 3 |
| 26–30  | 4 |
| ...    | +1 every 5 rounds |

Poison tiles are visually marked with a ⚠️ icon but use non-primary colors, so they can be confused with useful tiles at a glance. They are placed at random empty positions. Blending any tile with a poison tile removes the poison (both tiles are consumed, result replaces first tile's position). Poison is only deadly when directly tapped.

### 5.4 Multi-Target Rounds

See section 3.2. This is the most impactful difficulty lever because sub-targets accumulate tiles within the round — the board never clears between sub-targets.

---

## 6. Scoring

| Action | Points |
|--------|--------|
| Any blend | +10 |
| Matching the target | +(round × 50) |
| Matching at par (exactly 1 blend) | +100 bonus |
| Matching under par (0 blends — only possible if target accidentally exists on the board) | +200 bonus |

Score increases linearly with round number because the match bonus is `round × 50`.

---

## 7. Game Over Conditions

The game ends when any of these occur:

1. **No winning path exists**: After each blend, the game runs a recursive search (up to 50,000 nodes) on all remaining tile colors to determine if any sequence of blends can produce the target. If no path exists, game over. This is computationally expensive but exact.

2. **Board full and can't spawn ingredients**: At the start of a round (or sub-target), if there aren't enough empty cells to place the 2 ingredient tiles, game over.

3. **Poison tile tapped**: Instant game over.

### 7.1 The "No Winning Path" Check — Important Detail

The `canStillWin()` function considers ALL tiles on the board (including distractors and other leftovers) when searching for a winning blend sequence. It tries every possible pair of tiles to blend, then recursively checks if the resulting board state can still reach the target. This means the game only ends when it's truly mathematically impossible to win — not just when it looks hard.

However: the search caps at 50,000 nodes and returns `true` (assumes winnable) if the cap is hit. So very complex board states are assumed to be winnable.

---

## 8. Current Difficulty Curve — Analysis

### 8.1 Early Game (Rounds 1–10)

Very easy. Single targets, few distractors, no poison. The player is learning how the color wheel works. Board resets each round so there's no accumulation pressure.

### 8.2 Mid Game (Rounds 11–20)

Difficulty ramps: poison tiles appear, distractors increase, multi-targets start at round 15. This is the learning curve — the player must start planning ahead and avoiding poison.

### 8.3 Late Game (Rounds 21+)

Multi-target rounds with 2-3 targets mean the board fills up within a single round even though it starts clean. With 5+ distractors per round plus ingredients for each sub-target, a 3-target round can place 2+5+2+2 = 11+ tiles on a 25-cell board. Plus poison. Board management becomes critical.

### 8.4 The Death Spiral

In multi-target rounds, each blend reduces tile count by 1, but each sub-target match also removes the matched tile. So after sub-target 1 (1 blend + 1 removal = -2 tiles), the board has space. But sub-target 2 spawns 2 new ingredients, and sub-target 3 spawns 2 more. If the player makes inefficient blends (using extra blends beyond par), tiles accumulate faster than they're removed.

---

## 9. What Another AI Should Know Before Proposing Changes

### 9.1 Invariants That Must Be Preserved

- **Every round must be theoretically solvable when it starts.** The ingredients for the target are always spawned. The player can always solve it in exactly 1 blend if they find the right pair.
- **The color wheel mixing rule is the core identity.** Changing the mixing algorithm would break the entire game.
- **Par is always 1** for every target (2 ingredients, 1 blend needed). This is a design choice that keeps rounds fast.
- **The recursive win-check must remain correct.** Any board state modification must not break `canStillWin()`.

### 9.2 Safe Dimensions to Adjust

- Number and type of distractors (currently always primaries — could be non-primaries, secondaries, etc.)
- Number of poison tiles and their behavior (currently instant death — could be point penalty, timer, etc.)
- Multi-target thresholds (when 2/3/4-target rounds begin)
- Board size (currently fixed at 5×5)
- Whether/how many tiles carry over between rounds (currently: none, board resets)
- Timer pressure (currently: none)
- Undo availability (currently: 1 per round)
- Scoring weights and bonuses
- New tile types (e.g., wildcard tiles, frozen tiles, tiles that decay)
- New mechanics (e.g., adjacency requirements for blending, tile gravity, chain reactions)

### 9.3 Current Weaknesses (Observed During Playtesting)

1. **Poison tiles are visually subtle.** Small ⚠️ icon on a colored tile. Easy to tap accidentally, which feels unfair.
2. **No board fullness indicator.** The player can't see how many empty spaces remain.
3. **"New Game" button has no confirmation.** Accidental taps erase a long run.
4. **Empty cells are visually indistinct from very light-colored tiles.** The empty state blends with the board background.
5. **Similar colors (multiple shades of blue) are hard to distinguish** on the grid without labels.
6. **The background pattern intensifies with round depth**, competing with the board for visual attention at exactly the moments the player needs maximum focus.
7. **Difficulty levers all scale monotonically.** There's no ebb and flow — every round is harder than the last, with no "breather" rounds. This creates fatigue.
8. **The par system has no teeth.** Going over par has no penalty — you just don't get the bonus. There's no reason to avoid extra blends other than board space.
9. **Distractors are always primaries**, which are actually *useful* (you can blend them toward the target). True distractors should sometimes be *unhelpful* colors.

---

## 10. Complete State Machine

```
NEW_GAME
  → startNewRound()
    → clear board
    → choose target(s)
    → spawn ingredients + distractors + poison
    → PLAYING

PLAYING
  → player taps tile A (first tap)
    → if poison: GAME_OVER
    → else: tile A is selected
  → player taps tile B (second tap)
    → if B == A: deselect
    → else: perform blend(A, B)
      → result replaces A, B is removed
      → if result == target:
        → if more sub-targets: advance to next sub-target, spawn new ingredients → PLAYING
        → if no more sub-targets: ROUND_COMPLETE
      → else:
        → run canStillWin()
        → if false: GAME_OVER
        → else: PLAYING

ROUND_COMPLETE
  → show overlay (auto-dismiss after 0.6–1.4s, or tap to dismiss)
  → startNewRound() → PLAYING

GAME_OVER
  → show game over screen with stats
  → "Play Again" → NEW_GAME
```

---

## 11. Key Files (for implementation reference)

| File | Contents |
|------|----------|
| `Models/GameState.swift` | All game logic, state machine, difficulty scaling, win checking |
| `Item.swift` (PrismColor) | Color wheel definition, mixing algorithm, recipes, ingredient tables |
| `Models/GridPosition.swift` | 5×5 grid position struct |
| `ContentView.swift` | Main game view, overlays, UI layout |
| `Views/GameOverOverlay.swift` | Game over screen |
| `Views/AchievementsView.swift` | Achievement grid display |
| `Utilities/StatsManager.swift` | Persistent stats and achievement tracking |
