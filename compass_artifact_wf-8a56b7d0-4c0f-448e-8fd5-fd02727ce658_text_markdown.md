# Five daily puzzle mechanics that could make Stillhue a breakout hit

**The two failed Stillhue daily modes share one fatal flaw: they gave players no way to learn from their mistakes.** Every successful daily puzzle — Wordle, Contexto, Globle, Connections — has a feedback loop where each guess teaches the player something, progressively narrowing the solution space until the answer clicks. Without this loop, players who don't already know color theory are left guessing blind. The fix isn't better puzzles — it's better *feedback*. And the research reveals something encouraging: **no game currently combines daily color mixing with continuous proximity feedback**, making this an unfilled niche with proven mechanics ready to be adapted.

The analysis below draws on deep research into eight successful daily puzzle formats, twelve color-specific puzzle games, academic work on perceptual color distance, and the psychology of shareability. It concludes with five concrete mechanic proposals — and one strong top recommendation.

---

## Every viral daily puzzle solves the same design problem

Across Wordle, Contexto, Connections, Spelling Bee, Strands, Globle, Nerdle, and Heardle, **ten universal principles** emerge. Any Stillhue daily must satisfy most of them:

**High-bandwidth feedback per guess.** Wordle's green/yellow/gray ternary system gives 3⁵ = 243 possible information patterns per guess. Grant Sanderson (3Blue1Brown) demonstrated that a single optimal Wordle guess can reduce uncertainty from **12.5 bits to 3.6 bits** — cutting the solution space from 5,757 words to ~12. The best daily puzzles maximize information per player action. Games where guesses feel "wasted" (low information per action) feel frustrating and die fast.

