# Sound Design Brief — Stillhue (Color-Mixing Puzzle Game)

## What I Need From You

Design a complete sound palette for a cozy iOS puzzle game called **Stillhue**. I need you to specify the **exact musical approach** for each sound below — instruments, notes, chords, tempo, dynamics, timbre, effects — so that a developer can synthesize or produce each sound precisely.

I will be generating these sounds programmatically (synthesized WAV files, not recordings), so your recommendations should be translatable to synthesis: waveform types, frequencies, envelope shapes, effects chains, etc.

---

## The Game

Stillhue is a color-mixing puzzle. The player taps two colored tiles on a grid to blend them, trying to match a target color. It has a pixel-art cat mascot, a prismatic/glass aesthetic, and a zen pace (no timer, no pressure). Think of it as a meditative toy that happens to have a score.

---

## The Vibe (CRITICAL)

**Reference soundtracks:**
- **Animal Crossing** — soft rounded piano, jazzy major 7th chords, cozy and warm
- **Minecraft (C418)** — sparse ambient piano, long reverb, lots of breathing room between notes
- **Stardew Valley** — gentle, pastoral, cheerful without being hyper

**The feeling:** Someone whistling contentedly while walking through a park on a sunny afternoon. Warm. Safe. Delightful. Never anxious, never dark, never sharp.

**Hard rules:**
- NO horror vibes (no sustained drones, no pulsing/tremolo, no low rumbling, no hollow pure sine tones)
- NO harsh or startling transients
- NO minor keys for any SFX (minor is okay sparingly in the theme for emotional depth, but SFX must feel positive)
- NO synthetic/robotic feeling — everything should sound organic, like a real instrument being played softly
- The overall sonic identity should feel like a **warm wooden instrument** (kalimba, marimba, toy piano, music box) rather than electronic

---

## Audio Constraints

- **Format:** Mono WAV, 44100 Hz, 16-bit
- **Synthesis:** These will be generated programmatically (additive/FM synthesis + effects), not sampled
- **No tremolo or amplitude modulation** — previous versions used 10 Hz alpha-wave tremolo and it sounded like an 80s horror movie
- **Reverb is welcome** — simulated room reverb (multi-tap delay) gives the C418 spacious quality

---

## The Sounds I Need Designed

### 1. SELECT (Tile Tap Confirmation)

**When it plays:** Player taps a tile on the grid to select it for blending.
**Duration:** Very short — 0.2–0.4 seconds.
**Emotional role:** "Got it." Responsive, tactile confirmation. The player needs to feel their tap registered instantly.
**Paired haptic:** Crisp, light tap (0.35 intensity).
**Frequency:** Plays constantly — every tile tap. Must not be fatiguing over hundreds of taps.

**Design this:** What instrument sound? What note(s)? What envelope shape? What makes it satisfying but not annoying after 500 taps?

---

### 2. BLEND TONES (48 variants — Color Mixing Feedback)

**When it plays:** Two tiles merge into a new color. The specific tone depends on the *resulting* color's position on the 48-color wheel (0–47, where 0=Red, 8=Orange, 16=Yellow, 24=Green, 32=Blue, 40=Purple).
**Duration:** 0.3–0.6 seconds.
**Emotional role:** "Something transformed." Satisfying, tangible feedback that a mix happened. The tone should feel connected to the color — warm colors should sound different from cool colors.
**Paired haptic:** Soft thud blooming outward (0.5 intensity initial → 0.25 sustained bloom).

**Design this:** How should the 48 tones relate to each other musically? Should warm colors (red/orange/yellow) use different timbres or just different pitches from cool colors (blue/purple)? What's the frequency range? What instrument character? How do you make 48 variations that all sound cohesive but distinguishable?

---

### 3. ROUND COMPLETE (Standard Success)

**When it plays:** Player's blend matches the target color. Round advances.
**Duration:** 0.8–1.5 seconds.
**Emotional role:** "Nice one!" Warm satisfaction. Rewarding but not over-the-top — this plays every successful round (which can be every 10–30 seconds during good play). Must not become grating.
**Paired haptic:** Firm tap → warm swell → gentle fade (0.6 → 0.4 → 0.25 intensity).

**Design this:** What melodic phrase? What interval relationships? How do you make "success" that stays pleasant on the 50th hearing?

---

### 4. MILESTONE (Major Achievement — Every 4th Round)

**When it plays:** Player completes round 4, 8, 12, 16, 20, etc. Also plays when the daily puzzle is solved.
**Duration:** 1.2–2.0 seconds.
**Emotional role:** "That was special!" Celebration and progression. This is the BIG success sound — more triumphant than round complete, marking a real checkpoint. The player should feel they crossed a threshold.
**Paired haptic:** Same as round complete (firm tap → swell → fade).

