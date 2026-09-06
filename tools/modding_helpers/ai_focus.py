"""Who is after whom: the dynasty-focused view of one session's AI telemetry.

    python tools/modding_helpers/ai_focus.py [logfile] [--dynasty ID|name] [--family NAME]
    python tools/modding_helpers/ai_focus.py --selftest

Complements ai_telemetry.py (aggregate replay) with the questions of the first
session review: "nothing hostile happened to me, why?"

  * which AI dynasties list the focus dynasty as an enemy, how often they picked
    the Feud subtree, what its root weighed for them, and which hostile measures
    their party members started
  * how often the focus dynasty was the target of a building search (BLD) or a
    believer pick (BELIEVER)
  * enemy-list churn: InitEnemies re-rolls, in clusters (one cluster = one save
    load), and how many distinct lists each dynasty went through
  * subtree conversion: root picks vs. starts of the measures that subtree's
    leaves can run (names read from Scripts/AI/BaseTree/<subtree>/**), so a
    branch that soaks up ticks without acting stands out
  * hostile measure starts by actor: AI party members per dynasty, the focus
    family's own sims (--family, e.g. Barker), and everyone else (hired sims)
  * the distinct ::TWP::AI:: trace kinds

Focus defaults to the one dynasty id that appears in ENEMY candidate lists but never
in a SNAPSHOT - the human player, who has no AI snapshot. Needs Log = 1 data
(W, PICK, ENEMY, BLD, BELIEVER, trace); see ai_telemetry.py for the line formats.
"""
import os
import re
import sys
from collections import Counter, defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))

SNAPSHOT = re.compile(r"::TWP::SNAPSHOT (.*?) name=(.*)$")
MEMBER = re.compile(r"::TWP::MEMBER dyn=(\S+) sim=(.*)$")
WEIGHT = re.compile(r"::TWP::W (.*)$")
PICK = re.compile(r"::TWP::PICK (.*)$")
ENEMY = re.compile(r"::TWP::ENEMY (.*)$")
BLD = re.compile(r"::TWP::BLD (.*)$")
BELIEVER = re.compile(r"::TWP::BELIEVER (.*)$")
TRACE = re.compile(r"::TWP::AI:: (.*)$")
MEASURE = re.compile(r"Executing Measures/(\S+) on (.*)$")
MEASURE_NAME = re.compile(r'Measure(?:Run|Start)\([^)]*"([A-Za-z_]+)"\s*\)')
HOSTILE = re.compile(r"attack|sabot|\brob|rough|insult|blackmail|slander|charge|kidnap|poison|arson|steal"
                     r"|confisc|demolish|inspect|toad|gauntlet|discord|torture|detain|\bban|demand|brainwash"
                     r"|inquisit|scold|evidence|finish|bomb|mixture|hex|voodo|pddv|rome|widow", re.I)
SUBTREES = ["Dynasty", "Election", "Feud", "Trial", "Duel", "ToMEconomy", "BloodFeud"]
IDLE_MEASURES = {"DynastyIdle", "Idle", "GoIdle"}   # fall-through, not an action
LOAD_GAP_HOURS = 6.0


def default_log_path():
    root = os.environ.get("GUILD2") or r"G:\SteamLibrary\steamapps\common\The Guild 2 Renaissance"
    return os.path.join(root, "logfile.log")


def kv(text):
    return dict(part.split("=", 1) for part in text.split() if "=" in part)


def num(value, default=0.0):
    try:
        return float(value)
    except (TypeError, ValueError):
        return default


