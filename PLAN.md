# Stillhue Sensory Upgrade — Implementation Plan

## Codebase Architecture Summary

**Key files and their roles (as actually read, not from handoff docs):**

| File | Lines | Role | Sensory relevance |
|------|-------|------|-------------------|
| `ContentView.swift` | ~1050 | Main game view, all overlays, animation triggers, celebration dispatch | Hosts all visual effects, camera shake, aberration border, celebration timing |
| `GameState.swift` | ~1400 | All game logic, blend flow, scoring, bonuses, streak tracking | `performBlend()` is the core mix moment — controls timing, sound calls, haptic calls |
| `SoundManager.swift` | ~622 | AVAudioEngine singleton, all SFX synthesis, theme music | Entire audio pipeline — additive sine synthesis, arpeggios, meow, celebrations |
| `HapticManager.swift` | ~38 | UIKit feedback generators (light/medium/heavy/notification) | Simple enum, 5 static methods |
| `TileView.swift` | ~140 | Individual tile rendering — glass gradient, specular, shadow, spring animations | Core visual element. Already has good glass effect. |
| `GridView.swift` | ~171 | LazyVGrid layout, cell rendering, golden tile overlay | Hosts tile interactions, blend preview dots |
| `FloatingPointsView.swift` | ~163 | Score animation — bonus label + total, merge, zoom-to-score | 5-phase animation system with springs |
| `TunnelBackground.swift` | ~416 | Procedural background — seeded PRNG, 7 layouts, 8 shapes, discovered palette | Canvas-based, regenerates per round |
| `IridescentTheme.swift` | ~200+ | Color palette, glass card styling, iridescent background | Design system constants |
| `ChromaticAberrationBorder.swift` | ~80 | RGB channel-split border effect for multipliers | Already implemented, phase-animated |
| `MusicManager.swift` | ~32 | Thin wrapper delegating to SoundManager | Trivial |

**Blend flow (the core moment), traced through the code:**

1. `selectTile()` → second tile tap → `performBlend(posA, posB)`
2. Phase 1: `poppingPositions = [posA, posB]` — both tiles scale to 1.18× (spring 0.15/0.5) — **100ms sleep**
3. Phase 2: `blendingPositions = (posA, posB)` — tiles shrink to 0.3×, opacity 0.5 (easeIn 120ms) — **80ms sleep**
4. Haptic: `HapticManager.blend()` (medium impact)
5. Sound: `SoundManager.shared.playBlendTone(for: result)` (skipped if match)
6. Grid update: result placed at posA, posB cleared
7. If match: **250ms sleep** → `HapticManager.lineClear()` → grid clear → round complete flow
8. If no match: **120ms sleep** → check game over

**Total blend animation time: ~180ms visual + 80ms pause = ~260ms.** This is indeed too fast for a satisfying moment.

**Existing streak tracking:** `cleanRoundStreak` (undo-free rounds), `roundsWithoutDying` (lives), `blendsThisTarget`. There is NO consecutive-perfect-round streak counter. The `lastRoundWasPerfect` bool exists but is only used for the mercy system, not for escalating feedback.

**Audio architecture:** Single `AVAudioEngine` with one `playerNode` (SFX) and one `musicNode` (theme). SFX are pre-generated `AVAudioPCMBuffer` instances played via `playerNode.scheduleBuffer()`. **Critical limitation: `playerNode.stop()` is called before every new sound**, meaning sounds cannot overlap — playing a new sound kills the previous one.

---

## Assessment of Each Recommendation

### Rec 1: Metal SDF Metaball Blend Shader
**Report's feasibility estimate: Medium (5–7 days)**

**My assessment: DEFER. Too high-risk for the current phase.**

