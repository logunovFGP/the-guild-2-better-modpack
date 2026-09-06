"""Summarise what the AI dynasties did in one game session, and replay the tree's
weighted-random selection under alternative tuning from that same session - no
second run needed.

    python tools/modding_helpers/ai_telemetry.py [path/to/logfile.log]
    python tools/modding_helpers/ai_telemetry.py --selftest

Without a path it reads $GUILD2/logfile.log, falling back to the Steam install.
The game truncates the log on every launch, so copy a run you want to keep.

Line shapes written by Scripts/Library/utility.lua and aitwp.lua (each after "[Script] "):

  ::TWP::LOADED utility.lua                   once per start; missing = the Include failed
  ::TWP::ENV lua=.. table.sort=.. pairs=..    once per start: which stdlib parts exist
  ::TWP::SNAPSHOT t= round= diff= dyn= persona= money= bld= ws= members= title= office= rank=
                  enemies= P= A= I= goal= target= ticks= name=<free text, last>
                                              one per AI dynasty per game day
  ::TWP::MEMBER dyn= sim=<free text>          one per party member per day
  ::TWP::GOAL t= dyn= P= A= ambition= greed= bloodlust= enemies= members= ws= wanted=
              politics= economy= family= conflict= pick= target=
                                              each time a goal is (re)chosen
  -- the rest only with Log = 1 under [AI] in configs/config.ini --
  ::TWP::W t= dyn= node= base= c=<x:curve;..> g=<aligned|other|none> w=
                                              every Weight() of an instrumented node
  ::TWP::PICK t= dyn= node=                   the node the engine executed
  ::TWP::ENEMY t= dyn= goaltarget= cand=<id:favor:foe:shadow;..> pick=
  ::TWP::BLD t= owner= mode= class= cand=<idx:class:level;..> pick=
  ::TWP::BELIEVER t= actor= victim= mode= maxfavor= cand=<dyn:favorfrom:liking:office;..> pick=
  [Script] Executing Measures/<name>.lua on <sim>    written by the engine itself

Replay: a W line carries every input of utility_Score, so the weight under any other
UTILITY_LO/HI or goal factor is recomputed here (VARIANTS), summed against the
siblings logged at the same t, and turned into a predicted pick share per node. The
observed PICK share is printed beside it: if the two disagree for the "current"
variant, the roulette model is wrong, not the tuning.
"""
import os
import re
import sys
import tempfile
from collections import Counter, OrderedDict, defaultdict

SNAPSHOT = re.compile(r"::TWP::SNAPSHOT (.*?) name=(.*)$")
MEMBER = re.compile(r"::TWP::MEMBER dyn=(\S+) sim=(.*)$")
GOAL = re.compile(r"::TWP::GOAL (.*)$")
WEIGHT = re.compile(r"::TWP::W (.*)$")
PICK = re.compile(r"::TWP::PICK (.*)$")
ENEMY = re.compile(r"::TWP::ENEMY (.*)$")
BLD = re.compile(r"::TWP::BLD (.*)$")
BELIEVER = re.compile(r"::TWP::BELIEVER (.*)$")
TRACE = re.compile(r"::TWP::AI:: (.*)$")
MEASURE = re.compile(r"Executing Measures/(\S+) on (.*)$")
ENV = re.compile(r"::TWP::ENV (.*)$")

ROOTS = {"Dynasty", "Election", "Feud", "Trial", "Duel", "ToMEconomy", "Priorities", "IncomeForAI", "DoNothing", "BloodFeud"}
BLOODFEUD = {"bf_Provoke", "bf_ForgeEvidence", "bf_Charge", "bf_Razzia", "bf_Ambush", "bf_Recruit", "bf_Equip",
             "bf_Taunt", "bf_FundAllies", "bf_Hideout", "bf_Procure", "bf_Stock", "bf_Draw", "bf_UseArtefact",
             "bf_UseBuildingArtefact"}
DYNASTY = {"AIContractGuildHouse", "ApplyForOffice", "BuildHome", "CollectBankDebts", "CourtLover", "DefendRogue",
           "EducateChildren", "Festivities", "HireMyrmidon", "HomeLevelUp", "ManageParty", "NobilityTitle",
           "Privilege", "ReceiveDignitaries", "RepairBuildings", "Reproduce", "SelfHeal", "SocialLife",
           "Underworld", "d_GoIdle", "PlayerFriend"}
