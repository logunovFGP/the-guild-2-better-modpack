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
  ::TWP::SPY t= action=<order|begin|end> spy= victim= ok= evidence=
                                              one per spying order and the measure that carries it out;
                                              action=end is the proof it finished, evidence= what it got
  ::TWP::WAR t= dyn= raid= target= party= leader= chance= sent= odds=
                                              one per decided raid: assassination_attempt, workers_raid,
                                              raid_building, kidnap or kidnap_child; sent= is whether the
                                              squad actually formed, odds= the kidnap chance (-1 elsewhere)
  ::TWP::SUPPLY t= bld= proto= workers= live= kept=<id:amount;..> dropped=<id:name;..>
                                              economy_GetResourceNeeds held a resource back: requireditems
                                              lists every recipe of the building level, and this one feeds
                                              only a recipe the building has not unlocked or deselected
  ::TWP::NEEDSTALE t= bld= proto= need=<id:name:inv1|inv2:value;..>
                                              a Need_<itemid> the building can neither produce nor consume;
                                              nothing ever clears these, so a plot keeps wanting what a
                                              previous level, owner or occupant wanted
  ::TWP::UNLOAD t= cart= dest= via=<UnloadAll|autocart> items=<id:name:count;..>
  ::TWP::IDPROBE t= bld= proto= listid= getname= id_byname= id_bynumstr= id_bynum= prod1=
                 canprod_num= canprod_numstr= canprod_name=   each value <luatype>:<text>
                                              once per session: what the engine really returns for
                                              the two id spaces economy_FilterNeedsByLiveRecipes
                                              compares, and which argument form BuildingCanProduce
                                              accepts. engine.signatures.tsv cannot say - it records
                                              the accessor, and lua_tostring converts in place
                                              everything a cart put into a building; the autocart strips its
                                              EmptySlot dummies around each transfer, and in that window the
                                              engine can load goods of its own
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
SPY = re.compile(r"::TWP::SPY (.*)$")
ATTACK = re.compile(r"::TWP::ATTACK (.*)$")
HEAL = re.compile(r"::TWP::HEAL (.*)$")
SUPPLY = re.compile(r"::TWP::SUPPLY (.*)$")
NEEDSTALE = re.compile(r"::TWP::NEEDSTALE (.*)$")
UNLOAD = re.compile(r"::TWP::UNLOAD (.*)$")
IDPROBE = re.compile(r"::TWP::IDPROBE (.*)$")
HOSP = re.compile(r"::TWP::HOSP (.*)$")
HIRE = re.compile(r"::TWP::HIRE (.*)$")
HIJACK = re.compile(r"::TWP::HIJACK (.*)$")
HIREEND = re.compile(r"::TWP::HIREEND (.*)$")
RAID = re.compile(r"::TWP::RAID (.*)$")
SPEND = re.compile(r"::TWP::SPEND (.*)$")
ASSIGN = re.compile(r"::TWP::ASSIGN (.*)$")
BLDOWN = re.compile(r"::TWP::BLDOWN (.*)$")
DEADWORK = re.compile(r"::TWP::DEADWORK (.*)$")
# The trial system talks, and nothing here listened until 2026-09-21: [TRIAL] was the
# single largest unread subsystem in the log, 1889 lines of 10081 unparsed.
TRIAL_JUDGE = re.compile(r"\[TRIAL\] Judge (found|does not exist)")
TRIAL_WAIT = re.compile(r"\[TRIAL\] Waiting with (.+?)\s*$")
# behaviour_pretrial says so when it gives up on a vanished judge - the 2026-09-21 fix
# for the loop that had no exit. Without reading it the fix is unfalsifiable: a log
# with no stuck sims looks the same whether the release fired or nobody was summoned.
TRIAL_RELEASE = re.compile(r"\[TRIAL\] No judge for \d+ rounds, releasing")
# and the per-round counter, added 2026-09-22 because the release still did not fire and
# there was no way to tell "never reached the loop" from "counter never climbs".
TRIAL_ROUND = re.compile(r"\[TRIAL\] No judge, round (\d+) of (\d+)")
# The engine's own completion signal for anything that walks, and the missing half of
# the spin check below: a measure start is not evidence of progress, but a start
# followed by this line is evidence of the opposite.
UNREACHED = re.compile(r"cl_MoveTask::Process - (.+?) has not reached Target")
STAMP = re.compile(r"::TWP::\w+ t=([\d.]+)")
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
# traced 2026-09-18: 42 files under Feud/ emitted nothing at all, so a subtree taking
# 21% of every root pick and converting 3% of them could be measured and never diagnosed
FEUD = {"AttackBuilding", "AttackFeud", "ChargeCharacter", "DefendFeud", "OrderASpying"}
LEVELS = [("root", ROOTS), ("Dynasty/", DYNASTY), ("ToMEconomy/", ECONOMY), ("BloodFeud/", BLOODFEUD),
          ("Feud/", FEUD)]
_seen = Counter(n for _name, nodes in LEVELS for n in nodes)
assert not [n for n, c in _seen.items() if c > 1], "a node name in two levels makes level_of ambiguous"
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


def why_parts(text):
    """A ::TWP::WHY payload as a dict, keeping the bare words kv() throws away.

    The subject (`buyworkshop`, `tools`, a raid name) and the gate that fell (`shadow`,
    `noneonsale`) are positional, so kv() dropped both: self.why was parsed and never
    read, and every WHY distribution in six sessions came out of a hand-written grep.
    Emitters should prefer key=value - aitwp_Why callers are being moved over - but the
    positional form has to keep working for logs already on disk.
    """
    bare = [part for part in text.split() if "=" not in part]
    row = kv(text)
    # raid= is the migrated form; the positional word is what everything else still writes
    row["subject"] = bare[0] if bare else row.get("raid", "-")
    row["gate"] = bare[1] if len(bare) > 1 else ""
    return row


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
        self.rivals, self.blackboard, self.raids, self.spying = [], Counter(), [], []
        self.attacks, self.heals = [], []
        self.supply, self.stale_needs, self.unloads = [], [], []
        self.idprobe, self.hospitals, self.hires = [], [], []
        self.hijacks = []
        self.hire_ends = []
        self.raid_steps = []
        self.spends = []
        self.assigns = []
        self.misowned = []
        self.deadworkers = []
        self.trial_judge = Counter()             # "found" / "does not exist"
        self.trial_wait = Counter()              # sim -> times left waiting on a trial
        self.trial_released = 0                  # gave up on a judge that never came
        self.trial_rounds = []                   # the counter, per round, to see if it climbs
        self.unreached = []                      # (sim, the measure it was last running)
        self.tspan = [None, None]                # first and last gametime any channel stamped
        self.channels_seen = set()               # bare ::TWP:: names this log actually carries
        self.libs = set()                        # the library names that printed LOADED
        self.self_cancel = Counter()             # measure -> starts that cancelled themselves
        self.self_cancel_runs = Counter()        # of those, the ones on the very next log line
        self.pick_seq = defaultdict(list)        # dyn -> picked nodes, in order

    def feed(self, lines):
        dyn_of_sim, goal_of_dyn = {}, {}
        last_self_cancel = (None, -2)
        last_measure = {}                        # sim -> the measure it most recently started
        for index, line in enumerate(lines):
            line = line.rstrip("\r\n")
            if "[TRIAL]" in line:
                m = TRIAL_JUDGE.search(line)
                if m:
                    self.trial_judge[m.group(1)] += 1
                    continue
                m = TRIAL_WAIT.search(line)
                if m:
                    self.trial_wait[m.group(1).strip()] += 1
                    continue
                if TRIAL_RELEASE.search(line):
                    self.trial_released += 1
                    continue
                m = TRIAL_ROUND.search(line)
                if m:
                    self.trial_rounds.append(int(m.group(1)))
                    continue
            if "cl_MoveTask::Process" in line:
                m = UNREACHED.search(line)
                if m:
                    sim = m.group(1).strip()
                    self.unreached.append((sim, last_measure.get(sim, "-")))
                    continue
            if "::TWP::" in line:
                # bare prefix, so ::TWP::AI:: counts as AI - a space-suffixed test
                # called that channel silent when it had fired 6395 times
                self.channels_seen.update(LUA_CHANNEL.findall(line))
                m = STAMP.search(line)
                if m:
                    t = float(m.group(1))
                    if t > 0:
                        lo, hi = self.tspan
                        self.tspan = [t if lo is None else min(lo, t),
                                      t if hi is None else max(hi, t)]
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
                self.why.append(why_parts(m.group(1)))
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
            m = ATTACK.search(line)
            if m:
                self.attacks.append(kv(m.group(1)))
                continue
            m = HEAL.search(line)
            if m:
                self.heals.append(kv(m.group(1)))
                continue
            m = SPY.search(line)
            if m:
                self.spying.append(kv(m.group(1)))
                continue
            m = SUPPLY.search(line)
            if m:
                self.supply.append(kv(m.group(1)))
                continue
            m = NEEDSTALE.search(line)
            if m:
                self.stale_needs.append(kv(m.group(1)))
                continue
            m = UNLOAD.search(line)
            if m:
                self.unloads.append(kv(m.group(1)))
                continue
            m = IDPROBE.search(line)
            if m:
                self.idprobe.append(kv(m.group(1)))
                continue
            m = HOSP.search(line)
            if m:
                self.hospitals.append(kv(m.group(1)))
                continue
            m = HIRE.search(line)
            if m:
                self.hires.append(kv(m.group(1)))
                continue
            m = HIJACK.search(line)
            if m:
                self.hijacks.append(kv(m.group(1)))
                continue
            m = HIREEND.search(line)
            if m:
                self.hire_ends.append(kv(m.group(1)))
                continue
            m = RAID.search(line)
            if m:
                self.raid_steps.append(kv(m.group(1)))
                continue
            m = SPEND.search(line)
            if m:
                self.spends.append(kv(m.group(1)))
                continue
            m = ASSIGN.search(line)
            if m:
                self.assigns.append(kv(m.group(1)))
                continue
            m = BLDOWN.search(line)
            if m:
                self.misowned.append(kv(m.group(1)))
                continue
            m = DEADWORK.search(line)
            if m:
                self.deadworkers.append(kv(m.group(1)))
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
                last_measure[sim] = name
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
        "Scripts/AI/BaseTree/BloodFeud/bf_Assassinate.lua. The bar is TWP_ATTACK_WIN_CHANCE, 0.65 since "
        "2026-09-19, and the party is every free hand aitwp_WarCandidates offers, committed one at a "
        "time by aitwp_WarCommit until it clears - the per-pool shares that capped it at five are gone. "
        "The ::TWP::WHY raid= lines carry pool=, party=, theirs=, chance= and need=; the gate is Patron "
        "or round 10 (aitwp_RaidAllowed)."),
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
            # Settled on 2026-09-19 and no longer a WARN: this is the victim, not the
            # attackers. Every multi-order tick in that log was exactly N orders to N
            # different sims followed by N-1 cancels on one other sim, and that sim was
            # the AggressorMembers entry of the matching BattleStatistic block while the
            # ordering sims were its VictimMembers (3/2, 4/3, 2/1, 5/4, 7/6, 2/1). The
            # engine restarts a defender's Attack once per attacker who joins; it cancels
            # itself at equal priority 99 each time. Bounded by the number of attackers,
            # and nothing Lua orders. Only the order-guard finding can say anything about
            # our own guard, so leave the conclusion there.
            level = "NOTE"
            pointer = ("Expected, and not ours: the cancels land on the sim being attacked, not on the "
                       "attackers. N witnesses order Attack on one criminal in a tick and the engine "
                       "restarts that criminal's own defensive Attack once per attacker, cancelling the "
                       "running one at equal priority 99 - so N orders always read as N-1 cancels on a "
                       "single name. Confirm with the [STATEMACHINE] BattleStatistic block at that "
                       "gametime: the cancelling name is AggressorMembers, the ::TWP::ORDER sims are "
                       "VictimMembers. It stops being expected if the cancels ever land on a sim that "
                       "the ::TWP::ORDER lines name, which would mean aitwp_ClaimOrder in "
                       "Scripts/Library/aitwp.lua let one sim order twice - the order-guard finding "
                       "tests exactly that.")
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


# subtree -> (LEVELS index, what the last measurement said)
BARREN_SUBTREES = (("ToMEconomy", 2, "234 of 262 on 2026-09-18"),
                   ("Feud", 4, "1118 picks converted 36 measures on 2026-09-18, 3.2%"))


