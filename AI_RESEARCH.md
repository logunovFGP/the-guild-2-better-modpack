# AI synchronization research (2026-02-13)

## Question 1: How is state synchronized in multiplayer?

Multiplayer synchronization in this repository is primarily performed by built-in engine/session modules, not custom Lua network code.

- `Scripts/GameState/GameStartUp.lua` sets `SessionType = "LOCALHOST"`, attaches `cl_WorldSessionController`, and moves to `StartScreen`.
- `Scripts/GameState/JoinSession.lua` sets `SessionType = "CLIENT"`, starts `cl_ClientController`, then polls `\Application\Game\Controller` until `WorldReady == 1` before `ChangeGameState("Game")`.
- `Scripts/GameState/SelectSession.lua` enables `cl_SessionSelector` for session selection.
- `Scripts/GameState/Game.lua` attaches/disables `WorldSessionCtrl` when the game state is entered/left.
- `Scripts/Campaign/_Network/_Network.lua` only returns campaign world name from config; there is no custom packet or message synchronization code in this layer.

## Question 2: How does overall synchronization happen?

1. Session-level ownership and object state are handled by the underlying engine and modules.
2. Gameplay and AI scripts read/write shared object state through alias properties:
   - `GetProperty` / `SetProperty`
   - `GetData` / `SetData` (transient script-local context)
3. Important AI state persistence points:
   - `Scripts/Library/aitwp.lua` stores AI weights and relationships with properties like `AITWP_Political`, `AITWP_Agressive`, `AITWP_Intrigue`, and enemy lists.
   - `Scripts/Library/AI.lua` uses property-backed AI personality (`AI_PERSONA`) and dynasty state.
   - `Scripts/Campaign/DefaultCampaign.lua` sets scenario/dynasty mission context (`Scenario.AITWP_Mission`) and dynasty metadata (`DynastyAlias.PlayerDesc`) used by AI logic.
4. In practice: clients are expected to be authoritative-consistent on engine object properties and deterministic script execution; there is no custom snapshot/serialize/replay sync layer visible in the Lua code.

## Phase 1 evidence appendix (synchronization scope, additional)
- `Scripts/AI/BaseTree/readme.mkd` states the dynasty BaseTree is executed via round-robin over all dynasties, confirming a shared scheduler abstraction but not exposing the engine-side caller in reviewed Lua.
- `Scripts/Measures/Behaviour/std_Idle.lua` immediately routes dynasty Sims to `ms_DynastyIdle` via `MeasureRun("", nil, "DynastyIdle")`.
- `Scripts/AI/BaseTree/Dynasty/d_GoIdle.lua` and `Scripts/AI/BaseTree/ToMEconomy/Workshop/workshop_DoNothing.lua` return to `DynastyIdle`, so tree and measure layers are coupled through fallback actions.
- `Scripts/Measures/ms_DynastyIdle.lua` shows time-based branching (`math.mod(GetGametime(),24)`), random choice (`Rand`) and wait budget persistence (`_DO_NOTHING_TIME`) inside non-tree AI idle logic.
- Campaign/world scripts (`Scripts/GameState/*.lua`) remain transport/session-boundary oriented; no custom AI command transport was observed in this phase.

## Question 3: Which libraries from the provided list are used?

- No runtime usage was found in Lua code for:
  - `behaviourtree.lua`
  - `tiny-ecs`
  - `Jumper`
  - `serpent`

These names appear in documentation/research files (`Scripts/AI/README.md`, `Scripts/AI/BaseTree/readme.mkd`) as suggested tooling, not as loaded or imported modules.

## Practical conclusion

- Current synchronization strategy is module-based multiplayer session control + replicated world/entity state.
- AI synchronization relies on shared persistent properties (`SetProperty/GetProperty`) and deterministic decision logic, not external AI-specific data synchronization libraries.

## Recommended deterministic AI architecture (for implementation planning)

