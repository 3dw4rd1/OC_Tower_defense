# OC Tower Defense — Card System Spec
_Status: Draft | Owner: Amadeus | For: Sage (design validation) + Rex (implementation)_
_Last updated: 2026-03-27_

> **⚠️ Implementation Note:** This document describes design intent. Once implementation begins, the code is the source of truth.
> For current implementation, see `game/scripts/autoloads/CardManager.gd` and `game/scripts/cards/card_effect_registry.gd`.
> If there is any conflict between this spec and the code, trust the code.

---

## Overview

This document defines a new end-of-wave card draft system for OC Tower Defense. It covers the full design intent, card catalogue, and technical architecture. Sage should validate the design section before Rex begins implementation. Rex should follow the build order in Section 5 exactly.

---

## Part 1 — Design

### What It Is

After each wave ends, the player is presented with a **Card Draft Screen** showing 3 randomly drawn cards. The player picks one. The pick is free (no gold cost), permanent for the run, and stackable — the same card can be picked multiple times.

This system sits **on top of** the existing gold economy. Gold remains the currency for tower placement and skill tree upgrades. Cards are a completely separate, always-free progression layer.

### The Specialisation Engine

The invisible backbone of the system is a **specialisation score** tracked per tower type:

```
{ "basic": 0, "sniper": 0, "splash": 0, "slow": 0, "wall": 0 }
```

Every time the player picks a card with a `tower_affinity` field, that tower type's score increments by 1. This score does two things silently:

- **Snowball** — cards for the player's highest-scoring tower types appear more frequently in future draws
- **Unlock** — once a tower type crosses score thresholds, stronger cards for that type enter the draw pool

The player never sees this score directly. They feel it through the cards they're offered.

**If the player spreads evenly across all tower types and never specialises, later waves should become genuinely difficult and they will likely lose.** The card system should accelerate a committed build and leave an unfocused one behind.

### Card Rarities

| Rarity | Base Draw Weight | Unlock Condition |
|--------|-----------------|------------------|
| Common | 60% | Always available |
| Uncommon | 28% | Always available |
| Rare | 10% | Tower specialisation score ≥ 3 for that affinity |
| Legendary | 2% | Tower specialisation score ≥ 6 for that affinity |

The "Survivor's Instinct" meta-card (see catalogue below) permanently adjusts these weights when picked. It is stackable.

### Card Categories

**Tower Upgrades** — direct stat improvements to a specific tower type. Apply globally to all placed towers of that type and all future placements. These feed specialisation score.

**Synergy Cards** — bonuses that trigger when two tower types interact. Only appear in the draw pool if the player has placed both relevant tower types. Feed specialisation score for both affinities.

**Economy Cards** — gold income adjustments. No tower affinity, do not feed specialisation score.

**Map/Passive Cards** — terrain and environmental effects. No tower affinity.

**Curse Cards** — negative effects paired with a reward. The player must actively choose to take the downside. No tower affinity.

---

## Part 2 — Card Catalogue

### Common Cards

| ID | Name | Description | Affinity | Effect ID |
|----|------|-------------|----------|-----------|
| `rifle_atkspd_1` | Hair Trigger | Rifle Posts fire 20% faster. | basic | `tower_attack_speed` |
| `rifle_range_1` | Extended Barrel | Rifle Posts gain 15% range. | basic | `tower_range` |
| `sniper_dmg_1` | Hollow Point | Sniper Nests deal 20% more damage. | sniper | `tower_damage` |
| `sniper_range_1` | Eagle Eye | Sniper Nests gain 20% range. | sniper | `tower_range` |
| `splash_dmg_1` | Extra Fuel | Molotov Pits deal 15% more damage. | splash | `tower_damage` |
| `splash_radius_1` | Wide Spread | Molotov Pit AoE radius increases by 20%. | splash | `tower_aoe_radius` |
| `slow_intensity_1` | Deep Snag | Barbed Wire slows enemies 15% more. | slow | `tower_slow_intensity` |
| `slow_atkspd_1` | Rapid Coil | Barbed Wire fires 25% faster. | slow | `tower_attack_speed` |
| `economy_wave_1` | Scroungers | Wave end gold bonus +50g. | null | `wave_bonus_flat` |
| `economy_kill_1` | Bounty Board | All enemies drop +2g on death. | null | `kill_gold_flat` |

### Uncommon Cards

