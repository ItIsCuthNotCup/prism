# Stillhue — Sensory Design Audit
## Goal: Make every screen recording "oddly satisfying" for TikTok virality

**Audited by:** Claude (watching live gameplay, reading all source code)
**Date:** April 5, 2026
**Build observed:** Xcode simulator, iPhone 17 Pro, ~38 rounds played

---

## 1. CURRENT SOUND DESIGN — Exact Technical Specs

All SFX are synthesized via `AVAudioEngine` (no audio files for SFX). One audio file exists: `theme_intro.wav` for background music.

### Master Volume
- `engine.mainMixerNode.outputVolume = 0.35` (global)
- Music node: `0.5` on menu, `0.08` during gameplay (barely audible)
- Overall: **very quiet**. On a phone speaker this would be nearly inaudible in most environments.

### Individual Sound Events

| Event | Sound Design | Frequency Range | Duration | Volume | Haptic |
|-------|-------------|----------------|----------|--------|--------|
| **Tile select** | Single sine tone (A5, 880Hz) with glass harmonics | 880Hz | 80ms | 0.15 | Light impact |
| **Blend/mix** | Per-color tone mapped to wheel position. Sine + harmonics. D4→D6 range (~294–1175Hz) across 48 colors | 294–1175Hz | 180ms | 0.35 | Medium impact |
| **Round complete** | C major arpeggio: C5→E5→G5, staggered 80ms apart | 523–784Hz | ~380ms total | 0.30 | (none observed) |
| **Milestone (every 5th round)** | Extended arpeggio: C5→E5→G5→C6→E6, staggered 65ms | 523–1319Hz | ~580ms total | 0.30 | (none observed) |
| **Game over** | Descending minor third: G4→Eb4, warm timbre (0.85 warmth = nearly pure sine) | 311–392Hz | ~500ms total | 0.20 | Error notification |
| **Achievement unlock** | Synthesized "mew" — pitch sweep 600→850→500Hz with 3rd harmonic (nasal) | 500–850Hz | 220ms | 0.12 | (none observed) |
| **Celebration cats** | 5 variants, all major-key arpeggios (clapping, chase, binoculars, stretch, roll). Sine + harmonics. | ~349–1047Hz | 150–560ms | 0.20–0.25 | (none observed) |

### Background Music
- `theme_intro.wav` — loaded from bundle, looped via `musicNode`
- Menu volume: 0.5 × 0.35 master = **~17.5% effective volume**
- Gameplay volume: 0.08 × 0.35 master = **~2.8% effective volume** (intentionally "barely there")

### Sound Synthesis Method
- All tones: sine wave + 2nd harmonic (0.15) + 3rd harmonic (0.05) = "glass bell" timbre
- Envelope: 6ms attack, last 55% of duration decays with power curve (exponent 2.5)
- Arpeggios: notes layered into a single buffer with time offsets
- Warmth parameter: reduces harmonics toward pure sine (used on game over for gentleness)
- Cat meow: square-wave pitch sweep with 3rd harmonic for nasal quality

### Haptic Feedback (HapticManager.swift)
| Event | Style |
|-------|-------|
| Tile placed/selected | `UIImpactFeedbackGenerator(.light)` |
| Blend | `UIImpactFeedbackGenerator(.medium)` |
| Line clear | `UIImpactFeedbackGenerator(.heavy)` |
| Cascade/success | `UINotificationFeedbackGenerator(.success)` |
| Game over | `UINotificationFeedbackGenerator(.error)` |

---

## 2. CURRENT VISUAL DESIGN — Exact Technical Specs

### Color Palette
- Background: `0xF5F5F7` (warm off-white)
- Primary text: `0x3A3A4A` (warm near-black)
- Secondary text/labels: `0x888888` (size 10, semibold)
- Floating points: rendered in **target tile color** (not a fixed color)
- Bonus text: also in target tile color

### Typography
- **Everything**: `.system(design: .serif)` = New York on iOS
- Score: large bold serif
- Labels: size 10, semibold
- Bonus: size 14, bold, `.rounded` design (note: this breaks the serif rule — uses system rounded instead)
- Floating points total: size 28, black weight, `.rounded` design (also breaks serif rule)

