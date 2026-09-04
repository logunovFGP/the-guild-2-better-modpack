# Progress Log: AI Synchronization Research

## 2026-02-13

### Status
- Initialized Phase 1 and Phase 2 research execution; no implementation performed.

### Completed this session
- Read authoritative network/session files and captured evidence:
  - `Scripts/GameState/GameStartUp.lua`
  - `Scripts/GameState/JoinSession.lua`
  - `Scripts/GameState/Game.lua`
  - `Scripts/GameState/SelectSession.lua`
  - `Scripts/GameState/WaitforSync.lua`
  - `Scripts/Campaign/_Network/_Network.lua`
- Read core AI state files for persistence/timing evidence:
  - `Scripts/Library/AI.lua`
  - `Scripts/Library/aitwp.lua`
  - `Scripts/Campaign/DefaultCampaign.lua`
  - `Scripts/AI/BaseTree/Priorities.lua`
  - `Scripts/AI/BaseTree/IncomeForAI.lua`
  - `Scripts/Measures/ms_DynastyIdle.lua`
- Captured new evidence in `findings.md` under "Phase 1 evidence block (session/sync boundary discovery)".
- Added second-phase-1 block in `findings.md` on AI entry chain and scheduler cues (`std_Idle`, `ms_DynastyIdle`, BaseTree readme/d_leaf handoffs).
- Kept research scope: no code behavior changes were made; documentation/research-only updates only.

### Current position in plan
- Phase 1 and Phase 2 have been executed and documented with transport/state/timing evidence.
- Next action: Phase 3 (behavior-tree and architecture assessment), including decorator-tree design and deterministic command interface research.

### Next actions
- Capture authoritative call-chain evidence for all tree entry and scheduler attachment points in gameplay flow.
- Expand Phase 2 synthesis into concrete recommendations for host/client replay alignment once more runtime evidence is gathered.
- Keep `task_plan.md` and `findings.md` synchronized as Phase 3 progresses.
- Continue the "only documentation and planning/research" constraint until Phase 6 unless user explicitly requests implementation.

## 2026-02-13 (continued)

### Completed this session
- Documented Phase 2 evidence in `findings.md`:
  - Transport/custom hook check: no custom packet/websocket/socket transport surfaced in reviewed AI/gameplay/session Lua entry points.
  - Timing model and determinism risks: timer gates (`ReadyToRepeat`/`SetRepeatTimer`), hour math (`GetGametime`), deferred calls (`CreateScriptcall`), and property/state-driven random branches.
  - Reconnect/bootstrap/shutdown evidence for session lifecycle (`GameStartUp.lua`, `JoinSession.lua`, `Game.lua`, `WaitforSync.lua`, `SelectSession.lua`).
- Updated `task_plan.md` phase 2 items with implementation status and touched-file notes.
- Updated plan status language to reflect that this phase is implemented and awaiting user confirmation, not yet code changes.

### Decision log this session
- Chosen order: complete transport/transportability evidence before behavior-tree migration recommendations to avoid design overfitting.
- Applied only documentation edits (planning/research artifacts), honoring request constraints.
## 2026-02-13 (phase3)

### Completed this session
- Executed Phase 3 research pass for behavior-tree architecture and execution model.
- Added Phase 3 evidence in `findings.md`:
  - Round-robin and top-level tree module structure from `Scripts/AI/BaseTree/readme.mkd`.
  - BaseTree-to-measure boundary (`d_GoIdle`, `workshop_DoNothing`, `std_Idle`, `ms_DynastyIdle`) evidence for current decision-to-effect execution handoff.
  - Timer cadence and async execution evidence (`ReadyToRepeat`, `SetRepeatTimer`, `CreateScriptcall`) with determinism impact.
  - Deterministic decorator placement and command-interface candidate boundaries.
- Updated `task_plan.md` phase 3 item status blocks to reflect implementation status and touched-file tracking.
- Preserved documentation-only constraints (no code changes).

### Current position in plan
- Phase 1 and Phase 2 remain documented from prior runs.
- Phase 3 is now documented and ready for review/confirmation.
- Next action: Phase 4 research synthesis (library/runtime usage matrix and migration feasibility).

### Next actions
- Verify plan items against any engine-side invoker for BaseTree round-robin if available outside reviewed Lua modules.
- Expand Phase 3 hypothesis section with any newly discovered runtime-caller evidence before final architecture synthesis.
- Keep `task_plan.md`, `findings.md`, `progress.md`, and `AI_RESEARCH.md` synchronized as phases continue.

## 2026-02-14 (phase7 kickoff)

### Current position
- Added Phase 7 (reverse-engineering and binary-observability) to `task_plan.md`.
- Captured tooling evidence in `findings.md` that reverse-engineering CLI tooling is unavailable in this environment except `dotnet`, and MCP resource channels are empty.
- Added a dedicated reverse-engineering lane to `AI_RESEARCH.md` with non-invasive workflow, tool matrix, and injection risk guidance.

### Completed this session
- `task_plan.md`
  - Added Phase 7 research tasks and a "no binary mutation without approval" decision gate.
  - Added risk-aware completion staging and decision-log note.
- `findings.md`
  - Added Phase 7 evidence block (tooling audit + MCP availability + reverse-engineering order-of-operations recommendation).
- `AI_RESEARCH.md`
  - Added "Phase 7 — Reverse-engineering and binary-observability plan (research only)" with:
    - environment/MCP evidence,
    - toolchain matrix,
    - safe sequencing,
    - and MCP-assisted artifact handling recommendation.

### Next actions
- Continue by documenting explicit source files to inspect if RE-level observability becomes required:
  - game bootstrap module list,
  - native event/log hooks,
  - binary callback symbol candidates.
- Keep research non-invasive until user approves any binary-level tracing injection path.

## 2026-02-14 (phase7 continuous)

### Completed this session
- Added Phase 7 status updates in `task_plan.md` for each completed RE-lane task with "implemented, awaiting user confirmation".
- Added a new `AI_RESEARCH.md` section covering late-2025/early-2026 LLM decomp frontier and practical workflow posture for reverse-assisted decompilation.
- Added `findings.md` addendum on LLM tool classification (true decomp model vs assistant orchestration vs unstripping).

### Current position in plan
- Phase 7 tooling-and-observability evidence lane is now substantially updated with concrete classification of current AI-assisted decomp options.
- Next action is still to execute the next evidence-gathering pass if requested: identify exact host module boundaries and native callback candidates.

### Next actions
- If you want, next step is to pin concrete binaries and symbol targets for native inspection and produce a "module-by-module observability map" tied to `Scripts/AI/BaseTree` handoff points.