| ID | Name | Description | Affinity | Effect ID |
|----|------|-------------|----------|-----------|
| `rifle_atkspd_2` | Full Auto | Rifle Posts fire 35% faster. | basic | `tower_attack_speed` |
| `rifle_dmg_2` | Armour Piercing | Rifle Posts deal 25% more damage. | basic | `tower_damage` |
| `sniper_dmg_2` | Lethal Precision | Sniper Nests deal 40% more damage. | sniper | `tower_damage` |
| `splash_radius_2` | Shrapnel | Molotov Pit AoE radius increases by 35%. | splash | `tower_aoe_radius` |
| `slow_range_2` | Wide Net | Barbed Wire gains 35% range. | slow | `tower_range` |
| `synergy_slow_sniper` | Spotter | Slowed enemies take 30% bonus damage from Sniper Nests. | sniper | `synergy_slow_sniper_bonus` |
| `synergy_slow_dmg` | Lacerating | Enemies slowed by Barbed Wire take 25% bonus damage from all sources. | slow | `synergy_slow_all_bonus` |
| `economy_wave_2` | Wartime Economy | Wave end gold bonus +100g. | null | `wave_bonus_flat` |
| `economy_cost_1` | Bulk Order | All towers cost 10% less gold to place. | null | `tower_cost_reduction` |
| `map_dead_ground` | Dead Ground | One random open tile becomes difficult terrain — enemies crossing it move at 70% speed permanently. | null | `spawn_slow_tile` |
| `meta_lucky_1` | Survivor's Instinct | Rare and Legendary card drop chances permanently increased by 8%. Stackable. | null | `rare_weight_boost` |
| `curse_horde` | Horde Surge | The next wave spawns 40% more enemies. In return, draw 2 cards instead of 1 at the end of that wave. | null | `curse_next_wave_horde` |
| `curse_brittle` | Brittle Towers | All towers deal 20% less damage for 2 waves. Gain 150g immediately. | null | `curse_temp_damage_penalty` |

### Rare Cards

| ID | Name | Description | Affinity | Effect ID |
|----|------|-------------|----------|-----------|
| `rifle_chain` | Kill Chain | Every 10th kill by any Rifle Post triggers a free volley from all Rifle Posts simultaneously. Stacks reduce trigger count by 2. | basic | `rifle_kill_chain` |
| `rifle_dmg_3` | Overcharge | Every 5th shot from a Rifle Post deals 3× damage. | basic | `rifle_overcharge` |
| `sniper_execute` | Execute | Sniper Nests instantly kill enemies below 10% HP. | sniper | `sniper_execute` |
| `sniper_suppress` | Suppress | Sniper hits cause enemies to move 30% slower for 2 seconds. | sniper | `sniper_suppress` |
| `splash_dot` | Firebomb | Molotov explosions leave burning ground for 2 seconds, dealing damage over time. | splash | `splash_fire_dot` |
| `splash_knockback` | Concussive | Molotov explosions knock enemies back slightly. | splash | `splash_knockback` |
| `slow_aura` | Tangle Field | Barbed Wire gains a passive slow aura affecting all enemies in range, in addition to its projectiles. | slow | `slow_aura` |
| `slow_dot` | Infected Wound | Enemies hit by Barbed Wire take damage over time while slowed. | slow | `slow_dot` |
| `synergy_frost_fire` | Frost and Fire | Enemies slowed by Barbed Wire that are hit by a Molotov explosion are instantly frozen for 0.5 seconds. Requires both tower types placed. | splash | `synergy_frost_fire` |
| `economy_blood_money` | Blood Money | Brutes drop triple gold for the next 3 waves. | null | `curse_brute_gold_boost` |
| `map_clearcut` | Clearcut | Remove 3 random obstacle tiles from the map. | null | `remove_obstacles` |
| `map_overgrowth` | Overgrowth | 4 new obstacle tiles spawn in random open positions. Reshapes zombie routing. | null | `spawn_obstacles` |
| `curse_dead_weight` | Dead Weight | One random tower type is permanently removed from your card pool. Gain +30% to all cards for your highest-specialisation tower type. | null | `curse_remove_affinity` |

### Legendary Cards

