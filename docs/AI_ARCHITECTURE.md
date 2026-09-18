# AI architecture: what we use, where, and what to call it

The decision record for the dynasty AI. Read it before changing anything under
`Scripts/AI`, `Scripts/Library/utility.lua`, `aitwp.lua` or `aiboard.lua`, and
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
       ├─ state + Weight->Execute handoff                 aiboard.lua       §2.6
       ├─ HTN over the feud chain (which leaf, and why)   aihtn.lua         §2.7
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

**A library's basename must not match any other script file's**, in any folder of the
mod *or* the base game. Library files and the object scripts the engine binds by
basename (Buildings among them; the exe formats `%s_%s` for
`cl_GuildObject::RunScriptUnscheduled`) all register `<basename>_<Function>` globals, and
a library whose name is taken is skipped without a word - `Library/blackboard.lua` never
loaded because `Buildings/BlackBoard.lua`, the town notice board, owned the `blackboard_`
prefix. Tree nodes, measures and cutscenes are run by path and may share names with
each other. Check with `find Scripts -iname '<name>.lua'` against both trees before
naming one; `check_unresolved_calls.py` fails on a Library collision. The team met the same
rule for AI nodes in August 2025 (README, "Stability and AI Development Notes"); this is it
biting a library, and the checker is what turns a remembered rule into an enforced one.

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

### 2.6 Blackboard - `aiboard.lua`, prefix `aiboard_`

Two mechanisms, one file.

**Keys.** `BLACKBOARD_KEYS` is every `AI_*` / `AITWP_*` property the AI keeps on a
dynasty or sim, with owner and default. `aiboard_Recall(alias, key)` returns the
declared default instead of nil; an unregistered key logs `::TWP::BB unregistered
key` once. `aiboard_Remember`, `aiboard_Forget` complete the set.
`basetree_stats.py` exits 1 on an unregistered key.

**Weight -> Execute handoff.** The engine runs every sibling's `Weight()` before the
winner's `Execute()`, so an alias resolved in `Weight()` belongs to whichever
sibling ran last. Any node that resolves a target in `Weight()` and needs it in
`Execute()` files it: `aiboard_Stash("bf_Node", "Victim")` in `Weight()`,
`aiboard_Claim("bf_Node", "BF_MyVictim")` in `Execute()`, `aiboard_Drop` at the
end. `basetree_stats.py` exits 1 on a shared alias two siblings resolve differently
without stashing. The eight BloodFeud leaves that had this bug are the worked example.

Repeat-timer names (`ReadyToRepeat(x, "AI_BF_Supply")`) are **not** blackboard keys:
a separate namespace with its own lifetime, and the checker ignores them.

### 2.7 Supply chain - `aitwp.lua`, and the HTN over it - `aihtn.lua`, prefix `aihtn_`

The chain itself is procedural: `aitwp_ShoppingList` -> `bf_Procure` ->
`ms_bf_FeudSupply` (cart) -> `aitwp_InStore` / `aitwp_DrawFromStock` /
`aitwp_CanHandOver` -> `bf_UseArtefact`. Plus `aitwp_EquipmentTier` ->
`aitwp_FindUnequipped` -> `bf_Equip`, `aitwp_CourierOrders` on difficulty 4-5,
`aitwp_ReturnUnused` daily, `aitwp_MarketReport` for telemetry. The cart shops in each
town at the market or Kontor, then the workshops, then the **resource buildings in the
surroundings** - farms, mills, fruitfarms, rangerhuts, fishing huts - ownerless or
foreign, never its own dynasty's - including shops the blood enemy owns, since the
market is public and the goods are real. There the list is filtered by
`aitwp_WorthBuyingFromEnemy`: the price funds the house the goods will be used
against, so the trade only pays when the damage outweighs the gift.
`TWP_BF_ENEMY_SEVERITY` (3, a forged document) is the floor and
`TWP_BF_ENEMY_GOLD` x severity the ceiling, read from `ItemGetPriceBuy` at that
seller rather than the catalogue value - a shop sets its own price, and that is what
the rival actually collects. Equipment is never bought there: it does them no harm.
`aitwp_SellerStock` counts the same places for the
`MARKET` line, so what the telemetry calls unavailable is what the cart could not buy.
All of it hangs off
`aitwp_Residence(dyn, out)` - native `GetHomeBuilding` first, `aitwp_OwnBuilding`
living-room fallback, because the native is documented for sims and carts only.

