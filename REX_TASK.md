# Rex Phase 2 Task

You are Rex, the Godot 4 developer for OC Tower Defense. Read docs/GDD.md first to understand the full spec.

Your task is Phase 2: fix all critical bugs from QA and implement the tower system. Work on the `dev` branch.

First: `git checkout -b dev` (or `git checkout dev` if it exists).

## Bugs to fix

**BUG-01 — Wave-end gold bonus never awarded**
In `GameManager.gd`, `end_wave()` never calls `EconomyManager.award_wave_bonus()`.
Fix: add `EconomyManager.award_wave_bonus(current_wave)` in `end_wave()` before the state transition.

**BUG-02 — Enemies don't recalculate path after tower placement**
`enemy_basic.gd` only calls `_recalculate_path()` when path is empty. Enemies ignore mid-wave tower placement.
Fix: emit a `obstacle_changed` signal from `PathfindingManager.place_obstacle()`, and have all enemy types connect to it and call `_recalculate_path()`.

**BUG-03 — EnemyFast and EnemyTank missing**
WaveManager references `res://scenes/enemies/EnemyFast.tscn` and `res://scenes/enemies/EnemyTank.tscn` — both absent.
Create `enemy_fast.gd` and `enemy_tank.gd` (extend from enemy_basic or a shared base). Stats from GDD:
- Fast: 15 HP, high speed (1.8x basic), 8g drop
- Tank: 120 HP, low speed (0.5x basic), 20g drop
Create corresponding `.tscn` scenes.

**BUG-04 — No-blocking validation never called**
`PathfindingManager.has_valid_path()` exists but is never called on tower placement.
Fix: call it in the placement handler before confirming placement — reject with visual feedback if fully blocked.

**BUG-05 — TOTAL_WAVES duplicated**
Remove `const TOTAL_WAVES` from `WaveManager.gd`, replace with `GameManager.TOTAL_WAVES`.

## Tower system (new feature)

Implement all 4 tower types from GDD section 5:

| Tower   | Damage | Range   | Attack Speed | Cost | Special                        |
|---------|--------|---------|-------------|------|--------------------------------|
| Basic   | 10     | 96px    | 1.0/s       | 50g  | Single target                  |
| Sniper  | 40     | 192px   | 0.4/s       | 100g | Single target                  |
| Splash  | 15 AoE | 64px    | 1.0/s       | 120g | AoE radius 48px                |
| Slow    | 5      | 96px    | 2.0/s       | 80g  | 50% speed debuff for 2s        |

Create:
- `scripts/towers/tower_base.gd` — shared logic: range query, attack timer, targeting nearest enemy
- `scripts/towers/tower_basic.gd`, `tower_sniper.gd`, `tower_splash.gd`, `tower_slow.gd` — extend base
- Corresponding `.tscn` scenes in `scenes/towers/`
- Tower placement: `game_map.gd` handles mouse click input, calls `PathfindingManager.place_obstacle()`, spawns tower on tile
- Towers act as AStar2D obstacles (PathfindingManager already supports this)
- Towers are permanent — no selling or moving
- Call `has_valid_path()` before confirming placement (wires up BUG-04 fix)

## Basic HUD

Add a minimal HUD to `scenes/ui/hud.tscn`:
- Gold label (top left): shows current gold from EconomyManager
- Base HP label (top right): shows base_hp / 20
- Wave label (top centre): shows "Wave X / 10"
- Enemy count label: shows enemies remaining
- Tower selector panel (bottom): one button per tower type (name + cost). Clicking selects that tower for placement.

Wire all labels to autoload signals so they update live.

## Win / Lose screens

- Connect `GameManager.game_over` signal to a Game Over overlay (label + restart button)
- Connect `GameManager.victory` signal to a Victory overlay
- Restart button calls `get_tree().reload_current_scene()`

## When done

1. Commit everything to `dev` branch: `git commit -m "feat: Phase 2 - tower system, enemy types, bug fixes"`
2. Push: `git push origin dev`
3. Run: `openclaw system event --text "Rex done: Phase 2 complete - tower system, bug fixes, HUD pushed to dev" --mode now`