| ID | Name | Description | Affinity | Effect ID |
|----|------|-------------|----------|-----------|
| `rifle_legendary_bounce` | Ricochet | Rifle Post shots bounce to the nearest enemy within 64px after hitting their target. | basic | `rifle_ricochet` |
| `rifle_legendary_double` | Double Tap | Rifle Posts fire a second shot at a random enemy in range 0.1s after each primary shot. | basic | `rifle_double_tap` |
| `sniper_legendary_chain` | Chain Suppress | Suppress effect spreads to all enemies within 80px of the hit target. | sniper | `sniper_chain_suppress` |
| `sniper_legendary_oneshot` | One Shot | Sniper Nests have a 25% chance to instantly kill any Shambler. | sniper | `sniper_one_shot` |
| `splash_legendary_napalm` | Napalm | Burning ground from Firebomb stacks — enemies that re-enter burning tiles take double fire damage. Requires Firebomb (rare). | splash | `splash_napalm` |
| `splash_legendary_shockwave` | Shockwave | Molotov knockback becomes a stun — enemies are frozen for 0.5s on knockback. Requires Concussive (rare). | splash | `splash_shockwave` |
| `slow_legendary_plague` | Plague Pulse | Barbed Wire periodically emits a wide-range slow pulse affecting all enemies in a large radius every 3 seconds. | slow | `slow_plague_pulse` |
| `slow_legendary_tangle` | Tangle Field+ | Barbed Wire aura now fully stops enemies for 0.3s when they first enter range. Requires Tangle Field (rare). | slow | `slow_full_stop` |
| `killbox_legendary` | The Killbox | Enemies within a Splash explosion radius take 60% bonus damage from Sniper Nests for 3 seconds after the explosion. Requires both tower types placed at high specialisation. | sniper | `synergy_killbox` |

---

## Part 3 — Technical Architecture

### New Files

```
game/
├── scripts/
│   ├── autoloads/
│   │   └── CardManager.gd
│   └── cards/
│       └── card_effect_registry.gd
├── scenes/
│   └── ui/
│       ├── card_draft_screen.tscn
│       ├── card_draft_screen.gd
│       ├── card_panel.tscn
│       └── card_panel.gd
└── data/
    └── cards/
        ├── common.json
        ├── uncommon.json
        ├── rare.json
        └── legendary.json
```

### Existing Files to Modify

| File | Change |
|------|--------|
| `game/project.godot` | Register `CardManager` as an autoload, same pattern as existing autoloads |
| `game/scripts/autoloads/GameManager.gd` | Add `CARD_DRAFT` to `GameState` enum |
| `game/scripts/autoloads/GameManager.gd` | Update `end_wave()` to transition to `CARD_DRAFT` before `WAVE_COMPLETE` |
| `game/scripts/towers/tower_base.gd` | Read attack/range/damage multipliers from `CardManager` on ready and on `card_picked` signal |
| `game/scripts/autoloads/EconomyManager.gd` | Listen for economy cards via `CardManager.card_picked` signal |
| `game/scenes/levels/main.tscn` | Add `CardDraftScreen` as a child node |

### GameState Flow

Add `CARD_DRAFT` to the `GameState` enum in `GameManager.gd`:

```gdscript
enum GameState {
    SETUP,
    WAVE_ACTIVE,
    WAVE_COMPLETE,
    CARD_DRAFT,     # ← new
    GAME_OVER,
    VICTORY
}
```

Updated `end_wave()` flow:

```
WAVE_ACTIVE → end_wave() called
→ award wave bonus gold
→ set state to CARD_DRAFT
→ emit signal: card_draft_started
→ CardManager draws 3 cards, opens CardDraftScreen
→ player picks a card
→ CardManager applies effect, emits card_picked
→ CardDraftScreen closes
→ set state to WAVE_COMPLETE
→ player manually starts next wave as before
```

While in `CARD_DRAFT` state, `start_next_wave()` must be blocked.

### CardManager.gd — Full Responsibilities

Register in `project.godot` as:
```
CardManager="*res://scripts/autoloads/CardManager.gd"
```

**Signals to emit:**
```gdscript
signal card_draft_started(cards: Array)   # emits array of 3 card dicts
signal card_picked(card: Dictionary)      # emits the chosen card dict
```

**Internal state:**
```gdscript
var specialisation: Dictionary = { "basic": 0, "sniper": 0, "splash": 0, "slow": 0, "wall": 0 }
var active_effects: Dictionary = {}       # effect_id → accumulated value/count
var rare_weight_bonus: float = 0.0        # incremented by Survivor's Instinct
var _card_pool: Dictionary = {}           # rarity → Array of card dicts
var _curse_next_wave_double_draw: bool = false
```

**On `_ready()`:** load all four JSON files from `res://data/cards/` and populate `_card_pool`.

**`draw_cards(count: int) -> Array`:** weighted random draw. Base weights: Common 0.60, Uncommon 0.28, Rare 0.10, Legendary 0.02 — modified by `rare_weight_bonus`. Within each rarity tier, cards with affinity matching the player's top specialisation scores are weighted higher. Rare and Legendary cards for a tower type only enter the pool once that type's specialisation score meets the threshold (Rare ≥ 3, Legendary ≥ 6). Return `count` unique card dicts.

