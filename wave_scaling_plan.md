# Wave Scaling Plan

## Current State Summary

| Range | System | Details |
|-------|--------|---------|
| Waves 1–10 | Unified spawn system | Linear HP/speed ramps, 8→150 enemies |
| Waves 11–25 | Legacy fixed compositions | Compound scaling (5% speed, 10% HP per wave) |
| Scaling cap | Wave 25 tops out at | ~4.2× HP and ~2.1× speed from baseline |

---

## Proposed Improvements

### 1. Extend Beyond 25 Waves (Endless Mode)

After wave 25, continue with procedurally generated waves using an aggressive scaling formula.

```gdscript
# Post-wave-25 formula example
var endless_step = current_wave - 25
var hp_mult = pow(1.18, endless_step)     # 18% per wave (up from 10%)
var speed_mult = pow(1.07, endless_step)  # 7% per wave (up from 5%)
var count_mult = pow(1.12, endless_step)  # 12% per wave (new!)
```

---

### 2. Boss Waves (Every 5th Wave)

Waves 5, 10, 15, 20, 25 get a "boss" enemy — a single high-HP, high-reward unit spawned at the start.

- **Boss HP** = 8× wave HP value
- **Boss speed** = 0.7× wave speed
- **Boss gold** = 50–150g scaling by tier
- Boss has a pulsing visual (shader outline) to distinguish it

---

### 3. Elite Enemies (Wave 10+)

A new enemy tier that spawns randomly mixed into waves — faster than tanks, tankier than scouts.

```gdscript
# Elite stats
speed = 96.0       # 1.2× basic
_hp = 80           # between tank and basic
_enemy_type = "elite"
# Gold: 15g base
```

Introduced at wave 10 at ~10% of spawns, scaling to ~25% by wave 20.

---

### 4. Aggressive Count Scaling in Legacy Waves (11–25)

Current legacy wave counts are fixed (e.g., wave 11: 23 enemies). Apply a count multiplier too.

```gdscript
# Add count scaling to legacy waves
var count_mult = pow(1.08, multiplier_steps)  # 8% more enemies per wave
```

> Wave 25 currently has 75 enemies → with this formula: ~237 enemies.

---

### 5. Faster Spawn Intervals in Late Waves

Spawn interval is currently fixed once wave 10 is reached (0.45s). For waves 11–25, compress further.

```gdscript
# Legacy waves: further compress spawn interval
var interval_mult = pow(0.95, multiplier_steps)  # 5% faster each wave
var spawn_interval = 0.45 * interval_mult         # floors around 0.22s by wave 25
```

---

### 6. Armored Enemy Type (Wave 13+)

New enemy with damage reduction rather than just high HP — forces players to diversify tower types.

```gdscript
# Armored enemy
_hp = 60
speed = 60.0
armor = 0.35  # blocks 35% of incoming damage (requires enemy_basic to support armor stat)
_enemy_type = "armored"
```

---

### 7. Regenerating Enemies (Wave 17+)

Some enemies regenerate HP at a fixed rate, punishing slow/low-DPS builds.

```gdscript
const REGEN_RATE = 5.0  # HP per second
func _process(delta):
    if _hp < _max_hp:
        _hp = min(_hp + REGEN_RATE * delta, _max_hp)
```

---

### 8. Split Wave Mechanic (Wave 15+)

Some enemies split into 2 smaller enemies on death (like slimes), forcing players to account for secondary threats.

```gdscript
func die():
    if can_split:
        spawn_child_enemy(position, _hp * 0.4)
        spawn_child_enemy(position, _hp * 0.4)
    super.die()
```

---

### 9. Dynamic Difficulty Adjustment (DDA)

Track player performance (leaked HP vs. total base HP) and subtly adjust wave intensity.

```gdscript
# After each wave, compute a pressure score
var leak_ratio = leaked_this_wave / total_hp_that_reached_base
# If leak_ratio < 0.1 (player is dominating) → add +15% enemies next wave
# If leak_ratio > 0.5 (player is struggling) → reduce HP by 10% next wave
```

---

### 10. New Curse Cards for Late-Game Waves

Expand the curse card pool with more aggressive modifiers.

| Card | Effect |
|------|--------|
| Armored Advance | All enemies this wave have 30% damage reduction |
| Speed Frenzy | +50% enemy speed for 1 wave, +100% gold bonus |
| Double Trouble | All enemies that die spawn a weaker copy |
| Endless Hunger | Wave never ends — enemies respawn until 3 minutes pass |

---

## Implementation Priority

| Priority | Feature | Effort | Impact |
|----------|---------|--------|--------|
| 1 | Count scaling in legacy waves | Low | High |
| 2 | Faster spawn intervals (11–25) | Low | High |
| 3 | Boss waves every 5th wave | Medium | Very High |
| 4 | Elite enemy type | Medium | High |
| 5 | Endless mode post-wave-25 | Medium | Very High |
| 6 | Armored enemy type | Medium | High |
| 7 | New curse cards | Low | Medium |
| 8 | Regenerating enemies | Medium | Medium |
| 9 | Split mechanic | High | High |
| 10 | Dynamic difficulty (DDA) | High | Medium |
