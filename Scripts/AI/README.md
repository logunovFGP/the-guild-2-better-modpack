# Lua libraries/scripts commonly reused to build better game AI (modding-friendly)

This list focuses on **general-purpose** Lua components that help you move from “a bunch of scripts” to a structured AI with a **central state** (even if the underlying game engine state can’t be fully synchronized).

## 1) Decision-making frameworks (replace ad-hoc scripts)

### Behavior Trees (BT)
- BehaviourTree.lua (pure Lua BT; also on LuaRocks as `behaviour_tree`)
  - Repo: https://github.com/tanema/behaviourtree.lua
  - LuaRocks: https://luarocks.org/modules/timanema/behaviour_tree

### Alternative BT variant (different node set / “2e” edition)
- BehaviourTree.lua 2e
  - Repo: https://github.com/MaxYari/behaviourtreelua2e

## 2) Centralized state representation (your “single source of truth”)

### ECS (Entity Component System) — best fit for “centralized state” in mods
- tiny-ecs (simple ECS; good for projecting messy game state into your own authoritative snapshot)
  - Repo: https://github.com/bakpakin/tiny-ecs
  - Docs: https://bakpakin.github.io/tiny-ecs/doc/

## 3) Movement intelligence (often required for AI that feels “smart”)

### Pathfinding (grid-based)
- Jumper (A*, JPS, etc.)
  - Repo: https://github.com/Yonaba/Jumper
  - Examples: https://github.com/Yonaba/Jumper-Examples

## 4) Serialization (for snapshots, debugging, replay, and syncing *AI state*)

### Human-readable snapshots + robust table serialization
- serpent
  - Repo: https://github.com/pkulchenko/serpent
  - LuaRocks: https://luarocks.org/modules/paulclinger/serpent

## 5) Curated indexes to discover more “known good” Lua libs
- Awesome Lua
  - Repo: https://github.com/forhappy/awesome-lua
- Awesome LÖVE2D (many engine-agnostic Lua modules live here too)
  - Repo: https://github.com/love2d-community/awesome-love2d

## Minimal “stack” that addresses your problem directly

If your main issue is **no centralized state synchronization**, the shortest practical path is:
- ECS snapshot as your authoritative AI state: **tiny-ecs** → https://github.com/bakpakin/tiny-ecs
- Decision logic driven off that snapshot: **BehaviourTree.lua** → https://github.com/tanema/behaviourtree.lua
- Deterministic movement planning: **Jumper** → https://github.com/Yonaba/Jumper
- Snapshotting/record/replay/debugging: **serpent** → https://github.com/pkulchenko/serpent

## Current implementation status in this repository

- Multiplayer/session sync is handled by game engine modules in `Scripts/GameState` (`WorldSessionCtrl`, `SessionSelector`, `SessionCtrl`) rather than custom Lua transport code.
- AI and mission synchronization is persisted in engine properties (`SetProperty`/`GetProperty`) and script context (`SetData`/`GetData`) in `Scripts/Library/aitwp.lua`, `Scripts/Library/AI.lua`, and `Scripts/Campaign/DefaultCampaign.lua`.
- No runtime usage of the listed AI stack libraries was found in Lua execution paths:
  - `BehaviourTree.lua`
  - `tiny-ecs`
  - `Jumper`
  - `serpent`
- For full notes and evidence, see `AI_RESEARCH.md` at the repository root and the updated `AGENTS.md`/`llm.txt` files.
