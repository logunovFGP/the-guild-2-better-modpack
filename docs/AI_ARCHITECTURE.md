# AI architecture: what we use, where, and what to call it

The decision record for the dynasty AI. Read it before changing anything under
`Scripts/AI`, `Scripts/Library/utility.lua`, `aitwp.lua` or `blackboard.lua`, and
before proposing a technique: the choice for each area of the game is made here.
Change this file when the choice changes, not the other way round.

This supersedes the library survey in `Scripts/AI/README.md`, which recommends
Behavior Trees and ECS. Neither was adopted, for the reasons in §4.

---

## 1. The shape of the thing

The engine owns the loop. Every AI dynasty is ticked round-robin; on its turn the
engine walks `Scripts/AI/BaseTree/` as a **hierarchical selector**: each folder is a
level, each `.lua` file in it is a sibling node exposing exactly two functions,
`Weight()` and `Execute()`. The engine calls `Weight()` on every sibling, picks one
by **weighted random** (roulette over the returned weights, not argmax), then calls
that node's `Execute()`, which either runs a measure on a sim or descends into the
folder of the same name. Proven against 17,252 logged evaluations: observed pick
shares match roulette shares.

Everything the mod adds sits on top of that loop and never replaces it:

```
engine round-robin tick
  └─ BaseTree selector (roulette over Weight())          engine
       ├─ utility scoring inside Weight()                 utility.lua       §2.1
       ├─ goal blackboard (x3 aligned / x0.3 other)       utility.lua       §2.2
       ├─ feasibility ladder (attitude, rung, class)      aitwp.lua         §2.3
       ├─ scored target pickers                           aitwp.lua         §2.4
       ├─ combat estimate, legality                       aitwp.lua         §2.5
       ├─ state + Weight->Execute handoff                 blackboard.lua    §2.6
       └─ telemetry on every decision                     utility.lua       §2.8
  └─ Execute() -> a Measure                                Scripts/Measures  the action layer
       └─ per-sim States and Behaviours (FSM)              Scripts/States    engine/vanilla
            └─ needs (SimGetNeed / SatisfyNeed)            idlelib.lua       ambient layer
```

**This is not a Behavior Tree.** There are no sequence/selector composites, no
decorators, no running state across ticks. Every decision is one-shot and re-derived
from the world each tick; anything that takes time is a measure, and the measure
system is the action layer. That division is deliberate and it works: do not add a
BT library to sequence things the measure system already sequences.

In the literature this is **Utility AI over a static hierarchy with stochastic
selection**. Closest named relative: Dave Mark's Infinite Axis Utility System, with
two deviations - considerations are banded into 0.5..1.5 instead of multiplied raw
with a compensation factor, and selection is roulette instead of argmax because the
engine owns it.

---

## 2. Strategies in use, and their names

Library files are lower-case and the engine exposes their functions as
`<file>_<Name>`, so `Scripts/Library/aitwp.lua`'s `function WinChance()` is called
as `aitwp_WinChance`. Functions inside a library are PascalCase. Knobs are
`UPPER_SNAKE` globals declared next to the code that reads them.

### 2.1 Utility scoring - `utility.lua`, prefix `utility_`

| function | role |
|---|---|
| `utility_Score(dyn, base, {considerations}, tag, goal)` | the one scorer; emits the `W` line |
| `utility_Norm(x, lo, hi)` | any input -> 0..1 |
| `utility_Curve(x, kind)` | `linear`, `quad`, `sqrt`, `invert` |
| `utility_Trait(dyn, trait)` | personality column -> 0..1 |
| `utility_Priority(dyn, axis)` | `AITWP_<axis>` -> 0..1 |
| `utility_Money(dyn, comfortable)` | money -> 0..1, saturating |
| `utility_Trace(dyn, tag, weight)` | a constant weight that still logs |
| `utility_Picked(dyn, tag)` | emits the `PICK` line from `Execute()` |