### Tile Rendering (TileView.swift)
- `RoundedRectangle(cornerRadius: 10)`
- Fill: `LinearGradient` from `highlightColor` (top-left) to `color` (bottom-right)
- Glass specular overlay: white gradient 0.45→0.15→0.0→clear (top-left to bottom-right)
- Inner top-edge catch: white 0.3→clear, 12pt tall
- Border: white 0.35 opacity, 0.5pt (normal), 2.5pt white (selected/hinted)
- Shadow: color-matched, radius 4 (normal), 8 (selected), 12 (matched)
- Hint glow: pulsing animation 0.8s ease-in-out, repeating

### Tile Animations
| State | Scale | Opacity | Spring Config |
|-------|-------|---------|---------------|
| Normal | 1.0 | 1.0 | — |
| Selected | 1.0 | 1.0 | response: 0.25, damping: 0.7 |
| Blending | 0.3 | 0.5 | easeIn 120ms |
| Blend result | 1.06 | 1.0 | response: 0.25, damping: 0.7 |
| Matched | 1.12 | 1.0 | response: 0.25, damping: 0.7 |
| Popping | 1.18 | 1.0 | response: 0.15, damping: 0.5 |

### Floating Points Animation (FloatingPointsView.swift)
- Phase 1 (0ms): Bonus label drops in — spring 0.25/0.7
- Phase 2 (200ms): Total score pops in below — spring 0.3/0.6
- Phase 3 (700ms): Bonus collapses into total (fades, shrinks, slides down)
- Phase 4 (950ms): Total pulses to 1.2× then settles
- Phase 5 (1200ms): Whole group flies upward -120pt, shrinks to 0.3×, fades out (easeIn 350ms)
- Without bonus: pop in, hold 500ms, then zoom to score

### Background (TunnelBackground.swift)
- **Layer 1**: Grey dot grid (graph paper), 20pt spacing, 1.2pt radius dots, opacity fades with depth
- **Layer 2**: Colored marks using **discovered palette** (colors the player has mixed)
- 7 layout styles: scattered grid, free scatter, radial burst, diagonal bands, clusters, confetti, corner bloom
- 8 shape types: circle, square, diamond, triangle, ring, cross, star, dot
- Mark count: 60–200 per round (scales with depth)
- Mark sizes: 2.5–10pt radius
- Mark opacity: 0.06–0.22 (always subtle)
- Pattern regenerates per round (seeded PRNG = deterministic per seed)
- New game = new seed entirely

### Chromatic Aberration Border (ChromaticAberrationBorder.swift)
- Three colored strokes (R/G/B) offset 3pt max, blurred 4pt, glow 10pt
- Rotates offset direction via `phase` parameter
- Uses `.plusLighter` blend mode
- Active during score multiplier (3× golden, 5× untouchable)

### Game Over Screen
- Animated pixel cat (sleeping Siamese, 32 frames at 8fps via AnimatedCatView)
- Dynamic header: "Game Over" / "Nice Try" / "Great Run" / "Incredible" / "New Record"
- Large score with serif text
- Round reached + best score
- Zeigarnik hook: "X rounds from Round Y" or "X points from your best"
- "Needed: [color swatch] COLOR_NAME" — shows what they died on
- Share / Awards / Play Again buttons (Play Again = black pill capsule)
- Glass card overlay

### Start Screen
- Static pixel cat (`cat_0095`) — not animated (96-frame animation exists but unused)
- "Stillhue" title, "A color-mixing puzzle" subtitle
- Two mode buttons: "Classic" and "Hue of the Day"
- "How to Play" toggle link at bottom
- Settings gear top-right

---

## 3. WHAT'S WORKING (keep these)

1. **The tile glass effect is beautiful.** The gradient fill + specular highlight + color-matched shadow creates genuinely attractive tiles. The grid at rounds 20-35 with a full spread of colors looks like stained glass.

2. **Color variety is inherently satisfying.** By round 20+, the board has 8-12 distinct hues. The visual contrast between warm and cool colors is eye-catching.

3. **The background evolves with the player.** Using discovered colors in the background creates a subtle "your world is growing" effect. This is clever and invisible to most players but contributes to the feeling.

4. **The cat mascot is charming.** Pixel art Siamese cat is distinctive and TikTok-friendly as a brand element.

5. **The game over screen is well-designed for retention.** Zeigarnik hooks, dynamic headers, and showing what color killed you are all strong.

---

## 4. WHAT NEEDS CHANGING — Prioritized for "Oddly Satisfying"

### CRITICAL — The Mix Moment (highest priority for TikTok)