class Session(object):
    def __init__(self):
        self.names, self.persona, self.goal = {}, {}, {}
        self.dyn_of_sim = {}
        self.listed_by = defaultdict(Counter)    # candidate id -> {dyn: times listed}
        self.picked_by = defaultdict(Counter)    # candidate id -> {dyn: times picked}
        self.enemy_lists = defaultdict(set)      # dyn -> distinct candidate sets
        self.enemy_decisions = 0
        self.feud_w = defaultdict(list)          # dyn -> [(goal state, weight)]
        self.picks = defaultdict(Counter)        # dyn -> {node: picks}
        self.bld_owner, self.bld_total = Counter(), 0
        self.believer_victim, self.believer_total = Counter(), 0
        self.trace = Counter()
        self.init_enemies = []                   # (game hour, dynasty name)
        self.loads = 0
        self.measures = []                       # (measure file, actor sim)
        self.t = None

    def feed(self, lines):
        for line in lines:
            line = line.rstrip("\r\n")
            if "::TWP::LOADED" in line:
                self.loads += 1
                continue
            m = SNAPSHOT.search(line)
            if m:
                f = kv(m.group(1))
                dyn = f.get("dyn")
                self.names[dyn] = m.group(2).strip()
                self.persona[dyn] = f.get("persona", "?")
                if f.get("goal", "-") != "-":
                    self.goal[dyn] = f["goal"]
                continue
            m = MEMBER.search(line)
            if m:
                self.dyn_of_sim[m.group(2).strip()] = m.group(1)
                continue
            m = WEIGHT.search(line)
            if m:
                f = kv(m.group(1))
                self.t = num(f.get("t"), self.t)
                if f.get("node") == "Feud":
                    self.feud_w[f.get("dyn")].append((f.get("g", "none"), num(f.get("w"))))
                continue
            m = PICK.search(line)
            if m:
                f = kv(m.group(1))
                self.picks[f.get("dyn")][f.get("node", "?")] += 1
                continue
            m = ENEMY.search(line)
            if m:
                f = kv(m.group(1))
                dyn = f.get("dyn")
                cands = [c.split(":")[0] for c in f.get("cand", "").split(";") if c]
                self.enemy_decisions += 1
                for c in cands:
                    self.listed_by[c][dyn] += 1
                self.picked_by[f.get("pick")][dyn] += 1
                self.enemy_lists[dyn].add(frozenset(cands))
                continue
            m = BLD.search(line)
            if m:
                self.bld_total += 1
                self.bld_owner[kv(m.group(1)).get("owner")] += 1
                continue
            m = BELIEVER.search(line)
            if m:
                self.believer_total += 1
                self.believer_victim[kv(m.group(1)).get("victim")] += 1
                continue
            m = TRACE.search(line)
            if m:
                words = m.group(1).split()
                actor, message = " ".join(words[:2]), " ".join(words[2:])
                self.trace[re.sub(r"\d+", "N", message)[:70]] += 1
                if "InitEnemies Setting" in message:
                    self.init_enemies.append((self.t, actor))
                continue
            m = MEASURE.search(line)
            if m:
                self.measures.append((m.group(1), m.group(2).strip()))

    def resolve_focus(self, wanted):
        if wanted:
            if wanted in self.names or wanted in self.listed_by:
                return wanted
            matches = [d for d, n in self.names.items() if wanted.lower() in n.lower()]
            if len(matches) == 1:
                return matches[0]
            raise SystemExit("no unique dynasty matches %r (AI names: %s)" % (wanted, ", ".join(sorted(self.names.values()))))
        non_ai = [c for c in self.listed_by if c not in self.names]
        if len(non_ai) == 1:
            return non_ai[0]
        raise SystemExit("cannot infer the player's dynasty: non-AI ids in enemy lists = %s; pass --dynasty" % non_ai)


def subtree_measures(repo):
    """Measure names each BaseTree subtree can start, and which names several subtrees share."""
    root = os.path.join(repo, "Scripts", "AI", "BaseTree")
    names = {}
    for sub in SUBTREES:
        found = set()
        paths = [os.path.join(root, sub + ".lua")]
        for folder, _dirs, files in os.walk(os.path.join(root, sub)):
            paths += [os.path.join(folder, f) for f in files if f.endswith(".lua")]
        for p in paths:
            if os.path.exists(p):
                found |= set(MEASURE_NAME.findall(open(p, encoding="utf-8", errors="replace").read()))
        names[sub] = found
    shared = set(n for n in set.union(*names.values()) if sum(1 for s in names.values() if n in s) > 1) if names else set()
    return names, shared


def measure_matches(filename, name):
    base = os.path.basename(filename).lower()
    if base.endswith(".lua"):
        base = base[:-4]
    return re.fullmatch(r"(?:[a-z]+_)?(?:\d+[a-z]?_)?" + re.escape(name.lower()) + r"(?:_[a-z]+)?", base) is not None


def clusters(times):
    times = sorted(t for t in times if t is not None)
    out = []
    for t in times:
        if out and t - out[-1][1] <= LOAD_GAP_HOURS:
            out[-1][1] = t
            out[-1][2] += 1
        else:
            out.append([t, t, 1])
    return out


