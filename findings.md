# Findings: AI Synchronization Research

## Scope and objective
This file tracks evidence-first discoveries for deterministic multiplayer AI synchronization planning. It is intentionally deeper than a high-level description and is split by transport, state lifecycle, and behavior architecture.

## Immediate findings (high confidence)
- `Scripts/GameState/GameStartUp.lua` wires session flow for standalone/host path via `SessionType = "LOCALHOST"` and starts local world session control.
- `Scripts/GameState/JoinSession.lua` sets `SessionType = "CLIENT"` and uses `cl_ClientController` with polling until world ready.
- `Scripts/Campaign/_Network/_Network.lua` does not implement custom protocol hooks; it mainly maps mission/world metadata.
- AI and campaign scripts heavily read/write `GetProperty/SetProperty` and store authoritative decision state in properties.
- Runtime usage of the listed external libraries (`behaviourtree.lua`, `Jumper`, `serpent`, `tiny-ecs`) is not observed in active AI execution paths today.

## Phase 1 evidence block (session/sync boundary discovery)
- Network/session bootstrap:
  - Host path: `Scripts/GameState/GameStartUp.lua:4` attaches `WorldSessionCtrl`; `Scripts/GameState/GameStartUp.lua:8-13` set `SessionType = "LOCALHOST"` before `ChangeGameState("StartScreen")`.
  - Client path: `Scripts/GameState/JoinSession.lua:4` sets `SessionType = "CLIENT"`; `:8-10` attaches/enables `SessionCtrl` (`cl_ClientController`); `:16-35` waits on `\Application\Game\Controller.WorldReady`.
  - `Scripts/GameState/Game.lua:8-10` enables `WorldSessionCtrl` during gameplay entry and `:94-95` disables/detaches it in cleanup.
  - Session browsing is explicit in `Scripts/GameState/SelectSession.lua:3-4` and detached in cleanup `:8-10`.
- Campaign/network file:
  - `Scripts/Campaign/_Network/_Network.lua:1-7` exposes `GetWorld()` and dynasty creation helpers; no custom packet/custom transport logic is present.
- AI persistence + execution boundaries:
  - `Scripts/Library/AI.lua:66-90` writes `AI_PERSONA` using `SetProperty`.
  - `Scripts/Library/AI.lua:96-103` reads `AI_PERSONA` as decision state.
  - `Scripts/Library/aitwp.lua:21-44` recalculates AI weights and persists `AITWP_Political`, `AITWP_Agressive`, `AITWP_Intrigue`.
  - `Scripts/Library/aitwp.lua:170-215` initializes and stores `AITWP_Enemies`.
  - `Scripts/AI/BaseTree/Priorities.lua:2-10` gates dynasty priorities on `ReadyToRepeat`, then writes `AI_Priorities` via timered execution.
  - `Scripts/AI/BaseTree/IncomeForAI.lua:18-20` schedules deferred work with `CreateScriptcall("GiveAIMoney",...)`, showing asynchronous command scheduling exists.
- Randomness/timing risk footprint:
  - `Scripts/Library/aitwp.lua:53`, `170-173`, `198-201` use `Rand` during AI preference and enemy selection.
  - `Scripts/Library/AI.lua:72-88`, `109-115` use `Rand` during personality/decision weighting.
  - `Scripts/Measures/ms_DynastyIdle.lua:71`, `59-64`, `87-90` use `Rand` for non-tree AI behavior.
  - Many AI actions are gated by repeat timers (`ReadyToRepeat`/`SetRepeatTimer`) across `Scripts/AI/**`, e.g., `Scripts/AI/BaseTree/Priorities.lua:9`, `IncomeForAI.lua:10`, `IncomeForAI.lua:18`.

## Phase 1 deepening: AI decision entry chain and scheduler cues
- `Scripts/AI/BaseTree/readme.mkd:27` states dynasty BaseTree logic is triggered by round-robin across all dynasties.
- `Scripts/AI/BaseTree/readme.mkd:129` documents the building-specific branch trigger: when SIM enters building / finishes production inside a building.
- `Scripts/AI/BaseTree/Dynasty/d_GoIdle.lua:13` and `Scripts/AI/BaseTree/ToMEconomy/Workshop/workshop_DoNothing.lua:7` both route directly to `MeasureRun(..., "DynastyIdle")`, confirming fallback bridges from tree leafs to measure-level scripts.
- `Scripts/Measures/Behaviour/std_Idle.lua:4-5` routes dynasty Sims to `MeasureRun("", nil, "DynastyIdle")`.
- `Scripts/Measures/ms_DynastyIdle.lua` carries non-tree dynasty behavior and includes timing-dependent sleeps, sleep-budget properties (`_DO_NOTHING_TIME`), and `math.mod(GetGametime(),24)` for local day-phase behavior.
- `Scripts/Library/AI.lua` and `Scripts/Library/aitwp.lua` both persist most AI state in properties (`AI_PERSONA`, `AITWP_*`) rather than in a separate authoritative snapshot structure, which matters for deterministic reconciliation model design.

