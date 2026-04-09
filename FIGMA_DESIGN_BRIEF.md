# Stillhue — Dark Mode Redesign Brief

## What is Stillhue?
A color-mixing puzzle game for iOS. Players tap colored tiles on a 5×5 grid to mix colors and match a target color shown above the board. Think Wordle meets color theory. It has a pixel-art cat mascot, 48 discoverable colors, achievements, and two game modes (Classic endless + Hue of the Day).

## What We Want
The dark mode needs to look like a sexy, minimalist, modern premium app — not a dev prototype. Think: the Flighty boarding pass app aesthetic — true blacks, subtle neutral gray elevation, clean typography, sophisticated depth. The kind of app where someone screenshots it and posts "look how clean this is."

## Target Aesthetic
- True black (#000000) base — OLED-friendly, premium feel
- Neutral warm grays for elevated surfaces (#1C1C1E, #2C2C2E) — NO blue tint
- Clean sans-serif typography (SF Pro / Inter) with clear hierarchy
- Subtle depth through elevation and shadow, not heavy borders
- Colored game tiles should GLOW and float against the dark — they're the hero
- Frosted glass / blur effects where appropriate
- Minimal chrome — let the colors breathe
- Generous whitespace (dark-space)

---

## Screens to Redesign

### 1. Home Screen
**Current elements:** Cat mascot pixel art (centered), "Stillhue" title, "A color-mixing puzzle" subtitle, two game mode cards (Classic / Hue of the Day) with emoji icons + descriptions + chevrons, "How to Play" text link at bottom, 5-item tab bar

**Redesign notes:** This is the first impression. Needs to feel premium and inviting. The cat mascot is charming — keep it but present it beautifully (maybe with a subtle glow or particle effect behind it). Mode cards should feel like frosted glass or subtle elevated surfaces with more breathing room. Consider making this feel like a premium game launcher, not a settings list.

### 2. Game Screen (Main Gameplay)
**Current elements:**
- Top bar: settings gear (left), dark/light mode toggle sun/moon icon (right)
- Stats HUD: "ROUND 48" | "SCORE 90160" | "LIVES ♥♥♥♥" (pink droplet icons)
- Target color: large rounded-square swatch with glossy glass effect + color name label below (e.g. "ORANGE")
- 5×5 tile grid: mix of colored tiles (vibrant gradients with glass highlights) and empty dark cells
- Mixing lane: 3 slots at bottom where selected tiles queue before combining
- Tab bar: Daily, New, Home, Awards, Share

**Redesign notes:** This is where 95% of time is spent. The colored tiles are the SOUL of this app — they must be vibrant, glossy, with subtle inner highlights and colored glow/bloom against the dark background. Empty cells should be subtle dark wells. The HUD needs the most work — currently feels like raw data dump. Score should be hero-sized. Lives should be elegant (maybe thin pill shapes or subtle gem icons, not just colored dots). Consider: can the HUD feel like a sleek instrument panel? The target color swatch is already decent — keep the glass effect but refine it.

### 3. Settings Screen (Modal)
**Current elements:** "Settings" header + "Done" button, grouped sections:
- PREFERENCES: Color Assistance toggle, Sound Effects toggle, Music toggle, Haptics toggle (each with emoji icon)
- SAVED GAMES: Save Current Game row, Load Saved Game row (with chevrons)
- HOW TO PLAY: 6 instructional text items with emoji icons

**Redesign notes:** Should feel like iOS Settings but more premium. Clean grouped rows with subtle separators, proper spacing. Consider replacing emoji icons with SF Symbol icons for a more cohesive look. The How to Play section could be collapsible or presented differently.

### 4. Awards Screen (Modal)
**Current elements:** Awards/Stats segmented tab toggle, "27/35" achievement count, "ACHIEVEMENTS" label, 7-column grid of pixel-art cat achievement badges (unlocked = full color, locked = dark square), bottom stats bar (234 Games | 7505 Mixes | R70 Best | 42/48 Colors)

**Redesign notes:** The cat badges are the star here. Unlocked badges should glow or have a subtle warm aura. Locked badges should feel mysterious (maybe a subtle shimmer or question mark, not just dark). The grid could have more breathing room. The bottom stats bar is useful — make it feel like a premium footer.

### 5. Stats Screen (Tab within Awards modal)
**Current elements:** Awards/Stats tab, Classic/Hue of the Day sub-toggle, hero stat row (234 Games, 7505 Mixes, R70 Best, 214535 High Score), Color Discovery progress bar (42/48 = 88%), Performance section (Total Rounds: 5291, Perfect Rounds: 1670, Under Par: 0, Best Par Streak: 56), Items section with colored numbers (157 Lives Used in red, 145 Bonus Lives in orange, 3 Undos in green, 175 Golden Tiles in gold)

**Redesign notes:** Data-rich screen that needs clear visual hierarchy. Hero stats should be BIG and prominent in a card. Progress bar is nice — keep the gradient. Performance stats can be a clean list. The colored numbers in Items are great — they break up the monotony. Consider card groupings with subtle elevation.

---

## Current Color Tokens (Dark Mode)

### Backgrounds
| Token | Hex | Usage |
|-------|-----|-------|
| screenBg | #000000 | True black base |
| screenBgBottom | #050506 | Gradient end |

### Surfaces
| Token | Hex | Usage |
|-------|-----|-------|
| cardFill | #1C1C1E | Cards, elevated panels |
| overlayCard | #1C1C1E | Modal backgrounds |
| emptyCellTop | #161618 | Grid empty wells |
| emptyCellBottom | #111113 | Grid empty wells |

### Text
| Token | Hex | Usage |
|-------|-----|-------|
| textPrimary | #FFFFFF | Headings, scores |
| textSecondary | #9A9A9E | Labels, subtitles |
| textTertiary | #58585C | Hints, faint labels |
| textMuted | #78787E | Body text |

### Borders & Separators
| Token | Hex | Usage |
|-------|-----|-------|
| emptyCellBorder | #2A2A2E | Cell outlines |
| divider | #2A2A2E | Section separators |
| navBarDivider | #1A1A1C | Nav divider |

### Interactive
| Token | Hex | Usage |
|-------|-----|-------|
| primaryButtonBg | #F0F0F2 | CTA buttons (inverted) |
| primaryButtonText | #000000 | Button text |
| navIconActive | #D0D0D4 | Active tab |
| navIconInactive | #48484E | Inactive tab |

---

## Game Tile Colors (DO NOT CHANGE)
These are functional game colors — 48 colors on the color wheel. They MUST remain vibrant. The dark mode chrome exists to make these colors the star. Each tile has a gradient (lighter top → saturated bottom) with a subtle glass specular highlight.

---

## Design Constraints
- iPhone-only (portrait). Design for iPhone 15 Pro (393×852pt safe area)
- Must support dark AND light mode (dark mode is priority/default)
- SwiftUI implementation — keep designs achievable with standard components
- 5×5 grid layout is fixed game mechanic — don't change it
- 5-item tab bar (Daily, New, Home, Awards, Share) is fixed navigation
- Cat mascot pixel art is a brand asset — keep and present well
- Tile hue/saturation CANNOT change — they're functional game data
- Settings toggles, save/load, how-to-play content must remain

---

## Design Inspiration
- **Flighty** — the dark mode depth, typography, card layering
- **Apple Weather** — frosted glass cards over dark gradients
- **Halide** — premium dark UI with vibrant accent colors
- **Monument Valley** — elegant game UI that doesn't distract from gameplay
- **Things 3** — clean, sophisticated UI
- **Linear** — modern dark mode done right

---

## Deliverables
For each of the 5 screens, provide:
1. Full dark mode mockup at 393×852pt (iPhone 15 Pro)
2. Any new color tokens or typography changes
3. Notes on spacing, corner radii, blur values, and glow effects

The developer will read these designs directly from Figma via MCP and implement them in SwiftUI.
