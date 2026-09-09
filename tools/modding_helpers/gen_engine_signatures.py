"""Recover every engine Lua binding's arity and parameter types from GuildII.exe.

    python tools/modding_helpers/gen_engine_signatures.py [path-to-GuildII.exe]

Writes meta/engine.signatures.tsv (name, address, arity, parameter kinds) and
reports anything that disagrees with meta/engine.d.lua.

Why this exists
---------------
gen_engine_bindings.py recovers name -> address. gen_engine_meta.py scrapes
ScriptDocumentation.html, which is incomplete and in places wrong. Neither says
how many arguments a native really takes or what class it wants, so a call with
a plausible-looking but wrong argument list fails silently at runtime: the
binding reads a parameter that is not there, the node weighs 0, and nothing is
logged. This walks the code instead.

How the walk works
------------------
Every binding in GuildGameScriptBinding.cpp opens with an assert carrying the
source file and line, then fetches each parameter through one of a small set of
helpers. The fetch compiles to:

    push 0xce8b6c      <- class descriptor, or a default value, or nothing
    push 0x01
    push 0x00
    push 0x02          <- 1-based parameter index
    push esi           <- the binding object
    call 0x006373c0    <- the fetch helper; which one gives the parameter's kind

So the arity is the highest index fetched, and the helper identifies the kind.
Object parameters also carry a class descriptor, and those pin down the class:
the descriptors are runtime-initialised globals with nothing in the image, so
they are named here by what unambiguous natives ask for (DynastyGetMemberCount
wants a dynasty, SimGetAge a sim, CityGetLevel a settlement, and so on).

Known limits
------------
  * Bindings outside GuildGameScriptBinding.cpp -- GetID, GetProperty,
    RemoveAlias, HasProperty, Sleep, LogMessage and the rest of the 0x0063xxxx
    base module -- use a different fetch family and come out as "unresolved".
    They are the oldest and most heavily used calls in the tree, so they are
    not where a mistake hides.
  * Optional parameters are indistinguishable from required ones: the binding
    fetches them with a default and the call site may leave them off. Arity is
    therefore an upper bound, and fewer arguments at a call site is normal.
  * A helper this does not know leaves a gap in the parameter list, printed as
    "?" -- report those rather than trusting the arity around them.
"""
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
BINDINGS = os.path.join(REPO, "meta", "engine.bindings.tsv")
TARGET = os.path.join(REPO, "meta", "engine.signatures.tsv")

# The parameter fetch helpers, read out of CityGetLevel, CityGetPenalty,
# GetImpactValue, GetSkillValue, DynastyGetWorker and SetRepeatTimer.
FETCH = {
    0x6373C0: "object",
    0x637280: "number",
    0x6372D0: "number",
    0x637320: "bool",
    0x637370: "string",
    0x81DEA0: "outalias",
    0x6F4F20: "impactname",
    0x6F50C0: "skillname",
}
# The argument-count assert every binding in that translation unit opens with.
ASSERT = 0x637560
# Class descriptors, named by natives that can only mean one thing.
CLASS = {
    0xCE82B0: "guildobject",
    0xCE8B6C: "sim",
    0xCE8778: "settlement",
    0xCE7C14: "building",
}
CALL = re.compile(r"call\s+(?:fcn\.)?(?:0x)?([0-9a-f]{6,8})")
PUSH = re.compile(r"push\s+(0x[0-9a-f]+|[a-z]+)")
DECL = re.compile(r"^function\s+([A-Za-z_][A-Za-z0-9_]*)\(([^)]*)\)")
HEAD = re.compile(r"fcn\.([0-9a-f]{8})\(")


def default_exe():
    root = os.environ.get("GUILD2") or r"G:\SteamLibrary\steamapps\common\The Guild 2 Renaissance"
    return os.path.join(root, "GuildII.exe")


def disassemble(exe, addresses):
    """One rizin run for the lot; spawning it per function takes minutes."""
    script = "; ".join("s %s; af; pdf" % va for va in addresses)
    out = subprocess.run(["rizin", "-q", "-e", "scr.color=0", "-c", script, exe],
                         capture_output=True, encoding="utf-8", errors="replace")
    if out.returncode != 0:
        sys.exit("rizin failed: " + (out.stderr or "").strip())
    chunks, current = {}, None
    for line in out.stdout.splitlines():
        head = HEAD.search(line)
        if head and "call" not in line:
            current = "0x" + head.group(1)
            chunks[current] = []
        elif current is not None:
            chunks[current].append(line)
    return chunks


def signature(lines):
    """Parameter kinds by index; None when this is not a GuildGameScriptBinding native."""
    if not any(("%x" % ASSERT) in ln for ln in lines):
        return None, None
    pushes, params, classes = [], {}, {}
    for ln in lines:
        m = PUSH.search(ln)
        if m:
            pushes.append(m.group(1))
            continue
        c = CALL.search(ln)
        if not c:
            continue
        target = int(c.group(1), 16)
        if target in FETCH and len(pushes) >= 2:
            for candidate in (pushes[-2], pushes[-1]):
                try:
                    index = int(candidate, 16)
                except ValueError:
                    continue
                if 1 <= index <= 16:
                    params[index] = FETCH[target]
                    for p in pushes:
                        try:
                            cls = int(p, 16)
                        except ValueError:
                            continue
                        if cls in CLASS:
                            classes[index] = CLASS[cls]
                    break
        pushes = []
    if not params:
        return 0, []
    arity = max(params)
    kinds = [classes.get(i) or params.get(i, "?") for i in range(1, arity + 1)]
    return arity, kinds


def declared_arity():
    """Parameter counts as meta/engine.d.lua declares them, for the disagreement report."""
    path = os.path.join(REPO, "meta", "engine.d.lua")
    if not os.path.exists(path):
        return {}
    out = {}
    for line in open(path, encoding="utf-8", errors="replace"):
        m = DECL.match(line)
        if m:
            args = [a for a in m.group(2).split(",") if a.strip()]
            out[m.group(1)] = len(args)
    return out


def main(argv):
    exe = argv[1] if len(argv) > 1 else default_exe()
    if not os.path.exists(exe):
        sys.exit("no such file: " + exe)
    rows = []
    for line in open(BINDINGS, encoding="utf-8"):
        name, va, documented = line.rstrip("\n").split("\t")
        if name == "name":
            continue
        rows.append((name, va))
    chunks = disassemble(exe, [va for _, va in rows])

    declared = declared_arity()
    resolved, unresolved, disagree = 0, 0, []
    with open(TARGET, "w", encoding="utf-8", newline="\n") as handle:
        handle.write("name\tva\tarity\tparams\n")
        for name, va in rows:
            lines = chunks.get(va)
            arity, kinds = (None, None) if lines is None else signature(lines)
            if arity is None:
                unresolved += 1
                handle.write("%s\t%s\t-\tunresolved\n" % (name, va))
                continue
            resolved += 1
            handle.write("%s\t%s\t%d\t%s\n" % (name, va, arity, ",".join(kinds)))
            if name in declared and declared[name] != arity:
                disagree.append((name, arity, declared[name]))

    print("wrote %s" % os.path.relpath(TARGET, REPO))
    print("  %d bindings resolved from code, %d in another binding module" % (resolved, unresolved))
    if disagree:
        print("\n%d disagree with engine.d.lua (binary wins; the dump is known to be wrong):" % len(disagree))
        for name, got, said in sorted(disagree)[:40]:
            print("  %-34s binary %d, dump %d" % (name, got, said))
        if len(disagree) > 40:
            print("  ... and %d more, see the tsv" % (len(disagree) - 40))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