ECONOMY = {"BuildWorkshop", "BuyWorkshop", "SellWorkshop", "Workshop"}
LEVELS = [("root", ROOTS), ("Dynasty/", DYNASTY), ("ToMEconomy/", ECONOMY), ("BloodFeud/", BLOODFEUD)]
COLUMNS = ["money", "bld", "ws", "members", "title", "office", "rank", "enemies", "P", "A", "I", "ticks"]

# name -> (UTILITY_LO, UTILITY_HI, UTILITY_GOAL_ALIGNED, UTILITY_GOAL_OTHER)
VARIANTS = OrderedDict([
    ("current", (0.5, 1.5, 3.0, 0.3)),
    ("wide", (0.25, 1.75, 3.0, 0.3)),
    ("narrow", (0.75, 1.25, 3.0, 0.3)),
    ("goals x5", (0.5, 1.5, 5.0, 0.2)),
    ("no goals", (0.5, 1.5, 1.0, 1.0)),
    ("flat (old)", (1.0, 1.0, 1.0, 1.0)),
])


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


def curve(x, kind):
    x = min(1.0, max(0.0, x))
    if kind == "quad":
        return x * x
    if kind == "sqrt":
        return x ** 0.5
    if kind == "invert":
        return 1.0 - x
    return x


def replay(base, considerations, goal_state, variant):
    lo, hi, aligned, other = variant
    weight = base
    for x, kind in considerations:
        weight *= lo + (hi - lo) * curve(x, kind)
    if goal_state == "aligned":
        weight *= aligned
    elif goal_state == "other":
        weight *= other
    return weight


def level_of(node):
    for index, (_name, nodes) in enumerate(LEVELS):
        if node in nodes:
            return index
    return None