**Problem:** The actual color mixing — the core "oddly satisfying" moment — has almost no visual payoff. When two tiles mix:
- Source tile shrinks to 0.3× and fades to 0.5 opacity (120ms easeIn)
- Result tile appears at 1.06× scale with a spring
- That's it. No color blending animation, no particle effect, no visual "flow" between tiles.

**What it needs:** This is THE moment people would replay on TikTok. The two colors need to visually flow/merge into the result. Think: paint mixing, watercolor bleeding, liquid chrome pooling. The sound should accompany this with a satisfying tonal resolution.

**Research needed:** What visual effects make color mixing feel liquid/physical? Reference: satisfying paint mixing videos, slime mixing, watercolor wet-on-wet. The key is the TRANSITION — seeing two distinct colors become one.

### CRITICAL — Sound Design is Too Quiet and Too Simple

**Problem:** The entire sound palette is simple sine waves at very low volume. For TikTok audio capture:
- Master volume at 35% means screen recordings will be nearly silent
- All tones use the same "glass bell" timbre — no variety
- The blend tone (180ms) is shorter than human perception of "satisfying" (~300-500ms)
- No sound for the RESULT appearing — only the blend action
- No escalating audio feedback for streaks/combos
- The round complete arpeggio (C-E-G, 380ms) is too fast and generic
- No satisfying "click" or "snap" on tile selection

**What it needs:**
- Higher base volume for screen recording viability
- Distinct timbres per event type (not just frequency changes on the same sine wave)
- The mix/blend sound should have a tonal RESOLUTION — two notes becoming one chord
- Streak sounds that build (each consecutive perfect mix should pitch up or add harmony)
- A "snap" or "pop" on tile placement that feels tactile
- The round-complete sound needs to be more emotionally rewarding (longer, richer)

**Research needed:** What sounds trigger ASMR-like satisfaction? Reference: Tetris effect studies, "brain tingles" audio research, satisfying click/pop sounds in apps like Duolingo and Headspace. Key question: what frequency ranges and timbres create the "oddly satisfying" audio response?

### HIGH — No Visual Feedback for Streaks

**Problem:** Getting 5 perfect mixes in a row looks identical to getting 1. There's no visual escalation that would make a viewer think "wow, they're on a roll." The chromatic aberration border only activates for score multipliers, not for streaks of good play.

**What it needs:** Progressive visual intensity — each consecutive good round should make the next round's success feel MORE rewarding. This creates the visual "crescendo" that makes TikTok viewers watch to the end. Think: background getting more vivid, tile glow intensifying, particle density increasing.

### HIGH — Score Animation Could Be More Satisfying

**Problem:** The floating points animation is functional but not mesmerizing. The text pops in, merges, and flies up. It's well-timed but doesn't create a "wow" moment.

**What it needs:** The score should feel like it has WEIGHT. Consider: numbers that roll/count up (slot machine style), particles that spray from the merge point, the score counter at the top visually reacting when points arrive (pulse, glow, ripple).

### MEDIUM — Tile Appearance is Instant

**Problem:** New tiles appear on the grid with no entrance animation. They just "are there." For an oddly satisfying game, tiles should materialize in a way that feels good — fade in, scale up with a bounce, spread like a drop of paint.

### MEDIUM — The Background is Too Subtle

**Problem:** The background pattern (discovered colors, shapes) is so subtle (6-22% opacity) that it's invisible in screen recordings. The graph paper dots are more visible than the colored elements. This could be a beautiful evolving canvas but it's currently invisible to casual viewers.

### MEDIUM — No Particle System

**Problem:** There are no particles anywhere — no sparkles on perfect mix, no confetti on milestones, no shimmer on golden tiles. Particles are one of the most reliable "oddly satisfying" visual triggers.

### LOW — Font Inconsistency

**Problem:** The bonus labels and floating points use `.rounded` design instead of `.serif`. This creates a subtle style mismatch with the rest of the app.

### LOW — Start Screen Cat is Static

**Problem:** 96 frames of cat animation exist in the asset catalog but aren't used on the start screen. A gently animated cat would be more inviting and more TikTok-friendly.

---

## 5. RESEARCH ASSIGNMENTS FOR AI AGENTS

### Agent 1: Audio Satisfaction Research
**Question:** What specific sound characteristics (frequency, timbre, duration, envelope, harmonics) create the "oddly satisfying" or ASMR-like response in mobile game audio?

