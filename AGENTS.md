# Project ZeroG — Agent Instructions

Turn-based tactical RPG and deck-builder hybrid built in **Godot Engine** (2D, pixel art). Combat uses traditional target-selection (Final Fantasy 1–9 style) without a movement grid. Targets **PC, Mac, Android, and iOS**. Premium paid game with a free demo through the fourth party recruit (Seluc).

**Source of truth for design:** `gdd/GAME DESIGN DOCUMENT_ Project _ZeroG_.pdf`

When design questions arise, defer to the GDD. Do not invent mechanics that contradict it.

---

## Tech Stack

| Layer | Choice |
|-------|--------|
| Engine | Godot 4.x (2D renderer, cross-platform mobile) |
| Language | GDScript (primary); C# only if a dependency requires it |
| Art | 16-bit / pixel art sprites |
| UI | Clean, modern, minimalist — high-tech "Solo Leveling" system vibe; must not clutter mobile screens |
| Audio | HD-2D style orchestrated soundtrack over retro graphics; high-fidelity SFX |

---

## Project Structure (conventions)

Organize Godot scenes and scripts by game domain. Prefer small, composable scenes over monoliths.

```
zeroG/
├── gdd/                    # Design docs (read-only reference)
├── assets/
│   ├── sprites/
│   ├── audio/
│   ├── ui/
│   └── fonts/
├── scenes/
│   ├── combat/
│   ├── overworld/
│   ├── guildhall/
│   ├── ui/
│   └── characters/
├── scripts/
│   ├── autoload/           # Singletons (GameState, EventBus, SaveManager)
│   ├── combat/
│   ├── deck/
│   ├── loot/
│   ├── guildhall/
│   └── world/
├── data/                   # JSON / .tres resources (cards, items, enemies, quests)
└── tests/                  # GUT or Godot test framework
```

- Use **Resource** classes (`.tres` / `.gd` extending `Resource`) for data definitions: cards, gear, enemies, loot tables.
- Use an **autoload EventBus** for cross-system signals; avoid tight coupling between combat, deck, and UI.
- Keep platform-specific code isolated (input, safe areas, touch vs. keyboard).

---

## Core Game Systems

Agents implementing features should understand how these systems interact.

### Combat & Deck Engine

- **Deck:** 20–50 cards per character.
- **Hand:** Start with 5 cards; expand to 10 via leveling/gear; up to 12 playable in a single "overdrive" turn.
- **Mana:** Regenerate 5 per turn; cap 20 (expandable via items). Ultimate AoE abilities (e.g. Fissure) drain the entire pool.
- **Physical attacks:** Weapons deal slashing, blunt, or elemental damage. Physical hits can **proc** deck card abilities at zero mana cost.
- **Burn pile:** Played cards go to burn pile; revivable mid-combat. Empty draw pile → manual reshuffle with **Fatigue** penalty (mana burn or stat debuffs).
- **AI:** Standard enemies use fixed patterns. Bosses use fixed AI + randomized ability decks. Boss combos are **telegraphed one turn ahead**.

### Classes & Skills

- **Fluid class system:** Advanced class derived from the ratio of base cards (Warrior, Mage, Priest, Rogue) in a 50-card deck.
- **Class anchors:** Legendary gear can force a class override.
- **Class changes** must update 16-bit character sprites visibly.
- **Skill waking:** Passive skills (Locksmithing, Learn, etc.) unlock when conditions are met.
- **Learn (Blue Mage):** Steal boss abilities permanently; scaled boss cards cost heavy mana or act as one-time "Boss Essence" consumables.
- **Dormant cards:** Powerful unplayable cards until a specific weapon is equipped or a combo is played first (Exodia-style setups).

### Loot & Economy

Eight rarity tiers — use these exact names and colors in code and UI:

| Tier | Color |
|------|-------|
| Trash | Gray |
| Common | White |
| Magic | Blue |
| Rare | Yellow |
| Epic | Purple |
| Legendary | Orange |
| Mythic | Red |
| Unique | Green |

- **Cursed gear:** High stats + severe drawbacks; cannot be unequipped until blessed by a priest.
- **Card crafting:** Arcane Synthesizer fuses identical cards (Slash + Slash → Slash+) or combines elements (Slash + Ember → Flame Arc).
- **Gear enhancement:** Upgrade rarity with ores/materials, or **Imbue** weapons by permanently burning an ability card onto them.

### Guildhall (Base Building)