Reasons:
- The project has **zero Metal infrastructure** — no `.metal` files, no `MTKView`, no shader setup. Adding Metal requires: creating a `.metal` file, setting up `MTKView` in `UIViewRepresentable`, bridging shader uniforms from SwiftUI state, managing the render loop, and handling the overlay compositing with the existing SwiftUI `LazyVGrid`.
- `ShaderLibrary` (iOS 17+) exists but is limited to `colorEffect`, `distortionEffect`, and `layerEffect` modifiers — it cannot render arbitrary geometry like metaball blobs at arbitrary positions. You'd need `MTKView`.
- The blend happens between two tiles at arbitrary grid positions. The shader needs to know both tile positions in screen coordinates, which requires `GeometryReader` → coordinate conversion → shader uniform update per frame. This is fragile.
- **Risk of regression is high** — Metal rendering issues (blank views, coordinate mismatches, GPU hangs) are hard to debug and would block the entire app.
- **Better alternative for V1:** A pure SwiftUI animation that makes the blend moment feel more liquid — scale/opacity choreography with color interpolation overlays. Gets 60% of the visual impact at 5% of the risk. The metaball shader can be Phase 2 after the foundation is solid.

**Decision: Skip for now. Revisit after Phases 1–3 are shipped and stable. Flag for your review.**

### Rec 2: FM-Synthesized 3-Layer Audio
**Report's feasibility estimate: Medium (4–6 days)**

**My assessment: IMPLEMENT with modifications. Medium risk.**

The report is correct that the audio is too simple and too quiet. But the implementation needs adjustment:

- **The report says "AVAudioSourceNode render block"** — but the codebase uses `AVAudioPlayerNode` with pre-generated buffers, NOT `AVAudioSourceNode` with a real-time render callback. These are fundamentally different architectures. `AVAudioSourceNode` requires a real-time audio callback that must be lock-free and cannot allocate memory. Switching to this architecture is a significant refactor.
- **Better approach:** Keep the pre-generated buffer architecture but upgrade the synthesis. Generate FM-synthesized buffers at init time instead of simple sine+harmonics buffers. This preserves the zero-latency playback model while getting richer timbre.
- **The `playerNode.stop()` before every play** means sounds are interrupted. This needs fixing — use a pool of 2-3 player nodes so blend tone and round-complete can overlap.
- Volume increase from 0.35→0.55 is correct and trivial.
- Stereo panning requires switching from mono to stereo format — moderate change.
- Psychoacoustic bass for blend: good idea, implementable in the buffer generation.

**Files to touch:** `SoundManager.swift` (major rewrite of synthesis functions, add player pool, stereo format), `GameState.swift` (pass grid position to sound calls for stereo panning)

### Rec 3: Core Haptics Engine
**Report's feasibility estimate: Medium (4–5 days)**

**My assessment: IMPLEMENT. Low-medium risk.**

The current `HapticManager` is 38 lines of basic UIKit generators. Core Haptics is a strict upgrade. The report's pattern definitions are well-specified and actionable.

- `CHHapticEngine` setup is straightforward.
- Pre-compiled patterns are the right approach.
- The color-to-sharpness mapping is a nice touch but should be Phase 2 (after basic patterns work).
- **One concern:** The report says Core Haptics has 1–5ms latency vs. UIKit's 20–50ms. This is true for pre-compiled patterns but the difference is mainly noticeable in the blend moment where audio/haptic sync matters.

**Files to touch:** `HapticManager.swift` (full rewrite), `GameState.swift` (update haptic calls to new API)

### Rec 4: Time Dilation
**Report's feasibility estimate: Easy (1–2 days)**

**My assessment: DEFER to after the metaball shader.**

The report says time dilation is "easy" — but it's only easy if animations read a shared time scale. Currently:
- Blend timing is controlled by `Task.sleep` durations in `performBlend()` — these are real-time waits, not animation-driven.
- The visual animations use SwiftUI's `.animation()` modifiers which don't read a custom time scale.
- Without the metaball shader, there's nothing to slow down visually — the blend is just a scale/opacity change that takes 120ms. Slowing that down would just make a quick fade take longer, which wouldn't look "oddly satisfying" — it would look laggy.
- **Time dilation becomes valuable AFTER the blend has a richer visual** (metaball shader or equivalent). Without it, this recommendation has negative value.

**Decision: Skip for now. Revisit when/if the blend visual is upgraded.**

### Rec 5: Spring Animation Overhaul + Squash-and-Stretch
**Report's feasibility estimate: Easy (2–3 days)**

