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
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "Scripts", "AI", "BaseTree"))
WEIGHT = re.compile(r"function Weight\(\)(.*?)\r?\nend", re.S)
RETURN = re.compile(r"return\s+([^\r\n]*)")
GLOBAL_ASSIGN = re.compile(r"\n\s*(?!local\b)(?!if\b|for\b|while\b|return\b|end\b|else|elseif|--)[A-Za-z_][A-Za-z_0-9]*\s*=[^=]")
INPUTS = re.compile(r"utility_Trait|utility_Priority|utility_Money|CheckPersonalityWeight|aitwp_Get(?:PoliticalAmbititon|Agressiveness|Intrigue)|MakeDecision")


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


def main(argv):
    wanted = argv[argv.index("--list") + 1] if "--list" in argv and argv.index("--list") + 1 < len(argv) else None
    categories, hazards = {}, {"writes SIM in Weight()": [], "non-local assignment in Weight()": [],
                               "Rand() in Weight()": [], "uses personality/priority inputs": []}
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
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