def check_subtree_barren(s):
    """Root picks of a subtree whose children were never scored: the tick it spent finding
    every child at 0. The BloodFeud version of this is barren_entries; these two have the
    same disease and, until the children were traced, no way to show it."""
    for name, level, note in BARREN_SUBTREES:
        entered = sum(nodes.count(name) for nodes in s.pick_seq.values())
        if not entered:
            continue
        scored = len(set((dyn, t) for (dyn, t, lvl) in s.groups if lvl == level))
        if not scored:
            # not 100% barren - the children emitted nothing at all, so this log predates
            # their tracing. Saying "100%" here would be the same cried wolf as
            # order-guard-dead: a number that looks like a finding and is an artefact.
            yield Finding("WARN", "subtree-untraced",
                          "%s was entered %d times and not one child emitted a weight" % (name, entered),
                          "Scripts/AI/BaseTree/%s - two readings, and they need telling apart before "
                          "anything is concluded. Either the children carry no utility_Trace or "
                          "utility_Score yet, in which case this cannot be measured at all; or they do "
                          "and every one returned 0 before reaching it, in which case the subtree is "
                          "100%% barren and this is the worst reading there is, not a missing one. Grep "
                          "the child .lua files for utility_Trace and utility_Score to tell which - on "
                          "2026-09-19 all four of ToMEconomy's emitted, so its 8 of 8 was real. A "
                          "::TWP::WHY line from a child is itself proof the child ran and refused." % name)
            continue
        barren = max(0, entered - scored)
        share = 100.0 * barren / entered
        yield Finding("WARN" if share > 20 else "NOTE", "subtree-barren",
                      "%d of %d %s entries never scored a child (%.0f%%); %s"
                      % (barren, entered, name, share, note),
                      "Scripts/AI/BaseTree/%s.lua - the root cannot see its children's gates, so it "
                      "wins the roulette and then finds every child at 0. Count the DIRECT children "
                      "only: Feud/ holds 5 .lua files and ToMEconomy/ 4, and both are traced but for "
                      "one - the 42 and 32 you get from a recursive find are grandchildren, which "
                      "cannot run until their parent is picked and so cannot explain a barren entry. "
                      "The COUNT of traced children is measured; the PERCENTAGE can still be "
                      "an artefact - see the constant-return warning below, which is what Feud "
                      "turned out to be. ToMEconomy got aitwp_EconomyReady on "
                      "2026-09-18 and it did not help: 89%% before and 89%% after, because "
                      "DynastyIsShadow houses pass the gate on repeat timers they never set and then "
                      "every child rejects them for being shadow. Read the level table below for which "
                      "child is starving. FIRST, THOUGH, GREP THE CHILDREN FOR A BARE CONSTANT "
                      "RETURN: on 2026-09-21 most of Feud's 87%% was shadow dynasties scoring 3 in "
                      "AttackBuilding and 5 in AttackFeud through a plain `return 3` that called no "
                      "utility_Trace and so emitted no ::TWP::W. 18 of 26 dynasties were shadow, so "
                      "the subtree was working and this number was measuring the telemetry rather "
                      "than the AI. A weight returned without utility_Trace is invisible here and "
                      "reads as barren - that cost a gate that turned out to be a no-op." % name)


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


def war_party_max():
    """TWP_WAR_PARTY_MAX read out of the Lua, so the message cannot quote a stale cap."""
    try:
        blob, _libs = lua_sources(repo_root())
        m = re.search(r"TWP_WAR_PARTY_MAX\s*=\s*(\d+)", blob)
        return float(m.group(1)) if m else 8.0
    except Exception:
        return 8.0


def check_raids(s):
    if not s.raids:
        # Nothing was ever decided. The refusals say how far off it was, which is the
        # difference between a quiet feud and one that cannot arithmetically happen: the
        # party was capped at 5 by a share rule while the logged targets wanted 7.
        wanted = defaultdict(list)
        for row in s.why:
            if "need" in row and "party" in row:
                wanted[row.get("subject", "?")].append((num(row["need"]), num(row["party"]),
                                                        num(row.get("pool", 0))))
        cap = war_party_max()
        for raid, rows in sorted(wanted.items()):
            # need=-1 is aitwp_NeedHands saying there was nobody to measure, so those rows
            # carry no gap at all - reporting one as "-1 hands short" is a number that
            # reads like a finding and is an artefact. Say which of the two walls it hit.
            empty = [r for r in rows if r[2] <= 0]
            measured = [r for r in rows if r[0] > 0]
            if not measured:
                text = ("%s was considered %d times and never once went: the house had no "
                        "hirelings to send at all in %d of them" % (raid, len(rows), len(empty)))
            else:
                best = min(measured, key=lambda r: r[0] - r[1])
                gap = "needed %g, had %g" % (best[0], best[1])
                if best[0] > cap:
                    gap += ", and %g is past TWP_WAR_PARTY_MAX = %g, so no party this house "
                    gap += "can field clears that target"
                    gap = gap % (best[0], cap)
                text = ("%s was considered %d times and never once went; %d of those had nobody "
                        "to send, and the best of the rest %s"
                        % (raid, len(rows), len(empty), gap))
            yield Finding("WARN", "raid-never-decided", text,
                          "Scripts/Library/aitwp.lua - aitwp_WarCandidates offers the party and "
                          "aitwp_WarCommit commits it one hand at a time until it clears "
                          "TWP_ATTACK_WIN_CHANCE. pool= is what the house had before "
                          "aitwp_IsFreeForOrders ruled anyone out, so pool=0 is a recruiting problem "
                          "and a big pool with a small party is an availability one. need= is "
                          "aitwp_NeedHands read off the n-squared power model; if it sits above "
                          "TWP_WAR_PARTY_MAX the bar cannot be reached against that target at all.")
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


# How long a spy may still be out before it counts as leaked, used only when nothing in
# the log finished and there is no observed run to measure against. This is the TimeOut
# the order carries in Scripts/AI/BaseTree/Feud/OrderASpying.lua, not TWP_SPY_HOURS -
# that one is the cooldown between orders, which is a different number.
SPY_RUN_HOURS = 8.0


def spy_outstanding(rows):
    """Split unmatched spy begins into (leaked, in flight, the window used).

    A session always ends mid-flight, so a begin without an end is not the bug on its
    own. The 2026-09-19 log ended with ten unmatched begins and every one was younger
    than the median completed run; the check called that the abort signal twice on a
    healthy session, which is the cried wolf this findings layer exists to avoid. Pair
    each spy's begins with its own ends in order, then only a begin older than the
    longest run the log actually shows is a spy that never came back.
    """
    begins, ends, last = defaultdict(list), defaultdict(list), 0.0
    for x in rows:
        when = num(x.get("t"))
        last = max(last, when)
        if x.get("action") == "begin":
            begins[x.get("spy")].append(when)
        elif x.get("action") == "end":
            ends[x.get("spy")].append(when)
    runs = []
    for spy, started in begins.items():
        for i, when in enumerate(started):
            if i < len(ends[spy]):
                runs.append(ends[spy][i] - when)
    window = max(runs) if runs else SPY_RUN_HOURS
    leaked, inflight = [], []
    for spy, started in begins.items():
        for when in started[len(ends[spy]):]:
            (leaked if last - when > window else inflight).append((spy, when))
    return leaked, inflight, window


def check_spying(s):
    if not s.spying:
        return
    per = Counter(x.get("action") for x in s.spying)
    refused = sum(1 for x in s.spying if x.get("action") == "order" and x.get("ok") != "true")
    leaked, inflight, window = spy_outstanding(s.spying)
    evidence = sum(num(x.get("evidence")) for x in s.spying
                   if x.get("action") == "end" and num(x.get("evidence")) > 0)
    if refused:
        yield Finding("WARN", "spy-order-refused",
                      "%d of %d spy orders were refused by MeasureStart" % (refused, per["order"]),
                      "Scripts/AI/BaseTree/Feud/OrderASpying.lua - the myrmidon in MYRM could not be "
                      "given the measure. Usually it stopped being idle between Weight() and Execute(), "
                      "which is the alias hazard the whole tree has: every sibling's Weight() runs "
                      "before the winner's Execute().")
    # in flight at the last log line is not a leak, however many there are - see
    # spy_outstanding. Only a spy out longer than any run that finished is overdue.
    if leaked:
        yield Finding("WARN", "spy-never-ended",
                      "%d spy orders were still out at the last log line, longer than the "
                      "%.1f game hours the slowest completed run took" % (len(leaked), window),
                      "This is the shape AI spying was switched off for on 2025-04-23: "
                      "ms_145_OrderASpying looped `while true` with an exit only the AI ever set, so "
                      "orders ran forever, the myrmidons were never freed and they piled up until the "
                      "game fell over. GHOSTau fixed it on 2026-06-12 (89582daa) and it was re-enabled "
                      "on 2026-09-18. More than a couple outstanding means that fix is not holding - "
                      "put the return 0 back in Scripts/AI/BaseTree/Feud/OrderASpying.lua and say so.")
    else:
        yield Finding("NOTE", "spying",
                      "%d spy orders, %d began, %d ended, %d still out (all inside the %.1f h "
                      "a run takes), %.0f evidence gathered"
                      % (per["order"], per["begin"], per["end"], len(inflight), window, evidence),
                      "Scripts/AI/BaseTree/Feud/OrderASpying.lua, re-enabled 2026-09-18 with the "
                      "TWP_SPY_HOURS cooldown its crash history argued for. Evidence is what "
                      "HaveEvidence.ready:Accuser>=1 and Feud.razzia:Evidence>=threshold have been "
                      "starved of - if those two start applying, this is why.")


# Attacks that ended before the fight did. A couple is ordinary - the target walked
# indoors, the escort got there first. A sim that refuses this many times running is the
# 2026-09-19 shape: a caller looping on a measure that will not start.
#
# There is deliberately no general "measure spin" check here. It was written and thrown
# away the same hour: from the engine's `Executing Measures` lines a spin is genuinely
# indistinguishable from an idle sim, because ms_DynastyIdle and
# ms_048_HireEmployeeBuildingRandom legitimately repeat in runs of 40-105 by one sim.
# Both volume and unbroken-run-length flagged ten measures on a healthy log. The signal
# is not repetition, it is repetition *without completion* - which needs the measure to
# say whether it completed, and only AttackEnemy does that so far.
ATTACK_REFUSALS = 10


def check_attacks(s):
    """Where AttackEnemy ended up, and who never got a fight.

    ms_SquadHijackMember spun this measure 136 times on one sim across the 2026-09-19
    session and never reached BattleJoin; nothing in the log said so, because all six
    of the measure's failure exits were a silent StopMeasure.
    """
    if not s.attacks:
        return
    outcomes = Counter(a.get("result") for a in s.attacks)
    refused = defaultdict(Counter)
    for a in s.attacks:
        if a.get("result") != "joined":
            refused[a.get("sim")][a.get("result")] += 1
    worst = sorted(refused.items(), key=lambda kv_: -sum(kv_[1].values()))
    for sim, reasons in worst[:3]:
        total = sum(reasons.values())
        if total < ATTACK_REFUSALS:
            break
        yield Finding("WARN", "attack-refused",
                      "sim %s started AttackEnemy %d times and never joined a fight (%s)"
                      % (sim, total, ", ".join("%s %d" % (r, n) for r, n in reasons.most_common())),
                      "Scripts/Measures/ms_036_AttackEnemy.lua - result=mayattack is our own "
                      "aitwp_MayAttackHere guard in Scripts/Library/aitwp.lua refusing the fight "
                      "(added 2026-09-10; it says no inside a settlement unless the victim is wanted "
                      "or the house commands the watch), result=unreachable is the vanilla "
                      "ai_StartInteraction giving up. Then find the caller's loop: "
                      "Scripts/Measures/Squad/ms_SquadHijackMember.lua discarded Attack()'s return "
                      "value, so its `while true` could not break while the measure kept refusing - "
                      "fixed 2026-09-19. If this is back, another caller has the same shape.")
    if outcomes:
        yield Finding("NOTE", "attack-outcomes",
                      "AttackEnemy: %s" % ", ".join("%s %d" % (r, n) for r, n in outcomes.most_common()),
                      "Scripts/Measures/ms_036_AttackEnemy.lua emits ::TWP::ATTACK at every exit since "
                      "2026-09-19. joined is the only one that reaches BattleJoin; everything else is "
                      "a StopMeasure the caller has to cope with.")