### Problem framing

The current architecture already guarantees a strong engine-level sync channel (session/world state), but AI behavior can still diverge if:
- random decisions are not deterministic,
- timing-sensitive decisions occur out of phase across peers,
- or derived AI state is recomputed inconsistently from mutable world data.

### Recommended direction

Adopt a **command-sequence model** with a central AI state snapshot:

1. Define fixed AI decision windows (example: every `N` simulation ticks).
2. At each window, host-like/authoritative context computes an AI action plan from snapshot state and emits compact commands.
3. Broadcast/replicate those commands as normal game properties / existing networked data flow.
4. Execute commands deterministically and record intent/results for audit.

This approach keeps AI synchronized even if the exact per-frame execution timing varies across machines.

### Why not a websocket-only sync layer

A custom websocket layer would be redundant and high-risk in this codebase, because:
- there is already a session/network layer for world replication,
- adding another transport path raises reconciliation, authority, and replay complexity,
- failure modes become harder to debug in a mixed deterministic/non-deterministic environment.

Use existing property/data sync pathways as the transport unless a hard engine limitation forces a custom channel.

### Seed-based deterministic behavior

For any stochastic logic:
- replace free `math.random()` calls with seeded RNG streams (seeded from world/frame/index + stable salt),
- keep seeds/stream keys part of replicated AI state,
- log stream transitions so peers can replay the same choice sequence from the same input state.

### Goal-driven upgrade path for “smarter” AI

1. Normalize AI world view into a canonical snapshot schema (stable keys, normalized units/alliances/threat map).
2. Introduce explicit goals (e.g., Expand, Defend, Raid, Diplomatic pressure) with weighted utility.
3. Select goals by deterministic scoring each decision window.
4. Decompose goals into short, executable command chains instead of long ad hoc scripts.
5. Add telemetry: goals chosen, score rationale, tie-breakers, and command outcomes.

### Practical rollout sequence

- **Phase 1 (low risk):** add command schema + deterministic loop/tick alignment; stop behavior on random divergence.
- **Phase 2:** implement seed control for all random AI decisions and log audit trail.
- **Phase 3:** convert key ad-hoc decision branches into explicit goals with score-based selection.
- **Phase 4:** optional periodic hard reconciliation (coarse) if command/audit checks detect divergence.

### Expected outcomes

- Higher determinism across multiplayer clients.
- Reproducible debugging and easier replay analysis.
- Better control over AI “intelligence” through explicit utility-based goal choice.
- Reduced chance of desyncs caused by timing/order differences.

## Concrete implementation plan (no code changes now)

This section converts the direction above into concrete functions, data flow, and a decorator-based execution model that can be implemented directly in `Scripts/AI`.

### 1) Deterministic AI entrypoint and state model

Start by formalizing a typed AI context and central factory:

```lua
-- Scripts/AI/DeterministicAI.lua (target location)
function CreateAgent(dynastyAlias, factionAlias, seedContext, config)
  local dynSeed = HashStringToSeed(dynastyAlias, factionAlias, seedContext.WorldGuid)
  return {
    AgentId = build_agent_id(dynastyAlias, factionAlias),
    WorldGuid = seedContext.WorldGuid,
    Faction = factionAlias,
    Dynasty = dynastyAlias,
    DecisionTick = config.DecisionTick,
    SeedRoot = dynSeed,
    Seeds = {
      goal = dynSeed + 101,
      tactical = dynSeed + 211,
      tacticalSub = dynSeed + 313,
    },
    Snapshot = BuildSnapshot(dynastyAlias, factionAlias),
    Blackboard = {
      Cooldowns = {},
      LastGoal = "Idle",
      LastScore = 0,
      Version = "ai.v1.det-tree",
    },
    CommandQueue = {},
    Metrics = {
      LastTick = -1,
      LastPlanHash = "none",
      DivergenceFlag = false,
    },
  }
end
```