`aihtn.lua` plans over that chain. `AIHTN_TASKS` holds two tasks - `Feud` (twelve
methods, one per leaf) and `HaveEvidence` - each a list of methods
`{ name, when = { predicates }, steps = { subtasks } }` in preference order. A
predicate is `{ "Name", fn }`; `Name` is what the log prints when `fn` returns false.
A step names another task or a leaf. `aihtn_Plan` takes the first method whose every
predicate holds, decomposing compounds left to right, and returns the method name;
`aihtn_Step` runs it for `Feud` and files the first leaf of the chain in
`AI_HTN_Step`. `BloodFeud.lua` weighs 0 when that is `"-"`, and `utility_Score`
multiplies the named leaf by `UTILITY_HTN_FACTOR` (x3), logged as `h=step` on the
`W` line - `bf_` nodes only, so no other line moved.

**Soundness**: every predicate on the way to a step is a *necessary* condition of that
leaf's own `Weight()`, so "no method applies" proves every child weighs 0 and the root
may skip the tick. The converse is not claimed - leaves keep incidental gates (a target
in reach, the win chance) - which is why `BloodFeud.lua` keeps its own dampener.
A leaf gate that changes must change its method's `when`; no checker sees that, so the
five treasury thresholds are `TWP_BF_*` knobs read by both, and what artefacts are
usable at all is one `aitwp_ReadyArtefacts` call shared by planner and leaf.

**Necessary is not enough - a method must also be predictive.** Soundness only bounds
what a method may omit; a method that omits too much is sound and useless. Session 4
(2026-09-17) measured it: `Feud.duel` checked `Allowed(duel)` and `FitDuelist` but not
the target, so `bf_Provoke` was named the step **22 times, weighed twice, picked once** -
the x3 on a node that could not fire, and a root that could not skip the tick. Six of the
twelve methods had the same shape, and every one of them was a method whose leaf resolves
a target. The rule that follows: **if the leaf resolves a target, the method resolves it
too.** `aihtn_Targetable` does it for the artefact rows; `attack` carries the win-chance
bar, `razzia` and `building` their building lookup, `duel` both of `bf_Provoke`'s paths
plus the victim's `Get_Insult` cooldown, `taunt` its letter target.

**Method order is preference order**, and it is load-bearing: `aihtn_Plan` stops at the
first method that applies. `artefact` means *use what you have*, so it carries
`ReadyArtefacts>=1`; `restock` (the cart run) is deliberately **last**, being the one
method whose leaf does not act on the player at all. An earlier draft had an
unconditional `artefact` decompose through a `HaveItem` task into `bf_Procure`, which
made every solvent house plan a shopping trip while it held evidence and thugs - the
x3 went to the cart every tick. `bf_Procure` still competes on its own weight; the
planner only decides who gets the multiplier.

One compound task, not the four first sketched. `HaveFighters` would have put the
attack's preconditions in front of `bf_Recruit`, which does not have them - unsound,
and it would stop a house hiring below rung 4. `HaveItem` disappeared with the
reordering: it existed only to prepend `bf_Procure` to the artefact chain.

### 2.7.1 What it prints

One `::TWP::HTN` line per changed step, then throttled to `AIHTN_LOG_HOURS` (1):

```
::TWP::HTN t=1234.00 dyn=17 task=Feud method=charge step=bf_ForgeEvidence chain=bf_ForgeEvidence>bf_Charge fail=Feud.artefact:ReadyArtefacts>=1;Feud.building:BuildingArtefact>=1
::TWP::HTN t=1235.00 dyn=17 task=Feud method=- step=- chain=- fail=Feud.artefact:ReadyArtefacts>=1;...;Feud.restock:ShoppingList>0
```

`fail=` is every method that did not apply, as `<task>.<method>:<predicate>` - the
precondition that fell first, for each. That is the payoff: the class of silent chain
death the residence bug was, turned into a log line. `ai_telemetry.py` counts the
reasons and the BloodFeud entries that fired no leaf (85 of 110 before the planner).

### 2.8 Telemetry - `utility.lua`, one switch

`UTILITY_LOG` (nil = follow `[AI] Log` in `configs/config.ini`). Every line is
`::TWP::<CHANNEL> ...` through `utility_Emit`; decision logic never depends on it.

