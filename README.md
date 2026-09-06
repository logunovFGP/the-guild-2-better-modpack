# The Guild 2: Reforged

## About
The Guild 2: Reforged is brand new mod for The Guild 2: Renaissance that enhances gameplay with numerous improvements, additions and bugfixing.

## Manual Installation Guide

### Prerequisites
- A copy of The Guild 2: Renaissance (Steam, GOG, ...)
- Administrator rights on your computer (for copying files to program directories)

### Installation Steps

1. **Download the latest version**
   - [Download](https://gitlab.com/fajeth-modpack/megamodpack-reforged/-/archive/master/megamodpack-reforged-master.zip) the latest `.zip` file here: https://gitlab.com/fajeth-modpack/megamodpack-reforged/-/archive/master/megamodpack-reforged-master.zip

2. **Locate your game installation**
   - Typical Steam locations:
     - `C:\Program Files (x86)\Steam\steamapps\common\The Guild 2 Renaissance`
     - `C:\Program Files\Steam\steamapps\common\The Guild 2 Renaissance`
     - `D:\Steam\steamapps\common\The Guild 2 Renaissance`
     - `D:\SteamLibrary\steamapps\common\The Guild 2 Renaissance`
   - Typical GOG locations:
     - `C:\Program Files (x86)\GOG Galaxy\Games\The Guild 2 Renaissance`
     - `C:\Program Files\GOG Galaxy\Games\The Guild 2 Renaissance`

3. **Extract the mod files**
   - Extract the downloaded zip file to a temporary folder
   - You should see a folder named something like `megamodpack-reforged-master`

4. **Copy mod files to game directory**
   - First, DELETE the "Scripts", "GUI" folders from the original The Guild 2: Renaissance installation.
   - **Skipping the step above will lead to guaranteed Out of Sync error in Multiplayer!**
   - Copy all folders from the extracted directory to your game installation folder

5. **Choose your language**
   - Navigate to the `Translations` folder in the extracted files
   - Choose your preferred language folder (English, German, French, Italian, Spanish, Russian, or Polish)
   - Copy the following from your chosen language folder to your game directory:
     - `config.ini` to the main game directory
     - `DB/Text.dbt` to the game's `DB` folder
     - All files from the `sfx` folder to the game's `sfx` folder


## Local Development Setup (live editing from a git clone)

For contributors. Instead of copying files into the game after every change, mount your
clone into the game's `mods` folder with a directory junction. Script edits then go live
on the next game restart, with no copy step.

**Windows only.** The game ships for Windows, so development and testing happen there; the commands
below are PowerShell.

Requires the **Reforged fork build** of the game — the one with `GuildIILauncher.exe` and a
`mods\` folder (mod architecture 4.67+). The old vanilla layout (`ModLauncher.exe`, mod files
copied over the game root) does not support this; use the Manual Installation Guide above instead.

### 1. Clone

```bash
git clone git@gitlab.com:fajeth-modpack/megamodpack-reforged.git
cd megamodpack-reforged
git checkout modern
```

Development happens on **`modern`**, not `master`. `master` lags behind by months; `modern` is
what the published Workshop build is cut from.

### 2. Remove any Workshop copy of Reforged

Uninstall it in the launcher **and unsubscribe on the Steam Workshop**. An active subscription
makes Steam re-download the mod over your junction.

### 3. Add the packaging files the repo does not track

The Workshop package ships a few files that are not in git. Without `modinfo.txt` the launcher
will not list your clone as a mod at all. Create it in the repo root:

```ini
[ModInfo]
Name=Reforged
Author=Nauno
Version=1.68
Description=Local development build.
ModArchitecture=4.67
```

Optional: `preview.png`, `background.png`, `screenshots/`, `configs/config.ini`. If you still
have a Workshop install, copy them out of it before uninstalling.

Keep these out of commits with `.git/info/exclude` (local-only, unlike `.gitignore` which is
tracked and would show up in merge requests).

### 4. Create the junction

PowerShell, with `mods\Reforged` not present:

```powershell
New-Item -ItemType Junction `
  -Path "<game>\mods\Reforged" `
  -Target "<path-to-your-clone>"
```

A junction needs no administrator rights, but both paths must be on local drives.
Verify:

```powershell
Get-Item "<game>\mods\Reforged" | Format-List Name,LinkType,Target
```

`LinkType : Junction` confirms it.

### 5. Activate

Launcher → **Mods** → Reforged → **ACTIVATE**. It activates as a local mod, with no Workshop
link. `mods\modlist.txt` should read `Reforged = 1`.

### Development loop

1. Edit a `.lua` under `Scripts\`
2. Quit the game, relaunch via `GuildIILauncher.exe`
3. Check `logfile.log` in the game root

`tools\ReloadScriptTg2r.exe` can hot-reload `*.lua` in a running game instead, which
needs `[DEBUG]` with `AID = 1` and `ScriptDebugger = 1` in `configs\Reforged\config.ini`,
and the exe must sit in a direct subfolder of the game. **Database edits are not
hot-reloadable** — any `.dbt` change needs a full restart; reaching the main menu is
enough.

Reaching the main menu is enough to run the startup scripts — no save needs loading.

### Debugging

`LogMessage()` is the logging call, used 437 times across `Scripts\`:

```lua
LogMessage("@HUD_REFORGED #W my marker here")
```

It appears in `logfile.log` as `[HUD_REFORGED] my marker here`. The log also records
`[Script] Executing Measures/<name>.lua on <sim>`, useful for watching measures fire during play.

Reading the log from PowerShell — there is no `grep` on Windows:

```powershell
Select-String -Path "$env:GUILD2\logfile.log" -Pattern 'HUD_REFORGED'
Get-Content "$env:GUILD2\logfile.log" -Tail 40
Get-Content "$env:GUILD2\logfile.log" -Wait -Tail 20    # follow it live
```

Set `$env:GUILD2` to your game folder once per session, or substitute the full path.
`Select-String` is the closest equivalent to `grep`; `sls` is its alias.

To confirm the junction is actually feeding the engine, add a uniquely-named marker to
`Scripts/GameState/StartScreen.lua` in `Init()`, restart, and search the log for it. A hit
proves the engine read your working tree, since that string exists nowhere else.

### Database tables (`.dbt`)

`DB\*.dbt` are the engine's data tables: plain text, whitespace separated, one row per
line, each terminated by `|`. A mod ships **override** copies that the engine merges
over the base tables in the game folder.

```
//Table File, Version 1.02 (c) 2004 4head studios

Table Description:
"id" INT -1 |"name" STRING 0 |"observerrange" INT 0 |

Data:
21   "pickpocket"   300   |
```

- `~` in a cell means **inherit the base table's value**, so only cells you actually
  change need a real one.
- Rows absent from the base table are **added**, so a mod can introduce new actions,
  measures and memory events rather than only retuning existing ones.
- The key column is not always `id`. `Action.dbt` is keyed by **`name`** -- the engine
  builds a `std::map<cl_String, cl_ActionData>` from that column, so action ids have no
  ceiling and no bearing on lookup.
- Database edits are **not hot-reloadable**; restart as far as the main menu.

Encoding is unforgiving. Most tables are ASCII with CRLF; the `DB\Languages\**\Text.dbt`
files are UTF-16LE with a BOM and must stay that way. Never write a `.dbt` through a
text-mode `encoding=`; round-trip the bytes instead:

```python
raw = open(path, "rb").read()
open(path, "wb").write(raw.replace(old, new))
```

### Gotchas

- **`logfile.log` is truncated on every launch.** Check its modified time before concluding a
  change did not apply — a stale timestamp means the game never actually started.
- **`git checkout` swaps live game content.** Quit the game before switching branches.
- **Keep CRLF line endings** in `.lua` files, matching the rest of the tree.
- **Python needs the `G:/` drive form** for game paths, not git-bash's `/g/`. A
  `/g/...` path makes `os.listdir` and `glob` return nothing silently, so an
  offline scan of the game files can look like a negative result when it never ran.
- **An unbalanced `"` in a `.dbt` row silently loses that string.** The text system
  cannot parse the row and shows nothing. Three Spanish rows shipped that way. After
  editing a table, check every data row has exactly four quotes.
- **A UTF-8 BOM at the top of a `.dbt` silently deletes the entire table.** The parser
  expects `Table Description:` on line 1; with a BOM that line reads
  `\xEF\xBB\xBFTable Description:`, fails to match, and the whole file is discarded --
  every override row and every added row with it, and nothing in the log. This cost an
  entire evening: `Action.dbt` acquired one from a script that rewrote it with
  `encoding="utf-8-sig"`, after which a new crime action silently did nothing while
  action id, observer range, observation window, committer type and observer-script
  location were each eliminated as suspects in turn. Check the first three bytes:
  `546162` (`Tab`) is a healthy table, `efbbbf` is a dead one. Language `Text.dbt`
  files are the exception -- UTF-16LE, and they keep their `fffe` BOM.
- The repo is large (~1.2 GB of history, no LFS). A shallow clone helps if you do not need history.

### Contributing

Non-members cannot push to the upstream project, so merge requests come from a personal fork.
Keep `origin` pointed at upstream for pulling, and push to your fork:

```bash
git remote add fork git@gitlab.com:<you>/megamodpack-reforged.git
git checkout -b my-change modern
git push -u fork my-change
```

Then open the merge request against `fajeth-modpack/megamodpack-reforged:modern`.

### Scripting language: Lua 5.1

Everything under `Scripts\` is Lua. The engine embeds **Lua 5.1** for its backend
game scripting, so that is the dialect every measure, library and AI script must be
written in.

**Syntax rule: stick to standard 5.1.** Anything from a later version fails to parse
and the script simply does not load. The usual offenders:

| Do not use | From | Write instead |
|---|---|---|
| `//` integer division | 5.3 | `math.floor(a / b)` |
| `&` `\|` `~` `<<` `>>` bitwise operators | 5.3 | arithmetic, or a lookup table |
| `goto` / `::label::` | 5.2 | a flag and an `if`, or restructure the loop |
| integer/float distinction, `math.type` | 5.3 | there is one number type |
| `table.unpack`, `table.pack` | 5.2 | `unpack(t)` |
| `\z` escape in long strings | 5.2 | concatenate |
| `#!` shebang tolerance, `_ENV` | 5.2 | `setfenv` |

`%` and `math.fmod` behave as in 5.1. No script in this repo uses `os`, `io`,
`require`, `dofile` or `loadfile` — treat them as unavailable rather than testing it
in a live game. The engine adds its own global functions on top of the standard
library; those are documented in `ScriptDocumentation.html` and generated into
`meta/engine.d.lua`.

#### Installing Lua 5.1 (optional, for local syntax checking)

You do not need Lua installed to play or to edit scripts — the game brings its own
interpreter. Install it only to syntax-check a file before launching, which is much
faster than restarting the game to find a typo.

**Windows, via winget:**

```powershell
winget install DEVCOM.Lua
```

**Windows, via Scoop or Chocolatey:**

```powershell
scoop install lua
choco install lua51
```

**Windows, prebuilt binaries:** download `lua-5.1.5_Win64_bin.zip` from
<https://luabinaries.sourceforge.net/download.html>, unzip somewhere permanent and add
that folder to `PATH`.

A `[Environment]::SetEnvironmentVariable("Path", ..., "User")` edit does **not** reach
shells that are already open — start a new one, or call the exe by full path until you do.

Verify you got 5.1 and not 5.4; a 5.4 parser accepts `//` and would defeat the point:

```powershell
lua -v
```

Expected: `Lua 5.1.5  Copyright (C) 1994-2012 Lua.org, PUC-Rio`. The LuaBinaries zip
ships `lua5.1.exe` and `luac5.1.exe`; copy or symlink one to `lua.exe` if you want the
short name.

Then check a script without launching the game:

```powershell
luac5.1 -p Scripts\Measures\ms_011_AssignToLaborOfLove.lua
```

`-p` parses and reports errors without writing any output, exiting non-zero on a
failure. It catches syntax errors only, not unknown engine functions; for those use the
editor setup below. The generated declaration file is checked the same way:

```powershell
luac5.1 -p meta\engine.d.lua
```

#### Editor completion for the engine API

`.luarc.json` in the repo root points the
[lua-language-server](https://github.com/LuaLS/lua-language-server) at
`meta/engine.d.lua`, a declaration file generated from `ScriptDocumentation.html`:

```powershell
python tools\modding_helpers\gen_engine_meta.py
```

That gives completion, parameter hints and a warning on misspelled engine calls in any
editor with the Lua extension installed. `runtime.version` is set to `Lua 5.1`.
`meta\` sits outside `Scripts\`, so the engine never loads it.

The dump is incomplete, so a second tool reads the API straight out of the binary:

```powershell
python tools\modding_helpers\gen_engine_bindings.py
```

It walks the engine's Lua registration calls and writes `meta\engine.bindings.tsv`
(name, native address, whether the dump documents it). The current build registers
**1048** functions; `ScriptDocumentation.html` describes 764, of which 697 match. So
**351 engine calls are real but undocumented** -- `BuildingGetRoom`,
`BuildingIsWorkingTime`, `BlackBoardAddPamphlet` and the whole `CC_*` character-creation
family among them. Treat the TSV as ground truth and the dump as commentary.

It also writes `meta\engine.undocumented.d.lua`, giving those 351 completion and
parameter hints. There are deliberately no descriptions: nothing in the binary says
what they mean. What is recovered is mechanical -- native address, the `.cpp` file and
line, arity, each parameter's type, and which are optional -- by decoding the typed
argument-fetch calls each native makes.

Running the same recovery against 60 *documented* natives and comparing with the dump
measures how far to trust it: arity correct 53/60; across 111 parameter positions,
7 genuine type disagreements (6%) plus 9 more where the dump says `any` and the
recovery is the more specific of the two; optional flags agree 97/107. No `@return`
is emitted, because the likeliest return-pusher also correlates with Alias parameters.
95 stubs are `(...)` rather than `()` -- their parameters could not be read, and
declaring them as taking none would make the language server reject correct calls.

#### Resizing a GUI panel

The `.gui` files under `GUI/` are binary serialised, so a window's size cannot be edited
there. It can be changed on the live node tree instead, which is what
`Scripts/Library/guilayout.lua` does -- it is what stops long action descriptions being
cut off mid-sentence.

```lua
guilayout_GrowHelpPanels()                       -- every help window, default headroom
guilayout_GrowHelpPanels(200)                    -- ... with more

local Panels = guilayout_FindPanelsByTexture(GL_HUDROOT, "onscreenhelp/bg")
guilayout_GrowPanel(Panels[1], 120)              -- one window
```

Four things about this engine are worth knowing before trying it on another panel, all
verified in game and all of them cost a run to learn:

- **`ABS_HEIGHT` and `ABS_WIDTH` are the only geometry properties that carry a value.**
  `HEIGHT`, `WIDTH` and `ABS_YPOS` read 0 on every node.
- **`RESIZE` and `SHOW_VERTICAL_SCROLLBAR` do nothing.** Both read back changed and
  neither has any effect -- no fitting to content, no scrollbar. The engine consults them
  when it builds a panel and never again. **A property reading back changed proves only
  that the store accepted it**, which is the trap: it looks exactly like success.
- **A window is three siblings, each holding its own height.** The panel, the bordered
  frame (`cl_WinContainer`, the same height as its panel) and the text (`Label` or
  `Desc`). Growing the panel alone just exposes its backdrop below the border. All three
  have to be set.
- **Changes are per-session** and gone on restart, so they must be re-applied at
  `HudInit` -- and a bad write is undone by quitting.

Finding a specific panel is the hard part: a panel takes `NODE_NAME` from its `.gui`, so
all thirteen help windows are plain `Container`; the `AddPanel` order does not map onto
the `HudRoot` child order; and `measures.gui`, `items.gui` and `upgrades.gui` share every
extractable string. Identify a *cohort* by texture instead of trying to single one out.

```powershell
lua5.1 tools\modding_helpers\check_guilayout.lua
```

That runs the layout rules against node trees dumped from a real game, with no engine
needed -- the node API is four getters and two setters, so a plain table stands in. Set
`GL_GUILAYOUT_VERBOSE = true` to log every node touched in game.

### Other checks

```powershell
lua5.1 tools\modding_helpers\check_divegetalc.lua
```

Covers the contraband run in `ms_021_DiveGetAlc.lua`: that seizure risk falls with the
owner's Shadow Arts but never reaches zero, and that the price and shipment clamps hold.
The price formula divides a skill by 100 and doubles it, so without a cap a high enough
Bargaining made the liquor free and then negative -- that bound is asserted here.

```powershell
lua5.1 tools\modding_helpers\check_ai_decision.lua
```

Covers `ai_MakeDecision` in `Scripts/Library/AI.lua`, the personality roll behind AI
bribe and trait decisions: both paths return a real boolean (the one-trait path used to
return `0`, which Lua treats as true, so every bribe was accepted), the one-trait path is
a percentage of `AIPersonality.dbt`, and a missing column counts as 0 instead of erroring.

```powershell
python tools\modding_helpers\check_basetree_weights.py
```

Every node under `Scripts/AI/BaseTree` must define `Weight()` and `Execute()`, and
`Weight()` must return a number. The engine selects a child by **weighted random**
(`AIWeightedRandom.h` in `GuildII.exe`): a weight is a probability share, not a priority,
`0` means ineligible, and `return false` is undefined behaviour. Four nodes shipped that way.

### AI decision layer: telemetry, utility scoring, goals

The dynasty AI is the weighted-random tree under `Scripts/AI/BaseTree` (see
`check_basetree_weights.py` above). Three pieces sit on top of it, and one game
session collects everything needed to tune them.

**Collecting a session.** The game truncates `logfile.log` on every launch, so first
copy the log of the run you want as a baseline. Then set `Log = 1` under `[AI]` in
`configs\config.ini` (or `AILog = 1` under `[OPTIONS]`, the section the campaign scripts
are known to read). Pre-flight: launch to the main menu and check `logfile.log` for
`::TWP::LOADED` (the library is in) and `::TWP::ENV` (which stdlib exists); if `LOADED`
is missing, fix the Include before playing. Then load a save on difficulty Hard that is
past the AI truce (a few rounds in): `Feud/AttackBuilding` and the gauntlet nodes gate
on difficulty >= 2, and `aitwp_InitEnemies` assigns no enemies before the truce ends, so
a fresh easy game never exercises the Conflict paths. The first `::TWP::SNAPSHOT` lines
report `round=` and `diff=`, so a wrong save shows within the first game day. Play at
least three game days, then run

```powershell
python tools\modding_helpersi_telemetry.py
```

It reads `$env:GUILD2\logfile.log` (or a path you pass) and prints: whether
`utility.lua` loaded and what the engine's Lua stdlib offers; each dynasty's daily
snapshot (money, buildings, offices, enemies, priorities, goal, evaluations per day)
with the change over the session; how often the tree ticks; goal choices per persona;
measure starts per goal; the target decisions; and, for every level of the tree, the
observed pick share next to the share **predicted under six tuning variants**
(current, wide, narrow, stronger goals, no goals, the old constants). Every
`::TWP::W` line carries the raw inputs of `utility_Score`, so the roulette is replayed
offline for any `UTILITY_LO/HI` or goal factor - the tuning question is answered from
the one log instead of one run per value. `--selftest` exercises the parser on a
built-in sample.

Line types (all prefixed `[Script] `): `::TWP::LOADED`, `::TWP::ENV`, `::TWP::SNAPSHOT`
and `::TWP::MEMBER` (daily), `::TWP::GOAL` (each goal choice) are always on;
`::TWP::W`, `::TWP::PICK`, `::TWP::ENEMY`, `::TWP::BLD`, `::TWP::BELIEVER` and the
`::TWP::AI::` trace need `Log = 1`. The exact fields are in the docstring of
`ai_telemetry.py`. Without `Log = 1` a sample pre-change session showed 78% of AI
measure starts idle - that is the number to beat.

**Utility scoring** (`Scripts/Library/utility.lua`). A node keeps its tuned base weight
and multiplies it by considerations in 0..1, each mapped onto a 0.5..1.5 factor, then
by the goal factor; the tag names the node in the trace:

```lua
return utility_Score("dynasty", 20, {
	utility_Priority("dynasty", "Political"),   -- AITWP_* priority as 0..1
	utility_Trait("dynasty", "ambition"),        -- AIPersonality.dbt column as 0..1
	{ value = utility_Money("dynasty", 20000), curve = "quad" },
}, "ApplyForOffice", "Politics")
```

Curves: `linear` (default), `quad`, `sqrt`, `invert`. A node that stays a constant
wraps it as `return utility_Trace("dynasty", "BuildHome", 5)` and every node starts
`Execute()` with `utility_Picked("dynasty", "<Tag>")`, so the whole sibling set of a
level is on record. Never call `Rand` inside a consideration: the tree runs in
lockstep on every multiplayer peer, and nothing in the telemetry may touch game state.

**Goal blackboard.** `utility_ChooseGoal`, called daily from `Priorities.lua`, writes
`AI_Goal`, `AI_GoalTarget` and `AI_GoalUntil` on the dynasty and logs its inputs and
scores. Nodes that name a goal get x3 when it is the current goal, x0.3 otherwise, x1
when none is set; a goal lasts 72 game hours (`UTILITY_GOAL_HOURS`).

Targets in the Feud, Election and economy subtrees are chosen by score, not dice:
`aitwp_GetBestEnemy`, `aitwp_FindTargetBuilding` and `aitwp_FindBeliever` in
`Scripts/Library/aitwp.lua`, each logging its full candidate list so another ranking
rule can be tried against the same session. Ties fall to the lowest index so every
peer agrees.

```powershell
lua5.1 tools\modding_helpers\check_utility.lua
```

covers the curves, the goal argmax, both target rankings and every telemetry line
format without the engine.

### House rules and the blood feud

Behaviour the dynasty AI now follows, and where each rule lives:

| rule | where |
|---|---|
| Every child is educated: school, then the apprenticeship, university for scholars. Mandatory, weight 200 in `Dynasty/`, feasibility-checked in `Weight()` so no pick is wasted. | `Scripts/AI/BaseTree/Dynasty/EducateChildren.lua` |
| A house has a main class (`AI_MainClass`, its founder's) that its children are apprenticed into and its workshops are built for; rogue businesses only for a rogue house. It always keeps one rogue as its fighter (two as a blood enemy). | `aitwp_MainClass`, `aitwp_WantedApprenticeClass`, `aitwp_FindBuilder`; `ms_150_AttendApprenticeship.lua` reads `AI_ApprenticeClass`; `BuildWorkshop/Rogue.lua` |
| Three children: a young couple gets 30 days for their own, then adopts (`AI_NaturalTryUntil`). | `Dynasty/Reproduce/AdoptOrphan.lua` |
| Enemy lists come from relations, daily: blood target, trade rival, declared foes, dynasties disliked (favour < 30), capped at 5. No more random re-roll on load. | `aitwp_RefreshEnemies` from `Priorities.lua` |
| One coloured AI dynasty per human player is that player's **blood enemy** (`AI_BloodEnemy` on the player, `AI_BloodEnemyOf` on the AI; deterministic, re-assigned when it dies). Its goal is Conflict for life; the player outranks every other enemy. | `aitwp_EnsureBloodEnemies`, `utility_ChooseGoal`, `aitwp_GetBestEnemy` |
| The blood enemy runs the `BloodFeud` subtree (root weight 60): provoke duels by insult - never with martial arts and dexterity both under 5 or under 80% health, always against non-rogues, rogues on a daily 1-in-4 roll; forge evidence (Hexerdokument, bought at the market) against the player's most valuable character, fixed until charged; charge; razzia with a thug at evidence >= 35; ambush characters and employees outdoors away from town with every idle thug; keep 2 + title thugs; equip members, thugs and employees by title and treasury. | `Scripts/AI/BaseTree/BloodFeud.lua` and `BloodFeud/bf_*.lua`; helpers in `aitwp.lua` |
| The same duel rule governs accepting: an AI insulted by a player declines a duel it would die in; a blood enemy insulted by its player always takes satisfaction. | `ms_055_InsultCharacter.lua` `AIDecide` |

Property schema: `AI_MainClass` 1-4, `AI_ApprenticeClass` 1-4 on the child, `AI_NaturalTryUntil` game
hours, `AI_BloodEnemy` / `AI_BloodEnemyOf` dynasty ids, `AI_EvidenceTarget` sim id, `AI_BF_DuelRogues` 0/1.
The assignment is logged once as `::TWP::BLOODENEMY player=<id> enemy=<id> name=<dynasty>`; the
`BloodFeud/` level appears in the replay tables of `ai_telemetry.py`.

### Attitudes and the ladder of tools

Every AI dynasty holds an **attitude** towards each human player (`aitwp_Attitude`):
`blood` (its assigned rival), `feud` (a declared feud), `enemy` (in its enemy list or
favour under 30), `friend` (favour 70+, friend-for-now: a courtesy now and then, never
an alliance - `aitwp_PlayerPolicy` breaks one daily) or `neutral` (nothing). The blood
rival is one coloured dynasty per player, re-assigned from the coloured ones when it
dies and from the shadows only once every coloured one is gone.

Tools against a player unlock on a **ladder** (`TWP_TOOL_LIST` in `aitwp.lua`): rung 0
Serf/Commoner (title 1) ... rung 8 Prince (title 13+), and a rung also needs that many
rounds played, so the whole arsenal is open by round 8. Each tool has a class - R
reputation, E economic, P physical, L legal, O office power, D diplomatic recruitment -
and an attitude may use only its classes: blood everything, feud and enemy E/P/L/O
(no reputation attacks, no recruiting), lethal tools only in a declared feud, shadows
never lethal and never above rung 4. `aitwp_Allowed(dyn, victim, tool)` is the single
gate: every hostile leaf of `Feud/`, `Election/AttackOffice`, `Trial/AttackTrial`,
`Duel/AttackDuel`, the `BloodFeud/` nodes and the thieves' and robbers' building
plans call it; against AI victims it always answers yes. Office powers sit on the same
ladder. Cooldowns are per acting character, not per house.

The blood rival additionally buys through a thug (`bf_Procure`, 7% of cash, 15% at
rung 8, treasury >= 100k; `bf_Stock`/`bf_Draw` move the items home and to the user),
acquires a thieves' guild as its hideout whatever its class (`bf_Hideout`), taunts by
letter, funds its allies, and uses every artefact of the ladder through
`bf_UseArtefact`/`bf_UseBuildingArtefact`. The snapshot line carries `att=` and `rung=`.

### Item catalogue

[docs/ITEMS.md](docs/ITEMS.md) lists every item with its producer, the market that stocks it (and
from which town level) and its in-game effect. Regenerate after touching `DB/Items.dbt`,
`DB/BuildingToItems.dbt`, `DB/ItemsToMarket.dbt` or the item texts:

```powershell
python tools\modding_helpers\gen_items_md.py
```

### AI analysis tools

Everything the first session review needed, kept as tools so no session has to
reinvent them (all under `tools\modding_helpers`, all read-only):

| tool | question it answers |
|---|---|
| `python ai_telemetry.py [log]` | Session summary and the weighted-random replay under six tuning variants (see above). `--selftest` runs it on a built-in sample. |
| `python ai_focus.py [log] [--dynasty ID\|name] [--family Barker]` | Who lists a dynasty as an enemy and what they did about it; enemy-list churn per save load; per-subtree conversion of root picks into leaf measures; hostile measure starts by actor. Defaults to the human player (the one id in enemy lists with no AI snapshot). |
| `python check_unresolved_calls.py [paths] [--overlay DIR]` | Static: every call in the tree and the libraries resolves to a native, a builtin, a same-file function or `<file>_<Function>` in the repo or the vanilla `Scripts` overlay. Exit 1 otherwise - an unresolved call in `Weight()` is a node that silently weighs 0. |
| `python basetree_stats.py [--list CATEGORY]` | Shape of the tree: constant vs. `utility_Score` vs. `utility_Trace` weights, and hazards inside `Weight()` (writes to the shared `SIM` alias, non-local assignments, `Rand`, use of personality inputs). Tracks the conversion. |
| `python check_basetree_weights.py` | Every node has `Weight()`/`Execute()` and never returns a boolean weight. |

The two log tools need a session recorded with `Log = 1` (see the telemetry section);
the two static tools run on the working tree. Python on Windows needs `G:/...` paths.

### Parse-checking every script

```powershell
Get-ChildItem Scripts -Filter *.lua -Recurse | ForEach-Object { luac5.1 -p $_.FullName }
```

Silence means all 987 files parse. Worth running before any commit: a measure with a
syntax error simply never loads, with no error surfaced in game, and counting `function`
against `end` by eye does not catch a dangling expression.

## Usage

### Configuration
You can edit the game's configuration files manually:

- `config.ini` - Main game configuration 
- `userconfig.ini` - User-specific settings

## Troubleshooting

If you encounter issues after installation:

1. **Verify game files**
   - If using Steam: Right-click the game → Properties → Local Files → Verify integrity of game files
   - If using GOG: Right-click the game → Manage installation → Verify/Repair
   - Reinstall Reforged

2. **Language issues**
   - Make sure you've copied the correct language files from the Translations folder

### Known baseline log noise

These lines appear in `logfile.log` on a clean run and are **not** caused by the mod's
scripts. Recorded so they are not re-investigated:

- `[HUD] Error at HudInit::LoadPanels`
- `[subsystem] Shader Error : Failed to find shader BUILDING_LIGHT2` and `BUILDING_GLOW2`
- `[HUD] Panel with the name KontorPanel already exists`, followed by two groups of
  `Substitutioncommand %1i` / `%1t` errors. That string is in **no shipped table** — all
  twelve language files, the vanilla English table and the vanilla `Kontor.dbt` were
  searched — so it is generated engine- or GUI-side and cannot be fixed from the mod.
- `[StartMeasure] <sim>: Canceled 'UseLaborOfLove'(60) because of priority
  'UseLaborOfLove'(60)`, repeating dozens of times per session. A measure cancelling
  itself at equal priority; worth a look on its own.
- Unescaped literal `%` is widespread in the **vanilla** English text table (dozens of
  rows, e.g. `_ADMINSET_TIP_REPAIR_+0` and several `_ABILITIES_*`). Each logs a
  substitution error when it renders. Only rows the mod owns have been fixed.

## Stability and AI Development Notes

Recent years of multiplayer AI development exposed instability from the introduction of a new decision-tree path for AI dynasties.

The team found that AI script files must have unique names and this was fixed around August 2025, after a major stability effort by `naonauno`.

After that, a long bug-hunt followed: first for smaller defects and then for cases that eventually caused certain CTD or OOS failures. `Paweł` identified a key cause after tracing compiled game code: circular marriages. The game engine handles this poorly and may only fail later, so those states should be avoided. For context, search Discord for **`Bramblebee`**.

By fixing this and related issues, Reforged is now one of the most stable versions of TG2R we have had. In practical terms, vanilla appears more stable because its AI performs fewer actions and thus triggers fewer risky state combinations.

Active development happens on the `modern` branch. `master` is kept as an older reference point and lags behind it. Published builds are cut from `modern`, so that is the branch to base work on. We do not run long test cycles on every change. If you encounter issues, report them. If a version is stable for your setup, stay with it unless you intentionally want later changes.

There is no formal roadmap or big-picture plan at the moment. Development stays focused on bugfixes and occasional QoL features, which remains the core philosophy of Reforged.

## Updates

Stay updated with the latest changes:

- Visit our [GitLab repository](https://gitlab.com/fajeth-modpack/megamodpack-reforged) regularly
- Check the commit history for recent changes and improvements

## Credits

The Guild 2: Reforged Modpack is maintained by the Reforged Team.