Follow with:

```lua
function RebuildSnapshot(agent, tick, tickPeriod)
  -- one canonical source of truth used by planning
end

function BuildPlan(agent, snapshot, tick)
  -- produce compact commands, not direct global mutations
end

function PushCommand(agent, cmd)
  -- append command with deterministic index + checksum
end
```

### 2) Deterministic stream utilities

Guarantee no raw PRNG is used outside seeded stream functions:

```lua
function MakeRng(agent, channel)
  return {
    NextInt = function(min, max) ... end,
    NextFloat = function() ... end,
    NextChoice = function(list) ... end,
  }
end

function NextSeed(agent, channel)
  -- advance and persist stream seed deterministically
end
```

Store stream seeds on `agent.Seeds.<channel>` and replicate this state as part of AI state if commands are generated from it.

### 3) Command format for sync-safe execution

Use one command object shape:

```lua
{
  v = 1,
  agentId = "dynasty-11/faction-3",
  tick = 123456,
  seq = 12,
  type = "ReinforceFront",
  params = { target = "loc_44", amount = 1, priority = 0.62 },
  hash = "a1f3...",
  seedDigest = "goal:99321"
}
```

Execution contract:
- never execute side effects during planning,
- only execute `CommandQueue` in execution phase,
- include `v` (schema version) to protect future migration,
- persist `hash` and `seedDigest` for divergence checks.

### 4) Deterministic decorator tree (phase-driven)

Define exactly one deterministic root tree per tick window:

```text
RootSelector
└─ Decorator_PhaseWindow(Agent.DecisionTick, currentTick)
   └─ Decorator_AbortOnStaleSnapshot(agent.Metrics.LastTick, currentTick)
      └─ Decorator_StablePriority("Goal")
         ├─ Sequence_Defend
         │  ├─ Decorator_Condition(HasThreatToCore)
         │  ├─ Decorator_RepeatUntil(NeedNoMoreThreatActions)
         │  └─ Decorator_OrderedTasks({IssueThreatAssessment, SecureBorderCommand, RebuildForces})
         ├─ Sequence_Expand
         │  ├─ Decorator_Condition(HasExpansionCapacity)
         │  ├─ Decorator_OrderByScore(ScoreExpand, TieBreakSeeded)
         │  └─ Decorator_OrderedTasks({ScoutNewRegion, SecureOutpost, PrepareTradeRoute})
         ├─ Sequence_Diplomacy
         │  ├─ Decorator_Condition(HasDiplomaticLeverage)
         │  └─ Decorator_OrderedTasks({ThreatenEnemy, OfferTruce, RequestSupport})
         └─ Sequence_Economy
            ├─ Decorator_Condition(IsEconomyBelowTarget)
            └─ Decorator_OrderedTasks({RaiseTax, RebaseProduction, MoveResources})
```

Implementation notes:
- `Decorator_PhaseWindow` is the hard synchronization boundary.
- `Decorator_StablePriority` uses a fixed ordered list with deterministic score + seed tie-break.
- `Decorator_AbortOnStaleSnapshot` prevents acting on outdated snapshot drift.
- `Decorator_OrderedTasks` emits command groups in strict order.

### 5) Suggested function names for rollout

Keep APIs minimal and explicit:

- `CreateAgent(dynastyAlias, factionAlias, seedContext, config)`
- `ApplyPlanTick(agent, currentTick)`
- `CollectSnapshot(agent, currentTick)`
- `EvaluateGoalPriority(agent, goalName, snapshot, rngGoal)`
- `BuildDecoratorTree(agent, snapshot, rngGoal)`
- `SelectPlanNode(tree, snapshot)`
- `QueueCommand(agent, cmdType, params)`
- `ApplyCommands(agent, snapshot)`
- `VerifyDeterminism(agent, expectedHash, currentHash)`

### 6) Concrete rollout steps (documentation ready for implementation)