**My assessment: IMPLEMENT. Low risk. High impact.**

This is the **highest-ROI recommendation** for effort vs. impact:
- The codebase already uses springs in `TileView.swift` (response 0.15–0.25, damping 0.5–0.7). These can be tuned.
- Squash-and-stretch on tile tap is a simple `scaleEffect(x:y:)` addition to `TileView`.
- Tile entry animation (scale 0→1 with stagger) is straightforward in `GridView`.
- `.contentTransition(.numericText())` for score counter is a one-line change.
- **No new files needed.** Just modifying existing views.

**Concern:** The report's spring values conflict slightly with existing ones. I'll use the report's values as starting points but keep the existing damping ratios where they already feel good (e.g., the `isPopping` spring at 0.15/0.5 is already snappy and satisfying).

**Files to touch:** `TileView.swift` (squash-stretch, tune springs), `GridView.swift` (tile entry stagger), `ContentView.swift` (score counter transition), `GameState.swift` (expose tile entry state for stagger)

### Rec 6: Round Completion Cascade
**Report's feasibility estimate: Medium (3–5 days)**

**My assessment: IMPLEMENT a simplified version. Medium risk.**

The full 4-phase cascade as described is complex. The simplified version:
- Phase 1 (time freeze): Skip — depends on Rec 4 which we're deferring.
- Phase 2 (completion wave): Implementable. Each tile gets a delayed scale pulse based on distance from the matched tile. This is the money shot.
- Phase 3 (harmonic resolution): Already partially exists (round-complete arpeggio). Can be improved with FM synthesis from Rec 2.
- Phase 4 (ambient glow): The background already changes per round via `TunnelBackground`. A temporary brightness pulse is achievable with a simple overlay.
- Perfect-round color ripple: Nice but complex. Phase 2.

**Files to touch:** `GridView.swift` (wave animation), `ContentView.swift` (trigger wave + background pulse), `GameState.swift` (expose matched position for wave origin)

### Rec 7: Streak Escalation
**Report's feasibility estimate: Medium (3–5 days)**

**My assessment: IMPLEMENT the tracking + audio/visual hooks. Low-medium risk.**