`W` weight · `PICK` · `GOAL` · `ENEMY` · `BLD` · `BELIEVER` · `SNAPSHOT` (daily, per
dynasty) · `MEMBER` · `CART` · `HANDOVER` · `MARKET` · `AI` (free text from
`aitwp_Log`) · `BB` (blackboard) · `HTN` (§2.7.1) · `LOADED` / `ENV` (include probes).

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

**Knobs.** `TWP_<NAME>` in `aitwp.lua`, `UTILITY_<NAME>` in `utility.lua`,
`AIHTN_<NAME>` in `aihtn.lua`, declared
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
| **Multi-step schemes**: procure -> deliver -> equip / hand over -> strike; forge -> charge | **HTN**, thin (§2.7): ordered methods with preconditions over the BloodFeud leaves, which stay as they are and become the primitives; utility still scores *within* the chosen chain | done; the feud only. Widening it to the economy waits for that subtree to be scored at all |
| **Shared AI state** | Blackboard (§2.6) | done; migrate remaining bare `GetProperty("AI_…")` reads opportunistically |
| **Economy / businesses** | Utility for *what* to build, buy, produce, price; scored pickers for *which one of ours*; the existing `AI_Reserve_` / turnover properties become registered blackboard keys. **First task, from the maintainer:** `ToMEconomy/BuyWorkshop.lua` almost never fires - a constant-60 sibling against its constant 8, a cooldown shared with `BuildWorkshop`, and a home-city-only view. Second: the Rogue businesses, the weak set under AI control. | next after the feud verifies |
| **Where** to build, camp, expand; which town to work | **Influence maps** over settlements and roads, replacing `TWP_TOWN_RADIUS` and per-town dice. The engine's pathgrid already carries per-cell weights from the terrain materials (`EnableDrawPath`/`IllustratorsEnabled` show them) - that grid is the natural substrate, not a new one. | when the fork's random-world mode lands (announced for later in 2026); `TownRadius` is the placeholder until then |
| **Politics, elections, trials** | Utility (already scored: Election, Trial, ApplyForOffice) | done |
| **Diplomacy, grudges, who is the enemy** | Blackboard + attitude ladder + `aitwp_GetBestEnemy` | done |
| **Per-sim moment-to-moment** | Engine FSM + needs (§2.9) | vanilla, leave |
| **Multiplayer determinism** | No `Rand` in `Weight()`; ties to the lower index; if a decision must roll, roll from a seeded stream and log it (`AI_RESEARCH.md` phase 2) | 23 nodes still roll in `Weight()`, dice-by-design, not blocking |

**HTN, as built.** `Scripts/Library/aihtn.lua` (prefix `aihtn_`), §2.7: three tasks,
one decomposition per entry into `BloodFeud.lua`, preconditions that are the supply
helpers already returning booleans. It narrows the candidates; it does not replace the
scorer. Two tasks rather than four: `HaveFighters` would have made `bf_Recruit`
unreachable below rung 4, and `HaveItem` fell out when procuring became the last
method instead of the first. `"do"` is a Lua keyword, so a method's subtasks are `steps`.

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
   dump disagrees with the binary for 108 bindings; the binary wins. Using a `GL_*`
   or `MUSIC_*` constant the tree does not already use? Our checker cannot see
   constants - `GL_CLASS_FIGHTER` is documented and does not exist - so confirm it in
   SecondAID's lint or in an existing call site before trusting it.
3. New decision -> new telemetry line in the same change, and a parser for it in
   `ai_telemetry.py` if it is more than free text. Chased a defect down through a log?
   It goes into `CHECKS` in that file as a named check with a literal pointer, so the
   next session reads `--findings` instead of starting the forensics over.
4. New key -> `BLACKBOARD_KEYS`. New target resolved in `Weight()` -> stash it.
5. New library -> one `Include ("Library/<name>.lua")` in `Scripts/Library/stdafx.lua`.
   That list is the only loader; the engine never picks a library up by filename, and our
   `stdafx.lua` replaces the vanilla one wholesale, so a vanilla library it drops is gone
   too. `check_unresolved_calls.py` fails on a called library that no Include line loads.
6. Non-trivial logic -> one check in `check_utility.lua`, negative-tested once.
7. `lua5.1 tools/modding_helpers/check_utility.lua` and
   `python tools/modding_helpers/check_unresolved_calls.py` green.
