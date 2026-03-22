# Game Design Document — OC Tower Defense

_Status: v1.2 — Decisions locked | Owner: Sage | Last updated: 2026-03-22_

---

## 1. Overview

**Title:** OC Tower Defense  
**Genre:** 2D pixel art idle tower defense  
**Engine:** Godot 4.x  
**Platform:** PC (Windows/Linux/Mac)  
**Scope:** Solo prototype — test case for OpenClaw agent-assisted game development  
**Art style:** 16x16 pixel art — zombie apocalypse survival horror  

### Pitch
A strategic tower defense with no predefined lanes. Your towers are your maze. Enemies pathfind intelligently to your base — where you place your towers determines the path they take. Between waves, a skill tree lets you deeply upgrade each tower type, making progression feel powerful and personalised. Play actively or let it run while you're busy: the game is designed for both.

### Inspiration
- **yorg.io** — open-map, no-lane tower defense with emergent chokepoints

---

## 2. Core Loop

```
Wave starts → Zombies pathfind to base → Kill zombies → Earn gold
→ Wave ends → Auto-pause + gold bonus → Spend gold on towers & skill tree
→ Unpause → Next wave
```

### Dual Play Style
The game supports two playstyles simultaneously:

| Style | How it plays |
|-------|-------------|
| **Idle / Passive** | Set up between waves, auto-pause handles transitions, let waves resolve unattended |
| **Active / Optimising** | Place towers mid-wave as gold accumulates, react to zombie positioning, min-max routes |

Neither is "wrong" — the game rewards both. Active play offers faster skill tree growth; passive play is still completable.

---

## 3. Map

- **Count:** 1 map (prototype scope)
- **Layout:** Tile grid, open forest arena — no predefined paths or lanes
- **Base position:** Centre of map (draws zombies from all directions)
- **Tile size:** 16x16 px
- **Recommended map size:** 32x32 tiles (512x512 px logical, scaled up)

### Environment
- **Ground:** Green grass tiles — the primary terrain
- **Obstacles:** Forest trees (replacing rocks) — large, solid, impassable
- **Decorations (non-blocking):** Mushrooms, fallen logs, undergrowth — visual flavour only
- Trees are generated procedurally at map load using noise (same system as prior rocks)

### Pathfinding Rules
- Zombies use A* pathfinding to navigate to the base each tick
- Tower placement acts as obstacles — reshaping zombie routes in real time
- Trees are pre-placed obstacles that also influence routing from the start
- **No full blocking:** the player cannot place towers in a way that removes all routes to the base. If a placement would fully block the path, it is rejected (visual feedback shown)
- Zombies recalculate path when obstacles change

---

## 4. Enemies

### General Behaviour
- Spawn from the map edges (randomised spawn points per wave)
- Pathfind to the base autonomously
- Deal damage to the base on contact (not on death)
- Drop gold on death

### Enemy Types

| Enemy | HP | Speed | Gold Drop | Role |
|-------|-----|-------|-----------|------|
| **Shambler** | 30 | Medium | 5g | Standard zombie — balanced, introduces the core loop |
| **Runner** | 15 | High | 8g | Fast zombie — punishes coverage gaps; tests maze routing |
| **Brute** | 120 | Low | 20g | Hulking zombie — soaks damage; stresses single-target towers |

### Wave Composition (10 Waves)

| Wave | Enemies | Notes |
|------|---------|-------|
| 1 | Shambler ×5 | Tutorial feel — establish placement |
| 2 | Shambler ×8 | More volume |
| 3 | Shambler ×10 | First real chokepoint pressure |
| 4 | Shambler ×8 + Runner ×4 | Introduce Runners — gaps get punished |
| 5 | Runner ×10 | Pure speed wave |
| 6 | Shambler ×6 + Runner ×6 + Brute ×1 | First Brute appearance |
| 7 | Brute ×4 | DPS check |
| 8 | Shambler ×10 + Runner ×6 | Volume surge |
| 9 | Brute ×4 + Runner ×8 | Combined pressure |
| 10 | Shambler ×10 + Runner ×10 + Brute ×6 | Final mixed wave |

---

## 5. Towers

### General Behaviour
- Placed freely on any non-occupied tile
- Act as physical obstacles for zombie pathfinding
- Attack automatically — no player input required during combat
- Can be placed mid-wave or between waves