- Need to add a `consecutivePerfectRounds` counter (doesn't exist).
- Bloom on blend result: achievable with `.blur()` + `.blendMode(.screen)` overlay on `TileView`.
- Pitch escalation: straightforward in the FM synthesis buffers.
- Background saturation: achievable by adjusting the `TunnelBackground` alpha range.
- Chromatic aberration border already exists and is tied to multipliers. Tying it to streak as well is a small change.

**Dependency:** Builds on Rec 2 (audio) and Rec 5 (visual springs). Should come after both.

**Files to touch:** `GameState.swift` (streak counter), `SoundManager.swift` (pitch offset), `TileView.swift` (bloom), `TunnelBackground.swift` (saturation scaling), `ContentView.swift` (wire streak to aberration border)

### Rec 8: Camera Zoom Pulse
**Report's feasibility estimate: Easy (1–2 days)**

**My assessment: IMPLEMENT. Very low risk.**

- Replace the existing screen shake (which is a translation offset in `ContentView.swift` line ~196) with a scale effect.
- The ambient breathing is a nice touch — simple sinusoidal `scaleEffect` with `.animation(.easeInOut(duration: 4).repeatForever())`.
- **One concern:** The report says "no screen shake anywhere" but the game currently has screen shake on game over. I'll replace it with a zoom pulse. Flag for your review.

**Files to touch:** `ContentView.swift` (replace `gameOverShake` offset with zoom pulse, add blend zoom, add idle breathing)

### Rec 9: Particle Mist
**Report's feasibility estimate: Easy (2–3 days)**

**My assessment: IMPLEMENT with SwiftUI Canvas instead of SpriteKit. Low risk.**

- The report recommends SpriteKit overlay. But the app is pure SwiftUI — adding a SpriteKit layer introduces a new framework dependency, `UIViewRepresentable` bridging, and z-ordering concerns with the existing SwiftUI layout.
- **Better approach:** Use SwiftUI `Canvas` with `TimelineView` for particles. The app already uses `Canvas` for `TunnelBackground`. Same pattern, proven to work in this codebase.
- 10–14 particles per blend at 800–1200ms lifetime is easily handled by Canvas redraw.
- Color sampling from source tiles + result is straightforward.

**Files to touch:** New file `Views/BlendParticlesView.swift`, `ContentView.swift` (overlay), `GameState.swift` (expose blend event data)

### Rec 10: Auto-Clip Capture + TikTok Share
**Report's feasibility estimate: Medium (5–7 days)**

**My assessment: DEFER. High complexity, low urgency.**

- ReplayKit requires user permission and has quirks in Simulator (won't work at all).
- `AVMutableComposition` for cross-dissolve loop stitching is significant AVFoundation work.
- The app already has a Share button on the game over screen using `ShareSheet.swift`.
- This is a distribution feature, not a sensory feature. It should come after the sensory upgrades make the content worth sharing.
- **Should be its own project phase after all sensory work is done.**

**Decision: Skip entirely for this phase. Recommend as a follow-up project.**

---

## Implementation Order (Ranked)

### Phase 1: Foundation — Springs + Camera (2–3 days)
**Why first:** Lowest risk, touches every interaction immediately, no new dependencies.

| Task | Files | Risk |
|------|-------|------|
| Squash-and-stretch on tile tap/blend | `TileView.swift` | Low |
| Tune all spring parameters per report's dictionary | `TileView.swift`, `FloatingPointsView.swift` | Low |
| Tile entry animation with stagger | `GridView.swift`, `GameState.swift` | Low |
| Score counter `.numericText()` transition | `ContentView.swift` | Low |
| Camera zoom pulse replacing screen shake | `ContentView.swift` | Low |
| Ambient breathing on idle | `ContentView.swift` | Low |

**Rollback:** Revert spring values to originals. All changes are parameter tweaks.

### Phase 2: Audio Upgrade (3–4 days)
**Why second:** Audio is 50% of TikTok satisfaction. Independent of visual changes.

| Task | Files | Risk |
|------|-------|------|
| Raise master volume 0.35→0.55 | `SoundManager.swift` | Low |
| Add player node pool (2–3 nodes) for sound overlap | `SoundManager.swift` | Medium |
| Replace sine synthesis with FM synthesis for blend tones | `SoundManager.swift` | Medium |
| Add 3-layer structure: body + detail burst + air | `SoundManager.swift` | Medium |
| Add psychoacoustic bass to blend sound | `SoundManager.swift` | Medium |
| Upgrade round-complete arpeggio (longer, richer) | `SoundManager.swift` | Low |
| Stereo panning based on tile grid column | `SoundManager.swift`, `GameState.swift` | Medium |

**Rollback:** Keep old synthesis functions as `_legacy` methods. Toggle via a bool.

### Phase 3: Haptics Upgrade (2–3 days)
**Why third:** Completes the audio-haptic-visual triad. Independent of visuals.

| Task | Files | Risk |
|------|-------|------|
| Rewrite `HapticManager` with `CHHapticEngine` | `HapticManager.swift` (full rewrite) | Medium |
| Pre-compile 5 core patterns (select, blend, round-complete, streak, wrong) | `HapticManager.swift` | Low |
| Wire new haptic calls into `GameState.swift` | `GameState.swift` | Low |
| Fallback to UIKit generators if Core Haptics unavailable | `HapticManager.swift` | Low |

**Rollback:** Keep old UIKit implementation as fallback. Core Haptics gracefully degrades.

### Phase 4: Particles + Round Cascade (3–4 days)
**Why fourth:** Adds visual richness that builds on the improved springs and audio.

| Task | Files | Risk |
|------|-------|------|
| Create `BlendParticlesView` using Canvas + TimelineView | New: `Views/BlendParticlesView.swift` | Low |
| Emit 10–14 color-matched particles on blend | `BlendParticlesView.swift`, `ContentView.swift` | Low |
| Round-complete wave: delayed scale pulse radiating from match position | `GridView.swift`, `GameState.swift` | Medium |
| Background brightness pulse on round complete | `ContentView.swift`, `TunnelBackground.swift` | Low |

**Rollback:** Remove particle overlay. Revert grid wave changes.

### Phase 5: Streak Escalation (2–3 days)
**Why fifth:** Requires all prior phases to be working — it ties audio, visual, and haptic channels together.

| Task | Files | Risk |
|------|-------|------|
| Add `consecutivePerfectRounds` streak counter | `GameState.swift` | Low |
| Bloom overlay on blend result tile, scaled by streak | `TileView.swift` or `GridView.swift` | Low |
| Pitch escalation in blend tone (semitone offset per streak) | `SoundManager.swift` | Low |
| Background saturation increase with streak | `TunnelBackground.swift` | Low |
| Chromatic aberration border activation at streak ≥ 3 | `ContentView.swift` | Low |
| Particle count scaling with streak (10 → 14 → 18) | `BlendParticlesView.swift` | Low |
| Haptic intensity scaling with streak | `HapticManager.swift` | Low |

**Rollback:** Remove streak counter reads. All effects degrade to streak=1 defaults.

---

## Dependency Graph

```
Phase 1 (Springs + Camera) ─── independent ───┐
                                                ├─→ Phase 4 (Particles + Cascade)
Phase 2 (Audio) ─── independent ───────────────┤
                                                ├─→ Phase 5 (Streak Escalation)
Phase 3 (Haptics) ─── independent ─────────────┘
```

Phases 1, 2, and 3 are independent and could theoretically be parallelized. Phases 4 and 5 depend on all three being stable.

---

## Deferred / Skipped Recommendations

| Rec | Decision | Reason |
|-----|----------|--------|
| **1. Metal SDF Metaball** | DEFERRED | Zero Metal infrastructure exists. High risk of regression. Recommend as a dedicated Phase 6 after all other work ships. The improved springs + particles + cascade from Phases 1–4 will meaningfully improve the blend moment without Metal. |
| **4. Time Dilation** | DEFERRED | Only valuable with a richer blend visual. Without the metaball shader, slowing down a 120ms fade looks laggy, not cinematic. Implement alongside or after Rec 1. |
| **10. Auto-Clip Capture** | SKIPPED | Distribution feature, not sensory. High complexity (ReplayKit + AVFoundation compositing). Should be its own project after the sensory work makes content worth sharing. |

---

## Flags for Your Review

1. **Screen shake on game over:** The report says "no screen shake anywhere." The current code has a translation-based shake on game over (`gameOverShake` offset ±8/6pt). I plan to replace this with a zoom pulse (scale 1.0→1.03→1.0). Confirm this is OK, or would you prefer to keep the shake on game over specifically?

2. **FloatingPointsView uses `.rounded` font, not `.serif`:** The bonus labels and score numbers use `.system(design: .rounded)` instead of `.serif`. The report doesn't mention this. Should I fix this to match the serif convention, or does `.rounded` work better for numbers specifically?

3. **Metaball shader deferral:** I'm recommending we skip the Metal shader for now and focus on what SwiftUI can do natively. The blend moment will be significantly better with squash-stretch + particles + completion wave + FM audio + Core Haptics — but it won't have the "liquid paint" visual the report centers on. Are you OK with this for V1, knowing we can add the shader later?

4. **SpriteKit vs. SwiftUI Canvas for particles:** The report recommends SpriteKit. I'm recommending SwiftUI Canvas instead (already proven in this codebase via TunnelBackground). SpriteKit adds framework complexity. OK with Canvas?

5. **New third-party dependencies:** None planned. All implementations use Apple frameworks only (AVFoundation, CoreHaptics, SwiftUI).

---

## Estimated Total Timeline

| Phase | Estimate | Cumulative |
|-------|----------|------------|
| Phase 1: Springs + Camera | 2–3 days | 2–3 days |
| Phase 2: Audio | 3–4 days | 5–7 days |
| Phase 3: Haptics | 2–3 days | 7–10 days |
| Phase 4: Particles + Cascade | 3–4 days | 10–14 days |
| Phase 5: Streak Escalation | 2–3 days | 12–17 days |

App is **shippable after every phase.** Each phase independently improves the sensory experience.