- Starts as an abandoned **Heretic's Shack** outside a medium city.
- Upgrades cost Gold, Materials (Wood, Ore, Rock), and Primal Essence.
- **Barracks / Dispatch:** Recruit RNG mercenaries; equip Trash/Common gear on them for passive material-gathering missions.
- **Upkeep:** Positive upkeep — paying supplies grants **High Morale** (+XP, faster dispatch), not punishment for neglect.

### World & Exploration

- **Traversal:** Fully explorable zones (Octopath Traveler style) + overworld map for fast travel.
- **Encounters:** Invisible random encounters for standard enemies; bosses and uber bosses are visible on the field.
- **Primal Rifts:** Limited-time map dungeons with elite enemies, Primal Essence, Mythic gear, and Skill Waking opportunities.
- **Dead zones:** Low-level areas stay relevant via scaled dynamic chests, Metroidvania locks (Locksmithing), replayable bosses, and dispatch-board fetch quests.

---

## Characters & Narrative

### Playable Party (up to 4)

| Character | Role | Notes |
|-----------|------|-------|
| The Orphan (protagonist) | Scavenger, blank slate | No innate magic; outside the gods' control |
| Brynnael | Elven Healer | Priest/Mage affinity; betrayed by a human; backed by Sylvariel (New Goddess of Nature and Light) |
| Edward "Blackbeard" | Undead Rogue | Cursed by a ghost ship; protects un-life and the criminal underworld |
| Seluc | Orc veteran | Shaman/Monk affinity; Life Debt after rescue in a Primal Rift |

### Lore Constraints

- **Old Gods** hate technology and want to subjugate humanity.
- **New Gods** are architects of civilization who demand strict obedience.
- The **5-Step Plan** (Old Gods): erase non-human races → destroy New Gods → raze cities / breeding camps → primal regression → forced worship.
- **Twist:** The five magical seal documents that "prove" the conspiracy are themselves the apocalypse catalyst when all five are gathered.

Tone: underdog scavenger rising from nothing; divine war backdrop; technology vs. primal magic tension.

---

## UI & UX Guidelines

- Mobile-first layout: large touch targets, readable text, minimal chrome.
- Combat UI must show: hand, mana, burn pile state, enemy telegraphs, and target selection clearly.
- Loot tier colors must be consistent everywhere (inventory, tooltips, ground drops).
- Avoid modal overload on small screens; prefer slide panels and contextual actions.

---

## Coding Conventions

- **GDScript style:** `snake_case` for variables/functions, `PascalCase` for classes and nodes types, `UPPER_SNAKE_CASE` for constants.
- Prefer typed GDScript (`var health: int`, `func take_damage(amount: int) -> void`).
- Use `@export` for designer-tunable values on Resources and scenes.
- Signal names: past tense for events (`card_played`, `enemy_defeated`), not imperative.
- No magic numbers in gameplay logic — define constants or export vars with comments referencing GDD sections.
- Favor composition (`Node` children) over deep inheritance hierarchies.

### Naming

- Card IDs: `snake_case` (e.g. `flame_arc`, `boss_essence_fissure`)
- Scene files: `PascalCase.tscn` (e.g. `CombatScene.tscn`, `CardHand.tscn`)
- Data resources: match the entity (`cards/slash.tres`, `enemies/primal_rift_elite.tres`)

---

## What NOT to Do

- Do not add free-to-play monetization, ads, or gacha — this is a **premium** title.
- Do not add grid-based movement or real-time action combat.
- Do not introduce new rarity tiers or rename existing ones.
- Do not clutter the UI with fantasy ornamentation; keep the high-tech system aesthetic.
- Do not hardcode party members beyond the four named characters for the core roster.
- Do not spoil the 5-seal twist in player-facing early-game content.

---

## Build & Test

> Update this section as the Godot project is scaffolded.

```bash
# Run the game (once project.godot exists)
godot --path .

# Run tests (once GUT or test framework is added)
godot --path . -s addons/gut/gut_cmdln.gd
```

Until the project is initialized, agents may scaffold `project.godot` and directory structure when asked.

---

## Demo Scope (Free Version)

The free demo must include:

1. Intro narrative
2. Heretic's Shack (guildhall tutorial)
3. Core combat loop
4. Party progression through recruiting the **fourth character (Seluc)**

Do not implement paid-content gates until the full game scope is defined.

---

## Commit & PR Guidelines

- Commits: imperative mood, concise (e.g. `Add burn pile reshuffle fatigue penalty`)
- PRs: describe gameplay behavior change, link to GDD section when relevant, include screenshots for UI/combat changes
- Never commit secrets, API keys, or platform signing credentials
