# Deep Research Request: Daily Puzzle Mode for Stillhue

## What I Need

Research and recommend the best "daily puzzle" mechanic for a color-mixing puzzle game. We've tried two approaches and neither feels right. I need you to study what makes daily puzzle games successful, analyze competitors, and propose a mechanic that fits our specific game system.

---

## About the Game: Stillhue

Stillhue is an iOS color-mixing puzzle game with an NYT Games-quality aesthetic. Think Wordle meets paint mixing.

### Classic Mode (works great, not changing this)

1. A **target color** is shown at the top (e.g., "TEAL")
2. Below it is a **5×5 grid** of colored tiles
3. The player **taps two tiles** to mix them — the colors blend using RYB color wheel math
4. If the result matches the target → round complete, next round, score increases
5. If not → the mixed result replaces one of the source tiles on the grid, and you try again
6. The game gets harder over rounds (more complex target colors, more distractor tiles)
7. 3 lives, no timer. Zen puzzle feel.

### The Color System

- **48 colors** on an RYB color wheel, spaced 7.5° apart
- **Depth 0 (primaries):** Red, Yellow, Blue — these can't be made by mixing
- **Depth 1 (secondaries):** Orange = Red + Yellow, Green = Yellow + Blue, Purple = Red + Blue — plus nearby shades
- **Depth 2 (tertiaries):** e.g., Teal = Green + Blue, Vermillion = Red + Orange — these require 2 mixes from 3 base colors
- **Depth 3+:** Even more complex, requiring chains of 3+ mixes
- **Mixing rule:** The result is always the midpoint between two colors on the wheel. So Red (position 0) + Yellow (position 16) = Orange (position 8).

The mixing is intuitive for primaries → secondaries (everyone knows Red + Blue = Purple). It gets much harder at depth 2+ because you need to know things like "what two colors make Teal?" — that's not common knowledge.

### The Audience

Casual mobile gamers. The kind of person who plays Wordle, NYT Connections, or Spelling Bee daily. They want something they can do in 2-3 minutes, share with friends, and feel clever about. They do NOT want to study color theory.

---

## What We Tried for "Hue of the Day"

### Attempt 1: Mix-on-the-grid (like Classic mode but daily)
- Full 5×5 grid, one target color, 4 solution tiles hidden among 21 distractors
- Player mixes tiles 2 at a time (tap two, they blend) trying to reach the target in 3 mixes
- 3 tries total

**Why it failed:** The player has to chain 3 mixes correctly — mix A+B to get an intermediate, then mix that with C, then mix that result with D to get the target. This requires knowing the color mixing tree, which nobody does. You're basically guessing. It felt random, not clever.

### Attempt 2: Pick the right tiles (no mixing)
- Full 5×5 grid, one target color, 3 solution tiles hidden among 22 distractors
- Player taps 3 tiles that would combine to make the target (tiles highlight, auto-checks on 3rd pick)
- 3 tries total

**Why it failed:** Even simpler, and still too hard. Knowing that Teal is made from Green + Blue is easy, but knowing *which specific shade of green and which specific shade of blue* from a grid of 25 tiles requires color theory knowledge. Plus there's no feedback — you just pick 3 and it says "wrong." No learning, no narrowing down. The creator couldn't even solve it consistently.

### The Core Problem

Both attempts suffer from the same issue: **the player has no way to reason about the answer.** In Wordle, you get yellow/green feedback that narrows the solution space. In Connections, you can see groupings and use process of elimination. In our game, you just... guess which colors mix to make the target, and you either know color theory or you don't.

---

## What I Need You to Research

### 1. Successful Daily Puzzle Mechanics
Deep dive into what makes these daily games work:
- **Wordle** — why does the feedback loop work so well?
- **NYT Connections** — how does the "group of 4" mechanic create satisfying difficulty?
- **NYT Strands** — how does it use hints and progressive revelation?
- **Spelling Bee** — how does the "always achievable" feeling work?
- **Contexto** — how does the "hot/cold" feedback work?
- **Chrono** — ordering mechanic
- **Bandle, Heardle** — daily music puzzles
- **Nerdle, Mathler** — daily math puzzles
- **Any color-specific daily puzzle games** that already exist (research this thoroughly)

For each: What's the core loop? How does the player get feedback? What makes it feel solvable? What makes it shareable?

### 2. Color-Specific Puzzle Games
Research any existing color mixing, color matching, or color theory games:
- Are there any daily color puzzle games?
- How do they handle the "most people don't know color theory" problem?
- What mechanics do color games use? (matching, sorting, gradient completion, hue identification, etc.)
- Look at: I Love Hue, Blendoku, Color Zen, Hues (color sorting), or anything similar

### 3. The Shareability Factor
Wordle's emoji grid was genius. What makes a daily puzzle result shareable?
- It needs to convey performance without spoiling the answer
- It needs to be compact (fits in a text message)
- It needs to create friendly competition
- What formats work? (emoji grids, scores, streaks, time)

### 4. Difficulty Calibration
- How do successful daily puzzles ensure ~70-80% of players can solve it?
- How do they create a range from "easy for experts" to "just barely solvable for casuals"?
- What's the ideal solve time for a daily mobile puzzle? (Research suggests 2-3 minutes)

---

## Constraints for Your Recommendations

Whatever you propose must work within our existing system:

1. **We have 48 colors on a wheel.** Mixing is always midpoint between two colors.
2. **We have a 5×5 grid** already built and styled.
3. **The target color + swatch display** is already built.
4. **We can show any combination of tiles, targets, text, and feedback** — the UI is flexible.
5. **It must be solvable without color theory knowledge.** The player should be able to reason their way to the answer using feedback from the game, not prior knowledge.
6. **It must be daily and seeded** — same puzzle for everyone.
7. **It must be shareable** — a compact result format.
8. **2-3 minute solve time** for an average player.
9. **It should feel related to the Classic mode** — color mixing should be involved somehow, not a completely different game.
10. **Simpler is better.** The mechanic should be obvious on first play without instructions.

---

## What I Want Back

1. **3-5 concrete daily puzzle mechanic proposals**, each with:
   - Name
   - One-paragraph description of the core loop
   - How feedback works
   - How difficulty is calibrated
   - Example share format
   - Pros and cons
   - How it maps to our color system

2. **Your top recommendation** with a detailed explanation of why it's the best fit

3. **A list of existing games** I should play for research/inspiration

---

## Context on Quality Bar

This game is being built to NYT-acquisition quality. The daily mode is the single most important feature for retention and virality. It needs to be as immediately compelling as Wordle was when it first blew up. We'd rather ship nothing than ship something that feels forced or confusing.
