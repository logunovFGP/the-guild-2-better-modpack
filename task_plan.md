# Task Plan: Deep AI Synchronization Research (2026-02-13)

**Goal:** Produce a defensible, end-to-end research deliverable for multiplayer AI synchronization in this codebase, including deterministic state sync strategy, existing networking behavior, and practical tree/decision-engine guidance for future refactor.

## Status
- Current phase: Research design + evidence capture
- Last updated: 2026-02-13

## Phase 1 — Boundary & source discovery
- [ ] Map authoritative network/sync entrypoints used by game states.
  - Files: `Scripts/GameState/*.lua`, `Scripts/Campaign/_Network/_Network.lua`
  - Owners: AI-researcher
  - Exit check: list of authoritative entrypoints and who owns per-frame/game-state transitions.
  - Status: implemented, awaiting user confirmation
  - Touched: `task_plan.md`, `findings.md`
- [ ] Confirm existing AI state persistence points and mutable fields.
  - Files: `Scripts/Library/AI.lua`, `Scripts/Library/aitwp.lua`, `Scripts/AI/**/*`, `Scripts/AI/BaseTree/*`
  - Exit check: catalog of state fields + write/read sites, and replication assumptions.
  - Status: implemented, awaiting user confirmation
  - Touched: `task_plan.md`, `findings.md`
- [ ] Resolve true sync boundaries between host/client simulation and AI script execution.
  - Files: `Scripts/GameState/Game.lua`, `Scripts/GameState/JoinSession.lua`, `Scripts/Network*` if any
  - Exit check: timeline of multiplayer state convergence by tick/session event.
  - Status: implemented, awaiting user confirmation
  - Touched: `task_plan.md`, `findings.md`
  - Notes: Added deeper evidence block in `findings.md` for AI entry-chain and scheduler cues (`std_Idle`, `ms_DynastyIdle`, BaseTree readme references).

## Phase 2 — Network and transport model deep-dive
- [ ] Enumerate all custom transport/code hooks used by AI or campaign logic.
  - Files: `Scripts/GameState`, `Scripts/Campaign`, `Scripts/States`, `Scripts/Library`
  - Exit check: explicit statement: native session layer only vs custom packets/messaging.
  - Status: implemented, awaiting user confirmation
  - Touched: `task_plan.md`, `findings.md`
  - Notes: No custom Lua transport APIs found in reviewed gameplay/AI/session entry files; flow stays on engine `WorldSessionCtrl`/`SessionCtrl` modules.
- [ ] Check whether command/state replication is deterministic-by-default or timing-sensitive.
  - Files: `Scripts/AI` decision schedulers, tick/heartbeat hooks, and any event-driven updates.
  - Exit check: risk list with evidence and impact.
  - Status: implemented, awaiting user confirmation
  - Touched: `task_plan.md`, `findings.md`
  - Notes: AI behavior is timer/event-driven (`ReadyToRepeat`, `SetRepeatTimer`, hour math, deferred scriptcalls), and several decision inputs still use `Rand()` without documented replay-safe seeding.
- [ ] Analyze world/session bootstrap/shutdown behavior for replayability and reconnect.
  - Files: `Scripts/GameState/GameStartUp.lua`, `SelectSession.lua`, `WaitforSync.lua`
  - Exit check: what is restored and what is recomputed from scratch on reconnect.
  - Status: implemented, awaiting user confirmation
  - Touched: `task_plan.md`, `findings.md`
  - Notes: Host/client/session controllers are attached deterministically at state transitions; reconnect path relies on engine world/session readiness and session-state persistence, while script-local AI timers/state are reconstructed from object properties.

## Phase 3 — Decision-tree and behavior architecture assessment
- [ ] Inventory current behavior tree/documented tree usage and call graph.
  - Files: `Scripts/AI/BaseTree/readme.mkd`, `Scripts/AI/README.md`, `Scripts/AI/*`
  - Exit check: matrix of action nodes -> effectors -> state dependencies.
  - Status: implemented, awaiting user confirmation
  - Touched: `task_plan.md`, `findings.md`
  - Notes: Confirmed tree lifecycle is round-robin/dynasty-based and building-specific branch-activation points are readme-documented, with leaf/measure fallback paths to `MeasureRun("DynastyIdle")`.
- [ ] Identify where to place a deterministic decorator model.
  - Files: AI action modules in `Scripts/AI/Functions`, `Scripts/AI/Scripts`, `Scripts/Library`
  - Exit check: candidate insertion points and migration order.
  - Status: implemented, awaiting user confirmation
  - Touched: `task_plan.md`, `findings.md`
  - Notes: Candidate insertion points are the BaseTree leaf boundary and measure-entry boundary (`std_Idle` + `ms_DynastyIdle`), where deterministic wrappers can gate/validate command execution.
- [ ] Define command/plan interface for deterministic execution.
  - Exit check: command schema draft + validation path.
  - Status: implemented, awaiting user confirmation
  - Touched: `task_plan.md`, `findings.md`
  - Notes: Current system does not have a first-class command object; it invokes behavior via `MeasureRun`/`CreateScriptcall` side effects, so a command schema must be introduced as a migration layer before full decorator-tree enforcement.
- [ ] Define “periodic sync” and “seeded execution” model for multiplayer AI decisions.
  - Exit check: pseudocode timing spec.
  - Status: implemented, awaiting user confirmation
  - Touched: `task_plan.md`, `findings.md`
  - Notes: Existing cadence is timer-driven (`ReadyToRepeat` + per-minute/hour checks in state/AI scripts), so synchronization likely needs shared-phase gates + seeded RNG per tick bucket.

