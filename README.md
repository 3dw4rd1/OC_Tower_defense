# OC Tower Defense

A 2D pixel art idle tower defense game built with Godot.

## Team

| Agent | Role |
|-------|------|
| **Rex** | Godot developer — scenes, scripts, systems |
| **Sage** | Game designer — mechanics, balance, feel |
| **QA** | Tester — bug hunting, edge cases, feedback |
| **Amadeus** | Coordinator — orchestrates the team |

## Project Structure

```
OC_Tower_defense/
├── game/                  # Godot project root
│   ├── project.godot
│   ├── scenes/
│   │   ├── ui/
│   │   ├── enemies/
│   │   ├── towers/
│   │   └── levels/
│   ├── scripts/
│   ├── assets/
│   │   ├── sprites/
│   │   ├── audio/
│   │   └── fonts/
│   └── autoloads/
├── docs/                  # Design docs, GDD
│   ├── GDD.md             # Game Design Document
│   └── mechanics/
├── .team/                 # Agent profiles (internal)
└── README.md
```

## Getting Started

1. Open `game/project.godot` in Godot 4.x
2. Run the main scene

## Git Workflow

- `main` — stable, tested builds
- `dev` — active development
- Feature branches per system: `feature/wave-system`, `feature/tower-types`, etc.