class Session(object):
    def __init__(self):
        self.loaded = False
        self.env = None
        self.first, self.last = OrderedDict(), {}
        self.goals = []
        self.groups = defaultdict(list)          # (dyn, t, level) -> [(node, base, cons, g, w)]
        self.picks = Counter()
        self.enemy, self.bld, self.believer = [], [], []
        self.trace = Counter()
        self.measures = Counter()
        self.measures_by_goal = defaultdict(Counter)
        self.mismatch = 0
        self.errors = Counter()

    def feed(self, lines):
        dyn_of_sim, goal_of_dyn = {}, {}
        for line in lines:
            line = line.rstrip("\r\n")
            if "attempt to " in line:
                # a Lua runtime error; a node that errors in Weight() silently weighs 0
                self.errors[line.split("]", 1)[-1].strip()[:120]] += 1
                continue
            if "::TWP::LOADED" in line:
                self.loaded = True
                continue
            m = ENV.search(line)
            if m:
                self.env = m.group(1)
                continue
            m = SNAPSHOT.search(line)
            if m:
                fields = kv(m.group(1))
                fields["name"] = m.group(2).strip()
                key = fields.get("dyn", fields["name"])
                self.first.setdefault(key, fields)
                self.last[key] = fields
                if fields.get("goal", "-") != "-":
                    goal_of_dyn[key] = fields["goal"]
                continue
            m = MEMBER.search(line)
            if m:
                dyn_of_sim[m.group(2).strip()] = m.group(1)
                continue
            m = GOAL.search(line)
            if m:
                fields = kv(m.group(1))
                self.goals.append(fields)
                goal_of_dyn[fields.get("dyn")] = fields.get("pick")
                continue
            m = WEIGHT.search(line)
            if m:
                fields = kv(m.group(1))
                node = fields.get("node", "?")
                level = level_of(node)
                if level is None:
                    continue
                cons = []
                for part in fields.get("c", "").split(";"):
                    if part:
                        x, _sep, kind = part.partition(":")
                        cons.append((num(x), kind or "linear"))
                base, g, w = num(fields.get("base")), fields.get("g", "none"), num(fields.get("w"))
                if abs(replay(base, cons, g, VARIANTS["current"]) - w) > 0.01:
                    self.mismatch += 1
                self.groups[(fields.get("dyn"), fields.get("t"), level)].append((node, base, cons, g, w))
                continue
            m = PICK.search(line)
            if m:
                self.picks[kv(m.group(1)).get("node", "?")] += 1
                continue
            m = ENEMY.search(line)
            if m:
                self.enemy.append(kv(m.group(1)))
                continue
            m = BLD.search(line)
            if m:
                self.bld.append(kv(m.group(1)))
                continue
            m = BELIEVER.search(line)
            if m:
                self.believer.append(kv(m.group(1)))
                continue
            m = TRACE.search(line)
            if m:
                self.trace[" ".join(m.group(1).split()[2:])[:70]] += 1
                continue
            m = MEASURE.search(line)
            if m:
                name, sim = m.group(1), m.group(2).strip()
                self.measures[name] += 1
                dyn = dyn_of_sim.get(sim)
                goal = goal_of_dyn.get(dyn, "AI, goal unknown") if dyn else "not an AI party member"
                self.measures_by_goal[goal][name] += 1

    # predicted pick probability per node and variant, averaged over the evaluations of its level
    def predicted(self):
        result = {}
        for index, (name, _nodes) in enumerate(LEVELS):
            per_variant = {v: defaultdict(float) for v in VARIANTS}
            evaluations = 0
            for (dyn, t, level), entries in self.groups.items():
                if level != index:
                    continue
                evaluations += 1
                for v, params in VARIANTS.items():
                    weights = {node: replay(base, cons, g, params) for node, base, cons, g, _w in entries}
                    total = sum(weights.values())
                    if total > 0:
                        for node, w in weights.items():
                            per_variant[v][node] += w / total
            result[name] = (evaluations, {v: {n: s / evaluations for n, s in shares.items()}
                                          for v, shares in per_variant.items()} if evaluations else {})
        return result

    def root_cadence(self):
        by_dyn = defaultdict(set)
        for (dyn, t, level) in self.groups:
            if level == 0:
                by_dyn[dyn].add(num(t))
        gaps = []
        for times in by_dyn.values():
            ordered = sorted(times)
            gaps += [b - a for a, b in zip(ordered, ordered[1:])]
        if not gaps:
            return None
        gaps.sort()
        return gaps[len(gaps) // 2]


def delta(a, b):
    try:
        d = int(float(b)) - int(float(a))
    except (TypeError, ValueError):
        return b
    return "%s (%+d)" % (b, d) if d else b


def report(session, path):
    out = []
    out.append("%s" % path)
    out.append("utility.lua loaded: %s" % ("yes" if session.loaded else "NO - Include failed, utility nodes weigh 0"))
    if session.env:
        out.append("engine Lua: %s" % session.env)
    if session.last:
        snap = list(session.last.values())[-1]
        out.append("scenario: round %s, difficulty %s (Feud building attacks and the gauntlet need >= 2; the AI truce lasts 5 - difficulty rounds)"
                   % (snap.get("round", "?"), snap.get("diff", "? (older build)")))
    if session.errors:
        out.append("Lua runtime errors: %d (a node that errors in Weight() weighs 0 without a trace)" % sum(session.errors.values()))
        for text, count in session.errors.most_common(5):
            out.append("  %5d  %s" % (count, text))

    if session.first:
        widths = {c: max(len(c), 11) for c in COLUMNS}
        out.append("")
        out.append("%-24s %-7s %-9s " % ("dynasty", "persona", "goal") + " ".join("%-*s" % (widths[c], c) for c in COLUMNS))
        for key, snap in session.first.items():
            end = session.last[key]
            cells = [delta(snap.get(c), end.get(c)) for c in COLUMNS]
            out.append("%-24s %-7s %-9s " % (end["name"][:24], end.get("persona", "?"), end.get("goal", "-"))
                       + " ".join("%-*s" % (widths[c], v) for c, v in zip(COLUMNS, cells)))
        times = [num(s.get("t")) for s in list(session.first.values()) + list(session.last.values())]
        out.append("%d dynasties, game hours %d -> %d (last value, change since first snapshot in brackets)"
                   % (len(session.first), min(times), max(times)))
        ticks = [num(s.get("ticks")) for k, s in session.last.items() if s is not session.first[k]]
        if ticks:
            out.append("root evaluations per dynasty per day (snapshot ticks=): mean %.1f" % (sum(ticks) / len(ticks)))
    else:
        out.append("no ::TWP::SNAPSHOT lines (one per AI dynasty per game day once Priorities.lua has run)")

    gap = session.root_cadence()
    if gap is not None:
        out.append("root level evaluated every %.2f game hours per dynasty (median gap between W groups)" % gap)

    if session.goals:
        out.append("")
        out.append("goal choices: %d" % len(session.goals))
        picks = Counter(g.get("pick") for g in session.goals)
        persona_of = {k: s.get("persona", "?") for k, s in session.last.items()}
        by_persona = defaultdict(Counter)
        for g in session.goals:
            by_persona[persona_of.get(g.get("dyn"), "?")][g.get("pick")] += 1
        out.append("  " + ", ".join("%s %d" % (k, v) for k, v in picks.most_common()))
        for persona in sorted(by_persona):
            out.append("  persona %s: %s" % (persona, ", ".join("%s %d" % (k, v) for k, v in by_persona[persona].most_common())))

    predicted = session.predicted()
    for name, (evaluations, shares) in predicted.items():
        if not evaluations:
            continue
        nodes = sorted(set(n for v in shares.values() for n in v), key=lambda n: -shares["current"].get(n, 0))
        level_picks = sum(session.picks[n] for n in nodes)
        out.append("")
        out.append("%s level: %d evaluations, %d picks logged. observed pick share vs predicted share per variant:" % (name, evaluations, level_picks))
        out.append("  %-22s %6s %8s " % ("node", "picks", "observed") + " ".join("%11s" % v for v in VARIANTS))
        for node in nodes:
            observed = (100.0 * session.picks[node] / level_picks) if level_picks else 0.0
            out.append("  %-22s %6d %7.1f%% " % (node, session.picks[node], observed)
                       + " ".join("%10.1f%%" % (100.0 * shares[v].get(node, 0.0)) for v in VARIANTS))
    if session.mismatch:
        out.append("WARNING: %d W lines do not replay to their logged w under the current variant (custom lo/hi?)" % session.mismatch)

    if session.measures:
        total = sum(session.measures.values())
        out.append("")
        out.append("measure starts (top 12 of %d):" % total)
        for name, count in session.measures.most_common(12):
            out.append("  %6d  %5.1f%%  %s" % (count, 100.0 * count / total, name))
        for goal, counter in sorted(session.measures_by_goal.items(), key=lambda kv_: -sum(kv_[1].values())):
            subtotal = sum(counter.values())
            out.append("  while goal = %s (%d): %s" % (goal, subtotal, ", ".join(
                "%s %d" % (n.replace(".lua", ""), c) for n, c in counter.most_common(6))))

    if session.enemy or session.bld or session.believer:
        out.append("")
        out.append("target decisions:")
    if session.enemy:
        with_goal = [e for e in session.enemy if e.get("goaltarget", "0") not in ("0", "-1")]
        kept = sum(1 for e in with_goal if e.get("pick") == e.get("goaltarget"))
        cands = [len([c for c in e.get("cand", "").split(";") if c]) for e in session.enemy]
        out.append("  enemy: %d decisions, %.1f living candidates on average, goal target kept %d/%d times"
                   % (len(session.enemy), sum(cands) / float(len(cands)), kept, len(with_goal)))
    if session.bld:
        cands = [len([c for c in b.get("cand", "").split(";") if c]) for b in session.bld]
        out.append("  building: %d decisions, %.1f candidates on average, %d found nothing"
                   % (len(session.bld), sum(cands) / float(len(cands)), sum(1 for b in session.bld if b.get("pick") == "-1")))
    if session.believer:
        office = 0
        for b in session.believer:
            for c in b.get("cand", "").split(";"):
                parts = c.split(":")
                if len(parts) == 4 and parts[0] == b.get("pick") and num(parts[3]) > 0:
                    office += 1
        out.append("  believer: %d decisions, %d picked an office holder, %d found nobody"
                   % (len(session.believer), office, sum(1 for b in session.believer if b.get("pick") == "-1")))

    if session.trace:
        out.append("")
        out.append("AI trace messages (top 10 of %d):" % sum(session.trace.values()))
        for message, count in session.trace.most_common(10):
            out.append("  %6d  %s" % (count, message))
    elif not session.groups:
        out.append("")
        out.append("no Log = 1 detail (W/PICK/trace lines); set Log = 1 under [AI] in configs/config.ini for the replay tables")
    return "\n".join(out)


SAMPLE = """[Script] ::TWP::LOADED utility.lua
[Script] ::TWP::ENV lua=Lua 5.1 table.sort=true pairs=function
[Script] ::TWP::MEMBER dyn=1 sim=Bero Freudenreich
[Script] ::TWP::SNAPSHOT t=8 round=0 diff=4 dyn=1 persona=3 money=1000 bld=2 ws=1 members=1 title=2 office=-1 rank=5 enemies=1 P=20 A=60 I=10 goal=- target=0 ticks=0 name=Bero Freudenreich
[Script] ::TWP::GOAL t=8.00 dyn=1 P=20 A=60 ambition=80 greed=40 bloodlust=20 enemies=1 members=1 ws=1 wanted=1 politics=60 economy=20 family=60 conflict=80 pick=Conflict target=9
[Script] ::TWP::W t=10.00 dyn=1 node=Dynasty base=50 c= g=none w=50
[Script] ::TWP::W t=10.00 dyn=1 node=Feud base=30 c=0.80:linear g=aligned w=117.00
[Script] ::TWP::W t=10.00 dyn=1 node=DoNothing base=5 c= g=none w=5
[Script] ::TWP::PICK t=10.00 dyn=1 node=Feud
[Script] Executing Measures/ms_036_AttackEnemy.lua on Bero Freudenreich
[Script] ::TWP::W t=11.00 dyn=1 node=Dynasty base=50 c= g=none w=50
[Script] ::TWP::W t=11.00 dyn=1 node=DoNothing base=5 c= g=none w=5
[Script] ::TWP::PICK t=11.00 dyn=1 node=Dynasty
[Script] Executing Measures/ms_036_AttackEnemy.lua on Bero Freudenreich
[Script] Executing Measures/ms_003_Walk.lua on Player Guy
[Script] ::TWP::ENEMY t=10.00 dyn=1 goaltarget=9 cand=7:20:0:0;9:70:1:1; pick=9
[Script] ::TWP::BLD t=10.00 owner=9 mode=strongest class=-1 cand=0:6:3;1:1:1;2:2:2; pick=2
[Script] ::TWP::BELIEVER t=10.00 actor=1 victim=9 mode=office maxfavor=60 cand=7:30:55:2;8:70:10:-1; pick=7
[Script] ::TWP::MEMBER dyn=1 sim=Bero Freudenreich
[Script] ::TWP::SNAPSHOT t=32 round=0 diff=4 dyn=1 persona=3 money=1500 bld=2 ws=1 members=1 title=2 office=-1 rank=6 enemies=1 P=25 A=62 I=10 goal=Conflict target=9 ticks=24 name=Bero Freudenreich
"""


def selftest():
    session = Session()
    session.feed(SAMPLE.splitlines())
    _evals, root = session.predicted()["root"]
    assert session.loaded and _evals == 2, _evals
    assert abs(root["current"]["Feud"] - 0.3401) < 0.001, root["current"]
    assert abs(root["flat (old)"]["Feud"] - 0.1765) < 0.001, root["flat (old)"]
    assert abs(root["current"]["Dynasty"] - 0.5999) < 0.001, root["current"]
    assert session.mismatch == 0
    assert session.picks["Feud"] == 1 and session.picks["Dynasty"] == 1
    assert abs(session.root_cadence() - 1.0) < 1e-9
    assert session.measures_by_goal["Conflict"]["ms_036_AttackEnemy.lua"] == 2
    assert session.measures_by_goal["not an AI party member"]["ms_003_Walk.lua"] == 1
    assert session.last["1"]["ticks"] == "24" and session.goals[0]["pick"] == "Conflict"
    text = report(session, "<sample>")
    assert "goal target kept 1/1" in text and "1 picked an office holder" in text, text
    print(text)
    print("\nselftest ok")
    return 0


def main(argv):
    if len(argv) > 1 and argv[1] == "--selftest":
        return selftest()
    path = argv[1] if len(argv) > 1 else default_log_path()
    session = Session()
    with open(path, encoding="utf-8", errors="replace") as handle:
        session.feed(handle)
    print(report(session, path))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