def report(s, focus, family, repo):
    out = []
    label = s.names.get(focus, "id %s (no AI snapshot: the player)" % focus)
    out.append("focus dynasty: %s" % label)

    out.append("")
    listers = sorted(s.listed_by[focus].items(), key=lambda kv_: -kv_[1])
    out.append("listed as an enemy by %d of %d AI dynasties; picked as THE enemy %d times in %d decisions where listed"
               % (len(listers), len(s.names), sum(s.picked_by[focus].values()), sum(s.listed_by[focus].values())))
    if listers:
        out.append("  %-22s %-7s %-9s %8s %12s %18s  %s" % ("dynasty", "persona", "goal", "listed", "Feud picks", "Feud W mean/aligned", "hostile measures by its members"))
    for dyn, listed in listers:
        ws = s.feud_w.get(dyn, [])
        mean = sum(w for _g, w in ws) / len(ws) if ws else 0.0
        aligned = sum(1 for g, _w in ws if g == "aligned")
        feud, total = s.picks[dyn]["Feud"], sum(s.picks[dyn].values())
        hostile = Counter(name for name, sim in s.measures if s.dyn_of_sim.get(sim) == dyn and HOSTILE.search(name))
        out.append("  %-22s %-7s %-9s %8d %5d/%-6d %9.1f / %-8d %s"
                   % (s.names.get(dyn, dyn)[:22], s.persona.get(dyn, "?"), s.goal.get(dyn, "-"), listed, feud, total, mean, aligned,
                      ", ".join("%s x%d" % (n.replace(".lua", ""), c) for n, c in hostile.most_common(4)) or "-"))

    out.append("")
    out.append("as a target: building searches on its buildings %d of %d; believer picks with it as victim %d of %d"
               % (s.bld_owner[focus], s.bld_total, s.believer_victim[focus], s.believer_total))

    out.append("")
    cl = clusters(t for t, _n in s.init_enemies)
    distinct = [len(v) for v in s.enemy_lists.values()]
    out.append("enemy lists: %d InitEnemies re-rolls in %d cluster(s) [%s]; %d game starts (LOADED); distinct lists per dynasty: max %d, mean %.1f"
               % (len(s.init_enemies), len(cl), ", ".join("~h%.0f x%d" % (c[0], c[2]) for c in cl), s.loads,
                  max(distinct) if distinct else 0, sum(distinct) / len(distinct) if distinct else 0.0))
    out.append("  a cluster per save load means AITWP_Enemies is not persisted; lists are drawn by Rand in InitEnemies")

    names, shared = subtree_measures(repo)
    out.append("")
    out.append("subtree conversion (root picks -> starts of measures its leaves can run, idle fall-throughs excluded; * = name shared by several subtrees):")
    total_picks = Counter()
    for dyn_picks in s.picks.values():
        total_picks.update(dyn_picks)
    for sub in SUBTREES:
        counts = Counter()
        for name in names.get(sub, ()):
            if name in IDLE_MEASURES:
                continue
            n = sum(1 for f, _sim in s.measures if measure_matches(f, name))
            if n:
                counts[name + ("*" if name in shared else "")] = n
        picks = total_picks[sub]
        starts = sum(counts.values())
        rate = (100.0 * starts / picks) if picks else 0.0
        out.append("  %-11s picks %6d  starts %5d  (%5.1f%%)  %s" % (sub, picks, starts, rate,
                   ", ".join("%s %d" % (n, c) for n, c in counts.most_common(6))))

    out.append("")
    out.append("hostile measure starts by actor:")
    by_actor = defaultdict(Counter)
    for name, sim in s.measures:
        if not HOSTILE.search(name):
            continue
        dyn = s.dyn_of_sim.get(sim)
        if dyn:
            who = "AI party member of " + s.names.get(dyn, dyn)
        elif family and family.lower() in sim.lower():
            who = "focus family (%s)" % family
        else:
            who = "other sim (hired hand%s)" % ("" if family else ", or the player: pass --family")
        by_actor[who][name.replace(".lua", "")] += 1
    for who, counter in sorted(by_actor.items(), key=lambda kv_: -sum(kv_[1].values())):
        out.append("  %-48s %s" % (who[:48], ", ".join("%s %d" % (n, c) for n, c in counter.most_common(5))))
    if not by_actor:
        out.append("  none")

    out.append("")
    out.append("trace kinds (top 12 of %d lines):" % sum(s.trace.values()))
    for kind, count in s.trace.most_common(12):
        out.append("  %6d  %s" % (count, kind))
    return "\n".join(out)