# A sim turned away by the same hospital twice inside this many game hours means the
# IgnoreHospital cooldown is not holding. It is written in the per-patient epilogue of
# ms_MedicalTreatment, as GetGametime() + 12. It used to be written in PropertiesEnd,
# which this comment named until 2026-09-21 - by then that function had had no callers
# for seven months and has now been deleted.
HOSPITAL_COOLDOWN_HOURS = 12.0


def check_healing(s):
    """Who the hospital saw, and whether a refusal stuck.

    The 2026-09-19 session had 77 ms_AttendDoctor starts dominated by repeat visitors -
    one sim seven times in 34 game hours - because the no-money refusal was the one
    unsuccessful outcome that never set IgnoreHospital, and ai_VisitDoc comes round every
    game hour. Nothing could see it: a production measure writes no Executing Measures
    line, so the hospital left no trace in the log at all.
    """
    if not s.heals:
        return
    outcomes = Counter(h.get("outcome") for h in s.heals)
    yield Finding("NOTE", "healing",
                  "hospital saw %d patients: %s"
                  % (len(s.heals), ", ".join("%s %d" % (o, n) for o, n in outcomes.most_common())),
                  "Scripts/Measures/ms_MedicalTreatment.lua emits ::TWP::HEAL per patient since "
                  "2026-09-19. nomats is the hospital out of the medicine that disease needs - "
                  "bld_GetNeedForMedicine in Scripts/Library/bld.lua is what should have restocked "
                  "it; nomoney is the patient's own purse, and who pays is "
                  "gameplayformulas_PaysForTreatment.")
    # a refusal has to stick, or the patient is back within the hour
    seen = defaultdict(list)
    for h in s.heals:
        if h.get("outcome") != "healed":
            seen[(h.get("sim"), h.get("hospital"))].append(num(h.get("t")))
    repeats = []
    for (sim, hospital), times in seen.items():
        times.sort()
        for earlier, later in zip(times, times[1:]):
            if later - earlier < HOSPITAL_COOLDOWN_HOURS:
                repeats.append((sim, hospital, later - earlier))
                break
    if repeats:
        sim, hospital, gap = min(repeats, key=lambda r: r[2])
        yield Finding("WARN", "hospital-refusal-loop",
                      "%d sims were turned away twice by the same hospital inside %.0f game hours "
                      "(soonest: sim %s at hospital %s, %.1f h apart)"
                      % (len(repeats), HOSPITAL_COOLDOWN_HOURS, sim, hospital, gap),
                      "Both halves are proven, so suspect a THIRD thing before either. The WRITE "
                      "side is the per-patient epilogue of Scripts/Measures/ms_MedicalTreatment.lua, "
                      "which every unsuccessful outcome reaches - nomats and nomoney both set the "
                      "property correctly, checked 2026-09-21. The READ side was the hole and is "
                      "fixed: idlelib_VisitDoc kept the whole test inside its "
                      "not-AliasExists(Destination) branch, so ms_AttendDoctor - which passes a "
                      "HospitalID bound to the building the sim is standing in - skipped it and "
                      "never expired the property either. The cooldown is now resolved for every "
                      "caller and a refused destination is dropped so the ranking picks elsewhere. "
                      "If this fires again, read the doctor's own patient filter: it selects on "
                      "WaitingForTreatment and has never consulted IgnoreHospital, so a sim already "
                      "in the room is served and refused regardless of the flag.")
def check_supply(s):
    if not s.supply:
        return
    malformed, dropped = Counter(), Counter()
    dead = [r for r in s.supply if num(r.get("matched"), -1) == 0]
    if dead:
        yield Finding("ERROR", "supply-filter-dead",
                      "%d buildings had no requireditems entry match any recipe (protos %s)"
                      % (len(dead), ", ".join(sorted(set(r.get("proto", "?") for r in dead))[:6])),
                      "economy_GetProtoIngredientUsers keys ingredients by the numbers in "
                      "Items.dbt prod1..3, and economy_GetResourceNeeds keys them by "
                      "ItemGetID(<numeric string>). matched=0 means those two id spaces do not "
                      "compare equal, so the filter drops nothing and auto-supply is back to "
                      "buying every recipe of the building level. Normalise both through "
                      "helpfuncs_StringToIdList in Scripts/Library/economy.lua.")
    by_reason = Counter()
    for row in s.supply:
        for part in row.get("dropped", "").split(";"):
            if not part:
                continue
            # slotN:malformed is a usage list too short, usageN:orphan one too long
            if part.endswith(":malformed") or part.endswith(":orphan"):
                malformed[(row.get("proto", "?"), part.split(":")[-1])] += 1
            else:
                dropped[part] += 1
                by_reason[part.split(":")[-1]] += 1
    if malformed:
        yield Finding("WARN", "requireditems-malformed",
                      "requireditems and requireditemusages disagree in length: %s"
                      % ", ".join("proto %s %s x%d" % (p, kind, n)
                                  for (p, kind), n in malformed.most_common()),
                      "DB/BuildingToItems.dbt. economy_GetResourceNeeds reads the two columns as "
                      "parallel lists. malformed means the usage list is SHORT, so a slot reaches "
                      "CalcCurrentResourceNeeds as {nil, amount} and gets indexed; orphan means it "
                      "is LONG, which is harmless but still a wrong row. Count the entries of both "
                      "columns on that proto; the four rows found on 2026-09-19 were all orphans - "
                      "an item id had been lost, not a usage gained.")
    if dropped:
        yield Finding("NOTE", "supply-filtered",
                      "%d resources held back from auto-supply (%s): %s"
                      % (sum(dropped.values()),
                         ", ".join("%d %s" % (n, kind) for kind, n in by_reason.most_common()),
                         ", ".join("%s x%d" % (k, n) for k, n in dropped.most_common(6))),
                      "economy_FilterNeedsByLiveRecipes in Scripts/Library/economy.lua. locked means "
                      "no recipe that eats it is unlocked - the level 3 hospital listing ToadExcrements "
                      "for the 1000 gold Mixture upgrade is the case it was written for. deselected "
                      "means the recipe IS unlocked and the player took it out of the storage panel, so "
                      "that one follows the panel and comes back when they put it back. A name here "
                      "that the building does make is the bug, not the drop.")


def check_stray_goods(s):
    # the other half of the same question: goods that arrive in a building nothing asked for
    stale = Counter()
    stale_pairs = set()
    for row in s.stale_needs:
        for part in row.get("need", "").split(";"):
            bits = part.split(":")
            if len(bits) >= 2:
                stale[":".join(bits[:2])] += 1
                stale_pairs.add((row.get("bld"), bits[1]))
    if stale:
        yield Finding("WARN", "need-stale",
                      "%d buildings hold Need_ entries for goods they neither make nor use: %s"
                      % (len(set(r.get("bld") for r in s.stale_needs)),
                         ", ".join("%s x%d" % (k, n) for k, n in stale.most_common(6))),
                      "bld_LogStaleNeeds in Scripts/Library/bld.lua. Nothing clears Need_<itemid>: not a "
                      "level up, and not bld_HandleNewOwner, which drops MgmStor_* and leaves these behind. "
                      "Whatever is named here is what that building's cart keeps buying.")
    if not s.unloads:
        return
    by_dest = defaultdict(Counter)
    for row in s.unloads:
        for part in row.get("items", "").split(";"):
            bits = part.split(":")
            if len(bits) >= 3:
                by_dest[row.get("dest", "?")][bits[1]] += num(bits[2])
    matched = sorted("%s into bld %s" % (name, bld) for bld, name in stale_pairs
                     if name in by_dest.get(bld, {}))
    if matched:
        yield Finding("ERROR", "stray-goods-delivered",
                      "a cart delivered goods the building has no use for: %s" % ", ".join(matched[:6]),
                      "This closes the loop between bld_LogStaleNeeds and cart_UnloadAll: the building "
                      "asked for it through a stale Need_ property and a cart went and fetched it. Clear "
                      "the property where the need is written, not in the cart.")
    else:
        yield Finding("NOTE", "cart-unloads",
                      "%d cart unloads into %d buildings, nothing matching a stale need"
                      % (len(s.unloads), len(by_dest)),
                      "cart_UnloadAll and state_twp_autocart_UnloadItems. If a good still shows up in a "
                      "building that cannot use it, it did not come in on a cart and it was not a stale "
                      "Need_ - look at the engine's own management next.")


def check_idprobe(s):
    """The one-shot ::TWP::IDPROBE line, read as a verdict rather than left to the eye.

    It exists because the metadata cannot answer the question. meta/engine.signatures.tsv
    records the accessor a binding calls, not a requirement: BuildingCanProduce and
    ItemGetID both read `string`, and so does ItemGetName, whose every caller in the tree
    passes a number - lua_tostring converts in place, so a numeric argument can never
    raise a type error. That silence proves nothing; only a running game does.
    """
    if not s.idprobe:
        return
    row = s.idprobe[0]

    def part(key, which):
        kind, _, text = row.get(key, "nil:-").partition(":")   # each value is <type>:<text>
        return kind if which == "type" else text

    listid, byname = part("listid", "text"), part("id_byname", "text")
    numstr, bynum = part("id_bynumstr", "text"), part("id_bynum", "text")
    prod1_type, prod1 = part("prod1", "type"), part("prod1", "text")

    # 1. does ItemGetID resolve the numeric string vanilla actually hands it?
    if numstr != listid:
        yield Finding("ERROR", "idprobe-numstr-lost",
                      'ItemGetID("%s") returned %s, not the id %s - every resource need is built '
                      'this way' % (listid, row.get("id_bynumstr"), listid),
                      "Scripts/Library/economy.lua, economy_GetResourceNeeds builds its ids with "
                      "ItemGetID(<numeric string from gfind>). If that does not round-trip, the "
                      "whole auto-supply needs list is wrong and always has been. Switch that loop "
                      "to helpfuncs_StringToIdList, which converts by arithmetic and cannot depend "
                      "on what the engine chooses to resolve.")
    # 2. do the two id spaces the filter compares agree in TYPE as well as value? "963" and
    #    963 are different table keys, so a type split makes Users[ItemId] miss every time
    if prod1_type not in ("number", "nil"):
        yield Finding("ERROR", "idprobe-prod-type",
                      "GetDatabaseValue(Items, %s, prod1) came back as %s (%s), not a number"
                      % (listid, prod1_type, prod1),
                      "Scripts/Library/economy.lua, economy_GetProtoIngredientUsers keys its table "
                      "by these values while economy_GetResourceNeeds keys by ItemGetID. A string "
                      "key never equals a number key in Lua, so Matched stays 0 and the filter "
                      "silently drops nothing - which is the supply-filter-dead ERROR wearing its "
                      "other face. Normalise both through helpfuncs_StringToIdList.")
    # 3. which argument form does BuildingCanProduce actually accept?
    forms = [(f, part("canprod_" + f, "text")) for f in ("num", "numstr", "name")]
    good = [f for f, v in forms if v not in ("false", "nil", "-", "")]
    if not good:
        yield Finding("ERROR", "idprobe-canproduce-none",
                      "BuildingCanProduce said no to all three forms for %s (%s), a product this "
                      "building certainly makes"
                      % (byname or listid, ", ".join("%s=%s" % f for f in forms)),
                      "Scripts/Library/economy.lua, economy_BuildingCanProduceItem asks by number "
                      "then by name and takes a yes from either. If neither works, "
                      "economy_GetLiveProducts returns nothing and every resource is dropped - "
                      "check the building alias reaching it.")
    else:
        yield Finding("NOTE", "idprobe",
                      "engine id forms: ItemGetID by name=%s, by numeric string=%s, by number=%s; "
                      "Items.prod1 is a %s; BuildingCanProduce accepts %s"
                      % (byname, numstr, bynum, prod1_type, "+".join(good)),
                      "Scripts/Library/economy.lua, economy_ProbeItemIdSpaces - one line per "
                      "session. It settles what meta/engine.signatures.tsv cannot: that column "
                      "names the accessor a binding calls, not a requirement, and lua_tostring "
                      "converts a number in place so no form can raise a type error. If only one "
                      "of the three canprod_ forms works, economy_BuildingCanProduceItem can drop "
                      "the other and the hedge becomes a fact.")


# bld_GetNeedForMedicine returns 100 when a medicine is gone entirely; anything at or
# above this is "low enough that the next patient needing it is turned away".
MEDICINE_NEED_DRY = 100