1. Add new `AI_Snapshot` / `AI_Command` shape in `Scripts/AI` and persist only stable references (ids, not object pointers).
2. Introduce `CreateAgent` in a dedicated module and migrate any `math.random()` usage inside AI paths to `MakeRng(..., channel)`.
3. Replace ad-hoc direct actions inside `Scripts/Library/AI.lua` and `Scripts/Library/aitwp.lua` calls with command emission via `QueueCommand`.
4. Add decision loop in game heartbeat:
   - phase gate (`DecisionTick`)
   - snapshot build
   - tree build
   - plan generation
   - deterministic command apply.
5. Add diagnostics:
   - plan hash, seedDigest, command queue size, divergence count per tick.
6. Add reconciliation guardrails:
   - if local command hash differs from replicated `seedDigest`, raise `agent.Metrics.DivergenceFlag = true`, stop direct combat action and fallback to safe goal (`WaitAndHold`).
7. Iterate one goal branch at a time (Defend → Expand → Economy → Diplomacy), measure determinism logs before enabling the next branch.

## Deep corruption map and exact action chains (2026-02-14)

### Critical logic defects that are evidence-backed

1) `Scripts/Library/aitwp.lua` (function `InitEnemies`, lines 193-204)
- At line 200 the check is `if not DynastyIsShadow(DAli) and not DynID == GetID(DynAlias) then`.
- In Lua this parses as `(not DynastyIsShadow(DAli)) and (DynID == GetID(DynAlias))` and is opposite of the intent.
- This can permit self-selection or shadow dynasties entering enemy list incorrectly under edge conditions, and breaks deterministic targeting assumptions in feud-related branches.

2) `Scripts/AI/BaseTree/Dynasty/HireMyrmidon.lua` (lines 10-15)
- `if not BuildingGetType("myrm_home") == GL_BUILDING_TYPE_RESIDANCE then` has the same operator-precedence bug.
- Symptom: home building type check does not reliably reject non-residences, making hiring decisions dependent on non-obvious truthiness and enabling wrong action eligibility.

3) `Scripts/Library/AI.lua` (function `MakeDecision`, lines 996-1026)
- `CheckValue` is initialized to `0` and returned unmodified when `Trait2 == nil`.
- That means all single-trait calls are effectively deterministic-false instead of probabilistic.
- Usage evidence:
  - `Scripts/Measures/ms_041_BribeCharacter.lua` -> `AIInitBribe` calls `ai_MakeDecision("AI_Dyn", "ambition", 0, "greed", 0)` (works by comparison path).
  - `AIDecision` calls `ai_MakeDecision("AI_Dyn", "bribes", AcceptMod)` (single trait path, now effectively always false).

4) `Scripts/AI/BaseTree/Dynasty/d_GoIdle.lua` currently returns `0` in `Weight()` unconditionally.
- Even with valid idle sim and random branch logic, this leaf never contributes scheduling value.
- It still executes only if forced by caller, which strongly suggests this branch has drifted from intended intent and may mask missing fallback behavior.

5) `Scripts/AI/BaseTree/IncomeForAI.lua` uses async action boundary (`CreateScriptcall`) from AI path.
- `SetRepeatTimer("dynasty", "AI_Income", 1)` followed by `CreateScriptcall("GiveAIMoney", 1, "Library/chr.lua", "GiveMoney", "dynasty")`.
- In a deterministic architecture, delayed execution via global scriptcall queue is a potential desync source if scheduling order diverges.

6) `Scripts/Measures/ms_DynastyIdle.lua` and `Scripts/Measures/Behaviour/std_Idle.lua` are timing/state-coupled boundaries.
- `ms_DynastyIdle.lua` relies on shared properties (`_DO_NOTHING_TIME`, `ai_VisitDoc`) and multiple `Rand(...)` branches.
- `std_Idle.lua` routes dynasty sims directly with `MeasureRun("", nil, "DynastyIdle")`.
- This is a hard integration boundary between tree and non-tree execution where command metadata is not currently emitted.

