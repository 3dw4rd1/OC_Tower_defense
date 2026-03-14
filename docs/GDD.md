# Game Design Document — OC Tower Defense

_Status: Draft | Owner: Sage_

## Concept

**Genre:** 2D pixel art idle tower defense  
**Engine:** Godot 4.x  
**Platform:** PC (Windows/Linux/Mac)

## Core Loop

1. Enemies spawn in waves and follow a path to the base
2. Player places towers that automatically attack enemies
3. Killing enemies earns currency
4. Currency is spent on new towers or upgrades
5. Survive all waves to win the level

## Idle Element

- Towers act autonomously — no micromanagement required
- Player focuses on strategic placement and upgrades
- Offline/idle progression TBD

## Tower Types (initial)

| Tower | Attack | Role |
|-------|--------|------|
| Basic | Single target, medium range | Starter |
| Sniper | Single target, long range, slow | High-damage |
| Splash | Area of effect, short range | Crowd control |
| Slow | Reduces enemy speed | Support |

## Enemy Types (initial)

| Enemy | HP | Speed | Notes |
|-------|-----|-------|-------|
| Basic | Low | Medium | Starter |
| Fast | Low | High | Rushers |
| Tank | High | Low | Absorbs damage |
| Flying | Medium | Medium | Bypasses ground-only towers |

## Economy

- Killing enemies → gold
- Towers have build cost + upgrade costs
- No tower selling to start (keep it simple)

## Level Design

- Grid-based or fixed path (TBD)
- Multiple maps with varying path complexity
- First map: simple S-curve path, 10 waves

## Art Direction

- 2D pixel art
- Clean, readable sprites
- ~16x16 or 32x32 base tile size

---

_This doc is a living document. Sage updates it; Rex implements from it._