def check_hospital_stock(s):
    """Whether hospitals hold medicine, split by who owns them.

    An unowned hospital gets stock targets from hospital_SetupAI like any other, but
    bld_CheckCarts and bld_HandlePingHour both return immediately without an owner - so
    nothing fills those targets and nothing runs its hourly upkeep. That predicts neutral
    hospitals running dry and staying dry, which is a claim about stock over time and has
    to be measured rather than argued.
    """
    if not s.hospitals:
        return
    by_owner = defaultdict(list)
    for row in s.hospitals:
        by_owner[row.get("owned", "?")].append(row)
    meds = ("Bandage", "Medicine", "PainKiller")
    for owned in sorted(by_owner):
        rows = by_owner[owned]
        dry, worst = [], []
        for med in meds:
            # value is "<instock>:<need>"
            needs = [num(r.get(med, "0:0").split(":")[-1]) for r in rows if med in r]
            stocks = [num(r.get(med, "0:0").split(":")[0]) for r in rows if med in r]
            if not needs:
                continue
            if min(stocks) <= 0:
                dry.append(med)
            worst.append("%s %g-%g" % (med, min(stocks), max(stocks)))
        label = "owned" if owned == "true" else "neutral"
        level = "WARN" if (dry and label == "neutral") else "NOTE"
        yield Finding(level, "hospital-stock",
                      "%d %s hospital readings: stock range %s%s"
                      % (len(rows), label, ", ".join(worst),
                         ("; ran out of " + ", ".join(dry)) if dry else ""),
                      "Scripts/Buildings/Hospital.lua, hospital_LogStock - one line per hospital "
                      "per game day. A neutral hospital at zero is the case to watch: "
                      "hospital_SetupAI gives it stock targets from Setup() and OnLevelUp() with no "
                      "owner test, but bld_CheckCarts and bld_HandlePingHour in "
                      "Scripts/Library/bld.lua both return immediately without an owner, so no cart "
                      "is ever sent to fill them. An owned hospital at zero is a different problem - "
                      "read the supply-filtered and cart findings first. The second number per "
                      "medicine is bld_GetNeedForMedicine, where 100 means none left.")


def check_hiring(s):
    """Does deciding to hire ever produce a hireling?

    A house picked HireMyrmidon ten times on 2026-09-19 and every raid still reported
    pool=0, with no hire reporting a failure. The counts before each attempt say whether
    the number ever moves.
    """
    if not s.hires and not s.hire_ends:
        return
    per_dyn = defaultdict(list)
    for row in s.hires:
        per_dyn[row.get("dyn", "?")].append(row)
    stuck = []
    for dyn, rows in per_dyn.items():
        thugs = [num(r.get("thugs", -1)) for r in rows]
        if len(rows) >= 3 and max(thugs) <= 0:
            stuck.append((dyn, len(rows), rows[-1].get("slots", "?")))
    if s.hires:
        yield Finding("NOTE", "hiring",
                      "%d hire decisions across %d houses; thug counts seen %s"
                      % (len(s.hires), len(per_dyn),
                         "/".join(str(int(v)) for v in sorted(set(
                         num(r.get("thugs", -1)) for r in s.hires))[:8])),
                      "Scripts/Library/aitwp.lua, aitwp_LogHire - emitted by "
                      "Scripts/AI/BaseTree/Dynasty/HireMyrmidon.lua and "
                      "Scripts/AI/BaseTree/BloodFeud/bf_Recruit.lua before each attempt. Both now "
                      "wait TWP_HIRE_HOURS and stop at TWP_MAX_THUGS.")
    if s.hire_ends:
        stages = Counter(r.get("stage", "?") for r in s.hire_ends)
        hired = stages.get("hired", 0)
        wants = Counter(r.get("want", "?") for r in s.hire_ends
                        if str(r.get("stage", "")).startswith("noworker"))
        yield Finding("NOTE" if hired else "WARN",
                      "hire-outcomes",
                      "%d hire attempts finished: %s%s"
                      % (len(s.hire_ends),
                         ", ".join("%s %d" % (k, v) for k, v in stages.most_common(8)),
                         ("; levels asked for and not found: "
                          + "/".join(sorted(wants))) if wants else ""),
                      "Scripts/Measures/ms_048_HireEmployeeBuildingRandom.lua, every exit, via "
                      "aitwp_LogHireEnd. noworker_<err> is FindWorker refusing the level "
                      "ms_048_hireemployeebuildingrandom_DecideFirst asked for; since 2026-09-19 "
                      "DecideFirst walks down to a level it can actually fill, so a want= of 5 or "
                      "3 still showing here means the walk-down itself is not working. ownerpoor "
                      "is the building owner short of SimGetHandsel, which is a different problem "
                      "from under400 - that one reads the dynasty.")
    if stuck:
        dyn, tries, slots = max(stuck, key=lambda r: r[1])
        yield Finding("WARN", "hiring-never-lands",
                      "%d houses decided to hire repeatedly and never gained a thug "
                      "(worst: dyn %s, %d attempts, slots=%s at the last one)"
                      % (len(stuck), dyn, tries, slots),
                      "Scripts/Measures/ms_048_HireEmployeeBuildingRandom.lua is what both nodes "
                      "run. It gives up silently in several places - under 400 coins, at "
                      "TWP_MAX_THUGS, when FindWorker returns an error for the level "
                      "DecideFirst picked from the BUILDING level, and when the owner cannot "
                      "cover SimGetHandsel. slots= is BuildingCanHireNewWorker, so slots=false "
                      "means the building has no free worker place and the ceiling is the "
                      "building, not the knob.")


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


def check_hijack(s):
    """Does a kidnapping go in as a party, or as one thief at a time?

    Every thief on duty is handed "Hijack" while the guild's order stands, and until
    2026-09-19 each one opened its own squad, so four thieves meant four separate
    one-man kidnappings. The player watched a single thief walk into a party of three.
    hands= is the squad size at the moment that thief was committed.
    """
    if not s.hijacks:
        return
    joined = sum(1 for r in s.hijacks if r.get("joined") == "true")
    hands = [int(num(r.get("hands", -1))) for r in s.hijacks]
    yield Finding("NOTE", "hijack",
                  "%d thieves committed to a kidnapping, %d of them joining a colleague; "
                  "squad size seen %s"
                  % (len(s.hijacks), joined,
                     "/".join(str(v) for v in sorted(set(hands))[:8])),
                  "Scripts/Buildings/Thief.lua, thief_LogHijack - one line per thief checking "
                  "in while a HijackingOrder stands. The order itself is laid down in "
                  "thief_GetWorkerTask on a Rand(10) roll at night and now expires after "
                  "THIEF_HIJACK_ORDER_HOURS, because an order whose target does not resolve "
                  "used to stand for ever and starve pickpocketing, scouting and burglary.")
    lone = [r for r in s.hijacks if int(num(r.get("hands", -1))) == 1]
    if len(lone) > 1 and joined == 0:
        victims = len(set(r.get("victim", "?") for r in lone))
        yield Finding("WARN", "lone-kidnap",
                      "%d thieves each went after a victim alone and none joined a colleague "
                      "(%d distinct victims)" % (len(lone), victims),
                      "Scripts/Buildings/Thief.lua, the Hijack branch of thief_CheckInForWork. "
                      "It walks the guild's own workers looking for one whose squad already "
                      "carries this victim and joins that, the same test "
                      "Scripts/AI/Thief/thief_JoinSquad.lua makes; it only opens a new squad "
                      "when there is none. More than one lone hand and no join at all means "
                      "either the workers check in too far apart for the first squad to still "
                      "exist, or SquadGet is not finding it.")


# A sim that cannot reach where a measure sends it. This is the spin check the note above
# says could not be written, and the missing piece was never in our telemetry: the engine
# already reports non-completion for anything that walks, as
# "cl_MoveTask::Process - <sim> has not reached Target". Repetition alone flagged ten
# measures on a healthy log; repetition *plus* the engine saying the walk failed is the
# real signal, so this check counts only the failures and never the starts.
#
# Scaled per game hour, because the observed logs span 7.5 to 49 hours and a raw count
# reads a long healthy session as worse than a short broken one. Measured: 2026-09-06
# spread 1297 failures over 219 sims, worst 1.0/h; 2026-09-19 put 327 of 440 on five
# characters of one family, worst 12.5/h. The shape, not the volume, is the finding.
STUCK_WALK_PER_HOUR = 4.0
STUCK_WALK_MIN = 10


def check_stuck_walk(s):
    """Is anyone being sent somewhere they cannot get to, over and over?"""
    if not s.unreached:
        return
    lo, hi = s.tspan
    hours = (hi - lo) if (lo is not None and hi is not None and hi > lo) else 0.0
    per_sim = defaultdict(list)
    for sim, measure in s.unreached:
        per_sim[sim].append(measure)
    worst = sorted(per_sim.items(), key=lambda kv_: -len(kv_[1]))
    top = sum(len(v) for _k, v in worst[:5])
    yield Finding("NOTE", "unreachable-target",
                  "%d walks ended without reaching the target, across %d sims%s; "
                  "the top five carry %d%% of them (%s)"
                  % (len(s.unreached), len(per_sim),
                     (" over %.1f game hours" % hours) if hours else "",
                     100 * top // max(1, len(s.unreached)),
                     ", ".join("%s %d" % (k, len(v)) for k, v in worst[:5])),
                  "The engine writes this itself, from cl_MoveTask; no script emits it. A "
                  "thin spread over a hundred sims is ordinary town congestion. A tall "
                  "spike on a few names is a destination that cannot be walked to - read "
                  "the measure beside the name, and check the [Movement] "
                  "EN_PATHSTATE_ERROR_UNREACHABLE lines for the same tick.")
    if not hours:
        return
    stuck = [(sim, walks) for sim, walks in worst
             if len(walks) >= STUCK_WALK_MIN and len(walks) / hours >= STUCK_WALK_PER_HOUR]
    if stuck:
        sim, walks = stuck[0]
        measures = Counter(m for m in walks if m and m != "-")
        yield Finding("WARN", "stuck-walk",
                      "%d sims failed to reach a target more than %.0f times a game hour "
                      "(worst: %s, %d failures in %.1f h, last running %s)"
                      % (len(stuck), STUCK_WALK_PER_HOUR, sim, len(walks), hours,
                         ", ".join("%s x%d" % (k, v) for k, v in measures.most_common(3))
                         or "no measure start seen"),
                      "The measure keeps being re-picked because the walk never finishes, so "
                      "the sim gets nothing done all session. Scripts/Library/idlelib.lua "
                      "chooses the idle destination and is ours; "
                      "Scripts/Measures/ms_010_GoToSleep.lua walks the sim to its own "
                      "HomeBuilding and is inherited, untouched by us. Before blaming either, "
                      "check whether the "
                      "building is mid-evacuation or mid-level-up - the engine cannot path "
                      "into one, and that is not a script defect.")


# A trial that cannot find its judge. The player was fined 500 coins for a magistrate who
# was DEAD - still holding the office, still summoned, still failing to appear - and the
# log had been saying so 200 times a session in a subsystem no parser read.
#
# The share is the finding, not the count: some trials legitimately run while the
# magistrate is between buildings. Measured 2026-09-21 over 37.5 game hours: 200 missing
# against 82 found, 71%, spread over 11 sims in 11 families and NOT ONE of them the
# player's - so this stalls AI houses, and the fine the player saw is its visible corner.
TRIAL_NO_JUDGE_SHARE = 40
TRIAL_WAIT_REPEATS = 20


