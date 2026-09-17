"""Shape of the AI BaseTree: constants vs. computed weights, utility conversion
progress, and the shared-blackboard hazards.

    python tools/modding_helpers/basetree_stats.py [--list CATEGORY]

Per node file under Scripts/AI/BaseTree it classifies the last `return` of Weight():
  constant       a bare integer (the pre-utility tree: 184 of 218 in Sep 2026)
  utility_Score  scored from personality / priorities / money
  utility_Trace  a constant that is traced for the telemetry replay
  computed       any other expression
  zero-only      never returns anything but 0
and counts, inside Weight(): writes to the shared alias "SIM" (every sibling's Weight()
runs before one Execute(), so the last writer wins), assignments to non-local names
(globals leak between nodes and peers), calls to Rand (dice in a decision), and use of
personality or priority inputs. --list prints the files of one category, e.g.
--list constant to see what is left to convert.

Two of the categories are defects rather than statistics, and exit 1 on either:
  shared alias resolved in Weight(), not stashed
      two siblings in one folder resolve the same alias to different objects, and
      the loser's target is what the winner acts on. Fix with aiboard_Stash /
      aiboard_Claim. Identical calls are not flagged: they find the same object.
  unregistered blackboard key
      a property named AI_* or AITWP_* that is not in BLACKBOARD_KEYS, so a typo
      reads nil forever and the node quietly weighs 0. Repeat-timer names are a
      separate namespace and are not counted.

A third is reported but does not yet block, because 29 inherited nodes already do it:
  alias resolved in Weight(), read in Execute()
      the node resolves a target in Weight() and reads that alias again in
      Execute(), with every sibling's Weight() in between. Safe only while no
      sibling writes the same alias - bf_Procure bought a cart from one of these.
      Fix by re-resolving in Execute(), or with aiboard_Stash. Make it blocking
      once the count reaches zero.
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "Scripts", "AI", "BaseTree"))
WEIGHT = re.compile(r"function Weight\(\)(.*?)\r?\nend", re.S)
EXECUTE = re.compile(r"function Execute\(\)(.*?)\r?\nend", re.S)
ALIAS_USE = re.compile(r'"([A-Za-z][A-Za-z0-9_]*)"')
RETURN = re.compile(r"return\s+([^\r\n]*)")
GLOBAL_ASSIGN = re.compile(r"\n\s*(?!local\b)(?!if\b|for\b|while\b|return\b|end\b|else|elseif|--)[A-Za-z_][A-Za-z_0-9]*\s*=[^=]")
INPUTS = re.compile(r"utility_Trait|utility_Priority|utility_Money|CheckPersonalityWeight|aitwp_Get(?:PoliticalAmbititon|Agressiveness|Intrigue)|MakeDecision")
# A node resolving a shared alias to its own target inside Weight(). The engine runs
# every sibling's Weight() before the winner's Execute(), so the winner acts on
# whatever the last sibling wrote unless it files the target with aiboard_Stash.
# Residence and OwnBuilding join the finders after 2026-09-17: bf_Procure resolved the
# residence into "home" in Weight() and bought a cart with it in Execute(), twelve
# siblings later. Same hazard class, invisible to the old list.
RESOLVE = re.compile(r'((?:FindPlayerTarget|EvidenceTarget|NearbyPlayerSim|GetBestEnemy|FindTargetBuilding|Residence|OwnBuilding)\s*\([^)]*"([A-Za-z][A-Za-z0-9_]*)"\s*\))')
BLACKBOARD = os.path.abspath(os.path.join(HERE, "..", "..", "Scripts", "Library", "aiboard.lua"))
# only a property call names a blackboard key; "AI_BF_Supply" and friends are
# repeat-timer names, a separate namespace with its own lifetime
AI_KEY = re.compile(r'(?:Get|Set|Has|Remove)Property\s*\([^,]+,\s*"(AI_[A-Za-z0-9_]*|AITWP_[A-Za-z0-9_]*)"'
                    r'|aiboard_(?:Recall|Remember|Forget)\s*\([^,]+,\s*"(AI_[A-Za-z0-9_]*|AITWP_[A-Za-z0-9_]*)"')


def strip(src):
    src = re.sub(r"--\[\[.*?\]\]", "", src, flags=re.S)
    return re.sub(r"--[^\n]*", "", src)


def classify(body):
    returns = [r.strip() for r in RETURN.findall(body)]
    if not returns or all(r == "0" for r in returns):
        return "zero-only"
    last = [r for r in returns if r != "0"][-1]
    if re.fullmatch(r"\d+", last):
        return "constant"
    if last.startswith("utility_Score("):
        return "utility_Score"
    if last.startswith("utility_Trace("):
        return "utility_Trace"
    return "computed"


def registered_keys():
    """Every key declared in BLACKBOARD_KEYS, plus which of them take an index."""
    exact, prefixes = set(), set()
    if not os.path.exists(BLACKBOARD):
        return exact, prefixes
    for line in open(BLACKBOARD, encoding="utf-8", errors="replace"):
        m = re.match(r"\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*\{", line)
        if m and "owner" in line:
            exact.add(m.group(1))
            if "prefix = true" in line:
                prefixes.add(m.group(1))
    return exact, prefixes


def main(argv):
    wanted = argv[argv.index("--list") + 1] if "--list" in argv and argv.index("--list") + 1 < len(argv) else None
    categories, hazards = {}, {"writes SIM in Weight()": [], "non-local assignment in Weight()": [],
                               "Rand() in Weight()": [], "uses personality/priority inputs": [],
                               "shared alias resolved in Weight(), not stashed": [],
                               "alias resolved in Weight(), read in Execute()": [],
                               "unregistered blackboard key": []}
    exact, prefixes = registered_keys()
    resolved = {}
    nodes = 0
    for folder, _dirs, files in os.walk(ROOT):
        for name in files:
            if not name.endswith(".lua"):
                continue
            path = os.path.join(folder, name)
            rel = os.path.relpath(path, ROOT).replace(os.sep, "/")
            src = strip(open(path, encoding="utf-8", errors="replace").read())
            m = WEIGHT.search(src)
            if not m:
                continue
            nodes += 1
            body = m.group(1)
            categories.setdefault(classify(body), []).append(rel)
            if re.search(r'"SIM"\s*\)', body):
                hazards["writes SIM in Weight()"].append(rel)
            if GLOBAL_ASSIGN.search(body):
                hazards["non-local assignment in Weight()"].append(rel)
            if "Rand(" in body:
                hazards["Rand() in Weight()"].append(rel)
            if INPUTS.search(body):
                hazards["uses personality/priority inputs"].append(rel)
            folder_key = os.path.dirname(rel)
            for call, alias in set(RESOLVE.findall(body)):
                norm = re.sub(r"\s+", "", call)
                resolved.setdefault((folder_key, alias), []).append((rel, norm, "aiboard_Stash" in src))
            # An alias a node resolves in Weight() and then reads in Execute(). Every
            # sibling's Weight() runs in between, so the value is only safe by luck.
            # bf_Procure did this with the residence and bought a cart from a stale
            # alias for weeks; aiboard_Stash, or re-resolve in Execute().
            ex = EXECUTE.search(src)
            if ex and "aiboard_Stash" not in src:
                used = set(ALIAS_USE.findall(ex.group(1)))
                for _call, alias in set(RESOLVE.findall(body)):
                    if alias in used:
                        if rel not in hazards["alias resolved in Weight(), read in Execute()"]:
                            hazards["alias resolved in Weight(), read in Execute()"].append(
                                "%s  (%s)" % (rel, alias))
            for pair in set(AI_KEY.findall(src)):
                key = pair[0] or pair[1]
                if key in exact:
                    continue
                stem = re.sub(r"[0-9]+$", "", key)
                if stem in prefixes or key.rstrip("_") + "_" in exact:
                    continue
                hazards["unregistered blackboard key"].append("%s  (%s)" % (rel, key))

    # a hazard only when siblings in one folder resolve the same alias differently:
    # identical calls land on the same object, so the last writer changes nothing
    for (_folder, _alias), owners in resolved.items():
        # more than one node, and they ask for different things: one node using an
        # OR-fallback into its own alias is fine
        if len(set(rel for rel, _n, _s in owners)) > 1 and len(set(n for _r, n, _s in owners)) > 1:
            for rel, _norm, stashed in owners:
                if not stashed and rel not in hazards["shared alias resolved in Weight(), not stashed"]:
                    hazards["shared alias resolved in Weight(), not stashed"].append(rel)

    if wanted:
        for rel in sorted(categories.get(wanted, []) + hazards.get(wanted, [])):
            print(rel)
        return 0
    print("%d nodes with Weight() under %s" % (nodes, os.path.relpath(ROOT)))
    print("\nlast return of Weight():")
    for cat in ("constant", "utility_Score", "utility_Trace", "computed", "zero-only"):
        print("  %-14s %4d" % (cat, len(categories.get(cat, []))))
    print("\ninside Weight():")
    for label, files in hazards.items():
        print("  %-38s %4d" % (label, len(files)))
    print("\n--list <category> prints the files, e.g. --list constant or --list \"Rand() in Weight()\"")
    # These two are not statistics, they are defects: a sibling can take the target, or
    # a key reads nil for the rest of the game. Both fail silently in play, so fail here.
    # "alias resolved in Weight(), read in Execute()" is reported, not blocking: 29 nodes
    # in the inherited tree already do it (see the README backlog). Blocking on a
    # backlog that large only gets the check switched off. Make it blocking once the
    # count reaches zero.
    blocking = (hazards["shared alias resolved in Weight(), not stashed"]
                + hazards["unregistered blackboard key"])
    if blocking:
        print("")
        print("%d blocking hazard(s):" % len(blocking))
        for rel in sorted(blocking):
            print("  " + rel)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
