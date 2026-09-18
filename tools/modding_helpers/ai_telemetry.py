"""Summarise what the AI dynasties did in one game session, and replay the tree's
weighted-random selection under alternative tuning from that same session - no
second run needed.

    python tools/modding_helpers/ai_telemetry.py [path/to/logfile.log]
    python tools/modding_helpers/ai_telemetry.py [path/to/logfile.log] --findings
    python tools/modding_helpers/ai_telemetry.py --selftest

--findings prints only the checks: one ERROR / WARN / NOTE line each, with a literal
pointer to the file to open. They are everything six play sessions taught us, so the
next log does not have to be read from scratch - see the findings section below, and
add to CHECKS whenever a session teaches us something new.

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
  -- every line except LOADED and ENV goes through utility_Emit, gated by UTILITY_LOG
  -- (nil follows Log = 1 under [AI] in configs/config.ini; false silences, true forces) --
  ::TWP::W t= dyn= node= base= c=<x:curve[:lo:hi];..> g=<aligned|other|none> w=
                                              every Weight() of an instrumented node
  ::TWP::PICK t= dyn= node=                   the node the engine executed
  ::TWP::ENEMY t= dyn= goaltarget= cand=<id:favor:foe:shadow;..> pick=
  ::TWP::BLD t= owner= mode= class= cand=<idx:class:level;..> pick=
  ::TWP::BELIEVER t= actor= victim= mode= maxfavor= cand=<dyn:favorfrom:liking:office;..> pick=
  ::TWP::MARKET t= dyn= items=<name:home:away;..>  daily per blood rival: stock of each ladder item at the
                                              home market and in every other town's market or Kontor
  ::TWP::CART t= dyn= action=<buy|send|arrive> cart= carts= busy= need= money= result= items=<name,amount;..>
                                              the feud supply cart (result= of arrive is the count bought;
                                              action=courier: carts= delivered, need= ordered, result= rung gap)
  ::TWP::HANDOVER t= dyn= sim= item= today=<n>/<cap>   a tool handed from the residence store to a unit
  ::TWP::HTN t= dyn= task= method= step= chain= fail=<Task.method:Predicate;..>
                                              one per feud plan: the method taken and, for every method
                                              that did not apply, the precondition that fell first
  ::TWP::WHY t= dyn= <fight mine= theirs= chance= bar= | tools rung= carried= handovers=>
                                              the numbers behind an HTN predicate the fail= reason can only name
  ::TWP::ORDER t= sim= measure= action=<ordered|busy|sametick>   aitwp_ClaimOrder, the shared re-order guard
  ::TWP::CARTBUY t= dyn= bought= carts=<before>to<after> ok=   the feud cart purchase, judged on the count
  ::TWP::BLOODENEMY player= enemy= action=<chosen|kept> name=<free text, last>
                                              who each human player's blood rival is, on every sweep
  ::TWP::BB unregistered key <key> in <where>   a blackboard key nobody declared: it reads nil forever
  ::TWP::WAR t= dyn= raid= target= party= leader= chance= sent= odds=
                                              one per decided raid: assassination_attempt, workers_raid,
                                              raid_building, kidnap or kidnap_child; sent= is whether the
                                              squad actually formed, odds= the kidnap chance (-1 elsewhere)
  [StartMeasure] <sim>: Canceled 'A'(p) because of priority 'B'(q)
                                              engine: a measure start lost to the running one; p, q are
                                              the interruptvalue column of DB/Measures.dbt
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
import textwrap
from collections import Counter, OrderedDict, defaultdict, namedtuple

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
MARKET = re.compile(r"::TWP::MARKET (.*)$")
CART = re.compile(r"::TWP::CART (.*)$")
HANDOVER = re.compile(r"::TWP::HANDOVER (.*)$")
HTN = re.compile(r"::TWP::HTN (.*)$")
WHY = re.compile(r"::TWP::WHY (.*)$")
ORDER = re.compile(r"::TWP::ORDER (.*)$")
CARTBUY = re.compile(r"::TWP::CARTBUY (.*)$")
BLOODENEMY = re.compile(r"::TWP::BLOODENEMY (.*)$")
WAR = re.compile(r"::TWP::WAR (.*)$")
BB = re.compile(r"::TWP::BB (.*)$")
CANCEL = re.compile(r"\[StartMeasure\] (.*?): Canceled '(\w+)'\((\d+)\) because of priority '(\w+)'\((\d+)\)")

ROOTS = {"Dynasty", "Election", "Feud", "Trial", "Duel", "ToMEconomy", "Priorities", "IncomeForAI", "DoNothing", "BloodFeud"}
BLOODFEUD = {"bf_Provoke", "bf_ForgeEvidence", "bf_Charge", "bf_Razzia", "bf_Assassinate", "bf_WorkersRaid", "bf_RaidBuilding", "bf_Kidnap", "bf_KidnapChild", "bf_Recruit", "bf_Equip",
             "bf_Taunt", "bf_FundAllies", "bf_Hideout", "bf_Procure", "bf_UseArtefact",
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


# utility.lua multiplies the leaf aihtn_Step named by UTILITY_HTN_FACTOR, so the
# replay has to know it or every planned bf_ line reads as a mismatch. Not a tuning
# variant: the planner either points at a leaf or it does not.
HTN_FACTOR = 3.0


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


def replay(base, considerations, goal_state, variant, htn="-"):
    lo, hi, aligned, other = variant
    weight = base
    for x, kind, band in considerations:
        # a consideration with its own lo/hi band keeps it under every variant
        clo, chi = band if band else (lo, hi)
        weight *= clo + (chi - clo) * curve(x, kind)
    if goal_state == "aligned":
        weight *= aligned
    elif goal_state == "other":
        weight *= other
    if htn == "step":
        weight *= HTN_FACTOR
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
        self.market, self.carts, self.cancels, self.handovers = {}, [], Counter(), []
        self.htn = []                            # one entry per ::TWP::HTN line
        self.why, self.orders, self.cartbuy = [], [], []
        self.rivals, self.blackboard, self.raids = [], Counter(), []
        self.libs = set()                        # the library names that printed LOADED
        self.self_cancel = Counter()             # measure -> starts that cancelled themselves
        self.self_cancel_runs = Counter()        # of those, the ones on the very next log line
        self.pick_seq = defaultdict(list)        # dyn -> picked nodes, in order

    def feed(self, lines):
        dyn_of_sim, goal_of_dyn = {}, {}
        last_self_cancel = (None, -2)
        for index, line in enumerate(lines):
            line = line.rstrip("\r\n")
            if "attempt to " in line:
                # a Lua runtime error; a node that errors in Weight() silently weighs 0
                self.errors[line.split("]", 1)[-1].strip()[:120]] += 1
                continue
            if "::TWP::LOADED" in line:
                self.loaded = True
                parts = line.split("::TWP::LOADED", 1)[1].split()
                if parts:
                    self.libs.add(parts[0])
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
                        bits = part.split(":")
                        band = (num(bits[2]), num(bits[3])) if len(bits) >= 4 else None
                        cons.append((num(bits[0]), bits[1] if len(bits) > 1 and bits[1] else "linear", band))
                base, g, w = num(fields.get("base")), fields.get("g", "none"), num(fields.get("w"))
                h = fields.get("h", "-")          # only bf_ lines carry it
                # Inputs are logged through %.2f, so x carries up to 0.005 of rounding;
                # a quad curve on a wide band turns that into ~1% of the weight. Compare
                # in proportion, or every IncomeForAI and Trial line reads as a mismatch.
                if abs(replay(base, cons, g, VARIANTS["current"], h) - w) > max(0.01, 0.02 * w):
                    self.mismatch += 1
                self.groups[(fields.get("dyn"), fields.get("t"), level)].append((node, base, cons, g, h, w))
                continue
            m = PICK.search(line)
            if m:
                fields = kv(m.group(1))
                node = fields.get("node", "?")
                self.picks[node] += 1
                self.pick_seq[fields.get("dyn")].append(node)
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
            m = CANCEL.search(line)
            if m:
                self.cancels["%s(%s) lost to %s(%s)" % (m.group(2), m.group(3), m.group(4), m.group(5))] += 1
                # A measure re-ordered while it is still running cancels itself at equal
                # priority - that is the icon blinking, not two measures competing. A run
                # of them on consecutive log lines is one tick's worth of re-orders.
                if m.group(2) == m.group(4) and m.group(3) == m.group(5):
                    who = (m.group(1), m.group(2))
                    self.self_cancel[m.group(2)] += 1
                    if last_self_cancel == (who, index - 1):
                        self.self_cancel_runs[m.group(2)] += 1
                    last_self_cancel = (who, index)
                continue
            m = MARKET.search(line)
            if m:
                fields = kv(m.group(1))
                self.market[fields.get("dyn")] = fields
                continue
            m = CART.search(line)
            if m:
                self.carts.append(kv(m.group(1)))
                continue
            m = HANDOVER.search(line)
            if m:
                self.handovers.append(kv(m.group(1)))
                continue
            m = HTN.search(line)
            if m:
                self.htn.append(kv(m.group(1)))
                continue
            m = WHY.search(line)
            if m:
                self.why.append(kv(m.group(1)))
                continue
            m = ORDER.search(line)
            if m:
                self.orders.append(kv(m.group(1)))
                continue
            m = CARTBUY.search(line)
            if m:
                self.cartbuy.append(kv(m.group(1)))
                continue
            m = BLOODENEMY.search(line)
            if m:
                self.rivals.append(kv(m.group(1)))
                continue
            m = WAR.search(line)
            if m:
                self.raids.append(kv(m.group(1)))
                continue
            m = BB.search(line)
            if m:
                self.blackboard[m.group(1).strip()[:90]] += 1
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
                    weights = {node: replay(base, cons, g, params, h) for node, base, cons, g, h, _w in entries}  # cons carry their bands
                    total = sum(weights.values())
                    if total > 0:
                        for node, w in weights.items():
                            per_variant[v][node] += w / total
            result[name] = (evaluations, {v: {n: s / evaluations for n, s in shares.items()}
                                          for v, shares in per_variant.items()} if evaluations else {})
        return result

    def barren_entries(self):
        """BloodFeud entries where no bf_ leaf was picked next: the tick the subtree
        spent finding every child at 0. Session 2 (before the planner): 85 of 110."""
        barren = total = 0
        for nodes in self.pick_seq.values():
            for i, node in enumerate(nodes):
                if node != "BloodFeud":
                    continue
                total += 1
                if i + 1 >= len(nodes) or not nodes[i + 1].startswith("bf_"):
                    barren += 1
        return barren, total

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


# --------------------------------------------------------------------------- findings
# Six play sessions of forensics, written down as checks that run themselves. In: the
# log. Out: ERROR (something is broken right now), WARN (the AI is not doing what the
# design says it should), NOTE (expected behaviour, but the answer to a question that
# keeps coming back). Printed at the top of the report, or alone with --findings.
#
# Every pointer is a literal string naming the file to open, and where a thing was
# fixed it says so with the date - a finding that should be impossible then reads
# "inspect this", not "known issue". Pointers are never computed from the log: one
# that is goes stale without anyone noticing.
#
# Adding a check: write a generator that takes the Session and yields Finding(...),
# then put it in CHECKS. One line of text, one actionable sentence of pointer.
Finding = namedtuple("Finding", "level code text pointer")

SEVERITY = {"ERROR": 0, "WARN": 1, "NOTE": 2}

# A vanilla GUI error, once per start, nothing to do with the AI.
KNOWN_NOISE = "FindPanelsByTexture"

# Measures vanilla has always re-ordered on top of themselves. Counted, never blamed.
VANILLA_SELF_CANCEL = ("UseLaborOfLove", "Flirt", "BribeCharacter", "MakeACompliment", "PickpocketPeople")

# The libraries that print a LOADED probe. utility.lua prints its own unconditionally,
# so a log with none of these came from a game that never loaded the mod at all.
EXPECTED_LIBS = ("utility.lua", "aiboard.lua", "aihtn.lua")

STDAFX = ("Scripts/Library/stdafx.lua - a library loads only from its Include line there, never from "
          "its filename. aiboard.lua and trade.lua were missing from it and eight BloodFeud leaves "
          "errored in Weight() and weighed 0; fixed 2026-09-14. If this is back, an Include line was "
          "lost - check_unresolved_calls.py fails on that too.")

# Methods of AIHTN_TASKS whose failure has already been chased down once. Anything not
# listed gets the generic pointer in check_htn_methods.
HTN_NOTES = {
    "Feud.taunt": ("NOTE",
        "Expected against a blood rival, not a defect: the taunt letter needs NotFoe and a blood rival "
        "is already DIP_FOE. Scripts/Library/aihtn.lua, method taunt; the same gate is in "
        "Scripts/AI/BaseTree/BloodFeud/bf_Taunt.lua."),
    "Feud.duel": ("NOTE",
        "The duel modes of aitwp_PlayerTargetScore (Scripts/Library/aitwp.lua) return nil for a target "
        "that is indoors (SimIsInside), under 16, or the wrong class - a player who spends the day inside "
        "buildings cannot be provoked at all. 189 of 189 on 2026-09-18."),
    "Feud.assassinate": ("WARN",
        "Scripts/AI/BaseTree/BloodFeud/bf_Assassinate.lua. The bar is TWP_ATTACK_WIN_CHANCE = 0.75 and the "
        "party is aitwp_WarCandidates - half the thugs, a third of any other pool, plus the family rogues - "
        "committed one at a time by aitwp_WarCommit until it clears. The ::TWP::WHY lines carry party=, "
        "theirs= and chance=; the gate is Patron or round 10 (aitwp_RaidAllowed)."),
    "Feud.kidnap": ("NOTE",
        "Scripts/AI/BaseTree/BloodFeud/bf_Kidnap.lua. Two numbers have to clear, not one: the fight "
        "(aitwp_WinChance) and the snatch (aitwp_KidnapChance, bar TWP_KIDNAP_BAR). It also needs a "
        "thieves' guild of the house's own for the cell - ms_SquadHijackMember.lua stops dead without one "
        "and bf_Hideout is what buys it. Inside a town only when the house holds an office with "
        "CommandCityGuard; the ::TWP::WHY kidnap lines carry odds=, bar= and hands=."),
    "Feud.kidnapchild": ("NOTE",
        "Scripts/AI/BaseTree/BloodFeud/bf_KidnapChild.lua. Same as the kidnap but the target must be under "
        "sixteen (aitwp_FindReachableTarget mode child), and the gate is Patron with no round that opens "
        "it instead. A house with no player child in reach fails here every tick, which is normal."),
    "Feud.workersraid": ("NOTE",
        "Scripts/AI/BaseTree/BloodFeud/bf_WorkersRaid.lua. Needs a player worker outside the town radius at "
        "that moment (aitwp_FindWorkerTarget), so it fails all the hours the mines and huts are idle - that "
        "is expected, not a defect. Same gate as the assassination."),
    "Feud.raidbuilding": ("NOTE",
        "Scripts/AI/BaseTree/BloodFeud/bf_RaidBuilding.lua. The strictest gate in the tree: the player a "
        "high noble (Baron, rung 6) AND round 10, both. aitwp_FindOutsideBuilding wants a player building "
        "beyond the town radius, which many maps simply do not give the player."),
    "Feud.artefact": ("WARN",
        "aitwp_ReadyArtefacts wants the tool allowed at the player's rung (the ladder in aitwp_Allowed), "
        "off its Use<item> cooldown, and either in hand or handed over from the store. The ::TWP::WHY "
        "tools lines carry rung=, carried= and handovers=."),
    "Feud.building": ("NOTE",
        "The same aitwp_ReadyArtefacts pass as Feud.artefact, counting only the rows whose target is a "
        "building. A house with no building artefact allowed at the player's rung is the normal case "
        "early on; it stops being normal once the ::TWP::WHY tools rung climbs."),
    "Feud.razzia": ("NOTE",
        "Needs an idle myrmidon and TWP_BF_RAZZIA_EVIDENCE of evidence against the player. Evidence comes "
        "from ms_211_OrderCollectEvidence, which self-cancels - see the self-cancel finding."),
    "HaveEvidence.ready": ("NOTE",
        "No party member holds evidence against the player: aitwp_FindAccuser in Scripts/Library/aitwp.lua. "
        "Evidence is gathered by ms_211_OrderCollectEvidence and decays."),
    "HaveEvidence.forge": ("NOTE",
        "No Hexerdokument in hand or in the store: aitwp_ForgeryDocument. The feud cart buys them, so read "
        "the cart findings and the market nowhere column first."),
}

# The one check that reads the tree instead of the log: knobs lowered for a test run
# and easy to ship by accident.
TEST_KNOBS = (
    ("Scripts/Library/aitwp.lua", "TWP_BF_SUPPLY_HOURS", "2",
     "game hours between feud supply runs; 1 is the testing value, so one game day exercises the cart"),
    ("Scripts/AI/BaseTree/ToMEconomy/BuyWorkshop.lua", "TOM_BUY_WORKSHOP_HOURS", "96",
     "game hours between workshop purchases, before the difficulty scaling below it"),
)


def check_telemetry(s):
    if not s.libs and not s.groups and not s.last:
        yield Finding("ERROR", "no-telemetry", "not one ::TWP:: line in this file",
                      "Either the wrong file - the game truncates logfile.log on every launch, so copy a "
                      "run worth keeping - or mods/Reforged does not point at this checkout. " + STDAFX)
        return
    missing = [lib for lib in EXPECTED_LIBS if lib not in s.libs]
    if s.libs and missing:
        yield Finding("ERROR", "library-not-loaded", "no LOADED probe for " + ", ".join(missing), STDAFX)
    if s.libs and not s.groups:
        yield Finding("NOTE", "detail-log-off", "libraries loaded, but no W or PICK lines in the file",
                      "Log = 1 under [AI] in configs/config.ini, or AILog = 1 under [OPTIONS] in "
                      "userconfig.ini. Without it every weight below is blind.")


def check_runtime_errors(s):
    for text, count in s.errors.most_common(8):
        if KNOWN_NOISE in text:
            yield Finding("NOTE", "vanilla-noise", "%s x%d" % (text[:80], count),
                          "Pre-existing vanilla GUI error, unrelated to the AI; expected once per start.")
            continue
        ours = False
        for name in ("aiboard_", "aihtn_", "aitwp_", "utility_", "trade_"):
            if name in text:
                ours = True
        yield Finding("ERROR", "lua-error", "%s x%d" % (text[:95], count),
                      STDAFX if ours else
                      "A node that errors in Weight() weighs 0 and says nothing else, so this is never "
                      "cosmetic. Find the file named in the message, then run check_unresolved_calls.py - "
                      "it resolves every call in the tree against the exe bindings.")


def check_blackboard(s):
    for text, count in s.blackboard.most_common(6):
        yield Finding("ERROR", "unregistered-key", "%s x%d" % (text, count),
                      "Scripts/Library/aiboard.lua, BLACKBOARD_KEYS - a property the tree reads but never "
                      "declared. It reads nil forever, so the node that depends on it quietly weighs 0. "
                      "basetree_stats.py fails on this statically and exits 1, so a key showing up only "
                      "here is one built at runtime from pieces rather than written as a literal.")


def check_replay(s):
    if s.mismatch:
        yield Finding("ERROR", "replay-mismatch",
                      "%d W lines did not replay to their own logged w=" % s.mismatch,
                      "utility_Score in Scripts/Library/utility.lua and VARIANTS['current'] in this file "
                      "have drifted apart, so every predicted share below is wrong. The usual cause is a "
                      "new multiplier in Score that replay() does not model - the HTN x3 was one.")


def check_self_cancel(s):
    for measure, count in s.self_cancel.most_common(6):
        if count < 3:
            continue
        runs = s.self_cancel_runs[measure]
        if measure == "Attack":
            level = "WARN"
            pointer = ("Scripts/Measures/Behaviour/bs_IllegalDetection.lua orders Attack through "
                       "aitwp_ClaimOrder since 2026-09-18. Several crime events reach Run() in one tick "
                       "while GetCurrentMeasureName still names the old measure, so each one re-orders "
                       "Attack and cancels the running one: the attack icon blinking. Cross-check the "
                       "::TWP::ORDER lines for this measure - cancels with no action=busy or "
                       "action=sametick beside them mean the guard is a no-op again.")
        elif measure == "OrderCollectEvidence":
            level = "WARN"
            pointer = ("Scripts/Library/idlelib.lua, the myrmidon idle cycle, which orders this through "
                       "aitwp_ClaimOrder since 2026-09-18 - a myrmidon already collecting used to come back "
                       "round the loop and cancel its own sweep. It costs the feud its evidence when it "
                       "happens: HaveEvidence.ready needs aitwp_FindAccuser to find a member actually "
                       "holding some, and Feud.razzia needs TWP_BF_RAZZIA_EVIDENCE of it, so 92 of these on "
                       "2026-09-18 left two whole branches of the feud dead all day.")
        elif measure in VANILLA_SELF_CANCEL:
            level = "NOTE"
            pointer = ("Vanilla, and it has always done this: the idle library re-issues the measure while it "
                       "runs. Nothing of ours orders it. Noise unless the count changes by an order of "
                       "magnitude between sessions.")
        else:
            level = "NOTE"
            pointer = ("A measure re-ordered while it still runs cancels itself at equal priority. Vanilla "
                       "does this in several places; it only matters where the restart is visible or throws "
                       "work away. Guard the order site the way OrderAttack in "
                       "Scripts/Measures/Behaviour/bs_IllegalDetection.lua does.")
        yield Finding(level, "self-cancel",
                      "%s cancelled its own start %d times, %d of them on the very next log line"
                      % (measure, count, runs), pointer)


def check_order_guard(s):
    # The guard's job is to stop one sim being told to start the same measure twice in one
    # tick. That - not "no order was ever blocked" - is what proves it dead. The engine
    # starts Attack from its own combat reactions too, without passing through any Lua, so
    # a self-cancel with no order beside it is not evidence against the guard: on
    # 2026-09-18 that inference cried ERROR at a guard that was working perfectly.
    per_measure = defaultdict(Counter)
    repeats, seen = Counter(), defaultdict(set)
    for order in s.orders:
        measure = order.get("measure", "?")
        per_measure[measure][order.get("action", "?")] += 1
        if order.get("action") == "ordered":
            key = (order.get("sim"), order.get("t"))
            if key in seen[measure]:
                repeats[measure] += 1
            seen[measure].add(key)
    for measure, actions in sorted(per_measure.items(), key=lambda pair: -sum(pair[1].values())):
        cancelled = s.self_cancel.get(measure, 0)
        if repeats[measure]:
            yield Finding("ERROR", "order-guard-dead",
                          "%s: %d orders repeated a sim inside one tick (engine cancels: %d)"
                          % (measure, repeats[measure], cancelled),
                          "aitwp_ClaimOrder in Scripts/Library/aitwp.lua is not holding for this measure: the "
                          "same sim was told to start it twice at one timestamp, which is exactly what the "
                          "per-tick stamp exists to stop. If the stamp is integral and still misses, the "
                          "property is not handing back what was written - that failure made the first "
                          "version of this guard a silent no-op for a whole session.")
        else:
            yield Finding("NOTE", "order-guard",
                          "%s: %d ordered, %d refused as already running, %d refused inside one tick, "
                          "no sim ordered twice in a tick (engine cancels: %d)"
                          % (measure, actions["ordered"], actions["busy"], actions["sametick"], cancelled),
                          "aitwp_ClaimOrder in Scripts/Library/aitwp.lua, the shared re-order guard, called "
                          "from Scripts/Measures/Behaviour/bs_IllegalDetection.lua for Attack and from "
                          "Scripts/Library/idlelib.lua for OrderCollectEvidence. Working as intended.")


def check_barren(s):
    barren, total = s.barren_entries()
    if not total:
        return
    share = 100.0 * barren / total
    yield Finding("WARN" if share > 20 else "NOTE", "bloodfeud-barren",
                  "%d of %d BloodFeud entries fired no leaf (%.0f%%); 85/110 before the planner, 18/30 "
                  "after the gate, 0/17 on 2026-09-18" % (barren, total, share),
                  "Scripts/AI/BaseTree/BloodFeud.lua - the aihtn_Step gate is the only thing standing "
                  "between the subtree and a wasted tick now; the W = 15 dampener was deleted on "
                  "2026-09-18 once this reached zero, because every trigger it had left was the ordinary "
                  "window between entering and the leaf firing. A barren entry means a method applied and "
                  "its leaf still weighed 0, so that method is missing one of the leaf's own gates: "
                  "Scripts/Library/aihtn.lua, AIHTN_TASKS.")


def check_economy_barren(s):
    """ToMEconomy picks whose children were never scored: the tick the subtree spent
    finding every child at 0. 234 of 262 on 2026-09-18, and 637 of 637 in September."""
    entered = sum(nodes.count("ToMEconomy") for nodes in s.pick_seq.values())
    if not entered:
        return
    # the ToMEconomy/ level is index 2 of LEVELS; one W group per entry that reached a child
    scored = len(set((dyn, t) for (dyn, t, level) in s.groups if level == 2))
    barren = max(0, entered - scored)
    share = 100.0 * barren / entered
    yield Finding("WARN" if share > 20 else "NOTE", "economy-barren",
                  "%d of %d ToMEconomy entries never scored a child (%.0f%%); 234 of 262 on 2026-09-18"
                  % (barren, entered, share),
                  "Scripts/AI/BaseTree/ToMEconomy.lua - the aitwp_EconomyReady gate added 2026-09-18, the "
                  "same shape as the aihtn_Step gate on BloodFeud. All four children open on a cooldown "
                  "(AI_CheckWorkshop per member, BasicAI_NewWorkshop, AI_BuyWorkshop, BasicAI_SellShop) and "
                  "the root could not see any of them. If this climbs again, a fifth child has been added "
                  "whose gate aitwp_EconomyReady does not know about.")


def check_htn_methods(s):
    if not s.htn:
        return
    plans = len(s.htn)
    chosen = Counter(h.get("method") for h in s.htn)
    by_method = defaultdict(Counter)
    for h in s.htn:
        for reason in h.get("fail", "-").split(";"):
            if reason and reason != "-" and ":" in reason:
                method, _sep, predicate = reason.partition(":")
                by_method[method][predicate] += 1
    for method in sorted(by_method, key=lambda m: -sum(by_method[m].values())):
        if chosen.get(method.split(".")[-1], 0):
            continue
        hits = sum(by_method[method].values())
        if hits < plans:
            continue
        predicate, count = by_method[method].most_common(1)[0]
        level, pointer = HTN_NOTES.get(method, ("WARN",
            "Scripts/Library/aihtn.lua, AIHTN_TASKS - this method's when= list and the leaf it promises. A "
            "method that never applies is either correctly gated out by the scenario or gated on something "
            "its leaf does not actually need."))
        yield Finding(level, "htn-method-never-applied",
                      "%s applied in none of %d plans; %s fell %d times" % (method, plans, predicate, count),
                      pointer)


def check_htn_promise(s):
    planned = Counter(h.get("step") for h in s.htn if h.get("step", "-") != "-")
    for step, count in planned.most_common():
        picked = s.picks.get(step, 0)
        if count >= 5 and picked * 4 < count:
            yield Finding("WARN", "htn-step-unpicked",
                          "%s was planned %d times and picked %d: the x3 landed on a leaf weighing 0"
                          % (step, count, picked),
                          "Scripts/Library/aihtn.lua, AIHTN_TASKS - the method promising this leaf is "
                          "missing a gate the leaf has, almost always the target lookup. Six methods had "
                          "exactly this on 2026-09-17 (bf_Provoke planned 22, picked 1). The rule: a "
                          "precondition must be a necessary condition of the leaf's own Weight(), and "
                          "necessary is not enough - the method has to be predictive as well.")


def check_carts(s):
    buys = [c for c in s.carts if c.get("action") == "buy"]
    failed = [c for c in buys if c.get("result") != "true"]
    if failed:
        yield Finding("WARN", "cart-buy-failed",
                      "%d of %d feud cart purchases came back result=%s"
                      % (len(failed), len(buys), failed[-1].get("result")),
                      "aitwp_BuyResidenceCart in Scripts/Library/aitwp.lua, called from "
                      "Scripts/AI/BaseTree/BloodFeud/bf_Procure.lua. Three wrong root causes so far: "
                      "BuildingBuyCart is the ship native; bld_BuyCart reads the empty alias as the "
                      "building it runs on, which from an AI node is the dynasty; and then both natives "
                      "returned true and left the out alias unbound. Read the ::TWP::CARTBUY line before "
                      "touching anything - it names the step that fell.")
    for c in s.cartbuy[-2:]:
        if c.get("ok") != "true":
            yield Finding("NOTE", "cart-buy-step",
                          "CARTBUY bought=%s carts=%s ok=%s"
                          % tuple(c.get(k, "?") for k in ("bought", "carts", "ok")),
                          "aitwp_BuyResidenceCart in Scripts/Library/aitwp.lua. bought= is what "
                          "BuildingBuyCart returned and carts= is what the residence owned before and "
                          "after - the count is the truth and the return value is not, which is how three "
                          "fixes in a row believed a native that reported success and attached nothing. "
                          "bought=true with an unchanged count means the cart exists but not on this "
                          "building; check the residence cart cap before blaming the call.")
    sent = sum(1 for c in s.carts if c.get("action") == "send")
    home = sum(num(c.get("result")) for c in s.carts if c.get("action") == "arrive")
    if sent and not home:
        yield Finding("WARN", "cart-brings-nothing",
                      "%d supply runs left and nothing came home" % sent,
                      "Scripts/Measures/ms_bf_FeudSupply.lua - BuyInTown walks the workshop and resource "
                      "building classes with and without a dynasty, and BuyAt filters a rival's counter "
                      "through aitwp_WorthBuyingFromEnemy. An empty run means either nothing is for sale "
                      "(see the market nowhere column) or that filter is eating the whole list.")


def check_market(s):
    for dyn, fields in s.market.items():
        nowhere = []
        for entry in [e for e in fields.get("items", "").split(";") if e]:
            name, _sep, rest = entry.partition(":")
            home, _sep2, elsewhere = rest.partition(":")
            if num(home) <= 0 and num(elsewhere) <= 0:
                nowhere.append(name)
        if len(nowhere) >= 4:
            yield Finding("NOTE", "market-nowhere",
                          "dyn %s: %d ladder items are on sale nowhere (%s)"
                          % (dyn, len(nowhere), ", ".join(nowhere[:6])),
                          "aitwp_ShoppingList in Scripts/Library/aitwp.lua keeps asking for these and the "
                          "cart keeps coming home without them. Either no workshop in the world makes them "
                          "yet, or the scan in Scripts/Measures/ms_bf_FeudSupply.lua does not reach the "
                          "building class that does.")


def check_handovers(s):
    if s.htn and not s.handovers:
        yield Finding("NOTE", "no-handover",
                      "no tool ever left the residence store this session",
                      "aitwp_CanHandOver in Scripts/Library/aitwp.lua: the unit must carry no tool already "
                      "and the house must be under its daily cap. With stock at home and no hand-over the "
                      "block is usually aitwp_Allowed - the ladder will not release a tool above the "
                      "player's rung. The ::TWP::WHY tools lines carry that rung.")
    at_cap = [h for h in s.handovers if "/" in h.get("today", "") and
              h["today"].split("/")[0] == h["today"].split("/")[1]]
    if len(at_cap) >= 3:
        yield Finding("NOTE", "handover-cap",
                      "%d hand-overs hit the day's cap" % len(at_cap),
                      "aitwp_HandOverCap in Scripts/Library/aitwp.lua is members + myrmidons + 2. The house "
                      "is rationing tools; raising the cap makes the feud hit harder on the same stock.")


def check_buyworkshop(s):
    seen = sum(1 for entries in s.groups.values() for entry in entries if entry[0] == "BuyWorkshop")
    if 0 < seen <= 3:
        yield Finding("NOTE", "buyworkshop-rare",
                      "BuyWorkshop was scored %d times all session - too few to judge its weight" % seen,
                      "TOM_BUY_WORKSHOP_HOURS in Scripts/AI/BaseTree/ToMEconomy/BuyWorkshop.lua. The timer "
                      "is HOURS - difficulty*12, so the shipping 96 is a 48 game hour cooldown at "
                      "difficulty 4 and one game day evaluates the node about once. Lower it for a test "
                      "run and put it back.")


def check_raids(s):
    if not s.raids:
        return
    per_raid = defaultdict(Counter)
    for raid in s.raids:
        per_raid[raid.get("raid", "?")][raid.get("sent", "?")] += 1
    for raid, results in sorted(per_raid.items()):
        failed = sum(count for sent, count in results.items() if sent != "true")
        yield Finding("WARN" if failed else "NOTE", "raid",
                      "%s decided %d times, %d of them never formed a squad"
                      % (raid, sum(results.values()), failed),
                      "aitwp_SquadAttack in Scripts/Library/aitwp.lua creates the squad round the first "
                      "fighter and adds the rest; sent=false means SquadGet found no squad after "
                      "SquadCreate, so the leader measure name is wrong for that raid or the fighter could "
                      "not lead one. The leaves are Scripts/AI/BaseTree/BloodFeud/bf_Assassinate.lua, "
                      "bf_WorkersRaid.lua and bf_RaidBuilding.lua; each ::TWP::WAR line carries party=, "
                      "leader= and chance=.")


def check_blood_rival(s):
    if not s.groups:
        return
    if not s.htn:
        yield Finding("NOTE", "no-blood-rival",
                      "no dynasty ran the blood feud this session",
                      "aitwp_EnsureBloodEnemies, called daily from Scripts/AI/BaseTree/Priorities.lua, "
                      "gives every human player exactly one coloured AI dynasty as a blood rival and writes "
                      "AI_BloodEnemyOf. No HTN line at all means it never ran or never matched.")
        return
    dyns = sorted(set(h.get("dyn") for h in s.htn))
    if len(dyns) == 1:
        named = [r for r in s.rivals if r.get("enemy") == dyns[0]]
        who = (" = %s, player %s" % (named[-1].get("name", "?"), named[-1].get("player", "?"))) if named else ""
        yield Finding("NOTE", "one-blood-rival",
                      "the blood feud ran for exactly one dynasty (%s%s) - by design, one per human player"
                      % (dyns[0], who),
                      "Scripts/AI/BaseTree/BloodFeud.lua returns 0 without AI_BloodEnemyOf, so 'the AI "
                      "never attacked me' is a question about this one dynasty. The other houses run the "
                      "old Feud subtree under Scripts/AI/BaseTree/Feud, whose leaves are unscored constants "
                      "and do not target the player's own characters.")


def check_idle(s):
    total = sum(s.measures.values())
    idle = s.measures.get("ms_DynastyIdle.lua", 0) + s.measures.get("Behaviour/std_Idle.lua", 0)
    if total and idle * 2 > total:
        yield Finding("NOTE", "mostly-idle",
                      "%.0f%% of measure starts were idling (%d of %d)" % (100.0 * idle / total, idle, total),
                      "Expected while most party members have nothing assigned, but if it climbs, look at "
                      "the root weights: an AI that idles is an AI whose subtree children all weighed 0. "
                      "Scripts/AI/BaseTree, and basetree_stats.py --list zero-only.")


def check_test_knobs(_session):
    root = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
    for rel, knob, ship, what in TEST_KNOBS:
        path = os.path.join(root, *rel.split("/"))
        try:
            with open(path, encoding="utf-8", errors="replace") as handle:
                source = handle.read()
        except IOError:
            continue
        found = re.search(r"^%s\s*=\s*(\S+)" % knob, source, re.M)
        if found and found.group(1) != ship:
            yield Finding("NOTE", "test-knob", "%s = %s in the tree, ships at %s"
                          % (knob, found.group(1), ship),
                          "%s - %s. This is the one check that reads the checkout rather than the log. Put "
                          "it back before the branch goes out." % (rel, what))


CHECKS = (check_telemetry, check_runtime_errors, check_replay, check_self_cancel,
          check_order_guard, check_barren, check_economy_barren, check_blackboard, check_htn_methods, check_htn_promise, check_carts, check_market,
          check_handovers, check_buyworkshop, check_raids, check_blood_rival, check_idle, check_test_knobs)


def findings(session):
    found = []
    for check in CHECKS:
        found += list(check(session))
    found.sort(key=lambda f: SEVERITY.get(f.level, 3))
    return found


def format_findings(found):
    counts = Counter(f.level for f in found)
    parts = ["%d %s" % (counts[level], level.lower()) for level in ("ERROR", "WARN", "NOTE") if counts[level]]
    out = ["findings: %s" % (", ".join(parts) or "nothing to report")]
    for f in found:
        out.append("  %-5s %-26s %s" % (f.level, f.code, f.text))
        out += textwrap.wrap(f.pointer, width=104, initial_indent=" " * 8 + "-> ", subsequent_indent=" " * 11)
    return "\n".join(out)


# ------------------------------------------------------------------ pointer enforcement
# The findings above are worth exactly what their pointers are worth, and a pointer is a
# string: nothing stops one naming a file that moved or a function that was renamed, and
# it fails silently - the check still prints, it just sends you somewhere that is not
# there any more. A README line asking people to keep them honest is not enforcement.
# This is. It runs inside --selftest, the pass every change to this file already has to
# survive, and it fails the build.
#
# Four mechanical rules:
#   1. every repo path a pointer names exists on disk
#   2. every <library>_<Function> a pointer names is defined in that library (skipped
#      for a library that lives only in the vanilla tree, which is not in this checkout)
#   3. every TWP_ / TOM_ / UTILITY_ / AIHTN_ knob a pointer names still appears in the
#      Lua - a renamed knob vanishes from the tree, so this catches the rename
#   4. every ::TWP:: channel the Lua emits has a parser here. A channel nothing reads is
#      a channel the next session greps by hand, which is the failure this file exists
#      to end: telemetry added without a reader is telemetry added without a check.
#
# What it cannot enforce, stated plainly rather than pretended: that a defect chased
# down through a log actually became a check. Nothing mechanical can tell that a session
# taught us something. Rule 4 covers it only when the lesson came with a new log line,
# which so far it always has.
POINTER_PATH = re.compile(r"\b(?:Scripts|tools|docs)/[A-Za-z0-9_./]+\.(?:lua|py|md)\b")
POINTER_SYMBOL = re.compile(r"\b(aitwp|aihtn|aiboard|utility|bld|dyn|trade)_([A-Za-z]\w*)")
POINTER_KNOB = re.compile(r"\b(?:TWP|TOM|UTILITY|AIHTN)_[A-Z][A-Z0-9_]+\b")
LUA_CHANNEL = re.compile(r"::TWP::([A-Z]+)")
# Bounds of the findings section in this file: everything a Finding can print lives
# between these two literals.
POINTER_REGION = ("Finding = namedtuple(", "# ------------------------------------------------------------------ pointer")


def repo_root():
    return os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))


def lua_sources(root):
    """Every .lua file in the checkout, as one string plus the set of library basenames."""
    blob, libraries = [], {}
    for folder, _dirs, files in os.walk(os.path.join(root, "Scripts")):
        for name in files:
            if not name.endswith(".lua"):
                continue
            path = os.path.join(folder, name)
            with open(path, encoding="utf-8", errors="replace") as handle:
                text = handle.read()
            blob.append(text)
            if os.path.basename(folder).lower() == "library":
                libraries[name[:-4].lower()] = text
    return "\n".join(blob), libraries


def check_pointers():
    """Every pointer in this file resolves. Returns a list of problems; empty is good."""
    root = repo_root()
    with open(os.path.abspath(__file__), encoding="utf-8") as handle:
        source = handle.read()
    region = source[source.index(POINTER_REGION[0]):source.index(POINTER_REGION[1])]
    blob, libraries = lua_sources(root)
    problems = []

    paths = sorted(set(POINTER_PATH.findall(region)))
    for rel in paths:
        if not os.path.exists(os.path.join(root, *rel.split("/"))):
            problems.append("pointer names %s, which is not in the tree" % rel)

    symbols = sorted(set(POINTER_SYMBOL.findall(region)))
    for prefix, function in symbols:
        library = libraries.get(prefix)
        if library is None:
            continue                      # vanilla-only library, not in this checkout
        if not re.search(r"^function %s\(" % re.escape(function), library, re.M):
            problems.append("pointer names %s_%s, which %s.lua does not define" % (prefix, function, prefix))

    knobs = sorted(set(POINTER_KNOB.findall(region)))
    for knob in knobs:
        # on a word boundary: TWP_ATTACK_WIN_CHANC is a substring of the real knob and a
        # plain "in blob" test waves the typo through
        if not re.search(r"\b%s\b" % re.escape(knob), blob):
            problems.append("pointer names the knob %s, which no longer appears in the Lua" % knob)

    channels = sorted(set(LUA_CHANNEL.findall(blob)))
    for channel in channels:
        # a parser, not a mention: the channel has to be compiled into a regex or tested
        # for by name, or it is only spelled out in a comment somewhere
        if not re.search(r'(?:re\.compile\(r"|")::TWP::%s\b' % re.escape(channel), source):
            problems.append("the Lua emits ::TWP::%s and nothing here reads it - a channel without a "
                            "parser is a channel the next session greps by hand" % channel)

    return problems, (len(paths), len(symbols), len(knobs), len(channels))


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
    out.append("")
    out.append(format_findings(findings(session)))

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
        out.append("WARNING: %d W lines are more than 2%% off their logged w under the current variant (a wrong band, curve or goal factor - input rounding stays inside this)" % session.mismatch)

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

    if session.market:
        out.append("")
        out.append("market availability, last report per blood rival (item: stock at home / elsewhere):")
        for dyn, fields in session.market.items():
            here, away, nowhere = [], [], []
            for entry in [e for e in fields.get("items", "").split(";") if e]:
                name, _s, rest = entry.partition(":")
                home, _s, elsewhere = rest.partition(":")
                if num(home) > 0:
                    here.append("%s %d" % (name, num(home)))
                elif num(elsewhere) > 0:
                    away.append("%s %d" % (name, num(elsewhere)))
                else:
                    nowhere.append(name)
            out.append("  dyn %s at t=%s: home %s | elsewhere %s | nowhere %s"
                       % (dyn, fields.get("t"), ", ".join(here) or "-", ", ".join(away) or "-", ", ".join(nowhere) or "-"))
    if session.carts:
        out.append("")
        actions = Counter(c.get("action") for c in session.carts)
        bought = sum(num(c.get("result")) for c in session.carts if c.get("action") == "arrive")
        out.append("feud carts: %s; goods brought home %d" % (", ".join("%s %d" % a for a in actions.most_common()), bought))
        for c in session.carts[-6:]:
            out.append("  t=%s dyn=%s %s cart=%s carts=%s busy=%s need=%s result=%s items=%s"
                       % tuple(c.get(k, "?") for k in ("t", "dyn", "action", "cart", "carts", "busy", "need", "result", "items")))
    if session.handovers:
        out.append("")
        items = Counter(h.get("item") for h in session.handovers)
        at_cap = sum(1 for h in session.handovers if "/" in h.get("today", "") and h["today"].split("/")[0] == h["today"].split("/")[1])
        out.append("hand-overs from the store: %d (%d reached the day's cap): %s"
                   % (len(session.handovers), at_cap, ", ".join("%s %d" % i for i in items.most_common(8))))
    if session.htn:
        out.append("")
        stalled = [h for h in session.htn if h.get("step", "-") == "-"]
        out.append("HTN plans: %d, %d with no applicable method (%s)"
                   % (len(session.htn), len(stalled),
                      ", ".join("%s %d" % m for m in Counter(h.get("method") for h in session.htn).most_common(6))))
        reasons = Counter()
        for h in session.htn:
            for reason in h.get("fail", "-").split(";"):
                if reason and reason != "-":
                    reasons[reason] += 1
        if reasons:
            out.append("  why a method did not apply (top 10 of %d):" % sum(reasons.values()))
            for reason, count in reasons.most_common(10):
                out.append("    %6d  %s" % (count, reason))
        for h in session.htn[-4:]:
            out.append("  t=%s dyn=%s method=%s step=%s chain=%s"
                       % tuple(h.get(k, "?") for k in ("t", "dyn", "method", "step", "chain")))
    barren, entries = session.barren_entries()
    if entries:
        out.append("  BloodFeud entries that fired no leaf: %d of %d (%.0f%%); before the planner, 85 of 110"
                   % (barren, entries, 100.0 * barren / entries))
    if session.cancels:
        out.append("")
        out.append("measure starts cancelled by the engine (lost to a running measure's priority; top 10 of %d):" % sum(session.cancels.values()))
        for text, count in session.cancels.most_common(10):
            out.append("  %6d  %s" % (count, text))
        ours = [(t, c) for t, c in session.cancels.items() if t.startswith(("AttackEnemy(", "FeudSupply(", "AIBuyItem(", "InsultCharacter("))]
        if ours:
            out.append("  feud measures among them: " + ", ".join("%s x%d" % tc for tc in sorted(ours, key=lambda tc: -tc[1])))

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
[Script] ::TWP::LOADED aiboard.lua
[Script] ::TWP::LOADED aihtn.lua
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
[Script] ::TWP::W t=11.00 dyn=1 node=IncomeForAI base=60 c=0.50:linear:1:3 g=none w=120.00
[Script] ::TWP::PICK t=11.00 dyn=1 node=Dynasty
[Script] Executing Measures/ms_036_AttackEnemy.lua on Bero Freudenreich
[Script] Executing Measures/ms_003_Walk.lua on Player Guy
[Script] ::TWP::ENEMY t=10.00 dyn=1 goaltarget=9 cand=7:20:0:0;9:70:1:1; pick=9
[Script] ::TWP::BLD t=10.00 owner=9 mode=strongest class=-1 cand=0:6:3;1:1:1;2:2:2; pick=2
[Script] ::TWP::BELIEVER t=10.00 actor=1 victim=9 mode=office maxfavor=60 cand=7:30:55:2;8:70:10:-1; pick=7
[Script] ::TWP::MARKET t=12.00 dyn=1 items=HexerdokumentI:0:0;StinkBomb:2:0;Pddv:0:3;
[Script] ::TWP::CART t=12.10 dyn=1 action=send cart=77 carts=1 busy=1 need=2 money=250000 result=true items=StinkBomb,1;Pddv,1;
[Script] ::TWP::CART t=14.00 dyn=1 action=arrive cart=77 carts=1 busy=0 need=0 money=248000 result=2 items=
[StartMeasure] Kell Eylefson: Canceled 'AIBuyItem'(10) because of priority 'OrderCollectEvidence'(80)
[Script] ::TWP::HANDOVER t=14.50 dyn=1 sim=55 item=StinkBomb today=1/5
[Script] ::TWP::HTN t=12.00 dyn=1 task=Feud method=charge step=bf_ForgeEvidence chain=bf_ForgeEvidence>bf_Charge fail=Feud.artefact:ReadyArtefacts>=1
[Script] ::TWP::HTN t=13.00 dyn=1 task=Feud method=- step=- chain=- fail=Feud.artefact:ReadyArtefacts>=1;Feud.restock:Money>=supply
[Script] ::TWP::W t=15.00 dyn=1 node=bf_Procure base=60 c=0.50:linear g=none h=step w=180.00
[Script] ::TWP::W t=15.00 dyn=1 node=bf_Taunt base=30 c=0.50:linear g=none h=- w=30.00
[Script] ::TWP::PICK t=15.00 dyn=1 node=BloodFeud
[Script] ::TWP::PICK t=15.00 dyn=1 node=bf_Procure
[Script] ::TWP::PICK t=16.00 dyn=1 node=BloodFeud
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
    assert abs(root["current"]["Dynasty"] - 0.2882) < 0.001, root["current"]
    assert abs(root["current"]["IncomeForAI"] - 0.3429) < 0.001, "the 1..3 band must give 60 -> 120 at x=0.5"
    assert session.mismatch == 0, "a custom lo/hi band did not replay"
    assert session.picks["Feud"] == 1 and session.picks["Dynasty"] == 1
    assert abs(session.root_cadence() - 1.0) < 1e-9
    assert session.measures_by_goal["Conflict"]["ms_036_AttackEnemy.lua"] == 2
    assert session.measures_by_goal["not an AI party member"]["ms_003_Walk.lua"] == 1
    assert session.last["1"]["ticks"] == "24" and session.goals[0]["pick"] == "Conflict"
    assert session.market["1"]["items"].startswith("HexerdokumentI:0:0"), session.market
    assert len(session.carts) == 2 and session.cancels["AIBuyItem(10) lost to OrderCollectEvidence(80)"] == 1
    assert len(session.htn) == 2 and session.htn[0]["method"] == "charge", session.htn
    assert session.htn[1]["step"] == "-" and "Money>=supply" in session.htn[1]["fail"]
    # h=step must multiply in the replay, or the planned leaf reads as a mismatch
    assert session.mismatch == 0, "h=step did not replay"
    _bf_evals, bf = session.predicted()["BloodFeud/"]
    assert abs(bf["current"]["bf_Procure"] - 0.857) < 0.001, bf["current"]
    assert session.barren_entries() == (1, 2), session.barren_entries()
    text = report(session, "<sample>")
    assert len(session.handovers) == 1 and "hand-overs from the store: 1" in text, text
    # the findings layer: the checks are the point of the tool, so they are tested like code
    codes = [f.code for f in findings(session)]
    assert "library-not-loaded" not in codes, codes
    assert "htn-method-never-applied" in codes and "one-blood-rival" in codes, codes
    assert "bloodfeud-barren" in codes and "market-nowhere" not in codes, codes
    assert [f.level for f in findings(session)] == sorted(
        (f.level for f in findings(session)), key=lambda l: SEVERITY[l]), "findings must sort worst first"
    printed = format_findings(findings(session))
    assert "Scripts/AI/BaseTree/BloodFeud.lua" in printed and printed.startswith("findings:"), printed
    blank = Session()
    blank.feed([])
    assert findings(blank)[0].code == "no-telemetry", findings(blank)
    # The order guard: a sim ordered twice at one timestamp is the failure. A repeat in a
    # later tick is not, and neither is an engine cancel with no order beside it - the
    # first version of this check called both of those ERROR and libelled a working guard.
    across = Session()
    across.feed(["[Script] ::TWP::ORDER t=10.00 sim=1 measure=Attack action=ordered",
                 "[Script] ::TWP::ORDER t=10.50 sim=1 measure=Attack action=ordered",
                 "[StartMeasure] A: Canceled 'Attack'(99) because of priority 'Attack'(99)"])
    assert "order-guard-dead" not in [f.code for f in findings(across)], findings(across)
    within = Session()
    within.feed(["[Script] ::TWP::ORDER t=10.00 sim=1 measure=Attack action=ordered",
                 "[Script] ::TWP::ORDER t=10.00 sim=1 measure=Attack action=ordered"])
    assert "order-guard-dead" in [f.code for f in findings(within)], findings(within)
    # and the pointers themselves: a check that sends you to a file that moved is worse
    # than no check, because it reads as authoritative
    problems, counts = check_pointers()
    assert not problems, "stale pointers -- " + "; ".join(problems)
    print("pointers: %d paths, %d symbols, %d knobs, %d telemetry channels - all resolve" % counts)
    assert "goods brought home 2" in text and "nowhere HexerdokumentI" in text and "feud measures among them" in text, text
    assert "goal target kept 1/1" in text and "1 picked an office holder" in text, text
    print(text)
    print("\nselftest ok")
    return 0


def main(argv):
    # Dynasty names carry umlauts; a cp1251/cp866 console kills the whole report on print.
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except AttributeError:
        pass
    if len(argv) > 1 and argv[1] == "--selftest":
        return selftest()
    args = [a for a in argv[1:] if a != "--findings"]
    only_findings = len(args) < len(argv) - 1
    path = args[0] if args else default_log_path()
    session = Session()
    with open(path, encoding="utf-8", errors="replace") as handle:
        session.feed(handle)
    if only_findings:
        print(path)
        print(format_findings(findings(session)))
    else:
        print(report(session, path))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
