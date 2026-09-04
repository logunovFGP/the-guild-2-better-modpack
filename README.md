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

Reaching the main menu is enough to run the startup scripts — no save needs loading.

### Debugging

`LogMessage()` is the logging call, used 437 times across `Scripts\`:

```lua
LogMessage("@HUD_REFORGED #W my marker here")
```

It appears in `logfile.log` as `[HUD_REFORGED] my marker here`. The log also records
`[Script] Executing Measures/<name>.lua on <sim>`, useful for watching measures fire during play.

To confirm the junction is actually feeding the engine, add a uniquely-named marker to
`Scripts/GameState/StartScreen.lua` in `Init()`, restart, and search the log for it. A hit
proves the engine read your working tree, since that string exists nowhere else.

### Gotchas

- **`logfile.log` is truncated on every launch.** Check its modified time before concluding a
  change did not apply — a stale timestamp means the game never actually started.
- **`git checkout` swaps live game content.** Quit the game before switching branches.
- **Keep CRLF line endings** in `.lua` files, matching the rest of the tree.
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