### Tower Types

| Tower | Damage | Range | Attack Speed | Cost | Role |
|-------|--------|-------|-------------|------|------|
| **Rifle Post** | 10 | Medium | Medium | 50g | All-rounder starter — survivor with a rifle |
| **Sniper Nest** | 40 | Long | Slow | 100g | Single-target DPS, long corridors |
| **Molotov Pit** | 15 (AoE) | Short | Medium | 120g | Crowd control, clustered zombies |
| **Barbed Wire** | 5 | Medium | Fast | 80g | Slows zombie movement; support role |

### Placement Rules
- Cannot block all pathfinding routes (validated on placement attempt)
- Towers cannot be sold or moved (placement is permanent — raises stakes)

---

## 6. Skill Tree

### Philosophy
The skill tree is the **primary progression and expression system**. It should feel powerful, personal, and satisfying. Each tower type has its own tree. The player chooses which towers to invest in — you can't max everything.

### Economy
- **Gold** is the single currency for both tower placement and skill tree upgrades
- End-of-wave bonus: flat gold reward (scales with wave number)
  - Formula (draft): `bonus = 50 + (wave_number × 25)` 
- Gold is also earned per zombie kill (see enemy table above)

### Structure
- Each tower type has **1 skill tree** with **5 nodes**
- Nodes are arranged in a **branching path** — after node 2, player picks one of two branches (damage path vs utility path)
- Skills apply globally to all towers of that type on the map

### Skill Trees (Draft)

#### Rifle Post
```
[1] Faster Attack (+20% attack speed)
      ↓
[2] Extended Range (+25% range)
      ↙         ↘
[3a] Double Shot     [3b] Armour Pierce
     (fires 2 proj)       (ignores 50% Brute HP)
      ↓                    ↓
[4a] Overcharge          [4b] Ricochet
     (every 5th shot      (shots bounce to
      deals 3x damage)     nearest zombie)
```

#### Sniper Nest
```
[1] Lethal Precision (+30% damage)
      ↓
[2] Eagle Eye (+40% range)
      ↙         ↘
[3a] One Shot          [3b] Suppress
     (chance to         (hit zombies move
      instant-kill       30% slower for 2s)
      Shamblers)
      ↓                  ↓
[4a] Execute           [4b] Chain Suppress
     (guaranteed         (suppress spreads
      kill <10% HP)       to nearby zombies)
```

#### Molotov Pit
```
[1] Bigger Blast (+30% AoE radius)
      ↓
[2] Shrapnel (+20% damage)
      ↙         ↘
[3a] Firebomb          [3b] Concussive
     (AoE leaves         (AoE knocks zombies
      fire DoT 2s)        back slightly)
      ↓                   ↓
[4a] Napalm            [4b] Shockwave
     (fire DoT stacks)    (knockback
                           stuns for 0.5s)
```

#### Barbed Wire
```
[1] Deep Snag (+40% slow intensity)
      ↓
[2] Wide Net (+35% range)
      ↙         ↘
[3a] Lacerating        [3b] Infected Wound
     (slowed zombies     (slowed zombies
      take +50% damage)   take damage over time)
      ↓                    ↓
[4a] Tangle Field        [4b] Plague Pulse
     (AoE slow aura,       (periodic slow
      affects all nearby)   pulse, wide range)
```

### Skill Node Costs (Draft)

| Node | Cost |
|------|------|
| Node 1 | 75g |
| Node 2 | 125g |
| Node 3a / 3b | 175g |
| Node 4a / 4b | 250g |

---

## 7. Base & Win/Lose

- **Base HP:** 20
- Each zombie that reaches the base deals **1 damage** (all zombie types)
- HP reaching 0 = **Game Over**
- Surviving all 10 waves = **Victory**
- No HP regeneration between waves (considered for future iteration)

---

## 8. Game Flow

```
Title Screen
    ↓
Map loads — base placed, empty forest grid (trees pre-placed)
    ↓
[Between-wave phase] — player places towers, spends gold on skill tree
    ↓
Player manually starts Wave 1
    ↓
[Wave phase] — zombies spawn + pathfind, towers auto-attack
  - Player may place towers / upgrade mid-wave at any time
    ↓
Wave complete → Auto-pause → Gold bonus awarded
    ↓
[Between-wave phase] — player upgrades, plans next wave
    ↓
Player unpauses → next wave begins
    ↓
... repeat through Wave 10 ...
    ↓
Win or Game Over screen
```