**`pick_card(card_id: String) -> void`:** look up the card, increment `specialisation[tower_affinity]` if affinity is not null, call `CardEffectRegistry.apply(effect, params)`, emit `card_picked`.

**`get_tower_multipliers(tower_type: String) -> Dictionary`:** returns a dict of all current accumulated multipliers for that tower type, e.g. `{ "damage": 1.45, "range": 1.15, "attack_speed": 1.20 }`. Tower scripts call this to calculate their final stats.

### card_effect_registry.gd

Not an autoload — a plain script instantiated and held by `CardManager`. Contains one public method:

```gdscript
func apply(effect: String, params: Dictionary, card_manager: Node) -> void:
    match effect:
        "tower_attack_speed":   # multiply attack_speed for params.tower_type
        "tower_damage":         # multiply damage for params.tower_type
        "tower_range":          # multiply range_px for params.tower_type
        "tower_aoe_radius":     # multiply projectile_aoe_radius for params.tower_type
        "tower_slow_intensity": # multiply slow factor for params.tower_type
        "tower_cost_reduction": # reduce TOWER_COSTS in game_map.gd
        "wave_bonus_flat":      # add flat amount to EconomyManager wave bonus
        "kill_gold_flat":       # add flat amount to all kill gold awards
        "rare_weight_boost":    # increment card_manager.rare_weight_bonus by 0.08
        "synergy_slow_sniper_bonus":  # set a flag read by projectile.gd
        "synergy_slow_all_bonus":     # set a flag read by projectile.gd
        "synergy_frost_fire":         # set a flag read by enemy scripts
        "synergy_killbox":            # set a flag read by projectile.gd
        "rifle_kill_chain":           # tracked in CardManager active_effects
        "rifle_overcharge":           # tracked in CardManager active_effects
        "rifle_ricochet":             # set flag read by projectile.gd
        "rifle_double_tap":           # set flag read by tower_basic.gd
        "sniper_execute":             # set flag read by projectile.gd
        "sniper_suppress":            # set flag read by projectile.gd
        "sniper_chain_suppress":      # set flag read by projectile.gd
        "sniper_one_shot":            # set flag read by projectile.gd
        "splash_fire_dot":            # set flag read by projectile.gd
        "splash_knockback":           # set flag read by projectile.gd
        "splash_napalm":              # set flag, requires splash_fire_dot active
        "splash_shockwave":           # set flag, requires splash_knockback active
        "slow_aura":                  # set flag read by tower_slow.gd
        "slow_dot":                   # set flag read by projectile.gd
        "slow_plague_pulse":          # set flag read by tower_slow.gd
        "slow_full_stop":             # set flag, requires slow_aura active
        "spawn_slow_tile":            # call TerrainManager to place slow tile
        "remove_obstacles":           # call TerrainManager to remove N obstacles
        "spawn_obstacles":            # call TerrainManager to place N obstacles
        "curse_next_wave_horde":      # set flag in WaveManager
        "curse_temp_damage_penalty":  # set timed debuff in CardManager
        "curse_brute_gold_boost":     # set timed boost in EconomyManager
        "curse_remove_affinity":      # remove affinity from card pool, boost top affinity
```

### JSON Card Schema

Each card in a data file follows this exact schema:

```json
{
  "id": "rifle_atkspd_1",
  "name": "Hair Trigger",
  "description": "Rifle Posts fire 20% faster.",
  "flavor_text": "No time to aim. Just shoot.",
  "rarity": "common",
  "tower_affinity": "basic",
  "effect": "tower_attack_speed",
  "effect_params": {
    "tower_type": "basic",
    "multiplier": 0.20
  }
}
```

Fields with no tower affinity use `"tower_affinity": null`. Fields with no effect params use `"effect_params": {}`.

### CardDraftScreen Scene

A `CanvasLayer` scene (same pattern as `GameOverOverlay` in `hud.tscn`). When opened:

- Darkens the background with a semi-transparent `ColorRect`
- Displays a title label: "Choose your upgrade"
- Instantiates 3 × `card_panel.tscn`, one per drawn card, laid out horizontally
- Waits for the player to click a panel
- On click: calls `CardManager.pick_card(card_id)`, plays a selection animation, then closes

The screen is opened by connecting to `CardManager.card_draft_started`. It closes by emitting its own `draft_complete` signal, which `GameManager` listens to in order to transition from `CARD_DRAFT` to `WAVE_COMPLETE`.

### card_panel.tscn

A reusable single-card UI component. Contains:

- Background `ColorRect` (colour varies by rarity: grey/green/blue/gold)
- Card name `Label`
- Rarity `Label`
- Description `Label`
- Flavour text `Label` (italic, smaller)
- Hover highlight effect

Exposes a `setup(card_data: Dictionary)` method called by `CardDraftScreen`.

### How Tower Scripts Read Card Modifiers

In `tower_base.gd`, after `super._ready()` initialises stats, call:

```gdscript
func _apply_card_modifiers() -> void:
    var mods: Dictionary = CardManager.get_tower_multipliers(_tower_type)
    damage = int(damage * mods.get("damage", 1.0))
    range_px = range_px * mods.get("range", 1.0)
    attack_speed = attack_speed * mods.get("attack_speed", 1.0)
```

Also connect to `CardManager.card_picked` and re-call `_apply_card_modifiers()` so towers placed before a card was picked also benefit — but be careful not to double-stack. Use a base stats dictionary stored at `_ready()` time and always multiply from base, never from current.

---

## Part 4 — Synergy Card Rules

Synergy cards add complexity. Rex should implement these rules:

- Synergy cards only appear in the draw pool if the player has at least 1 of each relevant tower type currently placed on the map at the time of the draw.
- `CardManager` should check `get_tree().get_nodes_in_group("towers")` (towers should be added to a group on placement) to validate this before including synergy cards in the weighted draw.
- Synergy effects are implemented as flags in `CardManager.active_effects`. Projectiles and enemy scripts check these flags via `CardManager.has_effect("synergy_frost_fire")` etc.

---

## Part 5 — Build Order

Rex must follow this order. Do not skip ahead. Each step should be tested before proceeding.

**Step 1 — Data layer**
Create `data/cards/common.json`, `uncommon.json`, `rare.json`, `legendary.json` using the catalogue in Part 2. Implement card loading in `CardManager._ready()`. Verify all cards load without errors by printing the pool size to console.

**Step 2 — Specialisation tracking**
Implement `specialisation` dict and `pick_card()` increment logic in `CardManager`. No UI yet. Test by calling `pick_card()` manually from console and printing specialisation scores.

**Step 3 — Weighted draw logic**
Implement `draw_cards()` with rarity weights and specialisation-weighted card selection within tiers. Test by calling `draw_cards(3)` repeatedly and verifying distribution looks correct.

**Step 4 — GameState integration**
Add `CARD_DRAFT` to `GameManager.GameState`. Update `end_wave()` to transition through `CARD_DRAFT`. Block `start_next_wave()` during this state. Verify wave flow still works end-to-end with a placeholder draft (auto-pick first card, no UI).

**Step 5 — Card effect registry (simple effects only)**
Implement `card_effect_registry.gd` for common and uncommon tower stat effects only (`tower_attack_speed`, `tower_damage`, `tower_range`). Update `tower_base.gd` to read from `CardManager.get_tower_multipliers()`. Verify a stat card visibly affects tower behaviour in-game.

**Step 6 — CardDraftScreen and card_panel**
Build the UI. Wire it to `CardManager.card_draft_started`. Verify the full flow: wave ends → screen appears → player picks → stats apply → wave can be started again.

**Step 7 — Economy and map effects**
Implement economy effect IDs. Update `EconomyManager` to listen for relevant cards. Implement map effect IDs. Update `TerrainManager` to support `remove_obstacles()` and `spawn_slow_tile()`.

**Step 8 — Curse cards**
Implement curse effect IDs. Test `curse_next_wave_horde` (WaveManager hook) and `curse_brittle` (timed debuff) first.

**Step 9 — Synergy cards**
Implement synergy pool filtering (tower group check). Implement synergy effect flags. Update projectile and enemy scripts to check flags.

**Step 10 — Rare and legendary effects**
Implement remaining effect IDs from the registry. Test each one individually before moving to the next.

---

## Part 6 — Balancing Notes (Post-Implementation)

These values are starting points and will need tuning through playtesting:

- Rare weight threshold (specialisation ≥ 3) and Legendary threshold (≥ 6) may need adjustment depending on how fast specialisation accumulates
- `rare_weight_bonus` per stack of Survivor's Instinct (currently 8%) — watch for Legendary cards becoming trivially common with multiple stacks
- Curse rewards (150g for Brittle Towers, double draw for Horde Surge) should feel genuinely tempting but not obviously correct
- Kill Chain trigger count (10 kills) needs live testing — may be too slow or too fast depending on wave composition

Sage should track balance findings in a separate `docs/balance_log.md` as playtesting progresses.

---

_Design: Sage. Implementation: Rex. QA signs off after Step 6 and again after Step 10._
