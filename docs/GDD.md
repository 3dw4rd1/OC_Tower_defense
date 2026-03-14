# Game Design Document — OC Tower Defense

_Status: v1.0 Draft | Owner: Sage | Last updated: 2026-03-14_

---

## 1. Overview

**Title:** OC Tower Defense  
**Genre:** 2D pixel art idle tower defense  
**Engine:** Godot 4.x  
**Platform:** PC (Windows/Linux/Mac)  
**Scope:** Solo prototype — test case for OpenClaw agent-assisted game development  
**Art style:** 16x16 pixel art tiles  

### Pitch
A strategic tower defense with no predefined lanes. Your towers are your maze. Enemies pathfind intelligently to your base — where you place your towers determines the path they take. Between waves, a skill tree lets you deeply upgrade each tower type, making progression feel powerful and personalised. Play actively or let it run while you're busy: the game is designed for both.

### Inspiration
- **yorg.io** — open-map, no-lane tower defense with emergent chokepoints

---

## 2. Core Loop

```
Wave starts → Enemies pathfind to base → Kill enemies → Earn gold
→ Wave ends → Auto-pause + gold bonus → Spend gold on towers & skill tree
→ Unpause → Next wave
```

### Dual Play Style
The game supports two playstyles simultaneously:

| Style | How it plays |
|-------|-------------|
| **Idle / Passive** | Set up between waves, auto-pause handles transitions, let waves resolve unattended |
| **Active / Optimising** | Place towers mid-wave as gold accumulates, react to enemy positioning, min-max routes |

Neither is "wrong" — the game rewards both. Active play offers faster skill tree growth; passive play is still completable.

---

## 3. Map

- **Count:** 1 map (prototype scope)
- **Layout:** Tile grid, open arena — no predefined paths or lanes
- **Base position:** Centre of map (draws enemies from all directions)
- **Tile size:** 16x16 px
- **Recommended map size:** 32x32 tiles (512x512 px logical, scaled up)

### Pathfinding Rules
- Enemies use A* pathfinding to navigate to the base each tick
- Tower placement acts as obstacles — reshaping enemy routes in real time
- **No full blocking:** the player cannot place towers in a way that removes all routes to the base. If a placement would fully block the path, it is rejected (visual feedback shown)
- Enemies recalculate path when obstacles change

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
| **Basic** | 30 | Medium | 5g | Balanced, introduces the core loop |
| **Fast** | 15 | High | 8g | Punishes coverage gaps; tests maze routing |
| **Tank** | 120 | Low | 20g | Soaks damage; stresses single-target towers |

### Wave Composition (10 Waves)

| Wave | Enemies | Notes |
|------|---------|-------|
| 1 | Basic ×5 | Tutorial feel — establish placement |
| 2 | Basic ×8 | More volume |
| 3 | Basic ×10 | First real chokepoint pressure |
| 4 | Basic ×8 + Fast ×4 | Introduce Fast — gaps get punished |
| 5 | Fast ×10 | Pure speed wave |
| 6 | Basic ×6 + Fast ×6 + Tank ×1 | First Tank appearance |
| 7 | Tank ×4 | DPS check |
| 8 | Basic ×10 + Fast ×6 | Volume surge |
| 9 | Tank ×4 + Fast ×8 | Combined pressure |
| 10 | Basic ×10 + Fast ×10 + Tank ×6 | Final mixed wave |

---

## 5. Towers

### General Behaviour
- Placed freely on any non-occupied tile
- Act as physical obstacles for enemy pathfinding
- Attack automatically — no player input required during combat
- Can be placed mid-wave or between waves

### Tower Types

| Tower | Damage | Range | Attack Speed | Cost | Role |
|-------|--------|-------|-------------|------|------|
| **Basic** | 10 | Medium | Medium | 50g | All-rounder starter |
| **Sniper** | 40 | Long | Slow | 100g | Single-target DPS, long corridors |
| **Splash** | 15 (AoE) | Short | Medium | 120g | Crowd control, clustered enemies |
| **Slow** | 5 | Medium | Fast | 80g | Reduces enemy speed; support role |

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
- Gold is also earned per enemy kill (see enemy table above)

