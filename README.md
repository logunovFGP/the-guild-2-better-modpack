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

### Gotchas

- **`logfile.log` is truncated on every launch.** Check its modified time before concluding a
  change did not apply — a stale timestamp means the game never actually started.
- **`git checkout` swaps live game content.** Quit the game before switching branches.
- **Keep CRLF line endings** in `.lua` files, matching the rest of the tree.
- **An unbalanced `"` in a `.dbt` row silently loses that string.** The text system
  cannot parse the row and shows nothing. Three Spanish rows shipped that way. After
  editing a table, check every data row has exactly four quotes.
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