SAMPLE = """[Script] ::TWP::LOADED utility.lua AI.Log=0 OPTIONS.AILog=1
[Script] ::TWP::MEMBER dyn=1 sim=Tuva Einarson
[Script] ::TWP::SNAPSHOT t=8 round=35 diff=4 dyn=1 persona=0 money=1000 bld=2 ws=1 members=1 title=2 office=-1 rank=5 enemies=2 P=20 A=60 I=10 goal=Conflict target=999 ticks=0 name=Tuva Einarson
[Script] ::TWP::SNAPSHOT t=8 round=35 diff=4 dyn=2 persona=4 money=1000 bld=2 ws=1 members=1 title=2 office=-1 rank=5 enemies=1 P=20 A=10 I=10 goal=Economy target=0 ticks=0 name=Lotte Sackner
[Script] ::TWP::W t=10.00 dyn=1 node=Feud base=30 c=0.60:linear g=aligned w=99.00
[Script] ::TWP::AI:: Tuva Einarson InitEnemies Setting enemies to: 999,2,
[Script] ::TWP::ENEMY t=10.00 dyn=1 goaltarget=999 cand=999:10:1:0;2:40:0:0; pick=999
[Script] ::TWP::PICK t=10.00 dyn=1 node=Feud
[Script] Executing Measures/ms_132_ChargeCharacter.lua on Tuva Einarson
[Script] ::TWP::W t=10.10 dyn=2 node=Feud base=30 c=0.10:linear g=other w=4.95
[Script] ::TWP::ENEMY t=10.10 dyn=2 goaltarget=0 cand=999:30:0:0; pick=999
[Script] ::TWP::PICK t=10.10 dyn=2 node=Dynasty
[Script] ::TWP::BLD t=10.20 owner=999 mode=strongest class=-1 cand=0:1:2; pick=0
[Script] ::TWP::BELIEVER t=10.30 actor=1 victim=999 mode=office maxfavor=60 cand=2:30:55:2; pick=2
[Script] Executing Measures/ms_142_OrderASabotage_Bomb.lua on Some Thug
[Script] Executing Measures/ms_003_Walk.lua on Olina Barker
[Script] ::TWP::W t=30.00 dyn=1 node=Feud base=30 c=0.60:linear g=aligned w=99.00
[Script] ::TWP::AI:: Tuva Einarson InitEnemies Setting enemies to: 2,
[Script] ::TWP::ENEMY t=30.00 dyn=1 goaltarget=999 cand=2:40:0:0; pick=2
"""


def selftest():
    s = Session()
    s.feed(SAMPLE.splitlines())
    focus = s.resolve_focus(None)
    assert focus == "999", focus
    assert dict(s.listed_by["999"]) == {"1": 1, "2": 1} and s.picked_by["999"]["1"] == 1
    assert s.picks["1"]["Feud"] == 1 and s.feud_w["1"][0] == ("aligned", 99.0)
    assert s.bld_owner["999"] == 1 and s.believer_victim["999"] == 1
    assert len(s.init_enemies) == 2 and len(clusters(t for t, _n in s.init_enemies)) == 2
    assert len(s.enemy_lists["1"]) == 2
    assert measure_matches("ms_132_ChargeCharacter.lua", "ChargeCharacter")
    assert measure_matches("Artefacts/as_UseToadExcrements.lua", "UseToadExcrements")
    assert measure_matches("ms_142_OrderASabotage_Bomb.lua", "OrderASabotage")
    assert not measure_matches("ms_003_Walk.lua", "Rob")
    text = report(s, focus, "Barker", REPO)
    assert "listed as an enemy by 2 of 2" in text and "ChargeCharacter x1" in text, text
    print(text)
    print("\nselftest ok")
    return 0


def main(argv):
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    if "--selftest" in argv:
        return selftest()
    args = [a for a in argv[1:] if not a.startswith("--")]
    opts = {}
    for i, a in enumerate(argv):
        if a in ("--dynasty", "--family", "--repo") and i + 1 < len(argv):
            opts[a] = argv[i + 1]
    path = args[0] if args and args[0] not in opts.values() else default_log_path()
    s = Session()
    with open(path, encoding="utf-8", errors="replace") as handle:
        s.feed(handle)
    focus = s.resolve_focus(opts.get("--dynasty"))
    print(path)
    print(report(s, focus, opts.get("--family"), opts.get("--repo", REPO)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
