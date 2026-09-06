# Source Recovery Plan (Decompilation + Reconstruction)

## Purpose and Scope
This document defines a practical, evidence-first process for analyzing native binaries used by The Guild 2: Renaissance in support of AI synchronization research. It covers:
- native binary inventory verification,
- decompilation and symbol recovery,
- source reconstruction hypotheses,
- and feasibility assessment for source-backed recompilation.

The intent is research and engineering clarity, not guaranteed byte-for-byte rebuild of the shipped game executable.

## Why this is separated
`AI_RESEARCH.md` now remains focused on runtime synchronization architecture and gameplay-behavior risk. All reverse/source-recovery mechanics below are isolated in this file.

## Exact setup tasks (do in this order)

1. Install core runtime dependencies (base tools only)
   - Install **Git** (required for tool/repo installs).
   - Install **Java 17 JDK** (required by Ghidra).
   - Install **Python 3.11+** (required for scripting helpers and corpus tooling).

2. Install analysis platform: Ghidra + optional assistant plugins
   - Install **Ghidra** from official NSA/Ghidra release.
   - Install **Ghidrathon** if you need Python 3 scripts in Ghidra:
     - repo name: `Ghidrathon` (Ghidrathon project)
     - add release/plugin to Ghidra extension folder for your version.
   - Install **GhidraGPT** if you want LLM annotation/summarization inside Ghidra:
     - repo name: `GhidraGPT` (`weirdmachine64/GhidraGPT`)
     - add it as a Ghidra extension plugin.
   - Important: these are assistant layers only, not final source of truth.

3. Install CLI/disassembly stack
   - Install **rizin + Cutter**.
   - Install **radare2 / r2pipe**.
   - Install `sigcheck` and `strings` (Sysinternals + any `strings` implementation).
   - Install `Dependencies` (modern Dependencies GUI) for import/export graphing.
   - Optional (licensed): install **IDA Pro** and/or **Binary Ninja**.

4. Install native metadata helpers
   - `pefile`, `capstone`, `lief` Python packages.
   - Optional symbol helpers: PDB/WinDbg tools where available.
   - Keep one folder for all manifests and notes:
     - `source_recovery/tools/` (zips, docs, hash manifests)
     - `source_recovery/reports/` (tool outputs)

5. Compile/compatibility toolchain setup (only if attempting native recompilation)
   - Install **Visual Studio Build Tools** for a modern x86/x64 C++ toolchain (lowest-level baseline).
   - If full byte-match rebuild is required:
     - source/ABI mismatch is expected because game binaries are legacy MSVC-era (`0x014C`, `msvcr71/msvcp71/MFC71/stlport`).
     - you will likely need legacy Microsoft compiler-compatible environment, not only modern MSVC/clang.

6. Snapshot and verify installation
   - Capture:
     - binary hash manifest,
     - file list and versions,
     - dependency graph,
     - PE architecture.
   - Use this as the immutable baseline before decompiling any target file.

### Exact extension install procedure (Ghidra plugins)

- For both `Ghidrathon` and `GhidraGPT` use this same install path pattern:
  - Open your user extension folder:
    - `"$env:USERPROFILE\\.ghidra"` (PowerShell)
    - Inside it choose the active version folder, e.g. `ghidra_<VERSION>` and then `extensions`.
  - Copy extracted plugin folder(s) into:
    - `%USERPROFILE%\.ghidra\ghidra_<VERSION>\extensions\`
  - Restart Ghidra.
- If you use plugin archives from GitHub:
  - download the release zip for your exact Ghidra major version,
  - unzip,
  - keep the inner folder name as-is,
  - move only the plugin folder into the `extensions` directory.
- If extension path does not exist, create it manually with:
  - `New-Item -ItemType Directory -Path "$env:USERPROFILE\\.ghidra\\ghidra_<VERSION>\\extensions" -Force`

## Phase 0 — Baseline truth and legal guardrails
- Define objective first:
  - [ ] Understanding behavior only.
  - [ ] Rebuilding full original binary.
  - [ ] Recreating a compatible shim/bridge module.
- Confirm local legal/compliance constraints before any binary mutation (no runtime patching in this phase).
- Confirm no anti-cheat or platform restrictions block non-destructive inspection and symbol analysis.

## Phase 1 — Deterministic inventory and ABI framing
1. Confirm exact install root and binary set.
   - `G:\SteamLibrary\steamapps\common\The Guild 2 Renaissance` (current evidence root)
2. Capture immutable manifest:
   - file list with hashes (`SHA-256`, `SHA-1`)
   - file size and timestamp
   - machine type and PE headers
3. Note runtime dependencies and loader expectations:
   - old MSVC CRT/MFC/STL stack (e.g., `msvcr71.dll`, `msvcp71.dll`, `MFC71.dll`, `stlport*`).

Suggested command bundle (PowerShell):
```powershell
$root = 'G:\SteamLibrary\steamapps\common\The Guild 2 Renaissance'
Get-ChildItem -Path $root -Recurse -File -Include *.exe,*.dll |
  Select-Object FullName, Length, @{N='SHA256';E={(Get-FileHash $_.FullName -Algorithm SHA256).Hash}},
                @{N='Machine';E={(Get-PeHeader $_.FullName).Machine}}