## Phase 1 gaps to close (before full design)
- Need exact runtime attachment point for round-robin tick execution (the readme documents behavior intent; exact runtime caller remains outside reviewed Lua layer).
- Need explicit authoritative time/clock source used by deterministic scheduling across host/client (tick/round/gametime aliasing).

## Phase 2 evidence block (network transport model + synchronization boundaries)
- Transport layer scan in reviewed gameplay/AI/session files:
  - `Scripts/GameState/GameStartUp.lua:4-8` sets `SessionType = "LOCALHOST"` and uses native session controller wiring (`WorldSessionCtrl`).
  - `Scripts/GameState/JoinSession.lua:4-36` sets `SessionType = "CLIENT"` and then waits for `\Application\Game\Controller.WorldReady` before state transition.
  - `Scripts/GameState/Game.lua:8-10` enables/displays `WorldSessionCtrl` at gameplay entry; `:94-95` detaches/cleans it up in `CleanUp`.
  - `Scripts/GameState/WaitforSync.lua:14-18` contains no custom network messaging or transport hooks; cleanup only detaches HUD/WIN-related modules.
  - `Scripts/GameState/SelectSession.lua` and `Scripts/Campaign/_Network/_Network.lua` expose session/world data and browser helpers, not packet-level or socket-level logic.
  - `Scripts/GameState/DedicatedServer.lua:1-7` attaches `SimulationController` for server mode; no explicit packet API usage.
  - Conclusion: session/authority control is engine-controller-based in the reviewed layer; no custom Lua transport/messaging subsystem was found in these files.

- Replayability/reconnect and host/client lifecycle:
  - Host/client mode is selected early through `SessionType` + state controller attachments in `GameStartUp.lua` and `JoinSession.lua`.
  - Gameplay transition paths call `AttachGameStateModules` and `AttachSession` in GameState scripts (`GameStartUp`, `SelectSession`, `Game`) then detach in corresponding `CleanUp`, implying lifecycle-managed state and recomputation of runtime AI scheduling state.
  - `Scripts/GameState/WaitforSync.lua:4-18` only unhooks modules (`HUD`, `Input` controllers), indicating synchronization waits are expected to be owned by engine/session flow.

- Determinism and timing model evidence:
  - AI execution is primarily timer/event driven, not frame-driven command-first:
    - `Scripts/AI/BaseTree/Priorities.lua:2-9` (`ReadyToRepeat("dynasty","AI_Priorities")`) and `Scripts/AI/BaseTree/IncomeForAI.lua:6-11` (`SetRepeatTimer`) gate periodic decisions.
    - `Scripts/AI/BaseTree/IncomeForAI.lua:18-20` uses `CreateScriptcall("GiveAIMoney", ...)`, adding deferred execution.
    - `Scripts/Measures/ms_DynastyIdle.lua:53-55` uses `math.mod(GetGametime(),24)` and day-hour branches.
    - `Scripts/City/CityPingHour.lua:6-18` uses hourly pacing from `GetGametime()`, demonstrating periodic systems that can drift if authority/time sources diverge.
  - AI state and policies are property-driven, not derived from one deterministic command stream:
    - `Scripts/Library/AI.lua` and `Scripts/Library/aitwp.lua` persist `AI_*` keys via `SetProperty`.
    - Multiple files use `Rand()` for decisioning (`Scripts/Library/AI.lua:72-88`, `Scripts/Library/aitwp.lua:53`, `Scripts/AI/BaseTree/*` call paths), making deterministic replay dependent on strict execution ordering.
  - Net effect for stability risk: command ordering or timing differences (especially repeated timer boundaries and async scriptcalls) are likely stronger OOS vectors than raw network serialization in this Lua layer.