def check_trials(s):
    """Do trials find a judge, and does anyone wait for one that never comes?"""
    found = s.trial_judge.get("found", 0)
    missing = s.trial_judge.get("does not exist", 0)
    if not (found or missing or s.trial_wait):
        return
    total = found + missing
    share = (100.0 * missing / total) if total else 0.0
    stuck = [(sim, n) for sim, n in s.trial_wait.most_common() if n >= TRIAL_WAIT_REPEATS]
    families = len(set(sim.split()[-1] for sim in s.trial_wait if sim.split()))
    yield Finding("NOTE", "trials",
                  "%d trial judge lookups: %d found, %d missing (%.0f%%); %d sims waited, "
                  "across %d families; %d released after the judge never came; counter reached %s"
                  % (total, found, missing, share, len(s.trial_wait), families,
                     s.trial_released,
                     max(s.trial_rounds) if s.trial_rounds else "never logged"),
                  "Scripts/Measures/Behaviour/behavior_pretrial.lua writes all three lines; "
                  "Scripts/AI/BaseTree/Trial.lua is the node that enters. Until 2026-09-21 "
                  "nothing here read them and [TRIAL] was the largest unparsed subsystem in "
                  "the log. released>0 is the 2026-09-21 exit firing: the wait loop had none "
                  "and a sim summoned to a trial whose judge had died waited for ever. If "
                  "trial-no-judge is high and released is 0, that exit is not being reached.")
    if total and share >= TRIAL_NO_JUDGE_SHARE:
        yield Finding("WARN", "trial-no-judge",
                      "%.0f%% of trials found no judge (%d of %d)" % (share, missing, total),
                      "The office holder can be DEAD and still hold the office: "
                      "Scripts/States/state_dead.lua is the only place that gives it up, via "
                      "CityRemoveFromOffice, and a death away from a settlement may never "
                      "reach it. Check whether the judge lookup in "
                      "Scripts/Measures/Behaviour/behavior_pretrial.lua tests STATE_DEAD at "
                      "all before reporting the holder missing - 'does not exist' is what a "
                      "dead magistrate looks like from here.")
    # Only a consequence, never a signal. Measured 2026-09-21: on 2026-09-06, where the
    # judge was found 132 times out of 132, sims still waited at 5.5 times a game hour -
    # exactly the rate of the broken sessions. Waiting long is ordinary court business,
    # so firing on it alone sends the next session to the wrong file with confidence.
    if stuck and total and share >= TRIAL_NO_JUDGE_SHARE:
        sim, n = stuck[0]
        yield Finding("WARN", "trial-queue-stuck",
                      "%d sims waited on a trial more than %d times (worst: %s x%d)"
                      % (len(stuck), TRIAL_WAIT_REPEATS, sim, n),
                      "Nothing retires a queued trial whose judge is gone, so the same sims "
                      "are summoned for ever. Scripts/AI/BaseTree/Trial.lua picks the node "
                      "and Scripts/Measures/Behaviour/behavior_pretrial.lua runs it. This "
                      "only prints when trial-no-judge is already firing, because on its own "
                      "it is not evidence: a healthy court waits at the same rate.")


# A channel that is emitted by the Lua and has never produced a line. The pointer rule
# already fails the build when a channel has no parser; this is the other half - a parser
# for something that never speaks is a blind spot that reads like coverage. Found
# 2026-09-21: four channels silent across two whole sessions.
#
# Matches the channel in EVERY form it is written, not "::TWP::NAME ": AI emits
# "::TWP::AI::" with a different separator and a space-suffixed test called it silent
# when it had fired 6395 times. That near-miss is why this compares bare prefixes.
CHANNEL_SILENT_MIN_HOURS = 6.0


def check_silent_channels(s):
    """Channels the Lua emits that said nothing at all this session."""
    lo, hi = s.tspan
    hours = (hi - lo) if (lo is not None and hi is not None and hi > lo) else 0.0
    if hours < CHANNEL_SILENT_MIN_HOURS:
        return                                   # too short a run to call anything dead
    try:
        blob, _libs = lua_sources(repo_root())
    except (IOError, OSError):
        return
    emitted = sorted(set(LUA_CHANNEL.findall(blob)))
    silent = [c for c in emitted if c not in s.channels_seen]
    if not silent:
        return
    yield Finding("NOTE", "channel-silent",
                  "%d of %d emitted channels produced no line in %.1f game hours: %s"
                  % (len(silent), len(emitted), hours, ", ".join(silent)),
                  "Each is a ::TWP:: channel the Lua can write and did not, and silence means "
                  "three different things - grep the emitting function before concluding "
                  "anything. BB is aiboard reporting an UNREGISTERED key, so silence there "
                  "is the healthy answer, not a gap. HIJACK needs a thieves' guild to be "
                  "holding a kidnap order that session. And a channel can be gated so "
                  "tightly it reads as dead when it is not: SUPPLY only emits when a "
                  "resource is DROPPED or nothing matched (economy.lua, the Count > 0 and "
                  "DroppedLog test), which is once in 37.5 game hours - it was called dead "
                  "on 2026-09-21 on two logs and the third refuted it. This is the "
                  "counterpart to check_pointers, which fails the build for a channel with "
                  "no PARSER but cannot see a channel with no OUTPUT. Reading an OLD log "
                  "lists every channel added since it was taken, which is an artefact and "
                  "not a finding - judge this on the current session only.")


# What a sent raid actually did. ::TWP::WAR says only that a squad object resolved with
# members in it, measured in the same tick as SquadCreate - nothing about whether a measure
# started, anyone walked, or the order survived. The three squad measures emitted nothing at
# all until 2026-09-21, so on 2026-09-20 two raids reported sent=true and there was no way
# to tell a working ambush from a collapsed one. The session also ended 1.4 game hours after
# they went out, inside TWP_AMBUSH_HOURS, so even a perfect raid would have shown nothing.
RAID_GOOD = ("laid", "struck", "nobodycame", "timeout")


def check_raid_steps(s):
    """Did the party that was sent get anywhere?"""
    if not s.raid_steps:
        return
    outcomes = Counter(r.get("outcome", "?") for r in s.raid_steps)
    struck = outcomes.get("struck", 0)
    broken = sum(n for o, n in outcomes.items() if o not in RAID_GOOD)
    yield Finding("NOTE", "raid-steps",
                  "%d raid steps: %s" % (len(s.raid_steps),
                                         ", ".join("%s %d" % (o, n)
                                                   for o, n in outcomes.most_common(8))),
                  "Scripts/Library/aitwp.lua, aitwp_LogRaid - emitted at every exit of "
                  "Scripts/Measures/Squad/ms_bf_Ambush.lua and ms_bf_AmbushMember.lua. Read "
                  "it beside ::TWP::WAR: WAR says a squad was formed, this says what became "
                  "of it. laid means the leader set the meeting place, struck means a member "
                  "reached the victim, nobodycame and timeout are the ambush expiring "
                  "honestly - a mine nobody walks to is a wasted morning, not a defect.")
    if broken:
        bad = [(o, n) for o, n in outcomes.most_common() if o not in RAID_GOOD]
        yield Finding("WARN", "raid-collapsed",
                      "%d raid steps ended before the ambush was even set: %s"
                      % (broken, ", ".join("%s %d" % (o, n) for o, n in bad)),
                      "noleader and nodest are the leader measure failing at "
                      "Scripts/Measures/Squad/ms_bf_Ambush.lua before it can set the meeting "
                      "place; nosquad and nomeeting are a member arriving before the leader "
                      "ran, which is the same-tick shape - aitwp_SquadAttack adds every "
                      "member in the tick it calls SquadCreate, where vanilla joins them a "
                      "tick later via Scripts/AI/BaseTree/Feud/AttackFeud/AttackMyrmidon/"
                      "JoinSquad.lua. deserted means the squad emptied under the leader, "
                      "which aitwp_IsFreeForOrders should now prevent by honouring the "
                      "AI_RaidOrder stamp.")
    if s.raid_steps and not struck:
        yield Finding("NOTE", "raid-no-contact",
                      "%d raid steps and not one reached the victim" % len(s.raid_steps),
                      "Not a defect on its own: the ambush waits TWP_AMBUSH_HOURS for the "
                      "target to come within TWP_AMBUSH_RADIUS and a session can simply end "
                      "first, which is what happened on 2026-09-20 - the log stopped 1.4 "
                      "hours after the raid against a 4-hour wait. Judge this only on a "
                      "session that ran well past the ambush window.")


# chr_SpendMoney started actually debiting AI houses on 2026-09-21. Before that its AI
# branch was commented out and every debit fell through to an engine call that does not work
# on AI dynasties, so a house was credited through the AI_DynMoney ledger and never charged:
# 332 settlements in one session, all "received", none "spent". This is the check that says
# whether turning it on bankrupted anyone.
# route=poor is an ACTUAL refusal and aborts the caller; route=wouldrefuse is the same
# shortfall recorded while TWP_SPEND_ENFORCE is off, so the measure still runs. They have
# to be counted apart: on 2026-09-21 enforcement went out by mistake, a quarter of debits
# refused, and half a town stopped acting.
SPEND_POOR_SHARE = 25
SPEND_SHORT_SHARE = 25


def check_spending(s):
    """Do AI houses pay their bills now, and can they still afford to?"""
    if not s.spends:
        return
    routes = Counter(r.get("route", "?") for r in s.spends)
    poor = routes.get("poor", 0)
    short = routes.get("wouldrefuse", 0)
    share = 100.0 * poor / len(s.spends)
    short_share = 100.0 * short / len(s.spends)
    negative = sum(1 for r in s.spends if num(r.get("purse", 0)) < 0)
    yield Finding("NOTE", "spending",
                  "%d debits: %s" % (len(s.spends),
                                     ", ".join("%s %d" % (r, n) for r, n in routes.most_common())),
                  "Scripts/Library/chr.lua, chr_SpendMoney, via aitwp_LogSpend. route=ledger "
                  "is an AI house paying through AI_DynMoney, route=engine a player or a "
                  "GUI-driven dynasty going straight to the engine, route=poor a refusal. "
                  "Before 2026-09-21 none of this happened at all and every AI debit silently "
                  "succeeded without moving any money.")
    if negative:
        yield Finding("WARN", "spending-negative-purse",
                      "%d debits were priced against a NEGATIVE purse (worst %d)"
                      % (negative,
                         min(int(num(r.get("purse", 0))) for r in s.spends)),
                      "purse is GetMoney PLUS the unsettled ledger, and ledger= is that half "
                      "on its own - read them together, because the sum alone cannot tell a "
                      "house genuinely in debt from one hour of unsettled spending. "
                      "ledger near 0 with purse deeply negative is a house that really is "
                      "broke, which is the expected consequence of debits landing after "
                      "years of being free, not a defect. A large negative LEDGER is the "
                      "other case: chr_GiveMoney is not settling. Do not count "
                      "::AITWP::GiveMoney lines to judge that - it writes nothing at all "
                      "when the ledger is zero, so counting them undercounts settles and "
                      "was how this was misread on 2026-09-22.")
    if short_share >= SPEND_SHORT_SHARE:
        yield Finding("NOTE", "spending-would-refuse",
                      "%.0f%% of debits could not be covered (%d of %d) but were allowed "
                      "through, because TWP_SPEND_ENFORCE is off"
                      % (short_share, short, len(s.spends)),
                      "This is the number that decides whether enforcement can be turned "
                      "on in Scripts/Library/chr.lua. While it is high, switching it on "
                      "aborts that share of every paid measure - which is exactly what "
                      "happened on 2026-09-21 when it shipped on by accident.")
    if share >= SPEND_POOR_SHARE:
        worst = Counter(r.get("reason", "-") for r in s.spends if r.get("route") == "poor")
        yield Finding("WARN", "spending-broke",
                      "%.0f%% of debits were refused for want of money (%d of %d); most "
                      "refused reason: %s"
                      % (share, poor, len(s.spends),
                         ", ".join("%s %d" % (k, n) for k, n in worst.most_common(3))),
                      "This is the risk that was accepted when the debit path was turned on: "
                      "AI houses had been spending for free and may not survive paying. purse= "
                      "on each line is GetMoney plus the unsettled ledger. If purse is large "
                      "and the refusal still fires, the arithmetic is wrong, not the economy; "
                      "if purse is genuinely small, chr_GiveMoney in Scripts/Library/chr.lua "
                      "settles the ledger hourly and may simply be slower than the spending.")