7) `Scripts/AI/BaseTree/ToMEconomy/Workshop.lua` → `Scripts/AI/BaseTree/ToMEconomy/Workshop/VisitWorkshop.lua` → `Scripts/AI/BaseTree/ToMEconomy/Workshop/workshop_DoNothing.lua`
- Base nodes set repeat timers (`AI_CheckWorkshop`, `AI_CheckWorkshop`) then directly move/dispatch.
- This confirms a separate production sub-tree with similar side-effect execution style, not yet command-wrapped.

### Required fixes list (high-confidence, code-level research outcome)

1. Fix all unary-not/equality precedence defects in AI control paths.
- `aitwp.lua`: replace `not DynID == GetID(DynAlias)` with `DynID ~= GetID(DynAlias)` and gate shadow checks explicitly.
- `HireMyrmidon.lua`: replace `not BuildingGetType(...) == GL_BUILDING_TYPE_RESIDENCE` with `BuildingGetType(...) ~= GL_BUILDING_TYPE_RESIDENCE`.

2. Rework `ai_MakeDecision` contract and callers.
- Convert single-trait path to a deterministic random check equivalent to the two-trait branch.
- Rename local variables for clarity (`CheckTrait1`) and guard when traits are unknown.
- Add measure-level test notes: `ms_041_BribeCharacter` currently depends on this path.

3. Introduce decision/command gates around known timer + random hotspots.
- `ms_DynastyIdle.lua`, `std_Idle.lua`, and tree bridge nodes (`d_GoIdle`, `workshop_DoNothing`) should emit deterministic command descriptors before action execution.
- Keep current behavior but move side effects behind an auditable command stage.

4. Audit asynchronous action boundaries in AI tree layer.
- At minimum, document and evaluate `CreateScriptcall` usage in `IncomeForAI.lua` for sequence ordering.
- If strict determinism is required, replace with plan-stage commands (no direct mutable side-effects inside the timing loop) before execution.

### Synchronization architecture conclusion from research

- This codebase does not expose a custom Lua transport protocol for AI state; synchronization relies on engine session controls (`WorldSessionCtrl`, `SessionCtrl`, `cl_SimulationController`) and replicated object state (`SetProperty/GetProperty`).
- Therefore practical sync stability must come from:
  - explicit decision windows,
  - deterministic RNG channels,
  - command-first action emission,
  - and boundary validation at points where `ReadyToRepeat`, `SetRepeatTimer`, and `Rand` interact.

### Concrete function chain map for investigation follow-up

- Dynastic loop (documented as round-robin in `Scripts/AI/BaseTree/readme.mkd`) → prioritized nodes in `Scripts/AI/BaseTree/*.lua` → `MeasureRun(... "DynastyIdle")` in `d_GoIdle.lua` / `workshop_DoNothing.lua` → `std_Idle` / `ms_DynastyIdle` with shared timers and randomness.
- Priority updates: `Scripts/AI/BaseTree/Priorities.lua` -> `aitwp_CalculatePriorities("dynasty")` -> `Scripts/Library/aitwp.lua` (`InitEnemies`, `CalcNewPriority`, enemy/random logic).
- Decision utility path: `ms_041_BribeCharacter.lua` -> `ai_MakeDecision` in `Scripts/Library/AI.lua` for trait-gated branching outcomes.

## Additional architectural-level risk map (high-confidence, now documented from chain analysis)

### 1) Query path mutates relationship state (non-transactional read model)

- `Scripts/Library/AI.lua` → `function DynastyCalcThreat` (`DynastyCalcThreat`, lines 725-734) calls:
  - `dyn_GetEnemies(SimAlias)`
  - `dyn_GetEnemies(TargetAlias)`