- Phase 2 risk synthesis:
  - Sync boundary is mostly "engine session state + per-object persisted properties."
  - Deterministic AI synchronization gaps are likely in:
    - host/client timing alignment of repeat/economic loops,
    - execution ordering of deferred scriptcalls,
    - unseeded random branches in policy/state derivation paths.

## Research hypotheses status after Phase 1 evidence
- H1: AI divergence risk from timing/cadence drift is likely high (`ReadyToRepeat`/timers + async command scheduling confirmed).
- H2: Deterministic seeding alone is not sufficient; synchronization boundaries/windowing are required.
- H3: Command-queue layering remains valid, and is practical before full policy/strategy refactor.

## Phase 2 hypothesis update
- H4 (confirmed): No custom transport layer is apparent in reviewed session/AI scripts; synchronization is governed by engine controllers (`WorldSessionCtrl`, `SessionCtrl`, `SimulationController`) plus script-level state persistence/timing.
- H5 (confirmed): AI behavior determinism today is constrained by timer/event cadence and random branches more than by absent network packets in Lua.

## Phase 3 evidence block (behavior-tree architecture + execution model)
- Architecture and activation:
  - `Scripts/AI/BaseTree/readme.mkd:27` describes dynasty AI selection via a round-robin dynasty loop.
  - `Scripts/AI/BaseTree/readme.mkd` also frames AI into named top-level categories (`Dynasty`, `Election`, `Trial`, `Feud`, `Duel`, `ToMEconomy`) and documents where each group contributes decisions.
  - `Scripts/AI/BaseTree/readme.mkd:129` confirms building-specific tree paths can run when SIM enters building states or finishes production.
  - `Scripts/AI/BaseTree/*.lua` nodes are organized as independent `Weight` + `Execute` functions, not as an explicit deterministic event queue today.
- Runtime hand-off points and measured plan boundary:
  - `Scripts/AI/BaseTree/Dynasty/d_GoIdle.lua:13` and `Scripts/AI/BaseTree/ToMEconomy/Workshop/workshop_DoNothing.lua:7` route to `MeasureRun(…, "DynastyIdle")`.
  - `Scripts/AI/BaseTree/Dynasty/d_GoIdle.lua:13` proves non-strict coupling between tree output and measure-level execution.
  - `Scripts/Measures/Behaviour/std_Idle.lua:4-5` routes directly into `MeasureRun("", nil, "DynastyIdle")`.
  - `Scripts/Measures/ms_DynastyIdle.lua:53-55` combines day/time branching with stateful timer/properties, reinforcing non-tree execution paths.
- State model and determinism coupling:
  - `Scripts/Library/AI.lua` and `Scripts/Library/aitwp.lua` persist most AI decision context in runtime properties (`AI_*`, `AITWP_*`) rather than a dedicated replay-safe command store.
  - `Scripts/AI/BaseTree/IncomeForAI.lua:18-20` shows deferred `CreateScriptcall` execution in current path.
  - `Scripts/AI/BaseTree/Priorities.lua:2-9` and `Scripts/AI/BaseTree/IncomeForAI.lua:6-11` rely on per-object repeat timers (`ReadyToRepeat`/`SetRepeatTimer`).
  - Multiple behavior/state scripts include `Rand()` in decision branches (`Scripts/Library/AI.lua`, `Scripts/Library/aitwp.lua`, `Scripts/Measures/ms_DynastyIdle.lua`), so execution ordering stability directly controls replay consistency.
- Deterministic decorator insertion analysis:
  - Candidate boundary 1 (tree leaf): wrap each `Weight`/`Execute` leaf output into an explicit command object before measure dispatch.
  - Candidate boundary 2 (`DynastyIdle` bridge): wrap `std_Idle`/`ms_DynastyIdle` and add validation against synced snapshot/hash before random branches and timers mutate state.
  - Candidate boundary 3 (`AI_Priorities` refresh): convert periodic budgeter nodes (`Priorities`, `IncomeForAI`) into plan producers for engine-neutral replay checks.
- Periodic sync / seeded execution synthesis:
  - AI cadence is timer/event-driven, not fixed-tick; thus a seeded model should be synchronized at cadence boundaries, not per frame.
  - `ReadyToRepeat` and `SetRepeatTimer` keys appear in many nodes; this is likely where host/client divergence enters without shared sequence state.
  - A practical sync contract from this codebase would pin execution on shared timing keys (e.g., gametime bucket + dynasty id + function id) and deterministic RNG streams derived from that contract.

