"""Generate docs/ITEMS.md: every item in the game with its producer and its effect.

    python tools/modding_helpers/gen_items_md.py [--out docs/ITEMS.md]

Sources (the mod's table overrides the vanilla one row by row; "~" keeps the
vanilla value):

  DB/Items.dbt              id, name, type, ..., manufacturer = building type that makes it
  DB/BuildingToItems.dbt    building id, building name, "item ids this building produces"
  DB/ItemsToMarket.dbt      itemid, name, buildingtype (the market that stocks it),
                            minlevel (town level), spawn_gamestart (units at start)
  DB/Buildings.dbt          id, buildtime, name, class, level, type
  DB/Languages/Text.dbt     _ITEM_<name>_NAME_+0 and _ITEM_<name>_TOOLTIP_+0 (UTF-16LE)
  DB/Measures.dbt, DB/MeasureToObjects.dbt, DB/Filter.dbt
                            the Use<item> measure and its target filter -> the "Used on" column

The vanilla install is $GUILD2, else the Steam path. Python on Windows needs G:/ paths.
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
VANILLA = os.environ.get("GUILD2") or "G:/SteamLibrary/steamapps/common/The Guild 2 Renaissance"


def lines(path):
    if not os.path.exists(path):
        return []
    data = open(path, "rb").read()
    text = data.decode("utf-16-le", "replace") if b"\x00" in data[:200] else data.decode("utf-8", "replace")
    return text.splitlines()


def fields(line):
    # quoted strings are one field however they are spaced; the mod's rows use single spaces
    return [t.strip('"') for t in re.findall(r'"[^"]*"|\S+', line.strip().rstrip("|").strip())]


def table(name):
    """Rows by id, vanilla first, mod overlay with '~' inheritance."""
    rows = {}
    for base in (os.path.join(VANILLA, "DB", name), os.path.join(REPO, "DB", name)):
        for line in lines(base):
            if not re.match(r"^\s*\d+\s", line) or line.strip().startswith("//"):
                continue
            f = fields(line)
            old = rows.get(f[0])
            if old is None:
                rows[f[0]] = f
            else:
                rows[f[0]] = [f[i] if (i < len(f) and f[i] != "~") else (old[i] if i < len(old) else "") for i in range(max(len(f), len(old)))]
    return rows


def texts():
    out = {}
    for base in (os.path.join(VANILLA, "DB", "Languages", "Text.dbt"), os.path.join(REPO, "DB", "Languages", "Text.dbt")):
        for line in lines(base):
            m = re.search(r'"_ITEM_([A-Za-z0-9]+)_(NAME|TOOLTIP)_\+0"\s+"([^"]*)"', line)
            if m:
                out[(m.group(1), m.group(2))] = m.group(3)
    return out


def used_on_map():
    """item name -> what the Use<item> measure targets, from Measures/MeasureToObjects/Filter."""
    filt = {}
    for base in (os.path.join(VANILLA, "DB", "Filter.dbt"), os.path.join(REPO, "DB", "Filter.dbt")):
        for line in lines(base):
            m = re.match(r'^\s*(\d+)\s+"([^"]*)"\s+"(.*)"\s*\|?\s*$', line)
            if m:
                filt[m.group(1)] = (m.group(2), m.group(3))
    name2mid = {}
    for mid, f in table("Measures.dbt").items():
        if len(f) > 3:
            name2mid.setdefault(f[3].lower(), mid)
    rows = {}
    for f in table("MeasureToObjects.dbt").values():
        if len(f) > 4:
            rows.setdefault(f[1], f)

    def classify(item):
        mid = name2mid.get("use" + item.lower())
        if not mid:
            return "-"
        f = rows.get(mid)
        if not f:
            return "self"
        targets = f[7] if len(f) > 7 else ""
        kind = "building" if "2" in targets else "cart" if "3" in targets else "character"
        fname, expr = filt.get(f[3], ("", ""))
        if f[3] in ("0", "", "~"):
            return "position" if "4" in targets else "self"
        if "NOT(Object.BelongsToMe())" in expr or "CanBeAttacked" in fname or "Evil" in fname or "KeineArtefakte" in fname:
            return "another dynasty's " + kind
        if "BelongsToMe" in expr or fname.startswith("IsMy"):
            return "own " + kind
        return "other: " + (fname or expr[:40])
    return classify


def clean(text):
    text = re.sub(r"#E\[[A-Z_]+\]", "", text)
    text = text.replace("$N", " ").replace("|", "\\|")
    return re.sub(r"\s+", " ", text).strip()


def base_name(building):
    return re.sub(r"\d+[a-z]?$", "", building)


def main(argv):
    out_path = os.path.join(REPO, "docs", "ITEMS.md")
    if "--out" in argv:
        out_path = argv[argv.index("--out") + 1]

    items = table("Items.dbt")
    buildings = table("Buildings.dbt")
    type_name, building_name = {}, {}
    for f in sorted(buildings.values(), key=lambda r: int(r[0])):
        if len(f) > 5:
            type_name.setdefault(f[5], base_name(f[2]))
            building_name[f[0]] = base_name(f[2])

    producers = {}
    for f in table("BuildingToItems.dbt").values():
        if len(f) > 2:
            for iid in f[2].split():
                producers.setdefault(iid, set()).add(base_name(f[1]))

    # ItemsToMarket: id, itemid, name, buildingtype, minlevel, spawn_gamestart -> keyed by item id
    market = {}
    for f in table("ItemsToMarket.dbt").values():
        if len(f) > 5:
            market[f[1]] = (type_name.get(f[3], "type " + f[3]), f[4], f[5])

    txt = texts()
    used_on = used_on_map()

    by_type = {}
    for iid, f in items.items():
        if len(f) < 3 or not f[1] or f[1] == "~":
            continue
        by_type.setdefault(f[2], []).append((iid, f))

    out = []
    out.append("# Items")
    out.append("")
    out.append("Generated by `tools/modding_helpers/gen_items_md.py` from `DB/Items.dbt`, `DB/BuildingToItems.dbt`,")
    out.append("`DB/ItemsToMarket.dbt`, `DB/Buildings.dbt` and the English texts (mod tables over vanilla). Do not edit by hand.")
    out.append("")
    out.append("**Producer** = the building that manufactures the item (from `BuildingToItems` and the item's `manufacturer`")
    out.append("column) and, when a market stocks it, the market it spawns at with the town level needed and the units")
    out.append("placed at game start. **Used on** comes from the target filter of the item's `Use<name>` measure:")
    out.append("self, own building/cart, another dynasty's character or building, or a position; it decides")
    out.append("whether an item is a weapon against others or a buff for oneself. \"Another dynasty's character\"")
    out.append("also covers friendly gifts (Poem, Tart); the Effect column tells which. **Effect** is the in-game tooltip.")
    out.append("")
    labels = {"0": "engine placeholders (cannons, empty slot)", "2": "intermediate goods", "3": "trade goods, food, weapons and armour, deliveries",
              "5": "artefacts and documents", "8": "raw produce"}
    total = 0
    for t in sorted(by_type, key=lambda k: int(k)):
        rows = sorted(by_type[t], key=lambda r: (txt.get((r[1][1], "NAME"), r[1][1]).lower()))
        examples = ", ".join(clean(txt.get((f[1], "NAME"), f[1])) for _i, f in rows[:4])
        out.append("## Type %s: %s (%d items, e.g. %s)" % (t, labels.get(t, "unlabelled"), len(rows), examples))
        out.append("")
        out.append("| Producer | Name | Used on | Effect |")
        out.append("|---|---|---|---|")
        for iid, f in rows:
            name = f[1]
            prod = set(producers.get(iid, set()))
            if len(f) > 12 and f[12] not in ("", "0", "~"):
                # the manufacturer column is a Buildings.dbt row id
                prod.add(building_name.get(f[12], "building " + f[12]))
            parts = []
            if prod:
                parts.append("produced: " + ", ".join(sorted(prod)))
            if iid in market:
                where, lvl, spawn = market[iid]
                parts.append("sold: %s market, town level %s%s" % (where, lvl, (", %s at start" % spawn) if spawn not in ("0", "") else ""))
            producer = "; ".join(parts) or "-"
            display = clean(txt.get((name, "NAME"), ""))
            label = "**%s** (`%s`, id %s)" % (display, name, iid) if display else "`%s` (id %s)" % (name, iid)
            effect = clean(txt.get((name, "TOOLTIP"), "")) or "-"
            out.append("| %s | %s | %s | %s |" % (producer, label, used_on(name), effect))
            total += 1
        out.append("")
    out.append("%d items." % total)
    with open(out_path, "w", encoding="utf-8", newline="\n") as handle:
        handle.write("\n".join(out) + "\n")
    print("wrote %s: %d items in %d types" % (os.path.relpath(out_path, REPO), total, len(by_type)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