- `dyn_GetEnemies` (`Scripts/Library/dyn.lua:913-929`) unconditionally calls `dyn_RecountEnemies(SimAlias)` inside what is semantically a getter.
- `dyn_RecountEnemies` (`Scripts/Library/dyn.lua:868-908`) mutates `EnemyCounter` / `EnemyNo*` by deleting and re-creating dynasty properties on every call.
- Impact: threat evaluation becomes stateful and write-amplifying. A “read” for decision scoring can change the same replicated properties it depends on, which is an architectural desync risk when call ordering differs between peers.

### 2) Relationship mutation APIs are not idempotent at API boundary

- `dyn_AddEnemy` (`Scripts/Library/dyn.lua:964-980`) and `dyn_AddAlly` (`Scripts/Library/dyn.lua:1139-1157`) only append entries and increment counters.
- Neither function checks if the counterpart is already present before incrementing `*Counter`.
- Multiple relationship events for the same pair can therefore create duplicate edges before `GetRandomEnemy`/threat logic runs.
- Follow-on cleanup path (`dyn_RemoveEnemy`/`dyn_RemoveAlly`, `:986-1013`, `:1161-1189`) only zeroes first match, then `Recount...` compacts once per event.
- Impact: repeated diplomacy reactions can inflate edge state and then collapse non-deterministically across event order, especially when timers/callbacks overlap.

### 3) Cross-layer context boundary is alias-ID based (global, not re-entrant)

- `Scripts/Measures/ms_047_AdministrateDiplomacy.lua` frequently comments: `-- we need to save the ID here because the MyBoss-Alias gets lost after AIDecision` and then uses `SetData("MyBossID", ...)`, `SetData("MyDestID", ...)` before `MsgNews(...)`+`ms_047_administratediplomacy_AIDecision`.
- Same pattern in several branches around lines `798-815`, `954-963`, `1102-1110`.
- `AIDecision` (`:1211-1292`) writes transient keys (`ReasonToDecline`, `RivalID`, etc.) and returns decision tokens.
- Impact: runtime context is serialized through mutable IDs + shared data keys, not through an immutable command envelope, so async message callbacks can interfere with each other if nested or concurrent.

### 4) Multi-surface decision execution without explicit command contract

- Tree path: `Scripts/AI/BaseTree/ToMEconomy/Workshop.lua` (`AI_CheckWorkshop` timer) → `VisitWorkshop` move path or `workshop_DoNothing` (`:1-7`) → `MeasureRun("SIM", nil, "DynastyIdle")`.
- Dynasty path: `Scripts/AI/BaseTree/Dynasty/d_GoIdle.lua` (`Rand(10) < 8` and no-op branch) → `MeasureRun("SIM", 0, "DynastyIdle")`.
- Non-tree surface: `Scripts/AI/BaseTree/IncomeForAI.lua` emits `CreateScriptcall("GiveAIMoney", 1, "Library/chr.lua", "GiveMoney", "dynasty")`.
- Tree/measure coupling is split across:
  - timer checks (`ReadyToRepeat`/`SetRepeatTimer`)
  - random branches (`Rand(...)`)
  - implicit alias-dependent callbacks (`SetData`, `GetData`)
- Impact: no single execution contract exists for command emission, replay tags, or state transitions between scheduler/leaf/measure layers.

### 5) Scheduling and cooldown topology can split determinism by host ordering

- Known scheduler hot spots:
  - `AI_Priorities` (`Scripts/AI/BaseTree/Priorities.lua:2-10`)
  - `AI_Income` (`Scripts/AI/BaseTree/IncomeForAI.lua:9-20`)
  - `AI_CheckWorkshop` (`Scripts/AI/BaseTree/ToMEconomy/Workshop.lua:6-22`)
  - Many leaves use per-target keys like `AI_Bribe..GetID("Target")`, `DIP_..GetDynastyID(...)`.