Research areas:
- What makes Duolingo's sound design so satisfying? (specific frequencies, chime patterns)
- What frequency ranges trigger "brain tingle" / ASMR responses?
- How do "satisfying click" compilations achieve their effect? (attack time, harmonic content)
- What is the ideal duration for a "reward sound" in mobile games? (too short = forgettable, too long = annoying)
- How should sounds escalate during streaks? (pitch, harmony, layering, tempo)
- What volume levels are optimal for screen recording virality on TikTok?
- How does musical key/mode affect emotional satisfaction? (major vs. mixolydian vs. pentatonic)
- Reference games: Monument Valley, Alto's Odyssey, Threes!, I Love Hue
- Reference apps: Headspace, Calm, Duolingo
- What role does bass/sub-bass play in satisfaction on phone speakers vs. headphones?

Deliverable: Specific frequency, timbre, and envelope recommendations for each game event (tile select, mix, round complete, milestone, game over, streak escalation).

### Agent 2: Visual Satisfaction Research
**Question:** What specific visual effects and animations create the "oddly satisfying" response that makes content go viral on TikTok?

Research areas:
- What makes paint/color mixing videos so satisfying? (the transition physics, speed, viscosity)
- What particle effects create the most satisfaction? (sparkle, confetti, ripple, bloom)
- What animation curves feel most "juicy"? (overshoot, bounce, elastic vs. spring)
- How do the most satisfying mobile games handle the moment of success? (reference: 2048 merge, Candy Crush match, Tetris line clear)
- What role does color theory play in visual satisfaction? (complementary colors mixing, chromatic progression)
- What background effects enhance the "zen" feeling without distracting? (slow drift, parallax, breath-like pulse)
- What makes something "oddly satisfying" vs. just "nice"? (precision, symmetry, completion, transformation)
- How should visual intensity escalate during streaks?
- What TikTok-specific visual qualities get the most engagement? (high contrast, slow motion moments, seamless loops)
- Reference: satisfying art videos, ASMR visual triggers, soap cutting, paint pouring

Deliverable: Specific animation specifications (curves, durations, effects) for the mix moment, round completion, streak escalation, and particle systems.

### Agent 3: Addiction/Engagement Loop Research
**Question:** What sensory design patterns create the strongest "I need to play again" response, and how do the most successful casual games combine sound + visuals + haptics into a unified satisfaction loop?

Research areas:
- How do slot machines combine sound + light + haptics for maximum engagement? (variable ratio reinforcement schedule applied to sensory feedback)
- What is the "juice" framework in game design? (Jan Willem Nijman's talk, Vlambeer's approach)
- How does Candy Crush's sensory feedback loop work technically? (sound layering, screen effects, combo escalation)
- What role do haptics play in mobile game satisfaction? (which UIFeedbackGenerator patterns feel best?)
- How should the sensory "reward" scale with achievement? (linear vs. exponential vs. logarithmic escalation)
- What is the ideal feedback delay between action and reward? (instantaneous vs. slight delay for anticipation)
- How do zen/relaxation games keep players engaged without stress? (Flow state research, Csikszentmihalyi)
- What makes players want to SHARE a moment? (peak emotional moments, personal bests, "almost" moments)
- How should the game over sequence be designed to maximize replay intent?
- What is the relationship between sensory polish and perceived game quality? (does 20% more polish = 2× more downloads?)

Deliverable: A unified sensory feedback framework — mapping every game event to coordinated sound + visual + haptic responses, with escalation curves for streaks and progressive difficulty.

---

## 6. SUMMARY — The Gap

The game's visual design is **clean and attractive**. The gameplay loop is **solid**. The color system is **deep and interesting**.

But for "oddly satisfying" TikTok virality, the game is currently **too quiet, too subtle, and too instantaneous**. The core problem is that the most important moment — two colors becoming one — has almost no sensory payoff. That single moment, done right, is the entire TikTok strategy.

**Priority order:**
1. Make the mix moment visually mesmerizing (visual flow/merge effect)
2. Make the mix moment sonically satisfying (tonal resolution, richer timbre)
3. Add streak escalation (visual + audio builds with consecutive successes)
4. Add particles (sparkles, ripples, bloom on success moments)
5. Increase overall volume for screen recording
6. Make score feedback feel weighty (counting, particles, receiver reaction)

The game doesn't need to become loud or flashy — the zen vibe should stay. But "zen" and "satisfying" aren't opposites. Think: a perfectly smooth stone skipping across still water. Calm, beautiful, AND deeply satisfying.