---

## 9. UI / UX

### HUD (in-wave)
- Gold counter (top)
- Base HP bar (visible near base)
- Wave number + zombie count remaining
- Tower placement panel (sidebar or bottom bar)

### Between-wave screen
- Gold bonus notification
- Skill tree panel (per tower type — tabbed or expandable)
- "Start Next Wave" button (manual unpause)

### Skill Tree UI
- Visual node graph per tower
- Locked nodes shown greyed out
- Gold cost shown on each node
- Branching clearly visualised
- Selected path highlighted

---

## 10. Art Direction

**Theme:** Zombie apocalypse — human survivors defending a forest encampment against waves of the undead.

**World:** Dense forest, green grass, overgrown wilderness. Fallen logs, clusters of mushrooms, and undergrowth fill the gaps between trees. Nature is reclaiming the world.

**Survivors (towers):** Makeshift, jury-rigged, desperate. Rifle posts, fire pits, barbed wire — whatever keeps the dead out.

**Zombies (enemies):** Decayed, relentless, mindless. Varying in size and speed but all converging on the living.

**Palette:** Rich greens and earthy browns (world) · warm orange/yellow (fire, torchlight) · sickly grey-green (zombie flesh) · blood red (damage/death)

| Element | Description |
|---------|-------------|
| Ground | Green grass tiles — primary terrain |
| Trees | Dense forest trees — procedural obstacles, impassable |
| Decorations | Mushrooms, fallen logs, undergrowth — visual flavour, non-blocking |
| Base | Survivor camp — wooden barricade, campfire, makeshift walls |
| Enemy: Shambler | Standard zombie — ragged clothes, outstretched arms |
| Enemy: Runner | Fast zombie — hunched, sprinting, feral |
| Enemy: Brute | Hulking zombie — bloated, massive, slow but terrifying |
| Tower: Rifle Post | Wooden watchtower with armed survivor |
| Tower: Sniper Nest | Elevated platform, scoped rifle, camouflage netting |
| Tower: Molotov Pit | Burning barrel / thrown fire bombs |
| Tower: Barbed Wire | Coiled wire fence — slows anything that tries to pass |

---

## 11. Technical Notes (for Rex)

- **Pathfinding:** Godot's `NavigationRegion2D` or custom A* via `AStar2D`
  - Recommend `AStar2D` for tile-grid maps — gives direct control over blocked tiles
  - On tower placement: update A* grid, validate path still exists before confirming placement
  - Trees are treated as static obstacles (same as prior rocks) — AStar2D points disabled at their positions
- **Tower targeting:** each tower queries nearest zombie in range each attack tick
- **Autoloads:** `GameManager`, `WaveManager`, `EconomyManager`, `SkillTreeManager`, `TerrainManager`
- **Tile grid:** `TileMap` node, single layer, 16x16 tiles
- **Wave spawning:** WaveManager reads wave data from a resource/config file (data-driven)
- **Map dimensions:** 71×33 grid, 16px tiles, Camera2D centred at (568, 314) — confirmed in engine

---

## 12. Out of Scope (v1.0 Prototype)

- Multiple maps
- Flying enemies
- Tower selling / moving
- Meta-progression (prestige, unlocks between runs)
- Sound design (placeholder OK)
- Mobile support
- Saving / loading mid-run

---

## 13. Decisions Log

| # | Decision | Notes |
|---|----------|-------|
| 1 | Map size: **32x32 tiles** (expanded to 71×33 in engine) | Confirmed in engine — wider feel preferred |
| 2 | Base position: **Centre** | 4-directional zombie pressure; harder, more interesting |
| 3 | Skill tree depth: **4 nodes per tree** for prototype | Branching at node 2, two paths of 2 nodes each. Expandable later |
| 4 | Starting gold: **100g** | Clean round number; enough for 2 Rifle Posts before wave 1 |
| 5 | Theme: **Zombie apocalypse / forest** | Pivoted from dark sci-fi (humans vs AI robots) — better asset availability. Rocks → trees, robots → zombies |

---

_GDD owned by Sage. Implementation owned by Rex. QA signs off before each feature is closed._
