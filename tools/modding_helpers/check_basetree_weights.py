"""Every node under Scripts/AI/BaseTree must define Weight() and Execute(), and
Weight() must never return a boolean.

    python tools/modding_helpers/check_basetree_weights.py

The engine picks a child by weighted random (AIWeightedRandom.h in GuildII.exe):
it reads Weight() as a number, so `return false` there is undefined behaviour,
not "ineligible". Four nodes shipped that way; `return 0` is the correct gate.
"""
import os
import re
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "Scripts", "AI", "BaseTree")
WEIGHT = re.compile(r"function Weight\(\)(.*?)\nend", re.S)
BOOL_RETURN = re.compile(r"\breturn\s+(true|false)\b")


def strip_comments(src):
    src = re.sub(r"--\[\[.*?\]\]", "", src, flags=re.S)
    return re.sub(r"--[^\n]*", "", src)


def main():
    failures = []
    nodes = 0
    for folder, _dirs, files in os.walk(ROOT):
        for name in files:
            if not name.endswith(".lua"):
                continue
            path = os.path.join(folder, name)
            rel = os.path.relpath(path, ROOT).replace(os.sep, "/")
            src = strip_comments(open(path, encoding="utf-8", errors="replace").read())
            nodes += 1
            body = WEIGHT.search(src)
            if body is None:
                failures.append(rel + ": no Weight()")
                continue
            if "function Execute()" not in src:
                failures.append(rel + ": no Execute()")
            if BOOL_RETURN.search(body.group(1)):
                failures.append(rel + ": Weight() returns a boolean; use 0 to opt out")
    for line in failures:
        print("FAIL:", line, file=sys.stderr)
    if failures:
        print("FAILED: %d problem(s) in %d BaseTree nodes" % (len(failures), nodes), file=sys.stderr)
        return 1
    print("ok: %d BaseTree nodes define Weight()/Execute() with numeric weights" % nodes)
    return 0


if __name__ == "__main__":
    sys.exit(main())
