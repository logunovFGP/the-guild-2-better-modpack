"""Self-check for the measure-panel talent row (mdata_ShowTalentOSH).

Asserts the four things that rot silently: a measure in the table with no call
site, a talent whose label row is missing from Text.dbt, a call borrowing an OSH
row the measure already fills (the second Set would overwrite the first), and a
language file that never received the label rows.

    python tools/modding_helpers/check_talent_osh.py
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MDATA = os.path.join(ROOT, "Scripts", "Library", "mdata.lua")
TEXT = os.path.join(ROOT, "DB", "Languages", "Text.dbt")
MEASURES = os.path.join(ROOT, "DB", "Measures.dbt")
LANGUAGES = os.path.join(ROOT, "DB", "Languages")
SCRIPTS = os.path.join(ROOT, "Scripts", "Measures")


# The ten talent label rows every language file must carry.
ICON_ROWS = (
    "constitution", "shadow_arts", "charisma", "fighting", "dexterity",
    "craftsmanship", "rhetoric", "empathy", "bargaining", "secret_knowledge",
    "level",
)


def read(path, encoding="latin-1"):
    with open(path, "rb") as handle:
        return handle.read().decode(encoding)


def declared_scripts():
    """id -> script filename for the Measures.dbt rows that declare one.

    Rows carrying "~" inherit the vanilla path and are absent from the result.
    """
    header, data = read(MEASURES).split("Data:", 1)
    columns = re.findall(r'"([a-z_]+)"', header)
    found = {}
    for line in data.splitlines():
        cells = re.findall(r'"((?:[^"])*)"|(-?\d+)', line.strip())
        values = [a if b == "" else b for a, b in cells]
        if len(values) != len(columns):
            continue
        row = dict(zip(columns, values))
        if row["script"] not in ("~", "-", ""):
            found[int(row["id"])] = row["script"]
    return found


def main():
    mdata = read(MDATA)
    declared = {
        int(mid): (const or literal, name)
        for mid, const, literal, name in re.findall(
            r'\[(\d+)\]\s*=\s*\{\s*(?:([A-Z_]+)|"([a-z_]+)")\s*,\s*"([a-z_]+)"\s*\}', mdata
        )
    }
    if not declared:
        print("FAIL: no MeasureTalent rows parsed out of mdata.lua")
        return 1
    prefix = re.search(r'"@L(_[A-Za-z0-9_]+_TALENT_)"?', mdata).group(1)

    text_keys = set(re.findall(r'"(_[A-Za-z0-9_+]+)"', read(TEXT, "utf-16")))

    by_id = declared_scripts()
    on_disk = {}
    for base, _, files in os.walk(SCRIPTS):
        for name in files:
            if name.endswith(".lua"):
                on_disk.setdefault(name, os.path.join(base, name))

    errors = []

    for mid, (talent, name) in sorted(declared.items()):
        key = prefix + name + "_+0"
        if key not in text_keys:
            errors.append("measure %d: label %s missing from Text.dbt" % (mid, key))

        script = by_id.get(mid)
        if script is None:
            # The row inherits the vanilla script path. The filename number is
            # the ID over ten for 62 of the 64 declared rows, so only trust that
            # when exactly one file matches; IDs 481 and 1800 break the pattern.
            stem = "ms_%03d_" % (mid // 10)
            hits = [n for n in on_disk if n.startswith(stem)]
            if len(hits) != 1:
                errors.append(
                    "measure %d: script inherited from vanilla and %d files match %s*, "
                    "cannot verify call site" % (mid, len(hits), stem)
                )
                continue
            script = hits[0]

        path = on_disk.get(script)
        if path is None:
            errors.append("measure %d: script %s not on disk" % (mid, script))
            continue

        body = read(path)
        if "mdata_ShowTalentOSH" not in body:
            errors.append("measure %d: %s never calls mdata_ShowTalentOSH" % (mid, script))
            continue

        cost = re.search(r'ShowTalentOSH\(MeasureID,\s*"cost"\)', body)
        slot = "cost" if cost else "runtime"
        setter = "OSHSetMeasureCost" if cost else "OSHSetMeasureRuntime"
        if setter in body:
            errors.append(
                "measure %d: %s borrows the %s row but already calls %s"
                % (mid, script, slot, setter)
            )

    # Every per-language file needs the same label rows, or that language shows
    # a raw key where the row should be.
    langs = 0
    for entry in sorted(os.listdir(LANGUAGES)):
        path = os.path.join(LANGUAGES, entry, "Text.dbt")
        if not entry.startswith("#") or not os.path.isfile(path):
            continue
        langs += 1
        rows = read(path, "utf-16").count("MEASURES_TALENT_")
        if rows != len(ICON_ROWS):
            errors.append(
                "language %s: %d talent label rows, expected %d"
                % (entry, rows, len(ICON_ROWS))
            )

    if errors:
        print("\n".join("FAIL: " + e for e in errors))
        return 1
    talents = len(set(t for t, _ in declared.values()))
    print(
        "OK: %d measures, %d talents, %d label rows in English + %d language files"
        % (len(declared), talents, len(ICON_ROWS), langs)
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