**The "getting warmer" feeling is more powerful than right/wrong.** Contexto — the semantic guessing game where players receive a numerical closeness rank — proves that continuous proximity feedback creates a qualitatively different engagement from binary correct/incorrect. Players describe it as "delightfully frustrating." The dramatic rank jumps (going from #50,000 to #1,000) produce visceral dopamine hits. Globle transfers this to geography: a color-coded heat map on a 3D globe lets players *see* themselves converging on the answer through accumulated visual evidence. This continuous gradient is the most forgiving and accessible feedback model — every guess teaches something, no guess is wasted.

**One-a-day scarcity plus shared experience.** Wardle's original insight: "always leave them wanting more." One puzzle per day creates anticipation, prevents burnout, and transforms a solitary activity into a communal one. The NYT games ecosystem proved this scales — **11.1 billion puzzles were solved across NYT games in 2024**, with Connections alone generating 3.3 billion plays.

**Completion rate should be very high, but solve *quality* should vary widely.** Wordle's failure rate is just **1.33%**, but the distribution of solve speed (2 guesses to 6) creates enormous variation in how players feel about their performance. The design target isn't "70-80% can solve" — it's "95%+ can solve, but only 30% feel they solved it *well*." This creates multiple win states: beginners celebrate finishing, experts optimize performance.

**Solve time sits at 2-3 minutes.** Kelli Dunlap (clinical psychologist, American University) identified the key: "One of the nice things about Wordle being very short is that sense of guilt doesn't kick in." Cognitive research confirms that **5-6 minutes is the maximum focused engagement before players need a break**. The sweet spot — short enough for a morning routine, long enough to feel earned — is consistently 2-3 minutes across every successful daily puzzle.

**The share format IS the growth engine.** Wordle's emoji grid wasn't designed by Josh Wardle — it was invented by a group of players in New Zealand who started manually typing colored squares on Twitter. Wardle noticed and built one-click copy. The grid's genius: it reveals the *drama arc* of your solve without spoiling the answer, creating two audiences — players who compare performance, and non-players who see a mysterious visual and ask "what is this?" He deliberately removed the URL link: "when you share it on Twitter, it tries to show a big preview. It feels spammy." The result was counterintuitive — no link = more curiosity = more organic discovery. Between January 1-13, 2022, over **1.2 million** Wordle results were shared on Twitter alone.

---

## Why color puzzles specifically struggle — and how to fix it

Research into twelve color puzzle games reveals a consistent finding: **successful color games rely on perception, not knowledge.** I Love Hue, the most acclaimed color puzzle, never mentions hue, saturation, or complementary colors. It works because humans have innate relative color perception — we can tell whether adjacent colors "feel right" in a gradient without any theory. Blendoku's developer Rod Green described his own learning curve: "When I first started playing our prototype I was pretty much just guessing. Now after playing for a bit I can rationalize or logic out what swatch will solve a particular space."

The critical design lesson: **use visual/spatial feedback, not vocabulary.** Show players where their mix landed relative to the target. Never ask them to name colors or understand terms like "complementary" or "analogous." The research identifies five specific techniques that work:

- **Visual side-by-side comparison** (Colorfle, Color Merge) — the simplest feedback: "here's your result, here's the target"
- **Percentage/distance scores** (Color Match uses 60%/70%/90% thresholds) — continuous proximity signal
- **Fixed anchor points** (I Love Hue's dot tiles, Blendoku's pre-filled squares) — turn absolute identification into relative comparison
- **Directional hints** (Hexcodle's higher/lower arrows per channel) — actionable guidance on which way to adjust
- **Accumulated visual evidence** (Globle's heat map) — pattern builds across guesses, revealing the answer spatially

One crucial technical note: **simple RGB distance is terrible for perceptual color comparison.** Two colors that look very different might be mathematically close in RGB, and vice versa. For any feedback system that communicates "how close," Stillhue should compute distance in a perceptually uniform color space like **Oklab or CIELAB**, then map results to the 48-position wheel. A 48-position RYB wheel gives **~7.5° per step**, which is granular enough for meaningful feedback while remaining cognitively manageable.

---

## Proposal 1: "Drift" — navigate the color wheel

**Core loop.** The player sees a mini color wheel with two dots: their starting color (chosen by the puzzle designer) and the target color. Below the wheel, the familiar 5×5 grid of tiles. Each turn, the player taps one tile. Their current color mixes with that tile (midpoint), and their dot *moves* on the wheel. The goal: land on the target in 6 moves or fewer.

**How feedback works.** The wheel IS the feedback. After each tap, the player's dot visibly moves — toward the target (good!) or away from it (adjust!). No numbers needed. No color theory needed. The reasoning is purely spatial: "my dot is to the left of the target, so I should pick a tile to the right." Optionally, a small distance indicator (e.g., "5 steps away") can supplement the visual, but the wheel alone is sufficient.

A critical mathematical property makes this elegant: because mixing always produces the **midpoint**, each mix moves the player exactly halfway toward the selected tile. You can never overshoot by more than half the distance. This means the game is naturally self-correcting — like a binary search that converges rapidly. In theory, **6 guesses can cover 2⁶ = 64 positions**, more than enough for a 48-color wheel.

**Difficulty calibration.** Three variables: starting color, target color, and grid composition. Easy puzzles place tiles that create clear stepping stones toward the target. Hard puzzles force indirect routes — the obvious tiles are absent, requiring creative navigation through intermediate colors. The puzzle designer pre-computes that at least one valid path exists in ≤6 moves. Perceptual difficulty also varies: navigating between adjacent hues (yellow-green to green) is harder than crossing the wheel (red to blue).

**Example share format:**

```
🎨 Stillhue #47 — 4/6
🟥🟧🟨🟩
```

Each square represents proximity after that move: 🟥 = far (10+ steps), 🟧 = warm (5-9), 🟨 = close (2-4), 🟩 = on target (0-1). The sequence tells a convergence story — a skilled player's row narrows quickly (🟨🟩), while a struggling one might waver (🟥🟧🟥🟨🟩🟩). Shareable, spoiler-free, visually striking.

**Pros.** Simplest interaction (one tap per turn). Most intuitive mental model ("walk toward the target"). Self-correcting math prevents catastrophic mistakes. Creates a satisfying journey narrative. Fast — 6 turns at ~15 seconds each = ~90 seconds. The mini wheel requires zero explanation; the goal is obvious from the first glance.

**Cons.** Slightly different from Classic mode (one tile per mix instead of two). Chain dependency means one bad move affects subsequent positions — though the midpoint property limits damage. Might feel too easy if optimal tiles are on the grid (solvable in 2-3 moves), requiring careful grid design to maintain challenge. Needs a starting-color mechanic that Classic doesn't have.

**Mapping to Stillhue.** Uses the same 5×5 grid and midpoint-mixing engine. The wheel visualization is the only new UI element. The starting color and target are both displayed as swatches (leveraging the existing target display). Tiles can be tapped exactly as in Classic mode.

---

## Proposal 2: "Mixle" — the color-mixing Wordle

**Core loop.** Target color displayed as a swatch. Player has 6 guesses. Each guess: tap two tiles on the 5×5 grid to mix them. The result appears in a guess row alongside the target. Feedback shows: the resulting color, distance to target (in wheel steps, 0-24), and a directional arrow indicating clockwise or counterclockwise on the wheel.

**How feedback works.** The distance + direction system functions as "higher/lower" on a circle. After seeing "Your mix is 7 steps clockwise from the target," the player knows their next mix should aim for a result 7 positions counterclockwise. The visual comparison (result swatch beside target swatch) provides immediate perceptual feedback, while the number + arrow provides actionable reasoning data. A running history of guesses (like Wordle's rows) accumulates evidence.

**Difficulty calibration.** Controlled by target selection and grid composition. Easy: target is a primary or common secondary color, and tiles that produce it are visually obvious on the grid. Hard: target is a tertiary or muted color, and the correct pair requires non-obvious tile selection. The 48-color wheel means the target can always be exactly 0-24 steps from any given result, giving fine-grained difficulty control.

**Example share format:**

```
🎨 Mixle #103 — 3/6
🟥🟨🟩
```

Same proximity-per-guess format as Drift. Can optionally include directional arrows: `🎨 Mixle #103: ←7 →3 🎯`

**Pros.** Identical mechanic to Classic mode (tap two tiles to mix). Most Wordle-familiar structure — 6 guesses, guess count as primary score, guess rows accumulate. Each guess is independent (no chain dependency). Deep strategic thinking — must reason about the midpoint of two colors, which rewards developing color intuition. Naturally competitive (lower guess count = better).

**Cons.** Two inputs per guess doubles the decision complexity. "Which two tiles produce a midpoint at position X?" is harder to reason about than "which tile should I walk toward?" — this is the core accessibility tradeoff versus Drift. Direction on a circular wheel may confuse some players (clockwise/counterclockwise isn't as intuitive as left/right). May still feel like partially-informed guessing for the first 2-3 attempts before players accumulate enough feedback.

**Mapping to Stillhue.** Direct port of Classic mode's tap-two-tiles interaction, plus a feedback row. The only new UI: a row of result swatches with distance/direction indicators, and optionally a mini wheel showing guess history.

---

## Proposal 3: "Chromatch" — Connections meets color mixing

**Core loop.** Four target colors displayed in a row above the 5×5 grid, color-coded by difficulty (yellow, green, blue, purple — matching Connections' convention). The grid contains 20 "active" tiles (5 are grayed out as neutral). Each target is produced by mixing one specific pair of tiles. The player taps two tiles to mix them; if the result matches a target, those tiles light up and the target is checked off. If not, it's a mistake. Four mistakes allowed.

**How feedback works.** On a correct match: satisfying tile animation, target lights up, tiles removed from play (making remaining pairs easier to find — the progressive-reveal dynamic that makes Connections work). On a wrong match: the resulting color is briefly displayed alongside the four targets, and the game highlights which target the result was *closest* to, plus a "1 away" or "2 away" proximity message. This teaches the player: "those tiles almost made that target — try slightly different tiles for that one."

**Difficulty calibration.** Yellow-target pair uses tiles with obvious color relationships (two blues mixing to a mid-blue). Purple-target pair uses non-obvious or counterintuitive mixes (a warm orange and cool teal producing an unexpected neutral). Distractor tiles are chosen to create plausible wrong pairs — tiles that *look* like they should mix to a target but are off by a few wheel positions.

**Example share format:**

```
🎨 Chromatch #72 — 4/4, 1 mistake
🟩🟩🟥🟩🟩
```

Like Connections: each emoji represents an attempt (🟩 = correct pair found, 🟥 = mistake). Order of completion tells a story.

**Pros.** Connections is the second-most-popular NYT game (3.3 billion plays in 2024) — the mechanic is proven and beloved. Finding groups creates "aha" moments when a pair clicks. Progressive elimination makes later pairs easier, creating a natural difficulty curve within each puzzle. The four-mistake limit creates Connections' signature tension. Most social/competitive format — players can discuss which pair they found first.

**Cons.** Most complex to design and calibrate — requires four well-balanced pairs with convincing distractors. The "which target is it closest to" feedback may not provide enough directional information for total beginners. Requires the most color intuition of any proposal — players need to anticipate what two tiles will produce. The "find the pair" structure means early guesses may feel random if the player has no color intuition at all. Grid design is the most constrained (must accommodate four specific pairs plus distractors).

**Mapping to Stillhue.** Uses the 5×5 grid and pair-mixing mechanic directly. Four target swatches replace the single target of Classic mode. Could reuse the existing grid renderer with added animation states for matched/eliminated tiles.

---

## Proposal 4: "Hue Hunt" — Contexto for colors

**Core loop.** Target color displayed. Unlimited guesses. Each guess: tap two tiles on the 5×5 grid to mix them. The result appears with a numerical distance score (0-24, representing wheel steps from the target). All previous guesses are listed and sortable by distance, creating an accumulating leaderboard of your own attempts.

**How feedback works.** Pure hot/cold, modeled directly on Contexto. A result at distance 20 is "ice cold." Distance 10 is "getting warmer." Distance 3 is "burning up." Distance 0 is solved. The numerical rank gives precise feedback without requiring any color vocabulary — players don't need to know *why* their mix was close, just *how close*. The sortable history lets players spot patterns: "all my close guesses used that yellow-green tile — it must be involved."

Color-coded distance tiers add visual reinforcement: 🟢 0-2 (extremely close), 🟡 3-6 (warm), 🟠 7-12 (moderate), 🔴 13-24 (far). The distance number overlaid on the result swatch creates a Contexto-style "rank card" for each guess.

**Difficulty calibration.** Since guesses are unlimited, difficulty is measured by solve efficiency — how many guesses it takes to reach 0. Easy targets are common colors achievable through many tile pairs. Hard targets have few valid pairs on the grid. The scoring system (reported guess count) is the entire difficulty signal.

**Example share format:**

```
🎨 Hue Hunt #47 — Found in 8 🔴🔴🟠🟡🟡🟢🟢🟩
```

The emoji sequence shows the convergence arc: cold → warm → hot → solved. Long sequences = harder puzzle or less skilled player. Short sequences = skilled or lucky.

**Pros.** Zero frustration — no guess limit means players always solve, which is critical for casual/zen audiences. Strong Contexto precedent: the "getting warmer" loop is proven to be deeply compelling. Numerical distance makes feedback unambiguous. The accumulating guess history creates an information-rich environment that rewards pattern recognition. Naturally teaches color relationships — players discover which mixes move them closer without being told.

**Cons.** No stakes without a guess limit — the tension that makes Wordle/Connections addictive is absent. Scoring by guess count is less dramatic than a "pass/fail" moment. Can feel aimless in early guesses when the player has no basis for strategy. Shares are less compact (variable-length sequences). The "unlimited guesses" model trends toward longer sessions (5-10 minutes for struggling players), which may overshoot the 2-3 minute target.

**Mapping to Stillhue.** Identical grid and mixing mechanic to Classic. Adds: a scrollable guess history panel, a distance number overlaid on each result, and color-tier highlighting. The mini wheel could show all guess results plotted as dots, creating a Globle-like accumulating visual.

---

## Proposal 5: "Quick Mix" — the three-dart challenge

**Core loop.** Target color displayed. The player gets exactly 3 mixes. Each mix: tap two tiles, see the result next to the target with a distance score. After 3 mixes, the game ends. Score = distance of the player's closest result (0 = perfect, lower = better), converted to a par-style rating: **Ace** (0 steps), **Birdie** (1-2 steps), **Par** (3-5 steps), **Bogey** (6-10 steps), **Double Bogey** (11+).

**How feedback works.** After each mix, the result appears alongside the target with a distance indicator. The player sees how close they got and has 1-2 remaining attempts to improve. The wheel visualization shows all three results as dots, making it clear which was closest. Because only the best result counts, each mix is a fresh attempt — no chain dependency.

**Difficulty calibration.** Controlled entirely by target selection and grid composition. Easy puzzles have multiple tile pairs that produce near-exact matches. Hard puzzles have no exact matches on the grid — the best achievable result might be 2-3 steps away, making Par feel like a genuine accomplishment and Ace nearly impossible.

**Example share format:**

```
🎨 Stillhue #47 — Birdie! 🏌️
🟧🟩🟨
```

Three emojis for three attempts, plus the named rating. Ultra-compact. The rating word (Ace/Birdie/Par/Bogey) is immediately understandable and inherently shareable — golf metaphors are universally recognized.

**Pros.** Fastest format — guaranteed completion in under 90 seconds. Simplest rules — "mix 3 times, best score wins." The par rating system creates clear performance tiers that are fun to share. No frustration — there's no "fail" state, just degrees of success. The golf metaphor adds personality. Low barrier: even a total beginner can tap three random pairs and get a Bogey, which still feels like participation.

**Cons.** Only 3 data points means very limited learning within a single puzzle — less of a reasoning experience, more of a skill/intuition test. The feedback loop is weak: you see 3 results and that's it, with no opportunity to iterate based on what you learned. May feel too luck-dependent for competitive players. The "best of three" mechanic is less engaging than progressive convergence. Experienced players may solve in 1 attempt consistently, collapsing the challenge.

**Mapping to Stillhue.** Identical to Classic mode but with a hard 3-attempt cap and a scoring overlay. Minimal UI changes: a 3-slot result row, a distance badge on each result, and a rating screen at completion.

---

## Top recommendation: Drift, with Mixle as fallback

**Drift is the strongest design for Stillhue's daily mode because it solves the exact problem that killed the two failed attempts — it gives non-experts a spatial reasoning tool that requires zero color theory knowledge.** The mini color wheel transforms the puzzle from "guess a color" into "navigate to a dot," which is a task humans are hardwired to perform. You don't need to know that mixing warm and cool tones produces a neutral. You just need to see that your dot is to the left of the target and pick a tile that pulls you right.

Four specific factors make Drift the top choice:

**The midpoint math is naturally self-correcting.** Each mix moves the player exactly halfway toward the selected tile. This means overshooting is physically impossible — you can never end up farther from the target than your current distance to the selected tile. In Mixle, a badly chosen pair can produce a result on the opposite side of the wheel. In Drift, the worst case is that you moved halfway in the wrong direction, which is easily correctable on the next turn. This single property makes Drift dramatically more forgiving than pair-mixing approaches.

**One tap per turn halves the cognitive load.** In Mixle, the player must reason about the interaction between two selected tiles — a combined midpoint that requires two-dimensional spatial thinking. In Drift, the player considers one question: "Which tile on this grid will pull my dot toward the target?" This is the same cognitive task as pointing at something, which is about as intuitive as game mechanics get.

**The wheel creates a Globle-like accumulating visual.** As the player makes moves, their path traces across the wheel — a visual story of their convergence. This is exactly the mechanic that makes Globle compelling: accumulated colored evidence on a spatial surface. Each move adds to the picture, creating a sense of progress that's visible and tangible rather than numerical.

**The journey IS the narrative arc.** Great daily puzzles tell micro-stories. Wordle's grid shows a dramatic rescue (first two rows gray, then sudden green). Connections shows which categories you found first. Drift's share format shows a convergence path — a skilled player's `🟨🟩` (two moves, done) versus a beginner's winding `🟥🟧🟥🟨🟩🟩` tells a dramatic little story of struggle and triumph.

**If Drift feels too far from Classic mode**, Mixle is the strong fallback. It preserves the exact tap-two-tiles mechanic and adds Wordle-style feedback rows. The directional arrow (clockwise/counterclockwise) plus step distance gives players an explicit "higher/lower" signal that enables reasoning. It's less forgiving than Drift but more strategically deep, and its Wordle-familiar structure makes the rules instantly recognizable.

The honest recommendation: **prototype both Drift and Mixle, playtest each with 10 non-expert players, and ship whichever one produces more "oh, I see!" moments in the first 3 guesses.** The feedback loop is the entire game. If players feel like they're learning something on guess 2, you've won.

---

## Detailed implementation notes for Drift

**Starting color mechanics.** The puzzle is defined by three parameters: starting color (wheel position), target color (wheel position), and the 25-tile grid. The starting color should be **10-18 wheel steps from the target** — close enough that the player can see the relationship on the wheel, far enough to require 3-5 well-chosen moves. Display the starting color as a prominent swatch with a matching dot on the wheel.

**Grid design algorithm.** For each daily puzzle, generate the grid to guarantee at least one solvable path in ≤5 moves while ensuring no trivially obvious path exists in ≤2 moves. Include 3-5 tiles that are "helpful" (in the direction of the target) and 2-3 tiles that are "distractors" (would pull the player away). The remaining tiles are neutral/orthogonal. This ensures the 70-80% "sweet spot" where most players solve in 4-5 moves, skilled players in 3, and the rare player needs all 6.

**Wheel visualization.** A small (120×120pt) color wheel in the upper corner showing: the player's current position (filled dot), the target (ring/outline dot), and a faded trail connecting previous positions. When the player taps a tile, the dot animates along the wheel to its new position. The animation speed should be tuned to feel satisfying — fast enough to not break flow, slow enough to register the movement direction.

**Scoring tiers.** 1 move = 🏆 (miracle), 2 moves = ⭐ (brilliant), 3 moves = 🟢 (great), 4 moves = 🟡 (good), 5 moves = 🟠 (solid), 6 moves = 🔴 (made it), X = 😤 (didn't reach target within 1 step).

**Endgame.** After 6 moves, if the player hasn't landed exactly on the target, score based on final distance. Within 1 step = "close enough" (counts as solve). 2+ steps = "almost" (show the correct path). Always reveal at least one optimal path so the player learns — this is the "answer reveal" equivalent of Wordle showing the word.

**Colorblind accessibility.** Add an optional "distance number" overlay on the wheel showing the numerical step count. This provides a non-color-dependent feedback channel. Also consider shape markers on the wheel dots (circle for player, star for target) and a high-contrast mode.

---

## Games to play for research and inspiration

**Essential — play these first and study the feedback loops:**

- **Contexto** (contexto.me) — The direct ancestor of Drift's proximity feedback. Play 5 puzzles and pay attention to how the numerical rank changes your thinking. Notice how the "getting warmer" feeling compels you to keep guessing.
- **Globle** (globle-game.com) — The spatial-proximity model Drift adapts. Notice how accumulated colored dots on the globe create a visual convergence pattern.
- **Wordle** (nytimes.com/games/wordle) — Study the information density per guess. Notice how green/yellow/gray gives you three states per position, not just right/wrong.
- **NYT Connections** (nytimes.com/games/connections) — Study the "one away" feedback, the progressive elimination, and the four-difficulty-tier structure. Directly relevant to Chromatch.

**Important — study the color-specific design choices:**

- **I Love Hue** (iOS, by Zut Games) — The gold standard for color puzzles that require perception, not knowledge. Notice how fixed anchor tiles reduce the task from "know the color" to "compare the colors." The zen feel is directly relevant to Stillhue's brand.
- **Blendoku** (iOS, by Lonely Few) — Gradient completion puzzles. Notice how pre-filled tiles create implicit "answer keys" that make the puzzle solvable without theory.
- **Colorfle** (colorfle.com) — The closest existing "color Wordle." Play it and note where the feedback falls short — the green/yellow/gray system doesn't tell you *how close* your mix is, only whether components are right/wrong/misplaced. This is the gap Drift fills.

**Supplementary — broader daily puzzle mechanics:**

- **Spelling Bee** (nytimes.com/puzzles/spelling-bee) — Study the progressive achievement labels (Good → Genius → Queen Bee) as a model for Drift's scoring tiers.
- **Strands** (nytimes.com/games/strands) — Study the earned hint system, where finding non-theme words powers up hints. This could inspire a "hint tile" mechanic in Drift.
- **Hexcodle** (hexcodle.com) — A hex-code guessing game with directional arrows. Study where it works (the higher/lower signal) and where it fails (low hex digits barely affect the visible color).
- **Refractor** (refractor-game.com) — A daily spatial color-mixing puzzle. It uses RYB mixing rules and grid-based routing. Study the routing mechanic and community feedback about the tutorial confusion.
- **Color Zen** (iOS, by Large Animal Games) — Study the "cleaning up chaos" zen feel. The design insight that "tidying visual mess mirrors mental decluttering" is relevant to Stillhue's brand identity.
- **Paint Match** (ombosoft.itch.io/paint-match) — The standout color-mixing puzzle. The developer created an algorithm to order all colors by difficulty — study this as a model for Drift's difficulty calibration.