## Phase 4 — Library and tooling assessment
- [ ] Confirm which listed libraries are already present in runtime vs docs-only.
  - Files: `Scripts/AI/README.md`, `Scripts/AI/BaseTree/readme.mkd`, project-wide `luarocks`/plugin manifests if present.
  - Exit check: explicit runtime usage matrix.
- [ ] Evaluate feasible adoption path for each library (`behaviourtree.lua`, `Jumper`, `serpent`, `tiny-ecs`) in existing environment.
  - Exit check: compatibility and migration effort notes.

## Phase 5 — Determinism hardening recommendations
- [ ] Formalize seed strategy across all AI decision points.
  - Exit check: seed source, stream per subsystem, replay key derivation, salt strategy.
- [ ] Define anti-drift guardrails and divergence telemetry.
  - Exit check: reconciliation and rollback options with trigger thresholds.
- [ ] Draft concrete implementation sequence prioritized by risk.
  - Exit check: phased rollout with dependencies.

## Phase 6 — Documentation and finalization
- [ ] Update `AI_RESEARCH.md` with deep findings and concrete recommended architecture.
  - Exit check: section on transport boundaries, deterministic loop, and tree migration.
- [ ] Cross-link updated `AGENTS.md`/`*llm.txt` findings for future sessions.
  - Exit check: references updated where decisions rely on this research.
- [ ] Record final decision log and open questions in plan file.
  - Exit check: clear “approved for next implementation” vs “needs validation” notes.

## Phase 7 — Reverse-engineering and binary observability research (non-invasive)
- [ ] Collect host binary/assembly inventory and loading boundaries for AI-related behavior.
  - Files / assets: game install binaries in deployment tree, logs from session bootstrap files, runtime module load points.
  - Exit check: map of candidate DLL/EXE modules, architecture (PE/CLR/native), and load order clues.
  - Status: implemented, awaiting user confirmation
  - Touched: `task_plan.md`, `findings.md`, `AI_RESEARCH.md`, `progress.md`
- [ ] Audit available reverse-engineering toolchain and MCP support in this environment.
  - Checks:
    - CLI tool audit via `Get-Command` and PATH discovery (ghidra, ida, cutter, radare2/r2, x64dbg, strings, dumpbin, etc.).
    - MCP tooling availability (`list_mcp_resources`, `list_mcp_resource_templates`).
  - Exit check: required-tool matrix with confidence levels, and explicit list of unavailable tooling blockers.
  - Status: implemented, awaiting user confirmation
  - Touched: `task_plan.md`, `findings.md`, `AI_RESEARCH.md`
- [ ] Define legal and safety constraints for binary tracing before any runtime instrumentation.
  - Exit check: explicit constraints for EULA, anti-cheat/anti-tamper policy, and binary-modification boundaries.
  - Status: implemented, awaiting user confirmation
  - Touched: `task_plan.md`, `AI_RESEARCH.md`
- [ ] Design tracing plan for callback/state-chain reconstruction without binary mutation.
  - Include: log points, stable IDs, decision-window stamps, and callback provenance fields (`MyBossID`, `MyDestID`, `ctxId`).
  - Exit check: expected-to-observe data schema and reconciliation use.
  - Status: implemented, awaiting user confirmation
  - Touched: `task_plan.md`, `AI_RESEARCH.md`, `findings.md`
- [ ] Evaluate binary-extension/injection feasibility (research-only) against observed architecture.
  - Evaluate: symbol-level tracing, exported API hooks, and process event interception alternatives.
  - Exit check: risk/benefit decision: "prefer observability-only" or "suspend until explicit runtime support".
  - Status: implemented, awaiting user confirmation
  - Touched: `task_plan.md`, `AI_RESEARCH.md`
- [ ] Add `ReverseEngineering.md` or equivalent RE lane to `AI_RESEARCH.md` with recommended first-pass toolset.
  - Exit check: step-by-step lane for static extraction → network/AI callback mapping → command model evidence capture.
  - Status: implemented, awaiting user confirmation
  - Touched: `task_plan.md`, `AI_RESEARCH.md`
- [ ] Report if required MCP servers for reverse-engineering exist in this environment or must be added.
  - Exit check: required server names or vendor plugins and installation path for future provisioning.
  - Status: implemented, awaiting user confirmation
  - Touched: `task_plan.md`, `findings.md`, `AI_RESEARCH.md`, `progress.md`

Status note:
- [ ] Phase 7 tasks are research-only and are not implementation unless user explicitly approves a tooling/implementation change set.

## Phase 8 — Implementation-risk review and packaging
- [ ] Reconcile all plan findings from phases 1–7 into a single deterministic-reliability recommendation.
  - Exit check: single decision artifact with "do first / defer / reject" order.
- [ ] Record reversibility, rollback, and legal-operations constraints before any non-doc task.
  - Exit check: explicit "no injection unless required by user and with written approval".

## Decision Log
- Chosen sequencing: do sync transport analysis before behavior-tree design to avoid prescribing deterministic tree structure on an incomplete networking model.
- Non-trivial scope split: separate “state transport” from “AI policy logic” because most desync risks here come from implicit timing and data freshness, not policy selection alone.
- Evidence rule: every conclusion in research must be backed by file path references in `findings.md` and `progress.md`.
- Added: reverse-engineering research must be scoped to non-invasive telemetry/instrumentation first; any binary mutation/injection is blocked pending explicit approval and legal/safety check.

## Errors Encountered
- No known errors yet.

## References
- `AI_RESEARCH.md`
- `Scripts/AI/README.md`
- `Scripts/AI/BaseTree/readme.mkd`
- `Scripts/GameState/`
- `Scripts/Library/AI.lua`
