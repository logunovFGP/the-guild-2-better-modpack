"""Static check: every function call in the AI tree and its libraries resolves.

    python tools/modding_helpers/check_unresolved_calls.py [path ...] [--overlay DIR]

A call resolves when the name is an engine native (meta/engine.d.lua,
meta/engine.undocumented.d.lua, meta/engine.bindings.tsv), a Lua builtin, a function
defined in the same file, or <lower-cased file stem>_<Function> for a function defined
in any script of the repo or of the vanilla overlay - the game's own Scripts folder,
which the mod loads on top of (Library/trade.lua lives only there). That prefix rule
is how the engine exposes library functions: aitwp.lua -> aitwp_Log, AI.lua -> ai_BuyItem.

Resolving to a file is not enough for a library: the engine loads Scripts/Library/*.lua
only from the Include list in Scripts/Library/stdafx.lua, never by filename, and the mod's
stdafx.lua shadows the vanilla one. A called library function whose file is in no Include
line is nil at runtime, so this also fails on a missing Include.

Default paths: Scripts/AI/BaseTree, Scripts/Library/utility.lua, Scripts/Library/aitwp.lua.
Default overlay: $GUILD2/Scripts, else the Steam install. Exit code 1 when anything is
unresolved: an unresolved call inside Weight() makes the node error and weigh 0 with
no trace in the log.
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
DEFAULT_PATHS = ["Scripts/AI/BaseTree", "Scripts/Library/utility.lua", "Scripts/Library/aitwp.lua",
                 "Scripts/Library/aiboard.lua", "Scripts/Library/aihtn.lua"]
BUILTINS = set("tostring tonumber type pairs ipairs unpack pcall error assert next select rawget rawset "
               "setmetatable getmetatable print require dofile loadstring".split())
KEYWORDS = set("function if while for return end else elseif and or not local do then repeat until break "
               "in nil true false".split())
FUNCTION_DEF = re.compile(r"^function ([A-Za-z_]\w*)\s*\(", re.M)
CALL = re.compile(r"(?<![\w.:])([A-Za-z_]\w*)\s*\(")


def default_overlay():
    root = os.environ.get("GUILD2") or r"G:\SteamLibrary\steamapps\common\The Guild 2 Renaissance"
    return os.path.join(root, "Scripts")


def read(path):
    return open(path, encoding="utf-8", errors="replace").read()


def lua_files(root):
    if os.path.isfile(root):
        return [root]
    out = []
    for folder, _dirs, files in os.walk(root):
        out += [os.path.join(folder, f) for f in files if f.endswith(".lua")]
    return sorted(out)


def natives(repo):
    names = set()
    for meta in ("meta/engine.d.lua", "meta/engine.undocumented.d.lua"):
        p = os.path.join(repo, meta)
        if os.path.exists(p):
            names |= set(FUNCTION_DEF.findall(read(p)))
    tsv = os.path.join(repo, "meta", "engine.bindings.tsv")
    if os.path.exists(tsv):
        for line in read(tsv).splitlines()[1:]:
            names.add(line.split("\t")[0])
    return names


def prefixed_functions(roots):
    """Every <basename>_<Function> the engine can address, plus who owns each basename.

    Library files and the object scripts the engine binds by basename (Buildings and
    the like: cl_GuildObject::RunScriptUnscheduled formats %s_%s) all register
    <basename>_<Function> globals, and a Library file whose basename is already taken
    is skipped without a word (Library/blackboard.lua never loaded: Buildings/BlackBoard.lua
    owned the prefix). Tree nodes, measures and cutscenes are run by path and may share
    names with each other, so only Library-involved duplicates are a defect here.
    owners maps basename -> {relative path (lower) -> set of roots that have it}, so a
    vanilla file overlaid by the mod at the same relative path is one owner, not two.
    where maps <basename>_<Function> -> {relative path (lower)}: which file defines it,
    so the Include check below can tell a library function from a node's or a measure's.
    """
    names, owners, where = set(), {}, {}
    for root in roots:
        if not os.path.isdir(root):
            continue
        for path in lua_files(root):
            base = os.path.splitext(os.path.basename(path))[0].lower()
            rel = os.path.relpath(path, root).replace(os.sep, "/").lower()
            owners.setdefault(base, {}).setdefault(rel, set()).add(root)
            for fn in FUNCTION_DEF.findall(read(path)):
                names.add(base + "_" + fn)
                where.setdefault(base + "_" + fn, set()).add(rel)
    return names, owners, where


def basename_collisions(owners, mod_root):
    """A Library file whose basename any other script also uses, where at least one of
    the paths is the mod's own addition - the one shape that silently drops a library.
    Same-name pairs that involve no Library file are noted, not failed: nodes, measures
    and cutscenes are run by path and have coexisted that way in vanilla for years."""
    fail, note = [], []
    for base, rels in sorted(owners.items()):
        if len(rels) < 2:
            continue
        mod_only = [r for r, roots in rels.items() if roots == {mod_root}]
        involves_library = any(r.startswith("library/") for r in rels)
        (fail if (mod_only and involves_library) else note).append((base, sorted(rels)))
    return fail, note


def stdafx_includes(repo):
    """The library basenames the mod's stdafx.lua actually loads, or None if it is gone.

    Include ("Library/x.lua") is the only way a library is loaded; the engine does not
    pick up Scripts/Library/*.lua by filename. The mod's stdafx.lua replaces the vanilla
    one wholesale, so a vanilla library missing from the mod's list is not loaded either,
    however many scripts call it."""
    path = os.path.join(repo, "Scripts", "Library", "stdafx.lua")
    if not os.path.exists(path):
        return None
    return set(m.lower() for m in re.findall(r'Include\s*\(\s*"Library/([^"\n]+)\.lua"', read(path), re.I))


def missing_includes(called, where, included):
    """Called library functions whose file no Include line loads - nil at runtime.

    Keyed on the file that defines the function, never on the prefix alone: node and
    measure prefixes (def_, bf_provoke_, manageparty_) resolve to files outside Library/
    and are run by path, not by Include."""
    missing = {}
    for name in called:
        for rel in where.get(name, ()):
            if not rel.startswith("library/"):
                continue
            base = os.path.splitext(os.path.basename(rel))[0]
            if base not in included:
                missing.setdefault(base, set()).add(name)
    return missing


def strip(src):
    src = re.sub(r"--\[\[.*?\]\]", "", src, flags=re.S)
    src = re.sub(r"--[^\n]*", "", src)
    return re.sub(r'"[^"\n]*"', '""', src)


def calls_in(path):
    """Every global name called in the file, with comments and string bodies removed."""
    src = strip(read(path))
    local_defs = set(re.findall(r"\bfunction\s+([A-Za-z_]\w*)\s*\(", src))
    return set(name for name in CALL.findall(src)
               if name not in KEYWORDS and name not in BUILTINS and name not in local_defs)


def main(argv):
    overlay = default_overlay()
    paths = []
    skip = False
    for i, a in enumerate(argv[1:], 1):
        if skip:
            skip = False
            continue
        if a == "--overlay" and i + 1 < len(argv):
            overlay = argv[i + 1]
            skip = True
        else:
            paths.append(a)
    paths = paths or [os.path.join(REPO, p) for p in DEFAULT_PATHS]

    known = natives(REPO)
    roots = [os.path.join(REPO, "Scripts")]
    if os.path.isdir(overlay):
        roots.append(overlay)
    else:
        print("warning: vanilla overlay not found at %s; vanilla-only libraries (trade.lua) will show as unresolved" % overlay)
    prefixed, owners, where = prefixed_functions(roots)
    known |= prefixed
    collide, vanilla_dups = basename_collisions(owners, roots[0])
    for base, rels in collide:
        print("COLLISION %-24s %s  <- the engine loads ONE of these and says nothing" % (base, "  vs  ".join(rels)))
    if vanilla_dups:
        print("note: %d basename(s) shared by path-run scripts (nodes, measures, cutscenes); not a Library collision" % len(vanilla_dups))

    problems, called = {}, {}
    scanned = 0
    for root in paths:
        for path in lua_files(root):
            scanned += 1
            rel = os.path.relpath(path, REPO).replace(os.sep, "/")
            for name in calls_in(path):
                called.setdefault(name, []).append(rel)
                if name not in known:
                    problems.setdefault(name, []).append(rel)
    print("scanned %d files against %d known names (natives + prefixed script functions)" % (scanned, len(known)))
    for name, files in sorted(problems.items(), key=lambda kv: -len(kv[1])):
        print("UNRESOLVED %-32s in %d file(s): %s" % (name, len(files), ", ".join(files[:4]) + (" ..." if len(files) > 4 else "")))

    included = stdafx_includes(REPO)
    missing = {} if included is None else missing_includes(called, where, included)
    if included is None:
        print("warning: Scripts/Library/stdafx.lua not found; Include check skipped")
    for base, names in sorted(missing.items()):
        shown = sorted(names)
        callers = sorted(set(f for n in shown for f in called[n]))
        print('MISSING INCLUDE Library/%-16s called as %s in %s  <- add Include ("Library/%s.lua") to Scripts/Library/stdafx.lua'
              % (base + ".lua", ", ".join(shown[:3]) + (" ..." if len(shown) > 3 else ""),
                 ", ".join(callers[:3]) + (" ..." if len(callers) > 3 else ""), base))

    if problems or collide or missing:
        if problems:
            print("FAILED: %d unresolved name(s)" % len(problems), file=sys.stderr)
        if collide:
            print("FAILED: %d script basename collision(s) - rename the mod's file" % len(collide), file=sys.stderr)
        if missing:
            print("FAILED: %d library file(s) called but never Included - nil at runtime" % len(missing), file=sys.stderr)
        return 1
    print("ok: every call resolves, every library called is Included, no script basename collisions")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