```

## Phase 2 — Non-invasive behavior tracing first
- Build replay-oriented instrumentation at Lua/script boundary before deep decomp:
  - decision window stamp,
  - `selectedNode` / action id,
  - seed + deterministic window,
  - status channel markers (`ToDecided`, `AlreadyDecided`, `Rejected`),
  - callbacks/IDs used by AI (`MyBossID`, `MyDestID`-style provenance fields).

- Why this phase first:
  - It validates synchronization architecture independent of source recovery quality,
  - reduces reverse-engineering dependency and clarifies which exact callback semantics need native-level confirmation.

## Phase 3 — Static extraction and decompilation
Use layered toolchain for evidence:

### 3.1 Primary static stack
- `Ghidra` (Decompiler + flow graphs + function boundaries)
- `Cutter` / `rizin` or `radare2`
- `IDA` / Hex-Rays where licensed
- `Binary Ninja` where available

### 3.2 Auxiliary metadata tools
- `sigcheck`, `dumpbin`, `strings`, symbol browser (`Dependencies`, `PDB` tools when available)
- import/export table capture,
- API call frequency and module dependency graph capture.

### 3.3 Required evidence outputs
For every core candidate module:
- [ ] function list + xrefs + control-flow summaries,
- [ ] decompiler output snapshots (multiple passes if needed),
- [ ] symbol uncertainty score log,
- [ ] hypotheses that map to observed Lua callback boundaries.

## Phase 4 — LLM-assisted refinement (hypothesis lane)
**Important**: Treat LLM output as proposal support only.

Use in this order:
1. Produce baseline decompiler output.
2. Feed candidate snippets into LLM refiner tuned for readability/type consistency.
3. Back-compare with raw output and symbol context.
4. Keep only changes that improve explanatory consistency without changing low-level invariants.

Acceptance guardrails:
- [ ] no silent semantic assumptions,
- [ ] all edits annotated with confidence tags (`Certain / Probable / Hypothesis`),
- [ ] hash-anchored traceable corpus.

## Phase 5 — Source reconstruction path options
### Option A — Behavior-accurate companion module
- Build a clean-room companion that mirrors only required behavior patterns and call semantics.
- Lowest risk for modding workflows.

### Option B — Partial native rebuild
- Viable only with build system, headers, and dependency parity.
- High probability of ABI drift for exact recreation due to legacy toolchain (`MSVC7.1` lineage).

### Option C — Patch-level adaptation
- Only if explicit legal/runtime approval exists.
- Must keep replay safety and deterministic state boundaries unchanged.

## Phase 6 — Rebuild feasibility assessment
Because this binary chain includes legacy runtime stack (`0x014C`, old VC/MFC/STL components), exact full rebuild has low confidence unless:
- original build scripts + compiler versions are known,
- same library ABI/runtime contract is reproducible,
- resource and linker layout is controlled.

Recommended decision:
- Primary path: Lua determinism hardening + observation-driven behavior reconciliation.
- Secondary path: source-accurate semantic reconstruction for selected hot modules.
- Last resort: native patching only with explicit approval and rollback plan.

## Phase 7 — Output artifacts and handoff
Deliver:
- `source_recovery/evidence/` manifest files,
- `source_recovery/decomp/<module>/` raw + refined pseudocode snapshots,
- `source_recovery/signals/` decision/provenance mapping,
- `AI_RESEARCH.md` synchronization-linked findings update.

## Tooling matrix (research-only)
- Native analysis: Ghidra, IDA, Ghidra plugins (LLM assistants), Cutter/rizin/r2.
- Observability: structured logs + manifest snapshots + network/event timing where available.
- LLM research frontier (late-2025/early-2026): LLM4Decompile-style refinement workflows and benchmarked model-assisted passes are useful for explainability, not as final truth.

## Note on `msvcp71.dll`
- It is a Microsoft Visual C++ runtime dependency, not game logic.
- In practice it defines part of the expected runtime/ABI behavior for the legacy executable.
- It must be considered in ABI/recompilation planning, but it is not a source for AI logic.

## Measured findings (rizin, GuildII.exe build of 2026-09-01)

Everything below was read out of the shipped binary, not inferred from behaviour.
Reproduce with `rizin -q -e scr.color=0 -c 'af @ <addr>; pdf @ <addr>' GuildII.exe`.

### What the binary gives you for free
- PE32, image base `0x400000`, **no ASLR** (`pie false`), **no DEP** (`nx false`).
  File offset + `0x400000` == virtual address, so static addresses are stable.
- **Not stripped**: 1182 exported mangled symbols, covering the fork's own code only
  (`SteamManager`, `FileIntegrity`, `RG*`), not the original engine classes.
- **Full RTTI**, so internal class names are recoverable anyway --
  `ahead::guildgameobjects::cl_ActionData`, `cl_SimMemoryEvent`, `cl_Court`, ~1000 more.
- **37 `.\SourceCode\...\*.cpp` paths with line numbers** are embedded via assert macros,
  which maps the engine source tree. `CommitAction` reports
  `GuildGameObjectsScript\GuildGameScriptBinding.cpp:15664`.
- PDB name and GUID are present
  (`c:\Guild2Renaissance\trunk\Source\OUTPUT\GuildII\Release\GuildII.pdb`), the PDB is not.

### The Lua binding table
Each engine function is registered by pushing its native address, calling the registrar at
`0x0081e1f0`, then pushing its name. `tools/modding_helpers/gen_engine_bindings.py` walks
those sites and writes `meta/engine.bindings.tsv`.

| | |
|---|---|
| registration sites | 1050 |
| unique Lua names | 1048 |
| documented in `ScriptDocumentation.html` | 764 |
| in both | 697 |
| **registered but undocumented** | **351** |
| declared but not found by the walk | 67 |

The 351 are real API the dump never mentions. The 67 are characterised, not mysterious:
~55 are blocking calls with `NoWait` twins (`MsgBox`, `PlayAnimation`, `SendCommand`,
`ShowPanel`, `SquadWait`) whose name strings sit in `.rdata` but which register through a
second path, most likely the one that wraps a call so it can yield; a handful
(`f_MoveTo`, `f_Follow`, `StartVision`) have no string in the binary at all and are mod Lua
library functions the dump lists as though they were engine API.

### Action and observer subsystem

| address | what it is |
|---|---|
| `0x0071f755` | binding region: `push fnptr; call 0x81e1f0; push name; call 0x81e570` |
| `0x00708ac0` | native `CommitAction` (`GuildGameScriptBinding.cpp:15664`) |
| `0x00708c40` | native `StopAction` |
| `0x00708d10` | native `ActionLock` |
| `0x007d5390` | engine-side commit-action method the binding calls |
| `0x007d2010` | scan of the actor's **live** action vector; name at `+0x70`, owner at `+0x4c` |
| `0x007d3a60` | `Action.dbt` loader: opens `\Database`, gets table `Action`, iterates rows |
| `0x007d33f0` | `std::map::operator[]` (lower_bound `0x7d1df0`, cmp `0x8106a0`, insert `0x7d2b80`) |

**The action table is `std::map<cl_String, cl_ActionData>` keyed by the `name` column.**
There is no fixed-size array and no id ceiling; `id` is not the lookup key. A row is
skipped only when its name is empty.

`cl_ActionData` field offsets, from the loader's stores:

```
+0x00 memoryevent    +0x04 event_receivers   +0x08 favormod_receivers
+0x0c observerskill  +0x10 observerskillmod  +0x14 observerrange
+0x18 observerscript                         +0x4c name
```

Observer scripts load from the hardcoded prefix `Measures/Behaviour/` (string at `0xaf7860`).

`CommitAction` **returns `true` for an action name that does not exist**. The return value
says nothing about whether the row was found or the action dispatched, so it is worthless
as a diagnostic signal.

`CommitAction` is also not fire-and-forget: it starts a durable action that observers scan
while it runs, ended by `StopAction`. `Scripts/States/state_contaminated.lua` shows the
idiom -- commit, loop while the impact lasts, stop.

### The fork's mod layer is managed .NET
`SteamManager::ResolveModDatabasePath` at `0x5c63a0` is a thunk, `jmp dword [0xbc3bec]`,
and `[0xbc3bec]` holds `0x06000039` -- a .NET **MethodDef** token. So `SteamManager` and
`FileIntegrity` are C++/CLI. rizin cannot follow them; **ILSpy or dnSpy decompiles that
layer directly**, which is far cheaper than x86 archaeology for anything mod-resolution
related. Relevant exports: `ResolveModDatabasePath`, `ResolveModScriptPath`,
`ResolveModResourcePath`, `ResolveModObjectPath`, `ResolveModScenePath`,
`ResolveModWorldPath`, `GetModResourceChain`, `GetModStack`, `GetMergedScriptDir`,
`InvalidateModCaches`.

### FileIntegrity is a multiplayer join gate, not anti-tamper
It hashes **mod files** and compares host against client (`file_manifest.txt`,
`Invite join blocked: file integrity mismatch`). It does not guard the executable. The
practical consequence is that every player in a session needs byte-identical mod files.

### Method note
Two byte-pattern details cost real time when walking the binding table and are worth
carrying into any similar scan: the `this` pointer is pushed from whichever register the
compiler chose (accept `0x50`-`0x57`, not just `push esi`), and a stack cleanup or register
reload can sit between the registrar call and the name push. Requiring `push esi` and
adjacency found 972 of 1048 names, and made the 76 it missed look like evidence of a
second mechanism that did not exist.