### Structure
- Each tower type has **1 skill tree** with **5 nodes**
- Nodes are arranged in a **branching path** — after node 2, player picks one of two branches (damage path vs utility path)
- Skills apply globally to all towers of that type on the map

### Skill Trees (Draft)

#### Basic Tower
```
[1] Faster Attack (+20% attack speed)
      ↓
[2] Extended Range (+25% range)
      ↙         ↘
[3a] Double Shot     [3b] Armour Pierce
     (fires 2 proj)       (ignores 50% tank HP)
      ↓                    ↓
[4a] Overcharge          [4b] Ricochet
     (every 5th shot      (shots bounce to
      deals 3x damage)     nearest enemy)
```

#### Sniper Tower
```
[1] Lethal Precision (+30% damage)
      ↓
[2] Eagle Eye (+40% range)
      ↙         ↘
[3a] One Shot          [3b] Suppress
     (chance to         (hit enemies move
      instant-kill       30% slower for 2s)
      Basic enemies)
      ↓                  ↓
[4a] Execute           [4b] Chain Suppress
     (guaranteed         (suppress spreads
      kill <10% HP)       to nearby enemies)
```

#### Splash Tower
```
[1] Bigger Blast (+30% AoE radius)
      ↓
[2] Shrapnel (+20% damage)
      ↙         ↘
[3a] Firebomb          [3b] Concussive
     (AoE leaves         (AoE knocks enemies
      fire DoT 2s)        back slightly)
      ↓                   ↓
[4a] Napalm            [4b] Shockwave
     (fire DoT stacks)    (knockback
                           stuns for 0.5s)
```

#### Slow Tower
```
[1] Deep Freeze (+40% slow intensity)
      ↓
[2] Wide Chill (+35% range)
      ↙         ↘
[3a] Ice Shatter        [3b] Frostbite
     (frozen enemies      (slowed enemies
      take +50% damage)    take damage over time)
      ↓                    ↓
[4a] Glacial Field       [4b] Blizzard
     (AoE slow aura,       (periodic frost
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
- Each enemy that reaches the base deals **1 damage** (all enemy types)
- HP reaching 0 = **Game Over**
- Surviving all 10 waves = **Victory**
- No HP regeneration between waves (considered for future iteration)

---

## 8. Game Flow

```
Title Screen
    ↓
Map loads — base placed, empty grid
    ↓
[Between-wave phase] — player places towers, spends gold on skill tree
    ↓
Player manually starts Wave 1
    ↓
[Wave phase] — enemies spawn + pathfind, towers auto-attack
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
- Wave number + enemy count remaining
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

## 10. Technical Notes (for Rex)

- **Pathfinding:** Godot's `NavigationRegion2D` or custom A* via `AStar2D`
  - Recommend `AStar2D` for tile-grid maps — gives direct control over blocked tiles
  - On tower placement: update A* grid, validate path still exists before confirming placement
- **Tower targeting:** each tower queries nearest enemy in range each attack tick
- **Autoloads:** `GameManager`, `WaveManager`, `EconomyManager`, `SkillTreeManager`
- **Tile grid:** `TileMap` node, single layer, 16x16 tiles
- **Wave spawning:** WaveManager reads wave data from a resource/config file (data-driven)

---

## 11. Out of Scope (v1.0 Prototype)

- Multiple maps
- Flying enemies
- Tower selling / moving
- Meta-progression (prestige, unlocks between runs)
- Sound design (placeholder OK)
- Mobile support
- Saving / loading mid-run

---

## 12. Open Questions

- [ ] Map size — 32x32 tiles confirmed?
- [ ] Should base be centred or in a corner? (Centre = 4-directional pressure; corner = easier to defend)
- [ ] Node 5 (final skill)? Or keep trees at 4 nodes for prototype?
- [ ] Starting gold amount?

---

_GDD owned by Sage. Implementation owned by Rex. QA signs off before each feature is closed._