# Giving a building back to a member of the right class. Reported from play twice: when a
# dynasty's only Rogue dies the engine hands the thieves' guild to a sibling of the wrong
# class, and "Assign Owner" then does nothing. Vanilla's measure reported only a MsgQuick,
# so there was no way to tell a class rule from an engine refusal.
def check_assign(s):
    """Does reassigning a building to another member work, and if not, why not?"""
    if not s.assigns:
        return
    ok = [r for r in s.assigns if r.get("result") == "true"]
    bad = [r for r in s.assigns if r.get("result") != "true"]
    hows = Counter(r.get("how", "?") for r in ok)
    yield Finding("NOTE", "assign-owner",
                  "%d building reassignments: %d succeeded (%s), %d refused"
                  % (len(s.assigns), len(ok),
                     ", ".join("%s %d" % (h, n) for h, n in hows.most_common()) or "-",
                     len(bad)),
                  "Scripts/Measures/ms_035_AssignCharacterToBuilding.lua, via aitwp_LogAssign. "
                  "how=plain is vanilla's two-argument BuildingSetOwner; how=force is the third "
                  "argument meta/engine.signatures.tsv recovers from the binary and "
                  "meta/engine.d.lua does not document. A single how=force line settles what "
                  "every caller in both trees has been guessing at.")
    blocked = [r for r in bad if r.get("canown") == "false"]
    if blocked:
        r = blocked[0]
        yield Finding("NOTE", "assign-wrong-class",
                      "%d refusals were the class rule, not a defect (bld %s wants class %s, "
                      "sim is %s)" % (len(blocked), r.get("bld", "?"),
                                      r.get("bldclass", "?"), r.get("simclass", "?")),
                      "BuildingCanBeOwnedBy said no, so the engine is right and the member "
                      "genuinely cannot hold that building. The real problem is upstream: "
                      "nothing in Lua chooses the heir, so a dead owner's buildings are "
                      "reassigned by the engine with no class test at all. The three measures "
                      "that assign deliberately - ms_071_BuyBuilding, ms_238_TakeOverBid and "
                      "ms_043_CaptureBuilding - each carry their own copy of that test.")
    theft = [r for r in bad if r.get("how") == "notmine"]
    if theft:
        yield Finding("NOTE", "assign-not-yours",
                      "%d attempts to assign a building belonging to another dynasty were "
                      "refused" % len(theft),
                      "Working as intended, and worth watching. Filter 122 admits any "
                      "building a class-matching member is standing in - vanilla's did too "
                      "- and the only thing that ever stopped a rival's shop being taken "
                      "was the engine refusing the transfer. Since ms_035 retries with "
                      "BuildingSetOwner's third argument to defeat exactly that refusal, "
                      "the ownership test now lives in the measure. If this count is high "
                      "the button is being offered where it can never work, which is a UI "
                      "annoyance rather than a risk.")
    unexplained = [r for r in bad if r.get("canown") == "true" and r.get("how") != "notmine"]
    if unexplained:
        r = unexplained[0]
        yield Finding("WARN", "assign-refused",
                      "%d reassignments were refused although the member may own the building "
                      "(bld %s, previous owner %s)"
                      % (len(unexplained), r.get("bld", "?"), r.get("old", "?")),
                      "BuildingCanBeOwnedBy says yes and the measure's own filter let the "
                      "button appear, so neither class nor the filter explains this. old= is "
                      "the previous owner: if it is not -1, the engine is refusing to TRANSFER "
                      "rather than to assign, and the third argument of BuildingSetOwner is "
                      "the next thing to read - the only call that demonstrably works, "
                      "Scripts/Measures/Debug/Construct.lua, assigns a building it just "
                      "spawned and which has no previous owner.")


# Buildings whose owner is the wrong class for them. Nothing in Lua chooses an heir - the
# engine reassigns a dead owner's buildings with no class test - so this is the footprint of
# that bug, and it is otherwise invisible without clicking every building in the game.
def check_misowned(s):
    """Which buildings are held by a member who cannot legally own them?"""
    if not s.misowned:
        return
    per_bld = {}
    for r in s.misowned:
        per_bld[r.get("bld", "?")] = r
    stuck = [r for r in per_bld.values() if r.get("canown") == "false"]
    yield Finding("WARN", "misowned-building",
                  "%d buildings are held by an owner of the wrong class; %d of them cannot be "
                  "reassigned to that owner at all (needs class %s, owner is %s)"
                  % (len(per_bld), len(stuck),
                     "/".join(sorted(set(r.get("need", "?") for r in per_bld.values())))[:20],
                     "/".join(sorted(set(r.get("has", "?") for r in per_bld.values())))[:20]),
                  "Scripts/Library/bld.lua, bld_LogOwnerClass, once a day per building. Class "
                  "ids: 1 patron, 2 artisan, 3 scholar, 4 rogue. canown= is "
                  "BuildingCanBeOwnedBy for the CURRENT owner, and it is the same engine call "
                  "filter 122 uses to decide whether to draw the Assign-owner button - so "
                  "canown=false is exactly the building where that button will not appear. "
                  "Reassigning needs a member of class need=; if the dynasty has none, the "
                  "building cannot be recovered by the player at all and the real fix is "
                  "upstream at inheritance, which has no Lua hook.")


# A worker slot still held by a dead sim. Nothing released a job on death until 2026-09-22:
# Fire(), the documented call for it, had exactly one caller in either tree - the player's
# own Fire Employee action.
def check_dead_workers(s):
    """Are dead employees still occupying their places?"""
    if not s.deadworkers:
        return
    per = {}
    for r in s.deadworkers:
        per[(r.get("bld", "?"), r.get("slot", "?"))] = r
    blds = sorted(set(k[0] for k in per))
    yield Finding("WARN", "dead-worker",
                  "%d worker slots across %d buildings are held by a dead sim (worst building "
                  "%s)" % (len(per), len(blds),
                           Counter(k[0] for k in per).most_common(1)[0][0]),
                  "Scripts/Library/bld.lua, bld_LogDeadWorkers, once a day per building. "
                  "Scripts/States/state_dead.lua now calls Fire() so the NEXT death releases "
                  "its job, but an existing save keeps every slot already stuck - those have "
                  "to be freed by hand with the player's own Fire Employee action, or they "
                  "hold the place for ever. If this count keeps RISING after 2026-09-22 the "
                  "release is not being reached; if it is flat, it is the backlog.")


CHECKS = (check_telemetry, check_runtime_errors, check_replay, check_self_cancel,
          check_order_guard, check_barren, check_subtree_barren, check_blackboard, check_htn_methods, check_htn_promise, check_carts, check_market,
          check_handovers, check_buyworkshop, check_raids, check_spying, check_attacks, check_raid_steps, check_healing, check_hospital_stock, check_hiring, check_hijack, check_spending, check_assign, check_misowned, check_dead_workers, check_idprobe,
          check_blood_rival, check_stuck_walk, check_trials, check_silent_channels, check_idle, check_test_knobs, check_supply, check_stray_goods)


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