- Since no explicit world-tick phase contract in these Lua layers is evident, the practical determinism contract depends on host/client callback ordering and timer alignment around same keyspace.
- Impact: equivalent state can drift into different branch order across peers even when all inputs appear equivalent.

## Required fixes list by architecture layer

### State ownership/consistency fixes

1. Introduce an immutable `AI_Snapshot` input for every scoring block (`DynastyCalcThreat`, diplomacy checks, priority calc).
2. Change `dyn_GetEnemies` and `dyn_GetAllies` to true read paths (no mutation); keep reconciliation passes explicit and only called from state-change events.
3. Add dedupe guard in `dyn_AddEnemy` / `dyn_AddAlly` and move counter updates to compact phase after set membership change.
4. Version relationship payload shape (`EnemyCounter`, `EnemyNo*`, `AllyCounter`, `AllyNo*`) and detect impossible deltas (`>1 repeated pair append`) before accepting state.

### Execution model fixes

1. Make `AI_Priorities`, `AI_Income`, and workshop/civilian branches emit command descriptors instead of directly mutating via scriptcall or direct measure path.
2. Keep existing behavior under a command wrapper:
   - `BuildPlan` phase only reads and queues
   - `ApplyPlan` phase executes deterministic command queue
3. Add decision-window metadata (`snapshotTick`, `window`, `ownerTag`, `commandSeq`) in measure-level logs for `DynastyIdle` and diplomacy callback decisions.

### Callback boundary fixes

1. Replace global `SetData`/`GetData` message-context keys with per-dialog context objects keyed by stable conversation IDs in one explicit state table (`DiplomacyCtx`, `ctxId`) passed into `MsgNews`/AIDecision closures.
2. Record callback decisions in command log with `ctxId`, not alias/global `Destination`/`MyBoss` mutation, before performing any follow-up state update.
3. For high-risk diplomacy paths (`EndFeud`, `NAP`, `Alliance`), enforce no direct state writes inside callback branch before command envelope commit.

## Architectural recommendation (final)

Adopt a two-layer model:
- Layer 1: deterministic scheduler + snapshot builder (`AI_Priorities`, threat evaluation, feud/target selection) with no direct writes.
- Layer 2: validated command bus (`AI_Income`, branch selection, diplomacy replies, measure effects).

Concrete target for implementation-ready sequencing:
- Phase A: remove mutation from getter paths and add dedupe in add/remove relationship APIs.
- Phase B: isolate all callback/decision context in explicit IDs and immutable data objects.
- Phase C: wrap all tree/measure transitions in command descriptors and reconcile through existing session-owned replicated properties.

## Shared-tree trace synchronisation option (research for next plan)

### Proposed protocol concept from your request

- Introduce a shared `AIDecisionNode` (or `AISnapshot`) object with:
  - deterministic decision key (`agent|tick|window|nodeId|attempt`)
  - `ToDecided` / `AlreadyDecided` status envelope per decision task
  - `commandSeq`, `hash`, `seed`, and `owner` fields
- Define lock-like flow:
  1. AI host/owner computes a planned command proposal for `(agent, tickWindow)`.
  2. Candidate is published with state `ToDecided`.
  3. Peers validate the same snapshot/hash and reply `AlreadyDecided` if already accepted or `ToDecided` only if they can execute locally with the same result.
  4. Decision is committed when a quorum/consensus condition is met and then replayed as command queue.
- This could prevent divergent local decisions caused by timer ordering differences and callback side effects.

### Feasibility in this codebase (important constraint)

- No custom websocket transport is observed in reviewed Lua paths.
- Current transport boundary is engine-owned session replication (`WorldSessionCtrl`, `SessionCtrl`, `SimulationController`) plus object properties (`SetProperty/GetProperty`).
- Implementing websocket transport would require:
  - a new transport/plugin layer outside pure Lua,
  - extra serialization and reconciliation for every AI node transition,
  - and strict security/authority controls (host arbitration, replay abuse handling, reconnect recovery).