**Design this:** How does this build on the round complete sound? What makes it feel like a "leveled up" version? What chord voicing gives it that Animal Crossing warmth?

---

### 5. GAME OVER (Gentle Failure)

**When it plays:** No valid moves remain on the board, or player uses all 5 daily puzzle attempts.
**Duration:** 1.2–2.0 seconds.
**Emotional role:** "Time to rest." Gentle, sympathetic, NOT punishing. The code comments literally say "the player already feels bad enough." This should feel like setting something down softly, not like a buzzer. Think: a kind teacher saying "good try."
**Paired haptic:** Soft descending thud → empathetic fade (0.4 → 0.2 intensity).

**Design this:** How do you make "you lost" sound gentle and warm instead of sad or scary? What notes/intervals convey "that's okay" rather than "you failed"?

---

### 6. MEOW (Achievement Unlock Notification)

**When it plays:** Player unlocks an achievement badge. A small toast appears in the corner. Can fire up to 3 times in quick succession (1.5 seconds apart).
**Duration:** 0.2–0.4 seconds.
**Emotional role:** "Surprise!" Cute, charming, attention-getting without being startling. The cat mascot is "meowing" at you to say congrats.
**Paired haptic:** Light tap (0.35 intensity).

**Design this:** How do you make a synthesized sound that reads as "cute cat chirp" without using an actual cat sample? What frequency contour says "meow" musically?

---

### 7. CELEBRATIONS (5 Cat Animation Sounds)

These play randomly every 1–6 rounds after a successful round. A cat animation plays on screen. Each celebration has a different animation and needs a matching sound.

#### 7a. CLAPPING CAT
**Animation:** Cat pops up from bottom, claps paws together, drops back down.
**Duration:** ~2 seconds.
**Emotional role:** Encouraging applause. "You're doing great!"

#### 7b. CHASE CAT
**Animation:** Cat with a mouse runs horizontally across the screen left-to-right.
**Duration:** ~2 seconds.
**Emotional role:** Energetic, whimsical. A playful moment of joy.

#### 7c. BINOCULARS CAT
**Animation:** Cat pops up holding binoculars, looks around, faces camera, sinks back down.
**Duration:** ~2.5 seconds.
**Emotional role:** Curious and wondering. Discovery. "What did you find?"

#### 7d. STRETCH CAT
**Animation:** Cat appears, does a long stretch, then transitions to running off-screen.
**Duration:** ~3 seconds.
**Emotional role:** Relaxed satisfaction → playful energy. Contentment.

#### 7e. ROLL CAT
**Animation:** Cat pops up and rolls over playfully, then drops back down.
**Duration:** ~2.5 seconds.
**Emotional role:** Silly, spontaneous joy. Pure happiness.

**Design these:** Each needs a distinct sonic personality that matches its animation, but all five should feel like they belong to the same "family" of sounds. What unifies them? What differentiates them?

---

### 8. THEME MUSIC (Background Loop)

**When it plays:** Loops continuously. At 50% volume on menus, drops to 8% during gameplay (barely-there ambient bed).
**Duration:** 16 seconds (seamless loop).
**Emotional role:** Sets the entire mood of the game. This is the first thing a player hears. At menu volume it should feel inviting and cozy. At gameplay volume it should be an almost-subconscious ambient texture.

**Design this:** What key? What chord progression? How many notes per bar? What instrument? How sparse should it be? How do you make a 16-second loop that doesn't feel repetitive? Reference C418's "Minecraft" and Animal Crossing's hourly music for the feeling.

---

## What I Need Back

For each sound above, please provide:

1. **Instrument/timbre description** — what real-world instrument should it sound like, and how to achieve that with synthesis (waveform types, harmonic structure, filter characteristics)
2. **Exact notes/frequencies** — specific pitches in Hz, chord voicings, melodic intervals
3. **Rhythm/timing** — note durations, gaps between notes, overall duration
4. **Envelope shape** — attack time (ms), decay curve, sustain level, release time
5. **Effects** — reverb amount/character, any filtering, stereo width (though output is mono)
6. **Dynamic level** — relative loudness compared to other sounds in the palette
7. **Musical key/scale** — what key everything lives in, and why

Also provide:
- A **sonic palette overview** — how all the sounds relate to each other as a cohesive family
- A **key and scale recommendation** — what musical key/mode should unify everything
- **Anti-patterns to avoid** — specific things that would break the cozy vibe