def why_table(rows):
    """What each node said when it refused, grouped by subject.

    The WHY channel exists to answer 'why did this node weigh 0' and until 2026-09-19
    nothing read it - the lines were parsed into self.why and left there. A gate that
    fires 779 times out of 873 is the finding; without this block you only see it by
    grepping, which is how the ToMEconomy shadow leak went two sessions unnoticed.
    """
    if not rows:
        return []
    by_subject = defaultdict(list)
    for row in rows:
        by_subject[row.get("subject", "-")].append(row)
    out = ["", "why nodes refused (::TWP::WHY, %d lines):" % len(rows)]
    for subject, group in sorted(by_subject.items(), key=lambda kv_: -len(kv_[1])):
        gates = Counter(r["gate"] for r in group if r.get("gate"))
        if gates:
            detail = ", ".join("%s %d" % (g, n) for g, n in gates.most_common(6))
        else:
            # no positional gate, so summarise the numbers instead: a small value set
            # reads as counts, a wide one as its range
            bits = []
            for key in sorted(set(k for r in group for k in r)):
                if key in ("t", "dyn", "subject", "gate", "raid"):
                    continue
                values = [r[key] for r in group if key in r]
                distinct = sorted(set(values))
                if len(distinct) <= 4:
                    bits.append("%s %s" % (key, "/".join(distinct)))
                else:
                    numeric = sorted(num(v) for v in values)
                    bits.append("%s %g..%g" % (key, numeric[0], numeric[-1]))
            detail = ", ".join(bits) or "-"
        out.append("  %-24s %5d  %s" % (subject, len(group), detail))
    return out


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
    out.extend(why_table(session.why))

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
    # spying: an order that never ends is the bug it was disabled for, and a couple still
    # running at the end of a session is not - the measure lasts four game hours
    spy = Session()
    spy.feed(["[Script] ::TWP::SPY t=1.00 action=order spy=1 victim=2 ok=true evidence=-1",
              "[Script] ::TWP::SPY t=1.00 action=begin spy=1 victim=2 ok=true evidence=-1",
              "[Script] ::TWP::SPY t=5.00 action=end spy=1 victim=2 ok=true evidence=3"])
    codes_spy = [f.code for f in findings(spy)]
    assert "spying" in codes_spy and "spy-never-ended" not in codes_spy, findings(spy)
    assert "3 evidence gathered" in format_findings(findings(spy)), format_findings(findings(spy))
    # in flight, not leaked: ten begins in the last few hours of a session whose completed
    # runs take ~4 h. This is the 2026-09-19 log, which tripped the abort signal twice.
    flight = Session()
    flight.feed(["[Script] ::TWP::SPY t=1.00 action=begin spy=0 victim=2 ok=true evidence=-1",
                 "[Script] ::TWP::SPY t=5.00 action=end spy=0 victim=2 ok=true evidence=1"]
                + ["[Script] ::TWP::SPY t=%.2f action=begin spy=%d victim=2 ok=true evidence=-1"
                   % (28.0 + i * 0.3, i) for i in range(1, 11)]
                + ["[Script] ::TWP::SPY t=31.00 action=order spy=99 victim=2 ok=true evidence=-1"])
    codes_flight = [f.code for f in findings(flight)]
    assert "spy-never-ended" not in codes_flight, findings(flight)
    assert "10 still out" in format_findings(findings(flight)), format_findings(findings(flight))
    # leaked: begun and still out long after every finished run came home
    stuck = Session()
    stuck.feed(["[Script] ::TWP::SPY t=1.00 action=begin spy=0 victim=2 ok=true evidence=-1",
                "[Script] ::TWP::SPY t=5.00 action=end spy=0 victim=2 ok=true evidence=1"]
               + ["[Script] ::TWP::SPY t=%d.00 action=begin spy=%d victim=2 ok=true evidence=-1" % (i, i)
                  for i in range(1, 6)]
               + ["[Script] ::TWP::SPY t=100.00 action=order spy=99 victim=2 ok=true evidence=-1"])
    assert "spy-never-ended" in [f.code for f in findings(stuck)], findings(stuck)
    # AttackEnemy: refusing over and over is the hijack spin, a couple is ordinary
    spin = Session()
    spin.feed(["[Script] ::TWP::ATTACK t=%.2f sim=7 target=9 result=mayattack" % (1000 + i * 0.03)
               for i in range(12)])
    codes_spin = [f.code for f in findings(spin)]
    assert "attack-refused" in codes_spin and "attack-outcomes" in codes_spin, findings(spin)
    calm = Session()
    calm.feed(["[Script] ::TWP::ATTACK t=1.00 sim=7 target=9 result=unreachable",
               "[Script] ::TWP::ATTACK t=2.00 sim=7 target=9 result=joined"])
    assert "attack-refused" not in [f.code for f in findings(calm)], findings(calm)
    # the hospital: a refusal that did not stick brings the same patient back inside 12h
    heal = Session()
    heal.feed(["[Script] ::TWP::HEAL t=1.00 sim=4 hospital=9 cost=300 purse=12 outcome=nomoney",
               "[Script] ::TWP::HEAL t=2.00 sim=4 hospital=9 cost=300 purse=12 outcome=nomoney",
               "[Script] ::TWP::HEAL t=3.00 sim=5 hospital=9 cost=80 purse=999 outcome=healed"])
    codes_heal = [f.code for f in findings(heal)]
    assert "hospital-refusal-loop" in codes_heal and "healing" in codes_heal, findings(heal)
    assert "nomoney 2, healed 1" in format_findings(findings(heal)), format_findings(findings(heal))
    stuck_ok = Session()
    stuck_ok.feed(["[Script] ::TWP::HEAL t=1.00 sim=4 hospital=9 cost=300 purse=12 outcome=nomoney",
                   "[Script] ::TWP::HEAL t=20.00 sim=4 hospital=9 cost=300 purse=12 outcome=nomoney"])
    assert "hospital-refusal-loop" not in [f.code for f in findings(stuck_ok)], findings(stuck_ok)
    # auto-supply: a drop is a NOTE naming the good, a row whose two columns disagree is a WARN
    sup = Session()
    sup.feed(["[Script] ::TWP::SUPPLY t=1.00 bld=7 proto=392 workers=2 live=6 matched=11 "
              "kept=8:16;120:32; dropped=133:ToadExcrements:locked;204:Fungi:deselected;",
              "[Script] ::TWP::SUPPLY t=2.00 bld=9 proto=666 workers=1 live=3 matched=5 "
              "kept=201:6; dropped=slot6:malformed;usage8:orphan;"])
    codes_sup = [f.code for f in findings(sup)]
    assert "supply-filtered" in codes_sup and "requireditems-malformed" in codes_sup, findings(sup)
    assert "supply-filter-dead" not in codes_sup, findings(sup)
    printed_sup = format_findings(findings(sup))
    assert "ToadExcrements" in printed_sup, printed_sup
    # a locked recipe and a deselected one are different problems and must read differently
    assert "1 locked" in printed_sup and "1 deselected" in printed_sup, printed_sup
    # both directions of a misaligned row are named, and named apart
    assert "malformed x1" in printed_sup and "orphan x1" in printed_sup, printed_sup
    # matched=0 is the filter silently doing nothing, which silence would otherwise hide
    dead = Session()
    dead.feed(["[Script] ::TWP::SUPPLY t=1.00 bld=7 proto=392 workers=2 live=6 matched=0 "
               "kept=8:16; dropped="])
    assert "supply-filter-dead" in [f.code for f in findings(dead)], findings(dead)
    # the clay case: a stale need plus a cart that actually delivered it is the whole chain
    stray = Session()
    stray.feed(["[Script] ::TWP::NEEDSTALE t=2.00 bld=4 proto=195 need=30:Clay:inv1:2;",
                "[Script] ::TWP::UNLOAD t=3.00 cart=8 dest=4 via=autocart items=30:Clay:2;"])
    codes_stray = [f.code for f in findings(stray)]
    assert "need-stale" in codes_stray and "stray-goods-delivered" in codes_stray, findings(stray)
    # an unload that matches no stale need must not be blamed
    plain = Session()
    plain.feed(["[Script] ::TWP::UNLOAD t=3.00 cart=8 dest=4 via=UnloadAll items=120:Lavender:9;"])
    codes_plain = [f.code for f in findings(plain)]
    assert "cart-unloads" in codes_plain and "stray-goods-delivered" not in codes_plain, findings(plain)
    # the id probe: the healthy answer names which forms work, the sick ones are ERRORs
    ok = Session()
    ok.feed(["[Script] ::TWP::IDPROBE t=1.00 bld=7 proto=392 listid=number:360 "
             "getname=string:Bandage id_byname=number:360 id_bynumstr=number:360 "
             "id_bynum=number:360 prod1=number:201 canprod_num=boolean:true "
             "canprod_numstr=boolean:false canprod_name=boolean:true"])
    codes_ok = [f.code for f in findings(ok)]
    assert "idprobe" in codes_ok and not [c for c in codes_ok if c.startswith("idprobe-")], findings(ok)
    assert "accepts num+name" in format_findings(findings(ok)), format_findings(findings(ok))
    # a numeric string that does not round-trip breaks every resource need in the game
    lost = Session()
    lost.feed(["[Script] ::TWP::IDPROBE t=1.00 bld=7 proto=392 listid=number:360 "
               "getname=string:Bandage id_byname=number:360 id_bynumstr=nil:- "
               "id_bynum=number:360 prod1=number:201 canprod_num=boolean:true "
               "canprod_numstr=boolean:false canprod_name=boolean:true"])
    assert "idprobe-numstr-lost" in [f.code for f in findings(lost)], findings(lost)
    # a string where a number was expected is a table key that can never match
    typed = Session()
    typed.feed(["[Script] ::TWP::IDPROBE t=1.00 bld=7 proto=392 listid=number:360 "
                "getname=string:Bandage id_byname=number:360 id_bynumstr=number:360 "
                "id_bynum=number:360 prod1=string:201 canprod_num=boolean:true "
                "canprod_numstr=boolean:false canprod_name=boolean:true"])
    assert "idprobe-prod-type" in [f.code for f in findings(typed)], findings(typed)
    # and no form working at all means the live-product filter is blind
    blind = Session()
    blind.feed(["[Script] ::TWP::IDPROBE t=1.00 bld=7 proto=392 listid=number:360 "
                "getname=string:Bandage id_byname=number:360 id_bynumstr=number:360 "
                "id_bynum=number:360 prod1=number:201 canprod_num=boolean:false "
                "canprod_numstr=boolean:false canprod_name=nil:-"])
    assert "idprobe-canproduce-none" in [f.code for f in findings(blind)], findings(blind)
    # hospital stock: a neutral hospital at zero is the finding, an owned one is a NOTE
    dry = Session()
    dry.feed(["[Script] ::TWP::HOSP t=5.00 bld=1 owned=false level=2 Bandage=0:100 "
              "Medicine=0:100 PainKiller=2:75",
              "[Script] ::TWP::HOSP t=5.00 bld=2 owned=true level=3 Bandage=14:0 "
              "Medicine=9:0 PainKiller=8:0"])
    found_dry = {f.code: f for f in findings(dry)}
    assert "hospital-stock" in found_dry, findings(dry)
    printed_dry = format_findings(findings(dry))
    assert "neutral" in printed_dry and "ran out of Bandage, Medicine" in printed_dry, printed_dry
    assert [f.level for f in findings(dry) if f.code == "hospital-stock" and "neutral" in f.text] == ["WARN"], printed_dry
    assert [f.level for f in findings(dry) if f.code == "hospital-stock" and "owned" in f.text] == ["NOTE"], printed_dry
    # raids that never went: an empty house and an unreachable target read differently
    norai = Session()
    norai.feed(["[Script] ::TWP::WHY t=1.00 dyn=7 raid=assassination_attempt pool=0 party=0 "
                "theirs=1 chance=0.00 bar=0.65 need=-1"] * 3
               + ["[Script] ::TWP::WHY t=2.00 dyn=7 raid=assassination_attempt pool=1 party=1 "
                  "theirs=1 chance=0.01 bar=0.65 need=12"])
    printed_raid = format_findings(findings(norai))
    assert "raid-never-decided" in [f.code for f in findings(norai)], findings(norai)
    assert "3 of those had nobody to send" in printed_raid, printed_raid
    assert "past TWP_WAR_PARTY_MAX" in printed_raid, printed_raid
    # need=-1 must never be reported as a gap of its own
    assert "-1 hands" not in printed_raid and "needed -1" not in printed_raid, printed_raid
    empty_only = Session()
    empty_only.feed(["[Script] ::TWP::WHY t=1.00 dyn=7 raid=workers_raid pool=0 party=0 "
                     "theirs=1 chance=0.00 bar=0.65 need=-1"] * 2)
    assert "no hirelings to send at all" in format_findings(findings(empty_only)),         format_findings(findings(empty_only))
    # hiring: deciding to hire and never gaining a hand is the pool=0 shape
    nohire = Session()
    nohire.feed(["[Script] ::TWP::HIRE t=%d.00 dyn=7 node=HireMyrmidon bld=9 slots=true "
                 "thugs=0 robbers=0 mercs=0 thieves=0 beggars=0" % i for i in range(1, 5)])
    codes_hire = [f.code for f in findings(nohire)]
    assert "hiring-never-lands" in codes_hire and "hiring" in codes_hire, findings(nohire)
    grew = Session()
    grew.feed(["[Script] ::TWP::HIRE t=1.00 dyn=7 node=HireMyrmidon bld=9 slots=true "
               "thugs=0 robbers=0 mercs=0 thieves=0 beggars=0",
               "[Script] ::TWP::HIRE t=3.00 dyn=7 node=HireMyrmidon bld=9 slots=true "
               "thugs=1 robbers=0 mercs=0 thieves=0 beggars=0",
               "[Script] ::TWP::HIRE t=5.00 dyn=7 node=HireMyrmidon bld=9 slots=true "
               "thugs=2 robbers=0 mercs=0 thieves=0 beggars=0"])
    assert "hiring-never-lands" not in [f.code for f in findings(grew)], findings(grew)
    # hijack: the user watched one thief walk into a party of three. Two lone hands and
    # no join is that shape; the same two joining one squad is the fix working.
    alone = Session()
    alone.feed(["[Script] ::TWP::HIJACK t=1.00 bld=9 sim=11 victim=55 hands=1 joined=false",
                "[Script] ::TWP::HIJACK t=2.00 bld=9 sim=12 victim=55 hands=1 joined=false"])
    assert "lone-kidnap" in [f.code for f in findings(alone)], findings(alone)
    party = Session()
    party.feed(["[Script] ::TWP::HIJACK t=1.00 bld=9 sim=11 victim=55 hands=1 joined=false",
                "[Script] ::TWP::HIJACK t=1.10 bld=9 sim=12 victim=55 hands=2 joined=true",
                "[Script] ::TWP::HIJACK t=1.20 bld=9 sim=13 victim=55 hands=3 joined=true"])
    codes_hj = [f.code for f in findings(party)]
    assert "lone-kidnap" not in codes_hj and "hijack" in codes_hj, findings(party)
    # hire outcomes: every exit of ms_048 was a popup and nothing else, so a house that
    # tried and failed read exactly like one that never tried. want= must survive into
    # the text, or the finding cannot say which level could not be filled.
    hend = Session()
    hend.feed([
        '[Script] ::TWP::HIREEND t=1.00 bld=9 stage=noworker_NoWorker want=5 cost=-1 purse=8000',
        '[Script] ::TWP::HIREEND t=3.00 bld=9 stage=ownerpoor want=3 cost=9000 purse=800'])
    text_he = format_findings(findings(hend))
    assert "hire-outcomes" in [f.code for f in findings(hend)], findings(hend)
    assert "noworker_NoWorker 1" in text_he, text_he
    assert "not found: 5" in text_he, text_he
    ok_hire = Session()
    ok_hire.feed(
        ['[Script] ::TWP::HIREEND t=1.00 bld=9 stage=hired want=3 cost=900 purse=8000'])
    levels_he = [f.level for f in findings(ok_hire) if f.code == "hire-outcomes"]
    assert levels_he == ["NOTE"], findings(ok_hire)

    # debt vs backlog: same negative purse, different cause, and the check must not
    # conflate them. ledger~0 = really broke; ledger deeply negative = not settling.
    indebt = Session()
    indebt.feed(['[Script] ::TWP::SPEND t=1.00 sim=1 dyn=7 amount=50 route=ledger purse=-38611 ledger=-12 reason=x'])
    text_id = format_findings(findings(indebt))
    assert "spending-negative-purse" in [f.code for f in findings(indebt)], findings(indebt)
    assert "worst -38611" in text_id, text_id

    # the 2026-09-21 regression, as a fixture: a recorded shortfall must NOT read as a
    # refusal, and a negative purse is its own finding
    shortfall = Session()
    shortfall.feed(['[Script] ::TWP::SPEND t=%d.00 sim=1 dyn=7 amount=500 route=wouldrefuse purse=-1736 reason=WaresBought' % i for i in range(1, 4)]
                   + ['[Script] ::TWP::SPEND t=9.00 sim=1 dyn=7 amount=5 route=ledger purse=900 reason=x'])
    codes_sf = [f.code for f in findings(shortfall)]
    text_sf = format_findings(findings(shortfall))
    assert "spending-would-refuse" in codes_sf, findings(shortfall)
    assert "spending-broke" not in codes_sf, findings(shortfall)
    assert "spending-negative-purse" in codes_sf, findings(shortfall)
    assert "worst -1736" in text_sf, text_sf
    # a healthy run trips none of the three
    solvent = Session()
    solvent.feed(['[Script] ::TWP::SPEND t=1.00 sim=1 dyn=7 amount=5 route=ledger purse=900 reason=x'])
    codes_so = [f.code for f in findings(solvent)]
    assert "spending" in codes_so, findings(solvent)
    assert not [c for c in codes_so if c.startswith("spending-")], findings(solvent)

    # dead workers: deduplicate by (building, slot) so a daily line is not a new finding,
    # and the same sim in two slots of two buildings is two
    dw = Session()
    dw.feed(['[Script] ::TWP::DEADWORK t=1.00 bld=9 slot=3 sim=55 workers=6',
             '[Script] ::TWP::DEADWORK t=25.00 bld=9 slot=3 sim=55 workers=6',
             '[Script] ::TWP::DEADWORK t=25.00 bld=12 slot=0 sim=77 workers=4'])
    text_dw = format_findings(findings(dw))
    assert "dead-worker" in [f.code for f in findings(dw)], findings(dw)
    assert "2 worker slots across 2 buildings" in text_dw, text_dw

    # misowned: the footprint of the engine's classless inheritance. canown=false is the
    # building whose Assign-owner button will not appear, which is what the player reported.
    mis = Session()
    mis.feed(['[Script] ::TWP::BLDOWN t=1.00 bld=9 type=38 need=4 has=1 owner=11 canown=false',
              '[Script] ::TWP::BLDOWN t=25.00 bld=9 type=38 need=4 has=1 owner=11 canown=false',
              '[Script] ::TWP::BLDOWN t=1.00 bld=12 type=7 need=2 has=3 owner=14 canown=true'])
    text_mi = format_findings(findings(mis))
    assert "misowned-building" in [f.code for f in findings(mis)], findings(mis)
    # deduplicated by building, so a daily line does not inflate the count
    assert "2 buildings are held" in text_mi, text_mi
    assert "1 of them cannot be reassigned" in text_mi, text_mi

    # assign-owner: the three outcomes have to stay apart. A class refusal is the engine
    # being right; a refusal with canown=true is the one worth waking someone for.
    asn = Session()
    asn.feed(['[Script] ::TWP::ASSIGN t=1.00 bld=9 sim=11 old=-1 bldclass=4 simclass=4 canown=true result=true how=plain'])
    assert "assign-owner" in [f.code for f in findings(asn)], findings(asn)
    assert "assign-refused" not in [f.code for f in findings(asn)], findings(asn)
    wrongclass = Session()
    wrongclass.feed(['[Script] ::TWP::ASSIGN t=1.00 bld=9 sim=11 old=12 bldclass=4 simclass=2 canown=false result=false how=force'])
    codes_wc = [f.code for f in findings(wrongclass)]
    assert "assign-wrong-class" in codes_wc, findings(wrongclass)
    assert "assign-refused" not in codes_wc, findings(wrongclass)
    refused = Session()
    refused.feed(['[Script] ::TWP::ASSIGN t=1.00 bld=9 sim=11 old=12 bldclass=4 simclass=4 canown=true result=false how=force'])
    text_rf = format_findings(findings(refused))
    assert "assign-refused" in [f.code for f in findings(refused)], findings(refused)
    assert "previous owner 12" in text_rf, text_rf
    # and the one that settles the undocumented third argument
    forced = Session()
    forced.feed(['[Script] ::TWP::ASSIGN t=1.00 bld=9 sim=11 old=12 bldclass=4 simclass=4 canown=true result=true how=force'])
    assert "force 1" in format_findings(findings(forced)), format_findings(findings(forced))
    # a rival's building must read as a correct refusal, never as assign-refused
    notmine = Session()
    notmine.feed(['[Script] ::TWP::ASSIGN t=1.00 bld=9 sim=11 old=12 bldclass=4 simclass=4 canown=true result=false how=notmine'])
    codes_nm = [f.code for f in findings(notmine)]
    assert "assign-not-yours" in codes_nm, findings(notmine)
    assert "assign-refused" not in codes_nm, findings(notmine)

    # spending: AI houses paying through the ledger is the fix working; a flood of refusals
    # is the risk that was accepted when it was turned on.
    paid = Session()
    paid.feed(['[Script] ::TWP::SPEND t=1.00 sim=11 dyn=7 amount=100 route=ledger purse=9000 reason=Offering',
               '[Script] ::TWP::SPEND t=2.00 sim=12 dyn=7 amount=50 route=engine purse=400 reason=Offering'])
    codes_sp = [f.code for f in findings(paid)]
    assert "spending" in codes_sp, findings(paid)
    assert "spending-broke" not in codes_sp, findings(paid)
    broke = Session()
    broke.feed(['[Script] ::TWP::SPEND t=%d.00 sim=11 dyn=7 amount=900 route=poor purse=10 reason=LaborHansel' % i for i in range(1, 5)]
               + ['[Script] ::TWP::SPEND t=9.00 sim=12 dyn=7 amount=5 route=ledger purse=900 reason=Offering'])
    text_sp = format_findings(findings(broke))
    assert "spending-broke" in [f.code for f in findings(broke)], findings(broke)
    assert "LaborHansel 4" in text_sp, text_sp

    # raids: a healthy ambush that expires is NOT a collapse - a mine nobody walks to is a
    # wasted morning. Only the exits before the meeting place is set are the defect.
    ambush = Session()
    ambush.feed(['[Script] ::TWP::RAID t=1.00 obj=11 role=leader outcome=laid',
                 '[Script] ::TWP::RAID t=1.10 obj=12 role=member outcome=nobodycame',
                 '[Script] ::TWP::RAID t=1.20 obj=13 role=leader outcome=timeout'])
    codes_am = [f.code for f in findings(ambush)]
    assert "raid-steps" in codes_am, findings(ambush)
    assert "raid-collapsed" not in codes_am, findings(ambush)
    assert "raid-no-contact" in codes_am, findings(ambush)
    collapsed = Session()
    collapsed.feed(['[Script] ::TWP::RAID t=1.00 obj=11 role=member outcome=nosquad',
                    '[Script] ::TWP::RAID t=1.05 obj=12 role=member outcome=nomeeting',
                    '[Script] ::TWP::RAID t=1.10 obj=13 role=leader outcome=noleader'])
    text_co = format_findings(findings(collapsed))
    assert "raid-collapsed" in [f.code for f in findings(collapsed)], findings(collapsed)
    assert "3 raid steps ended before the ambush was even set" in text_co, text_co
    hit = Session()
    hit.feed(['[Script] ::TWP::RAID t=1.00 obj=11 role=leader outcome=laid',
              '[Script] ::TWP::RAID t=1.10 obj=12 role=member outcome=struck'])
    assert "raid-no-contact" not in [f.code for f in findings(hit)], findings(hit)

    # trials: the player was fined for a DEAD magistrate, and the log had been saying so
    # 200 times a session in a subsystem no parser read. The share is the finding.
    trial = Session()
    trial.feed(['[Script] ::TWP::W t=10.00 dyn=1 node=Dynasty base=5 c= g=none w=5']
               + ['[TRIAL] Judge does not exist.'] * 20
               + ['[TRIAL] Judge found.'] * 5
               + ['[TRIAL] Waiting with Emilie Nowak'] * 25
               + ['[Script] ::TWP::W t=25.00 dyn=1 node=Dynasty base=5 c= g=none w=5'])
    codes_tr = [f.code for f in findings(trial)]
    text_tr = format_findings(findings(trial))
    assert "trial-no-judge" in codes_tr and "trial-queue-stuck" in codes_tr, findings(trial)
    assert "80% of trials found no judge" in text_tr, text_tr
    assert "Emilie Nowak x25" in text_tr, text_tr
    assert "0 released after the judge never came" in text_tr, text_tr
    assert "counter reached never logged" in text_tr, text_tr
    # the per-round counter: if it never climbs the loop is not being re-entered,
    # which is a different defect from the release threshold being too high
    climbing = Session()
    climbing.feed(['[Script] ::TWP::W t=10.00 dyn=1 node=Dynasty base=5 c= g=none w=5']
                  + ['[TRIAL] No judge, round %d of 8 for Hinrich Mahler' % n for n in (1, 2, 3)]
                  + ['[TRIAL] Judge does not exist.'] * 3
                  + ['[Script] ::TWP::W t=25.00 dyn=1 node=Dynasty base=5 c= g=none w=5'])
    text_cl = format_findings(findings(climbing))
    assert "counter reached 3" in text_cl, text_cl
    # 2026-09-21 exit is unfalsifiable from the log
    freed = Session()
    freed.feed(['[Script] ::TWP::W t=10.00 dyn=1 node=Dynasty base=5 c= g=none w=5']
               + ['[TRIAL] Judge does not exist.'] * 20
               + ['[TRIAL] Judge found.'] * 5
               + ['[TRIAL] No judge for 8 rounds, releasing Emilie Nowak'] * 3
               + ['[Script] ::TWP::W t=25.00 dyn=1 node=Dynasty base=5 c= g=none w=5'])
    text_fr = format_findings(findings(freed))
    assert "3 released after the judge never came" in text_fr, text_fr
    # a healthy court: a judge is usually found and nobody waits in a loop
    court = Session()
    court.feed(['[Script] ::TWP::W t=10.00 dyn=1 node=Dynasty base=5 c= g=none w=5']
               + ['[TRIAL] Judge found.'] * 20
               + ['[TRIAL] Judge does not exist.'] * 2
               + ['[TRIAL] Waiting with Emilie Nowak'] * 3
               + ['[Script] ::TWP::W t=25.00 dyn=1 node=Dynasty base=5 c= g=none w=5'])
    codes_ct = [f.code for f in findings(court)]
    assert "trial-no-judge" not in codes_ct, findings(court)
    assert "trial-queue-stuck" not in codes_ct, findings(court)
    # a court with a judge but long queues must stay SILENT: that is the 2026-09-06 shape,
    # 132 of 132 judges found and sims still waiting 267 times
    patient = Session()
    patient.feed(['[Script] ::TWP::W t=10.00 dyn=1 node=Dynasty base=5 c= g=none w=5']
                 + ['[TRIAL] Judge found.'] * 40
                 + ['[TRIAL] Waiting with Michael Besant'] * 100
                 + ['[Script] ::TWP::W t=50.00 dyn=1 node=Dynasty base=5 c= g=none w=5'])
    assert "trial-queue-stuck" not in [f.code for f in findings(patient)], findings(patient)
    assert "trials" in codes_ct, findings(court)
    # channel-silent reads the checkout, so it needs a long-enough span to mean anything
    short = Session()
    short.feed(['[Script] ::TWP::W t=1.00 dyn=1 node=Dynasty base=5 c= g=none w=5',
                '[Script] ::TWP::W t=3.00 dyn=1 node=Dynasty base=5 c= g=none w=5'])
    assert "channel-silent" not in [f.code for f in findings(short)], findings(short)
    # and it must FIRE on a long run - with a positive case that proves the capture works.
    # Asserting only the absence let a gutted channels_seen pass on 2026-09-21.
    longrun = Session()
    longrun.feed(['[Script] ::TWP::W t=1.00 dyn=1 node=Dynasty base=5 c= g=none w=5',
                  '[Script] ::TWP::AI:: Someone AI::Feud Current enemy ID = 2',
                  '[Script] ::TWP::W t=40.00 dyn=1 node=Dynasty base=5 c= g=none w=5'])
    text_cs = format_findings(findings(longrun))
    assert "channel-silent" in [f.code for f in findings(longrun)], findings(longrun)
    seen_n = re.search(r'(\d+) of (\d+) emitted channels', text_cs)
    assert seen_n, text_cs
    # W and AI were emitted, so they must not be counted silent; equal counts means the
    # capture is dead and every channel reads as silent
    assert int(seen_n.group(1)) < int(seen_n.group(2)), text_cs

    # stuck-walk: the engine reports the failed walk, we only have to scale it. 20 failures
    # in 5 game hours on one sim is 4.0/h and fires; the same 20 spread over 20 sims does
    # not, which is the healthy 2026-09-06 shape and the reason the old spin check died.
    walker = Session()
    walker.feed(["[Script] ::TWP::W t=10.00 dyn=1 node=Dynasty base=5 c= g=none w=5"]
               + ["[Script] Executing Measures/ms_010_GoToSleep.lua on Uta Barker",
                  "[Subsystem] cl_MoveTask::Process - Uta Barker has not reached Target "
                  "(Errorcode 102)"] * 20
               + ["[Script] ::TWP::W t=15.00 dyn=1 node=Dynasty base=5 c= g=none w=5"])
    codes_sw = [f.code for f in findings(walker)]
    assert "stuck-walk" in codes_sw and "unreachable-target" in codes_sw, findings(walker)
    text_sw = format_findings(findings(walker))
    # the pointer names the same file, so a bare filename test passes even with the
    # attribution gutted; the count is what only attribution can produce
    assert "last running ms_010_GoToSleep.lua x20" in text_sw, text_sw
    spread = Session()
    spread.feed(["[Script] ::TWP::W t=10.00 dyn=1 node=Dynasty base=5 c= g=none w=5"]
                + ["[Subsystem] cl_MoveTask::Process - Sim%d has not reached Target "
                   "(Errorcode 102)" % i for i in range(20)]
                + ["[Script] ::TWP::W t=15.00 dyn=1 node=Dynasty base=5 c= g=none w=5"])
    assert "stuck-walk" not in [f.code for f in findings(spread)], findings(spread)
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