8. Lua is CRLF. The first Write/Edit on a file is gated; present the facts and retry.

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
- **2026-09-10** `blackboard.lua` never loaded in play: `Scripts/Buildings/BlackBoard.lua`
  owned the `blackboard_` prefix; libraries and basename-bound object scripts share the
  `<basename>_` globals. Renamed to `aiboard.lua` (prefix `aiboard_`);
  `check_unresolved_calls.py` now fails on a Library basename any other script uses.
  Found by the missing `::TWP::LOADED` marker.
- **2026-09-10** Maintainer direction recorded (README, AI backlog): work in this repository
  only; Rogue businesses are the weak set; first concrete task is `BuyWorkshop` never
  firing. Community engine facts recorded: hierarchical pathfinding and its debug overlay,
  the 4 GB address ceiling, SecondAID as the constants-aware lint we lack, the fork's
  random-world mode as the trigger for influence maps.
- **2026-09-14** The rename was only half the cause: `aiboard.lua` was never in
  `stdafx.lua`, under either name (`git log -S` on that file is empty for `blackboard` and
  `aiboard` alike), so the library still did not load and the eight leaves that call
  `aiboard_Stash` in `Weight()` errored and weighed 0. A library is loaded by its `Include`
  line, never by its filename; the basename rule decides whether that line *works*. Same
  sweep: `trade.lua` is vanilla-only and our `stdafx.lua` replaces vanilla's, which Includes
  it - so `trade_IsAlderman`, called in `Weight()` by `Dynasty/AIContractGuildHouse` and
  `Election/FavorAll/fvo_UseAldermanChain`, was nil in both. Inherited from upstream: our
  only `stdafx.lua` commit (`6779cd0b`) added `utility.lua` and nothing else.
  `check_unresolved_calls.py` now fails on a called library with no Include line.
- **2026-09-14** HTN over the feud chain (§2.7): `aihtn.lua`, three tasks, eleven
  methods, one call from `BloodFeud.lua`. `::TWP::HTN` names the method taken and, for
  every method that did not apply, the precondition that fell first. Two departures from
  the 2026-09-10 sketch, both forced by the soundness rule that a method's preconditions
  must be a subset of its leaf's own gates: `HaveFighters` dropped, because it would have
  put the attack's rung and cooldown in front of `bf_Recruit`, which has neither; and
  `HaveEvidence.procure` dropped as dead by construction. To keep the table and the leaves
  from drifting, the five treasury thresholds became `TWP_BF_*` knobs read by both, and
  artefact availability became one `aitwp_ReadyArtefacts` call shared by planner and leaf.
- **2026-09-15** Review of the above: `Feud.artefact` had no preconditions and stood
  first, so it applied whenever a cart could be sent and the x3 landed on `bf_Procure`
  nearly every tick - a solvent house planned a shopping trip while holding evidence,
  thugs and a target. No leaf was starved (the roulette still reached all thirteen) but
  the weighting was not what was intended and `method=` never varied. `artefact` now
  requires `ReadyArtefacts>=1` and procuring is a `restock` method placed last; the
  `HaveItem` task went with it. Method order is preference order - keep the methods that
  act on the player above the one that only buys.
- **2026-09-17** First play session with the HTN (one game day, round 42). Both libraries
  load, no nil calls, zero replay mismatches - but `bf_Provoke` was planned 22 times and
  picked once, because six methods omitted the target lookup their leaf performs. Fixed by
  adding it to all six. The dampener in `BloodFeud.lua` stays: barren entries came in at
  18 of 30, not the near-zero the gate was supposed to buy, because a method applying is
  not the same as its leaf firing. Re-measure after the next session.
- **2026-09-18** Third play session (one game day, round 43). Barren entries 0 of 17, the
  measurement the dampener was waiting for - but the planner reached only `restock` and
  `gang` all day, and the player was never confronted. Every aggressive method failed on
  one precondition each and the `fail=` reason names the predicate without the number that
  missed it: `Feud.duel:InsultableTarget` 189 of 189 (the duel modes of
  `aitwp_PlayerTargetScore` require the target *outdoors*, and the player spent the day
  inside), `Feud.taunt:NotFoe` 189 of 189 (a blood rival is already `DIP_FOE`, so the
  taunt letter is dead by construction in this scenario), `Feud.artefact:ReadyArtefacts>=1`
  189 of 189, `Feud.attack:WinChance>=bar` 113 of 113. So `aihtn_Why` emits `::TWP::WHY`:
  the rung, carried tools and hand-over budget behind the artefact count, and the fighter
  counts and chance behind the win-chance bar. A reason that names a predicate is not
  enough once the predicate is arithmetic - it has to carry the value.