A consideration is `{ value = 0..1, curve = kind, lo = , hi = }`. The band defaults
to `UTILITY_LO..UTILITY_HI` = 0.5..1.5, so a consideration at 0.5 leaves the base
alone and the extremes move it by half. **The band cannot veto.** A 0.5 floor is
why one thug still attacked six people. When a consideration must be able to kill
the score, give it `lo = 0`, or gate with an explicit early `return 0` above the
score - `bf_ThugAttack` does the latter for its win chance.

### 2.2 Goal blackboard - `utility.lua`

`utility_ChooseGoal` runs from the daily `Priorities` node every
`UTILITY_GOAL_HOURS` (72) and writes `AI_Goal` (Economy, Politics, Family,
Conflict), `AI_GoalTarget`, `AI_GoalUntil`. A node that names a goal in
`utility_Score(..., goal)` is scaled by `utility_GoalFactor`: x3 when aligned, x0.3
otherwise. Logged as `GOAL`.

### 2.3 Feasibility ladder - `aitwp.lua`

A hard filter that runs before scoring and answers "may this house use this tool
against this victim at all". `TWP_TOOL_LIST` declares every hostile tool with its
rung, class (R reputation, E economic, P physical, L legal, O office, D diplomatic)
and whether it is lethal. `aitwp_Attitude(dyn, player)` is one of `blood`, `feud`,
`enemy`, `friend`, `neutral`; `TWP_ATTITUDE_CLASSES` says which classes each may use;
`aitwp_Rung` caps by the player's title and the round. `aitwp_Allowed(dyn, victim,
tool)` combines them. Against other AI houses the ladder always says yes.

### 2.4 Scored target pickers - `aitwp.lua`

Deterministic replacements for the vanilla `DynastyGetRandom*` dice: ties fall to
the lower index, and each emits a telemetry line naming the candidates and the pick.

| function | picks | logs |
|---|---|---|
| `aitwp_GetBestEnemy(dyn)` | the enemy to pursue, honouring the goal target | `ENEMY` |
| `aitwp_FindPlayerTarget(player, mode, out)` | a player sim: `best`, `duel`, `rogue`, `outside` | - |
| `aitwp_EvidenceTarget(dyn, player, out)` | the fixed victim of a legal case | - |
| `aitwp_FindTargetBuilding(dyn, class, rule, out[, town])` | a building: `strongest`, ... | `BLD` |
| `aitwp_OwnBuilding(dyn, class, type, out)` | the house's own, highest level | - |
| `aitwp_OwnBuildingByTurn(...)` | the house's own, round-robin over days | - |
| `aitwp_MostDamagedBuilding(dyn, out)` | for repairs | - |
| `aitwp_FindBeliever(...)` | a convert | `BELIEVER` |

What stays random is dice by design and is listed in the README backlog: probability
gates, which of several *equal* servants goes.

### 2.5 Combat estimate and legality - `aitwp.lua`

Not a planner, a prediction. `anims_fight_sim` settles a swing as
`1+Rand(50)+FIGHTING*5` against `1+Rand(50)+DEXTERITY*5` and takes armour off as a
percentage; these read that forwards.

| function | role |
|---|---|
| `aitwp_HitChance(fighting, dex)` | that roll in closed form |
| `aitwp_FightStats(sim)` | damage, armour %, dex, HP, fighting (via `ai_GetPower`) |
| `aitwp_AddFighter(side, sim)` / `aitwp_SidePower` / `aitwp_WinChance(side, other)` | sides are plain tables; power is HP x damage through, so numbers count twice |
| `aitwp_GatherFighters(dyn, prefix, side, max)` | thugs, robbers, thieves, mercenaries the house can spare |
| `aitwp_DefenceOf(player, victim, side)` | victim + bodyguards + house members within `TWP_ESCORT_RADIUS` |
| `aitwp_MayAttackHere(dyn, victim)` | outside town, or wanted, or the house holds `CommandCityGuard` there |
| `aitwp_IsOutsideTown` / `aitwp_TownRadius` / `aitwp_IsWanted` / `aitwp_CommandsGuards` | its parts |

Bar: `TWP_ATTACK_WIN_CHANCE` = 0.75. Rough on purpose; what it rules out is the fight
nobody could have won. `aitwp_MayAttackHere` is asked twice - in `Weight()` and again
inside `ms_036_AttackEnemy` on arrival, for AI attackers only - because an order can
stand hours before the party catches up.

### 2.6 Blackboard - `blackboard.lua`, prefix `blackboard_`

Two mechanisms, one file.

**Keys.** `BLACKBOARD_KEYS` is every `AI_*` / `AITWP_*` property the AI keeps on a
dynasty or sim, with owner and default. `blackboard_Recall(alias, key)` returns the
declared default instead of nil; an unregistered key logs `::TWP::BB unregistered
key` once. `blackboard_Remember`, `blackboard_Forget` complete the set.
`basetree_stats.py` exits 1 on an unregistered key.

**Weight -> Execute handoff.** The engine runs every sibling's `Weight()` before the
winner's `Execute()`, so an alias resolved in `Weight()` belongs to whichever
sibling ran last. Any node that resolves a target in `Weight()` and needs it in
`Execute()` files it: `blackboard_Stash("bf_Node", "Victim")` in `Weight()`,
`blackboard_Claim("bf_Node", "BF_MyVictim")` in `Execute()`, `blackboard_Drop` at the
end. `basetree_stats.py` exits 1 on a shared alias two siblings resolve differently
without stashing. The eight BloodFeud leaves that had this bug are the worked example.

Repeat-timer names (`ReadyToRepeat(x, "AI_BF_Supply")`) are **not** blackboard keys:
a separate namespace with its own lifetime, and the checker ignores them.

### 2.7 Supply chain - `aitwp.lua`, procedural today, HTN candidate

`aitwp_ShoppingList` -> `bf_Procure` -> `ms_bf_FeudSupply` (cart) -> `aitwp_InStore`
/ `aitwp_DrawFromStock` / `aitwp_CanHandOver` -> `bf_UseArtefact`. Plus
`aitwp_EquipmentTier` -> `aitwp_FindUnequipped` -> `bf_Equip`, `aitwp_CourierOrders`
on difficulty 4-5, `aitwp_ReturnUnused` daily, `aitwp_MarketReport` for telemetry.
All of it hangs off `aitwp_Residence(dyn, out)` - native `GetHomeBuilding` first,
`aitwp_OwnBuilding` living-room fallback, because the native is documented for sims
and carts only. See §4 for what this becomes.

### 2.8 Telemetry - `utility.lua`, one switch

`UTILITY_LOG` (nil = follow `[AI] Log` in `configs/config.ini`). Every line is
`::TWP::<CHANNEL> ...` through `utility_Emit`; decision logic never depends on it.

`W` weight · `PICK` · `GOAL` · `ENEMY` · `BLD` · `BELIEVER` · `SNAPSHOT` (daily, per
dynasty) · `MEMBER` · `CART` · `HANDOVER` · `MARKET` · `AI` (free text from
`aitwp_Log`) · `BB` (blackboard) · `LOADED` / `ENV` (include probes).

Readers: `tools/modding_helpers/ai_telemetry.py` (replay and shares),
`ai_focus.py` (one dynasty's story). If a new decision has no line, it did not
happen as far as the next session can tell - log it in the same change.

### 2.9 Below the tree - engine and vanilla, leave alone

**FSM.** `Scripts/States/state_*.lua` and `Scripts/Measures/Behaviour/std_*.lua`:
per-sim states with enter/run/exit. Right for what a sim is doing this second;
wrong for choosing between forty options. Not ours to restructure.

**Needs.** `SimGetNeed` / `SatisfyNeed` / `ItemGetNeed`, used from `idlelib.lua` and
`std_Idle.lua`: what a sim does with nothing assigned. The per-sim ambient layer,
complementary to dynasty-level utility, not a duplicate of it. One debt: need ids
are bare numbers (`SatisfyNeed("", 8, 0.5)`); naming them is cosmetic, not a
refactor.

---

## 3. Naming

**Node files** `Scripts/AI/BaseTree/<Subtree>/<Group>/<prefix>_<VerbNoun>.lua`. The
prefix is the group's:

| prefix | folder | prefix | folder |
|---|---|---|---|
| `bf_` | BloodFeud | `attf_` | Feud/AttackFeud, Feud/AttackBuilding |
| `deff_` | Feud/DefendFeud | `att_` | Trial/AttackTrial |
| `fvt_` | Trial/FavorTrial | `atto_` | Election/AttackOffice |
| `defo_` | Election/DefendOffice | `fvo_` | Election/FavorOffice, FavorAll |
| `attd_` / `defd_` | Duel/AttackDuel, DefendDuel | `soc_` | Dynasty/SocialLife |
| `def_` | Dynasty/DefendRogue, Trial/DefendTrial | `priv_` | Dynasty/Privilege |
| `uw_` | Dynasty/Underworld | `fst_` | Dynasty/Festivities |
| `build_` | ToMEconomy/BuildWorkshop/* | `workshop_` | ToMEconomy/Workshop |

Top-level nodes and subtree roots carry no prefix (`Dynasty.lua`, `Feud.lua`). A node
has `Weight()` and `Execute()` and nothing else public; helpers are local or go to a
library. New groups get a new short prefix; do not reuse one across folders.

**Aliases.** Node-private, prefixed so a `grep` finds the owner: `TWP_` for library
scratch (`TWP_TA1`, `TWP_Def`, `TWP_GO`), `BF_` for BloodFeud leaves' claimed targets
(`BF_ChargeVictim`), group prefix otherwise (`dc_Servant`, `ib_Target`). A shared
name (`Victim`, `SIM`, `PlayerDyn`, `MYRM`) is only ever *read* in `Weight()` unless it
is stashed. `RemoveAlias` what you create, in the same function.

**Properties.** `AI_<Thing>` for state, `AITWP_<Axis>` for the mod's priority axes,
declared in `BLACKBOARD_KEYS` before first use. Indexed keys end in `_` or a stem
(`AI_Reserve_`, `AI_Courier`) and are declared `prefix = true`.

**Knobs.** `TWP_<NAME>` in `aitwp.lua`, `UTILITY_<NAME>` in `utility.lua`, declared
beside the code that reads them with the comment saying what moving them does.

**Telemetry.** `::TWP::<CHANNEL>` then `key=value` pairs, one line per decision,
inputs to two decimals - the analyzer's replay tolerance (2% of weight) is sized to
that.

**Measures.** Unchanged vanilla convention `ms_<NNN>_<Name>.lua`, mod additions
`ms_twp_<Name>.lua` or `ms_bf_<Name>.lua`. A measure is the action layer: it moves,
waits, and joins battles; it does not decide.

**Tools.** `tools/modding_helpers/<verb>_<noun>.py|lua`: `gen_*` writes to `meta/`,
`check_*` exits non-zero on a defect, `ai_*` reads a log, `basetree_stats.py` does
both. Every non-trivial helper leaves one check behind in `check_utility.lua`.

---

## 4. Which approach, per area

| area of the game | approach | status |
|---|---|---|
| **Which subtree / leaf / tool right now** | Utility (§2.1) inside the engine's selector | done, keep |
| **What the house is *for* this week** | Goal blackboard (§2.2) | done; goals re-chosen every 72h, watch item |
| **Whether a hostile act is allowed at all** | Feasibility ladder (§2.3) - a filter, not a score | done |
| **Who / what to hit** | Scored pickers (§2.4), deterministic | done |
| **Whether a fight is worth starting** | Prediction (§2.5), not planning | done, 0.75 bar to tune |
| **Multi-step schemes**: procure -> deliver -> equip / hand over -> strike; forge -> charge; recruit -> gather -> attack | **HTN**, thin: abstract tasks with ordered methods and preconditions; the leaves stay as they are and become the primitives; utility still scores *within* the chosen chain | **next** - see below |
| **Shared AI state** | Blackboard (§2.6) | done; migrate remaining bare `GetProperty("AI_…")` reads opportunistically |
| **Economy / businesses** (upcoming) | Utility for *what* to build, buy, produce, price; scored pickers for *which one of ours*; the existing `AI_Reserve_` / turnover properties become registered blackboard keys | not started |
| **Where** to build, camp, expand; which town to work | **Influence maps** over settlements and roads, replacing `TWP_TOWN_RADIUS` and per-town dice | later; `TownRadius` is the placeholder |
| **Politics, elections, trials** | Utility (already scored: Election, Trial, ApplyForOffice) | done |
| **Diplomacy, grudges, who is the enemy** | Blackboard + attitude ladder + `aitwp_GetBestEnemy` | done |
| **Per-sim moment-to-moment** | Engine FSM + needs (§2.9) | vanilla, leave |
| **Multiplayer determinism** | No `Rand` in `Weight()`; ties to the lower index; if a decision must roll, roll from a seeded stream and log it (`AI_RESEARCH.md` phase 2) | 23 nodes still roll in `Weight()`, dice-by-design, not blocking |

**HTN, the plan.** New `Scripts/Library/aihtn.lua` (prefix `aihtn_`): a table of ~4
abstract tasks (`Harm`, `HaveItem`, `HaveFighters`, `HaveEvidence`), each with 2-3
ordered methods `{ when = precondition, do = subtasks }`, primitives naming existing
leaves. One decomposition per entry into `BloodFeud.lua`. Preconditions are the
supply helpers that already exist and already return booleans (`aitwp_Residence`,
`InStore`, `StockCount`, `CanHandOver`, `EquipmentTier`). Payoff is a `::TWP::HTN`
line naming the task, the method, and *which precondition failed* when none applied
- the class of silent chain death the residence bug was, made into a log line. ~150
lines plus the table. It narrows the candidates; it does not replace the scorer.

**Not used, and why.** *Behavior Trees*: priority order must be hand-maintained across
233 nodes, and the measure system already sequences. *GOAP*: A* over preconditions
needs a clean world-state model and costs per tick; HTN gets the diagnostic value
for less. *MCTS*: needs a forward model of the simulation; there is none. *RL*: no
simulator, lockstep determinism, and a black box that cannot be debugged from a log
- the telemetry is fine for *offline* curve tuning, which is the useful 5%. *ECS*:
the engine owns the entities; a second store would be a second truth.

---

## 5. Before changing the AI

1. `python tools/modding_helpers/basetree_stats.py` - exit 0, or fix the hazard.
2. Calling a native the tree does not already call? `meta/engine.signatures.tsv`
   first (`gen_engine_signatures.py` rebuilds it from the exe with rizin). The doc
   dump disagrees with the binary for 108 bindings; the binary wins.
3. New decision -> new telemetry line in the same change, and a parser for it in
   `ai_telemetry.py` if it is more than free text.
4. New key -> `BLACKBOARD_KEYS`. New target resolved in `Weight()` -> stash it.
5. Non-trivial logic -> one check in `check_utility.lua`, negative-tested once.
6. `lua5.1 tools/modding_helpers/check_utility.lua` and
   `python tools/modding_helpers/check_unresolved_calls.py` green.
7. Lua is CRLF. The first Write/Edit on a file is gated; present the facts and retry.

---

## 6. Decisions, dated

- **2026-09-06** Utility scoring over the engine's selector; roulette kept because the
  engine owns it; telemetry from day one (`6779cd0b`, `bccca92b`).
- **2026-09-07** Blood rival supply chain: cart, store, just-in-time hand-over,
  courier; thugs use the plain Attack order (`d88d5d29`).
- **2026-09-08** `GetHomeBuilding` is sim/cart only - fourteen dynasty-alias sites were
  starving every store-dependent node; `aitwp_Residence`. Thief den stored a dynasty
  id as its hijack target and never cleared it. Attack rules: win-chance bar, mixed
  parties, escort counted, legality re-checked on arrival.
- **2026-09-09** Argument arity and class verified against the binary
  (`gen_engine_signatures.py`); `CommandCityGuard` replaces an invented office-level
  knob. Two suspected defects dismissed with evidence (see README backlog).
- **2026-09-10** Blackboard formalised; eight BloodFeud leaves were acting on a
  sibling's target; `basetree_stats.py` gates both hazard classes. HTN scoped to the
  supply chain only. Needs system confirmed live and complementary, not redundant.