## Phase 3 gaps to close before final design
- Need to locate the exact runtime invoker that triggers dynasty round-robin for BaseTree (the behavior README documents intent, but invoker is not clearly visible in reviewed Lua).
- Need exact validation point of `CreateScriptcall` ordering across host/client for `IncomeForAI.lua` and similar deferred calls.
- Need concrete command schema shape validation strategy for measure actions currently invoked by direct names (`MeasureRun` payloads).

## Phase 3 hypothesis update
- H6 (evidence-supported): deterministic control points exist today at existing measure-entry boundaries; this is where a command/seed gate can be inserted with lowest risk.
- H7 (evidence-supported): tree leaves do not currently expose explicit command metadata, so the architecture is policy-first + side-effect-first rather than command-first.

## Phase 7 evidence block (reverse-engineering and binary observability lane)

### Environment/tooling evidence collection
- CLI reverse-engineering tooling audit (PATH discovery) returned only `dotnet` in this environment.
- Confirmed missing in this session:
  - `ghidra`, `ghidraHeadless`, `ida`, `ida64`, `idat`, `cutter`, `radare2`/`r2`, `rizin`,
  - `strings`, `objdump`, `readelf`, `dumpbin`, `x64dbg`, `x32dbg`,
  - `jadx`, `frida`, `dnSpy`, `binaryninja`, `pin`, `gdb`/`lldb`, `wireshark`, `tcpdump`,
  - and related symbol/reverse binaries.
- MCP tooling/state query evidence:
  - `list_mcp_resources` returned an empty array (`[]`).
  - `list_mcp_resource_templates` returned an empty array (`[]`).
- Practical inference: no reverse-engineering MCP server is currently configured through available MCP resources.

### Reverse-engineering scope inference from code evidence
- Lua layers confirm no custom socket/websocket transport at the script level, so reverse-engineering the game binaries is not a prerequisite for implementing deterministic sync lanes in `Scripts`.
- High-confidence evidence suggests primary desync risk remains in script-level architecture:
  - timer-driven scheduling (`ReadyToRepeat` / `SetRepeatTimer`),
  - async execution (`CreateScriptcall`),
  - mutable getter-like functions and shared callback context.
- Therefore, the recommended research order is:
  1) instrumentable Lua-level telemetry and command contracts first,
  2) static binary observability (non-mutating) only if needed for gap closure,
  3) avoid binary injection unless explicitly approved.

### Required tool matrix draft (research only)
- Static extraction: `strings`, `dumpbin`/`llvm-objdump` (or `readelf`/`objdump` equivalents), `sigcheck`, PE analyzers.
- Symbol/function discovery: Ghidra/Cutter/rizin/IDA with signature and export scanning.
- Execution tracing: debugger/trace tooling (x64dbg/winDbg), function-call logging, event hooks.
- Network forensics: Wireshark + packet capture filters for session/auth/sync channels.
- Runtime telemetry correlation: log pipeline that normalizes decision window + seed digest + callback provenance IDs.
- MCP extension targets (if available): reverse-engineering servers or filesystem/file-analysis bridges to provide consistent log and artifact visibility to analysis workflows.

### Open RE backlog item
- Determine whether reverse-engineering/replay requirements can be satisfied with existing game-engine debug logs and non-invasive script traces before adding external binary tooling.

## Phase 7 addendum: LLM decomp landscape and workflow classification (research input)

### External method landscape confirmed for this session
- Decompilation-specific model families (for binary-to-source and refine tasks) are in active 2025/2026 development and can be used as a second-pass optimizer.
- Agentic assistants that drive Ghidra/GDB/objdump are practical productivity multipliers but are not full replacements for disassembly/decompiler validation.
- Open-source unstripping tools for Rust/Go symbol recovery are orthogonal to core AI synchronization research unless stripped native symbols obstruct callback tracing.

### Research interpretation for this repo
- For this project, the highest-confidence path remains:
  1) Lua-level deterministic trace instrumentation,
  2) command-phase logging and callback provenance,
  3) optional static/native observability if script traces cannot resolve a gap.
- LLM-assisted binary interpretation should be scoped as a hypothesis tool with explicit reproducibility checks, not as final truth.

### Concrete evaluation template (applied to future tools)
- Evidence anchor requirement: each assisted decomp pass must be linked to a concrete symbol/function and known runtime behavior.
- Acceptance gate: no tool output is accepted without side-by-side comparison to script-level behavior and deterministic trace replay.
- Priority: retain minimal attack surface and no binary mutation until synchronization architecture conclusions are blocked by missing native visibility.