- That is a significant production risk relative to current architecture unless the engine already exposes a stable network callback API for this mod layer.

### Recommended safer alternative for now

- Keep decision propagation in the existing replicated state channel and add an in-Lua “decision phase lock” using deterministic phase keys:
  - `AI_DecideWindow = {tickBucket, agentId, version}`
  - `AI_CommandLog` entries written as properties (or centralized table if available) with `(status, hash, seq, seedDigest)`.
- Use an explicit `AlreadyDecided` marker in this existing storage, not network socket messages.
- Apply on all peers by:
  - same snapshot function,
  - same weighted selection logic,
  - same command hash verification before execution.
- This gives most of the same convergence guarantee with lower integration risk than new transport code.

### Reverse-engineering / binary-extension direction: current recommendation
- This section was moved to the dedicated reverse/ recovery plan:
  - `SOURCE_RECOVERY.md`

- Practical policy still holds in this architecture:
  - prioritize deterministic Lua-layer synchronization first,
  - use binary-level work only for evidence gaps after trace-first evidence is exhausted,
  - avoid non-justified binary mutation paths in the base path.

### Research backlog update for this plan

- Tracing lane still applies as written in the sync recommendations.
- Detailed decomp/source-recovery tracing workflow is now in `SOURCE_RECOVERY.md`.

## Phase 7 — Reverse-engineering and binary-observability plan (research only)

### Collection status
- Environment audit found no reverse-engineering binaries in PATH for this session.
- MCP discovery is empty:
  - `list_mcp_resources` -> `[]`
  - `list_mcp_resource_templates` -> `[]`
- Practical implication: no configured MCP server currently exists for reverse-engineering or source-recovery workflows inside this workspace.

### Exact binary inventory collected from active game install (research evidence)
- Game install path used for this inventory:
  - `G:\SteamLibrary\steamapps\common\The Guild 2 Renaissance`
- No symlink directory inside the repository points to the game install (`AGENTS` instruction requested symlink usage; none exists in this workspace).
- `*.exe`/`*.dll` files discovered under this path (recursive scan):
  - `G:\SteamLibrary\steamapps\common\The Guild 2 Renaissance\dbghelp.dll`
  - `G:\SteamLibrary\steamapps\common\The Guild 2 Renaissance\fmod.dll`
  - `G:\SteamLibrary\steamapps\common\The Guild 2 Renaissance\GuildII.exe`
  - `G:\SteamLibrary\steamapps\common\The Guild 2 Renaissance\MFC71.dll`
  - `G:\SteamLibrary\steamapps\common\The Guild 2 Renaissance\ModLauncher.exe`
  - `G:\SteamLibrary\steamapps\common\The Guild 2 Renaissance\msvcp71.dll`
  - `G:\SteamLibrary\steamapps\common\The Guild 2 Renaissance\msvcr71.dll`
  - `G:\SteamLibrary\steamapps\common\The Guild 2 Renaissance\stlport.5.0.dll`
  - `G:\SteamLibrary\steamapps\common\The Guild 2 Renaissance\stlportd.5.0.dll`
  - `G:\SteamLibrary\steamapps\common\The Guild 2 Renaissance\WMEncoderEN.exe`
- Total discovered: `10` binaries.
- Initial architecture/signature observations:
  - Main executable and all DLLs in this scan are `x86` PE binaries (`Machine=0x014C`).
  - Runtime linkage strongly indicates an older MSVC toolchain (VS .NET 2003-era components: `msvcr71/msvcp71/MFC71/stlport`).
  - This increases the chance that high-level engine behavior (including AI scheduling semantics) is largely deterministic but opaque to Lua and best observed through runtime tracing first, then binary mapping if necessary.
### Decompilation + source recovery execution details
- Detailed execution plan moved to `SOURCE_RECOVERY.md`.
