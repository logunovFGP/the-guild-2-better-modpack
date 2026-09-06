"""Static check: every function call in the AI tree and its libraries resolves.

    python tools/modding_helpers/check_unresolved_calls.py [path ...] [--overlay DIR]

A call resolves when the name is an engine native (meta/engine.d.lua,
meta/engine.undocumented.d.lua, meta/engine.bindings.tsv), a Lua builtin, a function
defined in the same file, or <lower-cased file stem>_<Function> for a function defined
in any script of the repo or of the vanilla overlay - the game's own Scripts folder,
which the mod loads on top of (Library/trade.lua lives only there). That prefix rule
is how the engine exposes library functions: aitwp.lua -> aitwp_Log, AI.lua -> ai_BuyItem.

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
DEFAULT_PATHS = ["Scripts/AI/BaseTree", "Scripts/Library/utility.lua", "Scripts/Library/aitwp.lua"]
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
    names = set()
    for root in roots:
        if not os.path.isdir(root):
            continue
        for path in lua_files(root):
            prefix = os.path.splitext(os.path.basename(path))[0].lower() + "_"
            for fn in FUNCTION_DEF.findall(read(path)):
                names.add(prefix + fn)
    return names


def strip(src):
    src = re.sub(r"--\[\[.*?\]\]", "", src, flags=re.S)
    src = re.sub(r"--[^\n]*", "", src)
    return re.sub(r'"[^"\n]*"', '""', src)


def unresolved_in(path, known):
    src = strip(read(path))
    local_defs = set(re.findall(r"\bfunction\s+([A-Za-z_]\w*)\s*\(", src))
    return set(name for name in CALL.findall(src)
               if name not in KEYWORDS and name not in BUILTINS and name not in known and name not in local_defs)


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
    known |= prefixed_functions(roots)

    problems = {}
    scanned = 0
    for root in paths:
        for path in lua_files(root):
            scanned += 1
            for name in unresolved_in(path, known):
                problems.setdefault(name, []).append(os.path.relpath(path, REPO).replace(os.sep, "/"))
    print("scanned %d files against %d known names (natives + prefixed script functions)" % (scanned, len(known)))
    for name, files in sorted(problems.items(), key=lambda kv: -len(kv[1])):
        print("UNRESOLVED %-32s in %d file(s): %s" % (name, len(files), ", ".join(files[:4]) + (" ..." if len(files) > 4 else "")))
    if problems:
        print("FAILED: %d unresolved name(s)" % len(problems), file=sys.stderr)
        return 1
    print("ok: every call resolves")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
