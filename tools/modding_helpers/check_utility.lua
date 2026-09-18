-- Checks the utility scoring, goal blackboard, telemetry and scored target selection
-- behind the AI BaseTree: Scripts/Library/utility.lua and the aitwp_GetBestEnemy /
-- aitwp_FindTargetBuilding helpers in Scripts/Library/aitwp.lua.
--
--   lua5.1 tools/modding_helpers/check_utility.lua
--
-- No engine needed: every native the code touches is stubbed below, so a change
-- that breaks a bound, a curve, the goal argmax, a target ranking or a telemetry
-- line format (which tools/modding_helpers/ai_telemetry.py parses) fails here.

local Failures = 0

local function check(Name, Condition)
	if Condition then
		return
	end
	Failures = Failures + 1
	io.stderr:write("FAIL: " .. Name .. "\n")
end

local function near(a, b)
	return math.abs(a - b) < 0.0001
end

local function has(Text, Piece)
	return Text ~= nil and string.find(Text, Piece, 1, true) ~= nil
end

-- engine stubs ---------------------------------------------------------------
GL_BUILDING_CLASS_WORKSHOP = 1
GL_BUILDING_CLASS_RESOURCE = 6
GL_BUILDING_CLASS_LIVINGROOM = 2
DIP_FOE = 1
DIP_NEUTRAL = 2
DIP_NAP = 3
DIP_ALLIANCE = 4
STATE_DEAD = 99

local Props = {}
function GetProperty(Alias, Name) return Props[Name] end
function SetProperty(Alias, Name, Value) Props[Name] = Value end
function HasProperty(Alias, Name) return Props[Name] ~= nil end

Now = 1000
function GetGametime() return Now end
function GetID(Alias) return 1 end
function GetSettingNumber(Group, Name, Default) return Default end

local Logged = {}
function LogMessage(Text) Logged[#Logged + 1] = Text end
local function lastLog() return Logged[#Logged] end

local Weights = { ambition = 80, greed = 40, bloodlust = 20 }
function ai_CheckPersonalityWeight(Alias, Trait) return Weights[Trait] end

local World = { money = 8000, members = 3, workshops = 1, wanted = 3, enemies = 0 }
function GetMoney(Alias) return World.money end
function DynastyGetMemberCount(Alias) return World.members end
function DynastyGetBuildingCount(Alias, Class, Type) return World.workshops end
function ai_GetBestNumberOfWorkshops(Alias) return World.wanted end
function aitwp_GetCurrentEnemies(Alias) return World.enemies, World.enemylist or {} end
function aitwp_GetBestEnemy(Alias) return 42 end

dofile("Scripts/Library/utility.lua")
-- the engine reaches library functions as <file>_<Name>; mirror that for the
-- functions utility.lua and aitwp.lua call on it
utility_Clamp01, utility_Norm, utility_Curve, utility_GoalFactor = Clamp01, Norm, Curve, GoalFactor
utility_LogEnabled, utility_Stamp, utility_Tick, utility_TakeTicks, utility_Emit = LogEnabled, Stamp, Tick, TakeTicks, Emit
utility_Why = Why

check("load marker is logged at include time", has(Logged[1], "::TWP::LOADED utility.lua"))
check("environment probe is logged at include time", has(Logged[2], "::TWP::ENV lua=Lua 5.1"))
check("probe reports the table library", has(Logged[2], "table.sort=true"))
Logged = {}

-- Score ------------------------------------------------------------------------
check("base 0 stays 0 whatever the considerations", Score("d", 0, { 1 }) == 0)
check("nil base is 0", Score("d", nil, {}) == 0)
check("no considerations keeps the base", Score("d", 20, {}) == 20)
check("consideration 0 halves the base", near(Score("d", 20, { 0 }), 10))
check("consideration 1 adds half", near(Score("d", 20, { 1 }), 30))
check("consideration 0.5 is neutral", near(Score("d", 20, { 0.5 }), 20))
check("values above 1 clamp", near(Score("d", 20, { 7 }), 30))
check("values below 0 clamp", near(Score("d", 20, { -3 }), 10))
check("two considerations multiply", near(Score("d", 20, { 1, 1 }), 45))
check("quad curve: 0.5 -> 0.25", near(Score("d", 20, { { value = 0.5, curve = "quad" } }), 15))
check("sqrt curve: 0.25 -> 0.5", near(Score("d", 20, { { value = 0.25, curve = "sqrt" } }), 20))
check("invert curve: 0 -> 1", near(Score("d", 20, { { value = 0, curve = "invert" } }), 30))
check("custom lo/hi band", near(Score("d", 20, { { value = 1, lo = 1, hi = 2 } }), 40))
check("nothing is logged while Log is off", #Logged == 0)

-- Norm / Trait / Priority / Money ------------------------------------------------
check("Norm midpoint", near(Norm(150, 100, 200), 0.5))
check("Norm clamps low", Norm(50, 100, 200) == 0)
check("Norm clamps high", Norm(300, 100, 200) == 1)
check("Norm with an empty range is a step", Norm(5, 5, 5) == 1 and Norm(4, 5, 5) == 0)
check("Trait reads the personality column", near(Trait("d", "ambition"), 0.8))
check("unknown trait is neutral", near(Trait("d", "nosuch"), 0.5))
Props.AITWP_Political = 35
check("Priority reads AITWP_<Name>", near(Priority("d", "Political"), 0.35))
check("missing priority is neutral", near(Priority("d", "Intrigue"), 0.5))
Props.AITWP_Intrigue = 0
check("a computed 0 priority is 0", Priority("d", "Intrigue") == 0)
check("Money saturates at the comfortable level", near(Money("d", 4000), 1) and near(Money("d", 16000), 0.5))

-- GoalFactor -----------------------------------------------------------------------
Props = { AITWP_Political = 35 }
check("no goal set: factor 1", GoalFactor("d", "Politics") == 1)
Props.AI_Goal, Props.AI_GoalUntil = "Politics", Now + 10
check("aligned goal: x3", GoalFactor("d", "Politics") == 3)
check("other goal: x0.3", near(GoalFactor("d", "Economy"), 0.3))
check("Score applies the goal factor itself when a goal is named", near(Score("d", 20, { 0.5 }, nil, "Politics"), 60))
check("Score with another goal named", near(Score("d", 20, {}, nil, "Economy"), 6))
Props.AI_GoalUntil = Now
check("expired goal: factor 1", GoalFactor("d", "Politics") == 1)

-- telemetry ----------------------------------------------------------------------------
check("Log flag is read once from [AI] Log and defaults to off", LogEnabled() == false and UTILITY_LogEnabled == false)
Tick("d") Tick("d") Tick("d")
check("ticks accumulate per dynasty", TakeTicks("d") == 3)
check("taking the ticks resets them", TakeTicks("d") == 0)
check("Trace hands the weight back unchanged", Trace("d", "BuildHome", 5) == 5)
check("Trace is silent while Log is off", #Logged == 0)
Score("d", 20, { 0.5 }, "Tagged", "Politics")
check("Score is silent while Log is off even with a tag", #Logged == 0)

UTILITY_LogEnabled = true
Props.AI_GoalUntil = Now + 10
Score("d", 20, { 0.5, { value = 0.25, curve = "quad" } }, "ApplyForOffice", "Politics")
check("W line carries node, base, inputs, goal state and weight",
	has(lastLog(), "::TWP::W t=1000.00 dyn=1 node=ApplyForOffice base=20 c=0.50:linear;0.25:quad g=aligned w="))
check("W line weight is the returned weight", has(lastLog(), "w=" .. string.format("%.2f", 20 * 1.0 * (0.5 + 0.0625) * 3)))
check("a custom band is logged with the input", near(Score("d", 10, { { value = 0.5, curve = "linear", lo = 1, hi = 3 } }, "Band"), 20)
	and has(lastLog(), "c=0.50:linear:1:3 "))
Trace("d", "BuildHome", 5)
check("Trace logs a W line with no inputs", has(lastLog(), "node=BuildHome base=5 c= g=none w=5"))
Picked("d", "Dynasty")
check("PICK line", has(lastLog(), "::TWP::PICK t=1000.00 dyn=1 node=Dynasty"))
UTILITY_LogEnabled = false

-- the single switch --------------------------------------------------------------------
UTILITY_LOG = false
UTILITY_LogEnabled = true
Logged = {}
Score("d", 20, {}, "Switched")
Trace("d", "Switched", 5)
check("UTILITY_LOG = false silences every line even with the config flag on", #Logged == 0)
UTILITY_LOG = nil
UTILITY_LogEnabled = false
Trace("d", "Quiet", 5)
check("switch unset: the config flag decides, off logs nothing", #Logged == 0)
UTILITY_LOG = true
Trace("d", "Forced", 5)
check("UTILITY_LOG = true forces lines on", has(lastLog(), "node=Forced"))
UTILITY_LOG = nil
UTILITY_LogEnabled = true

-- ChooseGoal -----------------------------------------------------------------------
Props = { AITWP_Political = 10, AITWP_Agressive = 80 }
World = { money = 8000, members = 3, workshops = 3, wanted = 3, enemies = 2 }
Logged = {}
check("enemies plus aggression choose Conflict", ChooseGoal("d") == "Conflict")
check("Conflict records the best enemy as target", Props.AI_GoalTarget == 42)
check("goal runs for UTILITY_GOAL_HOURS", Props.AI_GoalUntil == Now + UTILITY_GOAL_HOURS)
check("GOAL line is logged when the switch is on", has(lastLog(), "::TWP::GOAL t=1000.00 dyn=1 P=10 A=80 ambition=80"))
check("GOAL line carries scores and the pick", has(lastLog(), "politics=50 economy=20 family=0 conflict=110 pick=Conflict target=42"))

World.enemies = 0
Logged = {}
check("a running goal is kept until it expires", ChooseGoal("d") == "Conflict")
check("keeping a goal logs nothing", #Logged == 0)
Now = Now + UTILITY_GOAL_HOURS
World.workshops = 0
check("after expiry a new goal is chosen: Economy at 0 of 3 workshops", ChooseGoal("d") == "Economy")
check("non-Conflict goals carry no target", Props.AI_GoalTarget == 0)

Now = Now + UTILITY_GOAL_HOURS
Props.AITWP_Political = 90
World.workshops = 3
check("political ambition beats a full economy", ChooseGoal("d") == "Politics")

Now = Now + UTILITY_GOAL_HOURS
Props.AITWP_Political = 0
World.members = 1
check("a party of one wants Family", ChooseGoal("d") == "Family")

Now = Now + UTILITY_GOAL_HOURS
Weights.ambition, Weights.greed = 0, 0
World = { money = 0, members = 3, workshops = 3, wanted = 3, enemies = 0 }
check("all scores 0: Economy is the fixed tie-break", ChooseGoal("d") == "Economy")

Now = Now + UTILITY_GOAL_HOURS
Props.AI_BloodEnemyOf = 77
Logged = {}
check("a blood enemy always chooses Conflict against its player", ChooseGoal("d") == "Conflict" and Props.AI_GoalTarget == 77)
check("the blood goal is logged as such", has(lastLog(), "blood=1 pick=Conflict target=77"))
Props.AI_BloodEnemyOf = nil

-- aitwp_GetBestEnemy / aitwp_FindTargetBuilding -------------------------------------
local Aliases = {}
function GetAliasByID(ID, Alias) Aliases[Alias] = ID; return true end
function AliasExists(Alias) return Aliases[Alias] ~= nil end
function RemoveAlias(Alias) Aliases[Alias] = nil end
function CopyAlias(From, To) Aliases[To] = Aliases[From] end
local Dyn = {
	[5] = { dead = true },
	[7] = { favor = 20, dip = DIP_NEUTRAL, shadow = false },
	[9] = { favor = 70, dip = DIP_FOE, shadow = true },
}
function DynastyIsDead(Alias) return Dyn[Aliases[Alias]].dead == true end
function DynastyIsShadow(Alias) return Dyn[Aliases[Alias]].shadow == true end
function GetFavorToDynasty(From, Alias) return Dyn[Aliases[Alias]].favor end
function DynastyGetDiplomacyState(A, Alias) return Dyn[Aliases[Alias]].dip end
function GetName(Alias) return "x" end

dofile("Scripts/Library/aitwp.lua")
aitwp_GetCurrentEnemies = function() return 3, { 5, 7, 9 } end

Props = {}
check("dead enemies are skipped, the most hated living one wins", GetBestEnemy("d") == 7)
Props.AI_GoalTarget = 9
check("the goal target is kept even when a colder enemy exists", GetBestEnemy("d") == 9)
Props.AI_BloodEnemyOf = 7
check("the blood target outranks the goal target", GetBestEnemy("d") == 7)
Props.AI_BloodEnemyOf = nil
UTILITY_LogEnabled = true
Logged = {}
GetBestEnemy("d")
check("ENEMY line lists living candidates as id:favor:foe:shadow and the pick",
	has(lastLog(), "::TWP::ENEMY t=") and has(lastLog(), " dyn=1 goaltarget=9 cand=7:20:0:0;9:70:1:1; pick=9"))
UTILITY_LogEnabled = false
aitwp_GetCurrentEnemies = function() return 1, { 5 } end
check("only dead enemies: -1", GetBestEnemy("d") == -1)

local Buildings = {
	[0] = { class = GL_BUILDING_CLASS_RESOURCE, level = 3 },
	[1] = { class = GL_BUILDING_CLASS_WORKSHOP, level = 1 },
	[2] = { class = GL_BUILDING_CLASS_LIVINGROOM, level = 2 },
	[3] = { class = GL_BUILDING_CLASS_WORKSHOP, level = 2 },
}
function DynastyGetBuildingCount2(Alias) return 4 end
function DynastyGetBuilding2(Alias, Index, Out)
	if Buildings[Index] == nil then return false end
	Aliases[Out] = Index
	return true
end
function BuildingGetClass(Alias) return Buildings[Aliases[Alias]].class end
function BuildingGetLevel(Alias) return Buildings[Aliases[Alias]].level end

UTILITY_LogEnabled = true
Logged = {}
check("strongest of any class: the level-2 workshop", FindTargetBuilding("d", -1, "strongest", "Out") and Aliases.Out == 3)
check("BLD line lists every building as idx:class:level and the pick",
	has(lastLog(), " owner=1 mode=strongest class=-1 cand=0:6:3;1:1:1;2:2:2;3:1:2; pick=3"))
UTILITY_LogEnabled = false
Buildings[3] = nil
check("resources are never a target", FindTargetBuilding("d", -1, "strongest", "Out") and Aliases.Out == 2)
check("class filter: the only workshop", FindTargetBuilding("d", GL_BUILDING_CLASS_WORKSHOP, "strongest", "Out") and Aliases.Out == 1)
Buildings[3] = { class = GL_BUILDING_CLASS_WORKSHOP, level = 4 }
check("weakest workshop for a forced sale", FindTargetBuilding("d", GL_BUILDING_CLASS_WORKSHOP, "weakest", "Out") and Aliases.Out == 1)
-- a sim alias that does not enumerate falls back to its dynasty
function DynastyGetBuildingCount2(Alias) if Alias == "TWP_Owner" then return 4 end return 0 end
function GetDynasty(Alias, Out) Aliases[Out] = "owner"; return true end
check("sim alias falls back to its dynasty", FindTargetBuilding("sim", -1, "strongest", "Out") and Aliases.Out == 3)
check("the fallback alias is cleaned up", Aliases.TWP_Owner == nil)
function GetDynasty(Alias, Out) return false end
check("no buildings: false", FindTargetBuilding("d", -1, "strongest", "Out") == false)

-- aitwp duelling: the model of Cutscenes/Duel.lua ---------------------------------------
aitwp_DuelDamage, aitwp_DuelHitsNeeded = DuelDamage, DuelHitsNeeded
aitwp_DuelHitChance, aitwp_DuelOdds = DuelHitChance, DuelOdds
FIGHTING, DEXTERITY = 1, 2
local Sheet = { s = { 3, 3, hp = 400, rel = 1.0 }, v = { 3, 3, hp = 400, rel = 1.0 } }
function GetSkillValue(Alias, Skill) return (Sheet[Alias] or {})[Skill] or 0 end
function GetHPRelative(Alias) return (Sheet[Alias] or {}).rel or 1 end
function GetHP(Alias) return (Sheet[Alias] or {}).hp or 0 end

-- damage is Duel.lua:337 with the roll at its mean: 50 + 12*F + (1+Rand(11))*F
check("no martial arts still does the flat 50", near(DuelDamage(0), 50))
check("martial arts 5 does 140", near(DuelDamage(5), 140))
check("martial arts 10 does 230", near(DuelDamage(10), 230))

-- the number this whole change exists for: three rounds is the ceiling
check("457 HP takes four hits at martial arts 5, so it cannot be done", DuelHitsNeeded(5, 457) == 4)
check("martial arts 6 brings it to three", DuelHitsNeeded(6, 457) == 3)
check("martial arts 10 brings it to two", DuelHitsNeeded(10, 457) == 2)
check("a corpse still counts as one hit, never zero", DuelHitsNeeded(5, 0) == 1)

-- the fitness floor is now the opponent, not a flat 5 on either talent
Sheet.v.hp = 457
Sheet.s[1], Sheet.s[2] = 0, 10
check("a pure dodger is not fit to duel: it can never land the four hits",
	IsFitToDuel("s", "v") == false)
Sheet.s[1], Sheet.s[2] = 6, 0
check("martial arts 6 against 457 HP is fit, dexterity or no dexterity",
	IsFitToDuel("s", "v") == true)
Sheet.s.rel = 0.79
check("under 80% health is still refused whatever the talents", IsFitToDuel("s", "v") == false)
Sheet.s.rel = 1.0
Sheet.v.hp = 400

-- the hit test is a bare >= (Duel.lua:457), so the chance is a step, not a curve. Both
-- sides pick their action now (duel_BestAction), so there is one ladder, not two.
check("a clear margin always lands", near(DuelHitChance(0, 10), 1))
check("one point short, the quick shot still lands", near(DuelHitChance(-1, 10), 1))
check("two short is still the quick shot's reach", near(DuelHitChance(-2, 10), 1))
check("three short, only the insult, and only if its check passes", near(DuelHitChance(-3, 10), 0.5))
check("four short, nothing reaches this turn", near(DuelHitChance(-4, 10), 0))
check("the misfire is max(0, 10-F) percent", near(DuelHitChance(0, 5), 0.95))
check("martial arts 10 never misfires", near(DuelHitChance(0, 10), 1))
check("no martial arts misfires one turn in ten", near(DuelHitChance(0, 0), 0.9))

-- the odds themselves
Sheet.s = { 10, 10, hp = 400, rel = 1.0 }
Sheet.v = { 10, 10, hp = 400, rel = 1.0 }
local Win, Lose, Draw = DuelOdds("s", "v")
check("win, lose and draw are a distribution", near(Win + Lose + Draw, 1))
check("evenly matched, the one who shoots first wins more - and that is never us", Lose > Win)
-- a duellist who cannot kill inside three rounds has no win, only a loss or a draw
Sheet.s = { 5, 10, hp = 400, rel = 1.0 }
Sheet.v = { 10, 2, hp = 457, rel = 1.0 }
Win, Lose, Draw = DuelOdds("s", "v")
check("four hits needed in three rounds is a win chance of exactly zero", near(Win, 0))
check("and it is still a real distribution", near(Win + Lose + Draw, 1))
-- and the other way round: outgun them and the odds say so
Sheet.s = { 12, 12, hp = 600, rel = 1.0 }
Sheet.v = { 1, 1, hp = 200, rel = 1.0 }
Win, Lose, Draw = DuelOdds("s", "v")
check("outgunned on every axis, the odds favour us", Win > Lose)
-- and no draw: competent duellists land every shot they can reach, so an advantage this
-- wide is decided on the first exchange. The draws live where neither side can carry
-- the damage inside three rounds, which is the common case at 400+ HP.
check("an overwhelming advantage is a certain win, not a draw", near(Win, 1))
Sheet.s = { 3, 3, hp = 400, rel = 1.0 }
Sheet.v = { 3, 3, hp = 400, rel = 1.0 }

-- aitwp_HasAtLeast / MissingEquipment: equipment ladders --------------------------------
aitwp_HasAtLeast = HasAtLeast
INVENTORY_EQUIPMENT, INVENTORY_STD = 1, 2
local Carried = {}
function GetItemCount(Alias, Item, Inventory) return Carried[Item] or 0 end
check("nothing carried: lacks the dagger", HasAtLeast("s", "weapon", "Dagger") == false)
Carried.Longsword = 1
check("a longsword counts as at least a dagger", HasAtLeast("s", "weapon", "Dagger") == true)
check("a longsword is not at least an axe", HasAtLeast("s", "weapon", "Axe") == false)
Carried.Chainmail = 1
check("missing piece of the top tier is the platemail", MissingEquipment("s", TWP_EQUIPMENT[3]) == "Platemail")
Carried.Platemail, Carried.FullHelmet = 1, 1
check("fully equipped: nothing missing", MissingEquipment("s", TWP_EQUIPMENT[3]) == nil)

-- aitwp_Attitude / PlayerRung / Rung / Allowed / AttitudeFactor: the ladder ------------
aitwp_ResolveDynasty, aitwp_Attitude, aitwp_IsHostile = ResolveDynasty, Attitude, IsHostile
aitwp_PlayerRung, aitwp_Rung, aitwp_Allowed = PlayerRung, Rung, Allowed
function IsType(Alias, Type) return false end
function GetID(Alias) return Aliases[Alias] or 1 end
function DynastyIsPlayer(Alias) return Dyn[Aliases[Alias]].player == true end
local Round = 8
function GetRound() return Round end
local Titles = { 5, 2 }
function DynastyGetMemberCount(Alias) return #Titles end
function DynastyGetMember(Alias, Index, Out) Aliases[Out] = Index; return true end
function GetNobilityTitle(Alias) return Titles[Aliases[Alias] + 1] end
Dyn[11] = { favor = 50, dip = DIP_NEUTRAL, player = true }
Aliases.player, Aliases.ai, Aliases.d = 11, 7, 7
Dyn[8] = { shadow = true }
Props = {}
aitwp_GetCurrentEnemies = function() return 0, {} end

check("favour 50, no feud, not listed: neutral", Attitude("d", "player") == "neutral")
Dyn[11].favor = 75
check("favour 70 and above: friend for now", Attitude("d", "player") == "friend")
aitwp_GetCurrentEnemies = function() return 1, { 11 } end
check("listed as an enemy beats the favour", Attitude("d", "player") == "enemy")
aitwp_GetCurrentEnemies = function() return 0, {} end
Dyn[11].favor = 20
check("favour under 30: enemy", Attitude("d", "player") == "enemy")
Dyn[11].dip = DIP_FOE
check("a declared feud: feud", Attitude("d", "player") == "feud")
Props.AI_BloodEnemyOf = 11
check("the assigned rival: blood, whatever the diplomacy", Attitude("d", "player") == "blood")
check("an alias that is no dynasty: neutral", Attitude("d", "nobody") == "neutral")
check("the resolve alias is cleaned up", Aliases.TWP_AttP == nil)
check("hostile attitudes", IsHostile("blood") and IsHostile("feud") and IsHostile("enemy")
	and not IsHostile("friend") and not IsHostile("neutral"))

check("the highest member title counts: citizen (5) is rung 2", PlayerRung("player") == 2)
Titles[2] = 8
check("nobleman (8) is rung 4", PlayerRung("player") == 4)
Titles[2] = 13
check("prince (13) is rung 8", PlayerRung("player") == 8)
Titles[2] = 16
check("above prince stays rung 8", PlayerRung("player") == 8)
Titles[1], Titles[2] = 1, 1
check("serfs only: rung 0", PlayerRung("player") == 0)
Titles[2] = 10
check("allodial baron (10) is rung 6", PlayerRung("player") == 6)
Round = 3
check("the round caps the rung", Rung("d", "player") == 3)
Round = 8
check("round 8 opens the title's rung", Rung("d", "player") == 6)
Aliases.d = 8
check("a shadow never climbs above rung 4", Rung("d", "player") == 4)
Aliases.d = 7

check("unknown tool: allowed", Allowed("d", "player", "no_such_tool") == true)
check("AI victims: the ladder does not apply", Allowed("d", "ai", "black_widow") == true)
Props.AI_BloodEnemyOf = nil
Dyn[11] = { favor = 50, dip = DIP_NEUTRAL, player = true }
check("neutral player: nothing", Allowed("d", "player", "pickpocket") == false)
Dyn[11].favor = 75
check("friend for now: nothing", Allowed("d", "player", "pickpocket") == false)
Dyn[11].favor = 20
check("enemy: economic tools within the rung", Allowed("d", "player", "burglary") == true)
check("enemy: no reputation tools", Allowed("d", "player", "pamphlet") == false)
check("enemy: no lethal tool even at rung 6", Allowed("d", "player", "black_widow") == false)
Dyn[11].dip = DIP_FOE
check("feud: lethal tools open at rung 5", Allowed("d", "player", "black_widow") == true)
check("feud: still no reputation tools", Allowed("d", "player", "taunt_letter") == false)
check("feud: no diplomatic recruitment", Allowed("d", "player", "fund_allies") == false)
check("rung 6: forged evidence II is open", Allowed("d", "player", "forge2") == true)
check("rung 6: no count's tools", Allowed("d", "player", "disappropriate") == false)
Titles[2] = 9
check("baron (rung 5): forged evidence I only", Allowed("d", "player", "forge1") == true and Allowed("d", "player", "forge2") == false)
Round = 2
check("round 2: even a baron only faces rung-2 tools", Allowed("d", "player", "charge") == false and Allowed("d", "player", "burglary") == true)
Round = 8
Props.AI_BloodEnemyOf = 11
check("blood rival: reputation and recruitment too", Allowed("d", "player", "taunt_letter") and Allowed("d", "player", "fund_allies"))
Aliases.d = 8
check("a shadow rival never uses lethal tools", Allowed("d", "player", "black_widow") == false)
check("a shadow rival keeps its rung-4 tools", Allowed("d", "player", "kidnap") == true)
check("the victim alias is cleaned up", Aliases.TWP_AlV == nil)

check("shadow blood rival: half the feud pipeline", AttitudeFactor("d", "player") == 0.5)
Aliases.d = 7
check("coloured blood rival: factor 1", AttitudeFactor("d", "player") == 1)
Props.AI_BloodEnemyOf = nil
Dyn[11].dip = DIP_NEUTRAL
check("plain enemy: softened to 0.6", near(AttitudeFactor("d", "player"), 0.6))
Dyn[11].favor = 50
check("neutral player: the feud subtree is off", AttitudeFactor("d", "player") == 0)
check("AI victim: factor 1", AttitudeFactor("d", "ai") == 1)

-- aitwp_ShoppingList / DrawFromStock / IdleThug: the cart supply chain ------------------
aitwp_ProcureTools, aitwp_Severity, aitwp_StockCount, aitwp_StockCap = ProcureTools, Severity, StockCount, StockCap
aitwp_Residence = Residence
GL_BUILDING_TYPE_RESIDENCE = 9
-- until the building table below exists, every home the stub hands back is a residence
function BuildingGetType(Alias) return GL_BUILDING_TYPE_RESIDENCE end
aitwp_InStore, aitwp_EquipmentTier, aitwp_NoteMissing, aitwp_MissingEquipment = InStore, EquipmentTier, NoteMissing, MissingEquipment
aitwp_IsTool, aitwp_CanHandOver, aitwp_CarriedTools, aitwp_HandOversToday, aitwp_HandOverCap = IsTool, CanHandOver, CarriedTools, HandOversToday, HandOverCap
STATE_IDLE = 7
STATE_DYING = 98
STATE_UNCONSCIOUS = 97
local IdleState, CurMeasure = false, "AttendMass"
local Downed = {}
function GetState(Alias, State)
	if State == STATE_IDLE then
		return IdleState
	end
	return Downed[Alias] or false
end
function GetCurrentMeasureName(Alias) return CurMeasure end
function SimGetAge(Alias) return 30 end
function DynastyGetWorkerCount(Alias, Profession) return 0 end
function DynastyGetWorker(Alias, Profession, Index, Out) return false end
function GetHomeBuilding(Alias, Out) Aliases[Out] = "home"; return true end
function ItemGetBasePrice(Item) return 1000 end
function ItemGetID(Item) return Item end
function ItemGetName(Item) return Item end
-- the sim "s" has its own inventory; every other alias reads the shared store Carried
local Stock, Added = { s = {} }, {}
function GetItemCount(Alias, Item, Inventory) return (Stock[Alias] or Carried)[Item] or 0 end
function RemoveItems(Alias, Item, Count, Inv) local T = Stock[Alias] or Carried; T[Item] = (T[Item] or 0) - Count; return Count end
function AddItems(Alias, Item, Count, Inv) Added[Item] = (Added[Item] or 0) + Count; return Count end
function GetDynasty(Alias, Out) Aliases[Out] = 7; return true end

-- Inverted on 2026-09-19: the rule is a blacklist of engine states now, not a whitelist
-- of measure names. A thug at mass IS free - interrupting it costs the house nothing and
-- the whitelist is why a party of k hands almost never existed in one tick.
check("a thug at mass is free: a measure name no longer decides", IsFreeForOrders("k") == true)
CurMeasure = "PatrolTheTown"
check("a thug on patrol is free for an order", IsFreeForOrders("k") == true)
CurMeasure = "PickpocketPeople"
check("a thief on its rounds is free for an order", IsFreeForOrders("k") == true)
-- but a fighter already on a raid is not offered to the next one. STATE_FIGHTING covers
-- the swing, not the walk to it, and an ambush lies up for hours before anything happens -
-- so on states alone the second raid to evaluate would dismantle the first.
CurMeasure = "SquadWarMember"
check("a thug already on a raid is not free", IsFreeForOrders("k") == false)
CurMeasure = "SquadHijackMember"
check("nor one on a hijack", IsFreeForOrders("k") == false)
CurMeasure = "bf_AmbushMember"
check("nor one lying up in an ambush", IsFreeForOrders("k") == false)
CurMeasure = "AttackEnemy"
check("nor one already swinging", IsFreeForOrders("k") == false)
CurMeasure = "SupplyWorkshop"
check("a chore that is not a commitment stays free", IsFreeForOrders("k") == true)
Downed.k = true
check("a thug lying unconscious takes no orders", IsFreeForOrders("k") == false)
Downed.k = nil
IdleState = true
check("an idle thug is free", IsFreeForOrders("k") == true)
IdleState = false
CurMeasure = "AttendMass"

Carried = {}
Props.AI_BloodEnemyOf = 11
Dyn[11] = { favor = 20, dip = DIP_FOE, player = true }
Titles[1], Titles[2] = 5, 9
World.money = 200000
local Tools = {}
local N = ProcureTools("d", "player", Tools)
check("rung 5 blood rival: 18 tools with an item", N == 18)
check("most severe first: the lethal black widow poison", Tools[1].item == "BlackWidowPoison" and Severity(Tools[1]) == 5)
check("least severe last: a reputation tool", Severity(Tools[N]) == 1)
check("two adults can use two of a tool a day", StockCap("d", Tools[1]) == 2)
local Needs = {}
N = ShoppingList("d", "player", Needs)
check("200k, 7% budget, 1000 each: 14 tools, one of each", N == 14 and Needs[1][2] == 1)
check("the shopping list starts with the most severe tool", Needs[1][1] == "BlackWidowPoison")
Carried.BlackWidowPoison = 1
N = ShoppingList("d", "player", Needs)
check("a tool at its cap is not bought again; the next severe one leads", N == 14 and Needs[1][1] == "WeaponPoison")
check("nothing on the list is the capped tool", (function() for i = 1, N do if Needs[i][1] == "BlackWidowPoison" then return false end end return true end)())
World.money = 1000
check("a poor house buys nothing", ShoppingList("d", "player", {}) == 0)
World.money = 200000

Carried.StinkBomb = 1
check("hand-over cap: members and thugs plus two", HandOverCap("d") == 4)
check("the hand-over takes from the store and counts", DrawFromStock("s", "StinkBomb", 1) == true and Added.StinkBomb == 1 and Carried.StinkBomb == 0 and HandOversToday("d") == 1)
Stock.s.StinkBomb = 1
Carried.Voodo = 1
check("a unit holding a tool gets no second one", DrawFromStock("s", "Voodo", 1) == false)
Stock.s.StinkBomb = nil
Props.AI_HO_Count = 4
check("the day's cap blocks the hand-over", DrawFromStock("s", "Voodo", 1) == false)
Props.AI_HO_Round = -5
check("a new day resets the count", HandOversToday("d") == 0 and DrawFromStock("s", "Voodo", 1) == true)
check("nothing in store: no hand-over", DrawFromStock("s", "Pendel", 1) == false)

-- aitwp_OwnBuilding / MostDamagedBuilding / FindTargetBuilding in one town -----------------
aitwp_OwnBuilding, aitwp_MostDamagedBuilding, aitwp_FindTargetBuilding = OwnBuilding, MostDamagedBuilding, FindTargetBuilding
Buildings = {
	[0] = { class = GL_BUILDING_CLASS_RESOURCE, level = 3, type = 5, hp = 0.9, town = 1 },
	[1] = { class = GL_BUILDING_CLASS_WORKSHOP, level = 1, type = 7, hp = 0.4, town = 1 },
	[2] = { class = GL_BUILDING_CLASS_LIVINGROOM, level = 2, type = 9, hp = 1.0, town = 2 },
	[3] = { class = GL_BUILDING_CLASS_WORKSHOP, level = 4, type = 7, hp = 0.7, town = 2 },
}
function DynastyGetBuildingCount2(Alias) return 4 end
function DynastyGetBuilding2(Alias, Index, Out) if Buildings[Index] == nil then return false end Aliases[Out] = Index; return true end
function BuildingGetClass(Alias) return Buildings[Aliases[Alias]].class end
function BuildingGetLevel(Alias) return Buildings[Aliases[Alias]].level end
function BuildingGetType(Alias) return Buildings[Aliases[Alias]].type end
function GetHPRelative(Alias) return Buildings[Aliases[Alias]].hp end
function GetSettlementID(Alias) if Alias == "town" then return 1 end return Buildings[Aliases[Alias]].town end
Aliases.d = 7
check("own building: the highest-level workshop", OwnBuilding("d", GL_BUILDING_CLASS_WORKSHOP, -1, "Out") and Aliases.Out == 3)
check("own building by type: the level-4 one of two", OwnBuilding("d", -1, 7, "Out") and Aliases.Out == 3)
check("own building: none of that type", OwnBuilding("d", -1, 99, "Out") == false)
check("the most damaged building and its health", near(MostDamagedBuilding("d", "Out"), 0.4) and Aliases.Out == 1)
check("strongest workshop in one town only", FindTargetBuilding("d", GL_BUILDING_CLASS_WORKSHOP, "strongest", "Out", "town") and Aliases.Out == 1)
check("strongest workshop anywhere", FindTargetBuilding("d", GL_BUILDING_CLASS_WORKSHOP, "strongest", "Out") and Aliases.Out == 3)

-- aitwp_HasNightTrade: which houses are allowed to be awake at 2am ------------------------
-- The engine exposes no opening hours, so this list is the decision, not a reading.
aitwp_NightTrades, aitwp_HasNightTrade = NightTrades, HasNightTrade
GL_BUILDING_TYPE_CRYPT, GL_BUILDING_TYPE_THIEF, GL_BUILDING_TYPE_DIVEHOUSE = 40, 41, 42
GL_BUILDING_TYPE_TAVERN, GL_BUILDING_TYPE_ROBBER = 43, 44
check("night trade: a house of workshops and a resource sleeps", HasNightTrade("d") == false)
Buildings[4] = { class = GL_BUILDING_CLASS_WORKSHOP, level = 1, type = GL_BUILDING_TYPE_THIEF, hp = 1.0, town = 1 }
function DynastyGetBuildingCount2(Alias) return 5 end
check("night trade: a thieves' guild keeps the house up", HasNightTrade("d"))
Buildings[4].type = GL_BUILDING_TYPE_CRYPT
check("night trade: so does a crypt", HasNightTrade("d"))
Buildings[4].type = GL_BUILDING_TYPE_TAVERN
check("night trade: and a tavern", HasNightTrade("d"))
Buildings[4].type = 7
check("night trade: another workshop does not", HasNightTrade("d") == false)
Buildings[4] = nil
function DynastyGetBuildingCount2(Alias) return 4 end

-- aitwp_Residence: the store lookup every supply node hangs off ---------------------------
Buildings.home = { class = GL_BUILDING_CLASS_LIVINGROOM, level = 1, type = GL_BUILDING_TYPE_RESIDENCE, hp = 1.0, town = 1 }
local HomeLookupAnswers = true
function GetHomeBuilding(Alias, Out)
	if not HomeLookupAnswers then
		return false
	end
	Aliases[Out] = "home"
	return true
end
check("residence: the engine lookup when it answers", Residence("d", "Out") and Aliases.Out == "home")
HomeLookupAnswers = false
check("residence: the living room when a dynasty alias gets no answer", Residence("d", "Out") and Aliases.Out == 2)
HomeLookupAnswers = true

-- aitwp_ClaimOrder: one order per sim per measure per tick --------------------------------
-- The engine cancels a running measure when the same one is started again at equal
-- priority, so every one of these is a fight or a sweep thrown away and restarted.
aitwp_ClaimOrder, aitwp_LogOrder = ClaimOrder, LogOrder
CurMeasure = "Idle"
check("claim order: the first ask in a tick takes it", ClaimOrder("s", "Attack") == true)
-- the regression that made the first version of this guard a silent no-op for a whole
-- session: a property does not hand a float back unchanged, so the stamp must be integral
check("claim order: the stamp is whole hundredths, never the raw gametime",
	Props["AI_Ordered_Attack"] == math.floor(GetGametime() * 100))
check("claim order: the second ask in the same tick does not", ClaimOrder("s", "Attack") == false)
check("claim order: a different measure is a separate claim", ClaimOrder("s", "Razzia") == true)
Now = Now + 1
check("claim order: a later tick may order again", ClaimOrder("s", "Attack") == true)
Now = Now + 1
CurMeasure = "Attack"
check("claim order: never while that measure is the one already running",
	ClaimOrder("s", "Attack") == false)
CurMeasure = "PatrolTheTown"

-- the attack rules: HitChance / WinChance / NeedHands / MayAttackHere --------------------
aitwp_HitChance, aitwp_FightStats, aitwp_AddFighter = HitChance, FightStats, AddFighter
aitwp_SidePower, aitwp_WinChance, aitwp_DefenceOf = SidePower, WinChance, DefenceOf
aitwp_ClearFighters, aitwp_NeedHands = ClearFighters, NeedHands
aitwp_IsFreeForOrders, aitwp_TownRadius = IsFreeForOrders, TownRadius
aitwp_OnRaidOrder = OnRaidOrder
aitwp_IsOutsideTown, aitwp_IsWanted, aitwp_CommandsGuards = IsOutsideTown, IsWanted, CommandsGuards
GL_PROFESSION_MYRMIDON, GL_PROFESSION_ROBBER, GL_PROFESSION_THIEF, GL_PROFESSION_MERCENARY = 1, 2, 3, 4
PENALTY_UNKNOWN = 0

-- one sheet per alias, so a side can be built out of unlike fighters
local Sheets = {}
local function sheet(Name, Damage, Armor, Dex, Hp, Fight)
	Sheets[Name] = { damage = Damage, armor = Armor, dex = Dex, hp = Hp, fighting = Fight }
	Aliases[Name] = Name
	return Name
end
function ai_GetPower(Alias) local S = Sheets[Alias] or {} return S.damage or 0, S.armor or 0 end
function GetHP(Alias) local S = Sheets[Alias] or {} return S.hp or 0 end
function GetSkillValue(Alias, Skill)
	local S = Sheets[Alias] or {}
	if Skill == FIGHTING then return S.fighting or 0 end
	if Skill == DEXTERITY then return S.dex or 0 end
	return 0
end

check("an even swing lands half the time", near(HitChance(3, 3), 0.5))
check("ten points of fighting over dexterity always lands", HitChance(13, 3) == 1)
check("ten points under never lands", HitChance(3, 13) == 0)

sheet("a1", 20, 0, 3, 100, 3)
sheet("a2", 20, 0, 3, 100, 3)
sheet("d1", 20, 0, 3, 100, 3)
local One, Two, Solo = {}, {}, {}
AddFighter(One, "a1")
AddFighter(Two, "a1")
AddFighter(Two, "a2")
AddFighter(Solo, "d1")
check("an even fight is even", near(WinChance(One, Solo), 0.5))
check("two of a kind beat one four to one", near(WinChance(Two, Solo), 0.8))
check("two of a kind clear the three-in-four bar", WinChance(Two, Solo) >= TWP_ATTACK_WIN_CHANCE)
check("one of a kind does not", WinChance(One, Solo) < TWP_ATTACK_WIN_CHANCE)

-- aitwp_EconomyReady: does any child of ToMEconomy have anything to do? ------------------
-- 89% of that subtree's entries scored no child at all until this gate went in.
aitwp_EconomyReady = EconomyReady
local Timers, IdleMembers = {}, true
function ReadyToRepeat(Alias, Name) return Timers[Name] ~= false end
function dyn_IsIdleMember(Alias) return IdleMembers end
local OwnsWorkshop = true
function dyn_GetRandomWorkshopForSim(SimAlias, Out) return OwnsWorkshop end
function DynastyGetMember(Alias, Index, Out) Aliases[Out] = Index return true end
function DynastyGetMemberCount(Alias) return 3 end

Timers.AI_CheckWorkshop = true
check("economy ready: a member off the check timer is enough", EconomyReady("d"))
Timers.AI_CheckWorkshop = false
Timers.BasicAI_NewWorkshop, Timers.AI_BuyWorkshop, Timers.BasicAI_SellShop = false, false, false
check("economy ready: every child on cooldown means nothing to do", EconomyReady("d") == false)
Timers.AI_BuyWorkshop = true
check("economy ready: one free dynasty timer is enough", EconomyReady("d"))
Timers.AI_BuyWorkshop = false
Timers.BasicAI_SellShop = true
check("economy ready: selling a shop counts too", EconomyReady("d"))
Timers.BasicAI_SellShop = false
IdleMembers = false
Timers.AI_CheckWorkshop = true
check("economy ready: a timer nobody idle can use is not enough", EconomyReady("d") == false)
IdleMembers = true

-- The shadow case, which is 89% of this subtree's traffic and the reason the gate did
-- nothing for a whole session. BuildWorkshop, BuyWorkshop and SellWorkshop all refuse a
-- shadow dynasty, so they never reach an Execute() that would set their timer, so the
-- timer reads ready for ever and the gate waved every shadow house through.
local RealIsShadow = DynastyIsShadow
local Shadow = false
function DynastyIsShadow(Alias) return Shadow end
Timers = {}
IdleMembers = false
Shadow = true
check("economy ready: a shadow house is not sent in on timers no child of its will read",
	EconomyReady("d") == false)
Shadow = false
check("economy ready: the same timers still admit a real house", EconomyReady("d"))
Shadow = true
IdleMembers = true
Timers.AI_CheckWorkshop = true
check("economy ready: a shadow house with an idle member and a workshop gets Workshop",
	EconomyReady("d"))
-- the third of Workshop's gates. A member who owns no workshop cannot make that node
-- fire, and for a shadow house Workshop is the only child that can fire at all.
OwnsWorkshop = false
check("economy ready: an idle member with no workshop is not enough",
	EconomyReady("d") == false)
OwnsWorkshop = true
DynastyIsShadow = RealIsShadow

IdleMembers = true
-- hand the real ones back before the blocks below use them
Timers = {}
function dyn_IsIdleMember(Alias) return true end

-- the war party: who is offered, incremental commitment, the leader roll -------------------
aitwp_WarPools, aitwp_WarCandidates = WarPools, WarCandidates
aitwp_IsHouseHead, aitwp_WarCommit, aitwp_RaidAllowed = IsHouseHead, WarCommit, RaidAllowed
GL_PROFESSION_MYRMIDON, GL_PROFESSION_ROBBER = 1, 2
GL_PROFESSION_THIEF, GL_PROFESSION_MERCENARY = 3, 4
GL_CLASS_CHISELER = 4

-- Every free hand is offered; WarCommit is what stops the house emptying itself. The two
-- thug case is the bug: the old ceil(n/2) share returned 1, and one hand cleared nothing.
local Pool2 = { [GL_PROFESSION_MYRMIDON] = 2 }
function DynastyGetWorkerCount(Alias, Profession) return Pool2[Profession] or 0 end
function DynastyGetWorker(Alias, Profession, Index, Out)
	if (Pool2[Profession] or 0) <= Index then
		return false
	end
	sheet(Out, 20, 0, 3, 100, 3)
	Aliases[Out] = Out
	return true
end
local RealMemberCount = DynastyGetMemberCount
function DynastyGetMemberCount(Alias) return 0 end
IdleState = true
local Offered, Held = WarCandidates("d", "TWP_C")
check("war candidates: a house with two thugs offers both", Offered == 2)
check("war candidates: and reports the pool it drew them from", Held == 2)
Pool2 = { [GL_PROFESSION_MYRMIDON] = 3, [TWP_PROFESSION_BEGGAR] = 2 }
Offered, Held = WarCandidates("d", "TWP_C")
check("war candidates: two beggars are two hands, not none", Offered == 5)
Pool2 = { [GL_PROFESSION_MYRMIDON] = 20 }
Offered = WarCandidates("d", "TWP_C")
check("war candidates: the party max is the only ceiling", Offered == TWP_WAR_PARTY_MAX)
Pool2 = {}
Offered, Held = WarCandidates("d", "TWP_C")
check("war candidates: an empty house offers nobody and says so", Offered == 0 and Held == 0)
IdleState = false
DynastyGetMemberCount = RealMemberCount

-- commitment stops at the bar instead of emptying the house into the fight
sheet("w1", 20, 0, 3, 100, 3)
sheet("w2", 20, 0, 3, 100, 3)
sheet("w3", 20, 0, 3, 100, 3)
sheet("w4", 20, 0, 3, 100, 3)
Aliases.w1, Aliases.w2, Aliases.w3, Aliases.w4 = "w1", "w2", "w3", "w4"
local Lone = {}
AddFighter(Lone, "d1")
local Party = {}
local Sent, Chance = WarCommit("w", 4, Lone, TWP_ATTACK_WIN_CHANCE, Party)
check("war commit: stops at two, the first party that clears the bar", Sent == 2)
check("war commit: and reports the chance it stopped at", Chance >= TWP_ATTACK_WIN_CHANCE)
sheet("giant", 400, 90, 9, 400, 12)
local Hopeless, Huge = {}, {}
AddFighter(Huge, "giant")
local None = WarCommit("w", 4, Huge, TWP_ATTACK_WIN_CHANCE, Hopeless)
check("war commit: nobody goes when the whole house cannot clear it", None == 0)

-- the raid gates: Patron (rung 3) or round 10, and the building raid wants both
Titles = { 7 }
Round = 1
check("raid: Patron alone opens the assassination", RaidAllowed("player", "assassination_attempt"))
check("raid: Patron alone does not open a building raid", RaidAllowed("player", "raid_building") == false)
Titles = { 1 }
Round = 10
check("raid: round ten alone opens the workers raid", RaidAllowed("player", "workers_raid"))
check("raid: round ten alone does not open a building raid", RaidAllowed("player", "raid_building") == false)
Titles = { 10 }
Round = 10
check("raid: Baron and round ten open the building raid", RaidAllowed("player", "raid_building"))
Titles = { 10 }
Round = 9
check("raid: Baron without the round does not", RaidAllowed("player", "raid_building") == false)
Titles = { 1 }
Round = 1
check("raid: a serf in round one is raided by nobody", RaidAllowed("player", "assassination_attempt") == false)

-- the leader roll: 30 percent, and never when the party already wins outright
aitwp_WarLeader = WarLeader
local RealRand, RollValue = Rand, 0
function Rand(Range) return RollValue end
function DynastyGetMember(Alias, Index, Out) Aliases[Out] = "boss"; return true end
function dyn_IsIdleMember(Alias) return true end
RollValue = 0
check("war leader: never rides out on a certain win", WarLeader("d", 1, "Boss") == false)
check("war leader: rides out on a made roll", WarLeader("d", 0.8, "Boss") == true)
RollValue = TWP_WAR_LEADER_CHANCE
check("war leader: stays home on a missed roll", WarLeader("d", 0.8, "Boss") == false)
Rand = RealRand

-- the kidnap: a second number, because winning the brawl is not getting the body away -----
aitwp_KidnapChance, aitwp_MayAttackHere = KidnapChance, MayAttackHere
local Outside, Ours = true, false
function GetNearestSettlement(Alias, Out) Aliases[Out] = "town" return true end
aitwp_IsOutsideTown = function(Alias) return Outside end
aitwp_CommandsGuards = function(DynAlias, CityAlias) return Ours end
Props.CityBodyguard, Props.KIbodyguard = 0, 0

check("kidnap: an unescorted victim out of town is the base plus one hand",
	near(KidnapChance("d", "v", 1), TWP_KIDNAP_BASE + TWP_KIDNAP_PER_HAND))
Props.CityBodyguard = 2
check("kidnap: two bodyguards cost two escorts' worth",
	near(KidnapChance("d", "v", 1), TWP_KIDNAP_BASE + TWP_KIDNAP_PER_HAND - 2 * TWP_KIDNAP_PER_ESCORT))
Props.CityBodyguard = 0
Outside = false
check("kidnap: inside a town the watch takes its cut",
	near(KidnapChance("d", "v", 1), TWP_KIDNAP_BASE + TWP_KIDNAP_PER_HAND - TWP_KIDNAP_WATCH))
Ours = true
check("kidnap: unless the watch is the house's own - the office path",
	near(KidnapChance("d", "v", 1), TWP_KIDNAP_BASE + TWP_KIDNAP_PER_HAND))
check("kidnap: more hands never push it past certainty", KidnapChance("d", "v", 99) <= 1)
Props.CityBodyguard = 20
check("kidnap: and a wall of bodyguards never pushes it below nothing", KidnapChance("d", "v", 1) >= 0)
Props.CityBodyguard = 0
Outside, Ours = true, false

-- the kidnap gates: earlier than the raids, and the child waits for Patron alone.
-- The leader-roll block above left DynastyGetMember answering "boss"; the ladder needs the
-- index back before PlayerRung can read a title off it.
function DynastyGetMember(Alias, Index, Out) Aliases[Out] = Index return true end
function DynastyGetMemberCount(Alias) return #Titles end
Titles = { 5 }
Round = 1
check("kidnap: a burgher is already worth taking", RaidAllowed("player", "kidnap"))
check("kidnap: but their child is not, below Patron", RaidAllowed("player", "kidnap_child") == false)
Titles = { 1 }
Round = 5
check("kidnap: round five opens it with no title at all", RaidAllowed("player", "kidnap"))
check("kidnap: no round opens taking a child", RaidAllowed("player", "kidnap_child") == false)
Titles = { 7 }
Round = 1
check("kidnap: Patron opens the child in round one", RaidAllowed("player", "kidnap_child"))
Titles = { 1 }
Round = 1
check("kidnap: a serf in round one is left alone", RaidAllowed("player", "kidnap") == false)
-- hand the real ones back: the MayAttackHere checks further down use them, and a stub left
-- lying about is a test that passes for the wrong reason
aitwp_IsOutsideTown, aitwp_CommandsGuards = IsOutsideTown, CommandsGuards
function GetNearestSettlement(Alias, Out) Aliases[Out] = 1 return true end

-- a hurt thug against a fit, armoured swordsman is the fight that was killing them
sheet("hurt", 12, 0, 2, 30, 2)
sheet("knight", 40, 50, 6, 100, 8)
local Hurt, Knight = {}, {}
AddFighter(Hurt, "hurt")
AddFighter(Knight, "knight")
check("a hurt thug stays home against a knight", WinChance(Hurt, Knight) < TWP_ATTACK_WIN_CHANCE)
check("armour cuts the damage that gets through", SidePower(Hurt, Knight) < SidePower(Hurt, Solo))
check("the dead count for nothing", select(4, FightStats("nobody")) == 0)

-- the roster: thugs, and the camps' marauders, thieves and mercenaries
local Roster = { [GL_PROFESSION_MYRMIDON] = 1, [GL_PROFESSION_ROBBER] = 2, [GL_PROFESSION_MERCENARY] = 1 }
function DynastyGetWorkerCount(Alias, Profession) return Roster[Profession] or 0 end
function DynastyGetWorker(Alias, Profession, Index, Out)
	if (Roster[Profession] or 0) <= Index then
		return false
	end
	sheet(Out, 20, 0, 3, 100, 3)
	return true
end
-- NeedHands: the n-squared reading of SidePower that the bar rests on. These four pin
-- the whole argument for TWP_ATTACK_WIN_CHANCE = 0.65 and fail the moment anyone moves
-- the bar without redoing the arithmetic.
check("need hands: a 7% chance needs seven of them at the old 0.75 bar", NeedHands(1, 0.07, 0.75) == 7)
check("need hands: the best logged target needed three at 0.75", NeedHands(1, 0.36, 0.75) == 3)
check("need hands: and only two at 0.65, which is why the bar moved", NeedHands(1, 0.36, 0.65) == 2)
check("need hands: nobody to measure reads -1", NeedHands(0, 0, 0.65) == -1)
check("need hands: an already-winning party needs no more", NeedHands(2, 1, 0.65) == 2)
-- and the knob itself, not just the arithmetic: the whole reason 0.65 was chosen is that
-- the best target the 2026-09-19 log offered becomes a two-hand job. Raise the bar and
-- this goes red, which is the point - moving it is a decision, not a tweak.
check("need hands: the shipped bar keeps the best logged target at two hands",
	NeedHands(1, 0.36, TWP_ATTACK_WIN_CHANCE) == 2)

-- where the fight may happen
-- the raid stamp: aitwp_MayAttackHere only judges a fighter this house sent. Without it
-- the guard also refused the engine's own AttackEnemy filter, which re-selects every two
-- game minutes, so the refusal repeated for ever instead of settling anything.
local WasNow = Now
Props.AI_RaidOrder = nil
check("raid stamp: an unsent fighter is not on a raid order", OnRaidOrder("raider") == false)
SetProperty("raider", "AI_RaidOrder", Now)
check("raid stamp: freshly sent counts", OnRaidOrder("raider") == true)
Now = WasNow + TWP_RAID_ORDER_HOURS - 1
check("raid stamp: still counts inside the window", OnRaidOrder("raider") == true)
Now = WasNow + TWP_RAID_ORDER_HOURS + 1
check("raid stamp: expires by itself, so nothing has to clear it", OnRaidOrder("raider") == false)
Now = WasNow
Props.AI_RaidOrder = nil

local Inside, Wanted, OfficeCity, Privilege = false, false, 0, 0
function SimIsInside(Alias) return Inside end
function GetNearestSettlement(Alias, Out) Aliases[Out] = 1; return true end
function GetDistance(A, B) return 100 end
function CityGetLevel(Alias) return 3 end
function CityGetPenalty(City, Sim, Type, Fugitive, Out) return Wanted end
function GetImpactValue(Alias, Name) if Name == TWP_GUARD_PRIVILEGE then return Privilege end return 0 end
function SimGetCityOfOffice(Alias, Out) Aliases[Out] = OfficeCity; return OfficeCity ~= 0 end
function DynastyGetMemberCount(Alias) return 1 end
function DynastyGetMember(Alias, Index, Out) Aliases[Out] = "member"; return true end

check("the town edge grows with the town", TownRadius("town") == TWP_TOWN_RADIUS + 3 * TWP_TOWN_RADIUS_PER_LEVEL)
check("close to a town is not outside it", IsOutsideTown("v") == false)
check("no attack in town on someone the watch protects", MayAttackHere("d", "v") == false)
Wanted = true
check("a felon is fair game in town", MayAttackHere("d", "v") == true)
Wanted = false
OfficeCity, Privilege = 1, 1
Aliases.town = 1
check("the office that commands the watch buys the same licence", MayAttackHere("d", "v") == true)
Privilege = 0
check("an office without that privilege does not", MayAttackHere("d", "v") == false)
Inside = true
check("indoors is never outside town", IsOutsideTown("v") == false)

-- the blackboard: key registry and the Weight() -> Execute() handoff ----------------------
dofile("Scripts/Library/aiboard.lua")
aiboard_Stem, aiboard_Known = Stem, Known
aiboard_Recall, aiboard_Remember, aiboard_Forget = Recall, Remember, Forget
aiboard_Stash, aiboard_Claim, aiboard_Drop = Stash, Claim, Drop
local Store = {}
function SetData(Key, Value) Store[Key] = Value end
function GetData(Key) return Store[Key] end
function GetAliasByID(ID, Out) if ID == 0 then return false end Aliases[Out] = ID; return true end
Props = {}
function GetProperty(Alias, Name) return Props[Name] end
function SetProperty(Alias, Name, Value) Props[Name] = Value end
function HasProperty(Alias, Name) return Props[Name] ~= nil end
function RemoveProperty(Alias, Name) Props[Name] = nil end

check("a missing key falls back to its declared default", Recall("d", "AITWP_Agressive") == 50)
Remember("d", "AITWP_Agressive", 90)
check("a written key reads back", Recall("d", "AITWP_Agressive") == 90)
Forget("d", "AITWP_Agressive")
check("a forgotten key returns to its default", Recall("d", "AITWP_Agressive") == 50)
check("an indexed key matches its registered stem", Stem("AI_Courier2") == "AI_Courier")
check("a non-prefix key does not match by stem", Stem("AI_Goal7") == nil)
Logged = {}
check("an unregistered key reads nil", Recall("d", "AI_Typpo") == nil)
check("and says so instead of failing silently", has(lastLog(), "::TWP::BB unregistered key AI_Typpo"))
Logged = {}
Recall("d", "AI_Typpo")
check("but only once per key", #Logged == 0)

-- the handoff: what a sibling writes afterwards must not reach the winner
Aliases.MyTarget = 4242
check("stashing a live alias succeeds", Stash("bf_Mine", "MyTarget") == true)
Aliases.MyTarget = 99                    -- a sibling resolves the shared alias to its own target
check("the claim returns the node's own target, not the sibling's",
	Claim("bf_Mine", "Out") and Aliases.Out == 4242)
check("a claim for a node that never stashed fails", Claim("bf_Other", "Out2") == false)
RemoveAlias("Gone")
check("stashing a missing alias reports it", Stash("bf_Gone", "Gone") == false)
check("and its claim fails rather than acting on nothing", Claim("bf_Gone", "Out3") == false)



-- buying at the blood rival's own counter: damage done vs coin handed over ---------------
-- ItemGetPriceBuy is the seller's own asking price; base price is the fallback.
TWP_ENEMY_SHOP_PRICE = {}          -- item -> what this seller charges, nil = cannot answer
function ItemGetPriceBuy(Item, _Seller) return TWP_ENEMY_SHOP_PRICE[Item] end
Aliases.Shop = 1

check("a lethal poison is worth funding them for",
	WorthBuyingFromEnemy("BlackWidowPoison", "Shop") == true)
check("a forged document is, too - the case it exists for",
	WorthBuyingFromEnemy("HexerdokumentI", "Shop") == true)
check("a reputation trinket is not: severity 1 buys nothing",
	WorthBuyingFromEnemy("ThesisPaper", "Shop") == false)
check("nor toad excrement, economic and below the bar",
	WorthBuyingFromEnemy("ToadExcrements", "Shop") == false)
check("equipment is never bought there, it does the rival no harm",
	WorthBuyingFromEnemy("Longsword", "Shop") == false)
check("an item that is not a tool at all is refused",
	WorthBuyingFromEnemy("NotAThing", "Shop") == false)

-- the seller's own asking price decides, not the catalogue
TWP_ENEMY_SHOP_PRICE["WeaponPoison"] = 99999
check("a shop charging far over the odds is walked past",
	WorthBuyingFromEnemy("WeaponPoison", "Shop") == false)
TWP_ENEMY_SHOP_PRICE["WeaponPoison"] = 10
check("and the same item at a fair price is taken",
	WorthBuyingFromEnemy("WeaponPoison", "Shop") == true)
TWP_ENEMY_SHOP_PRICE["WeaponPoison"] = nil
check("with no seller price to read, the base price decides",
	WorthBuyingFromEnemy("WeaponPoison", "Shop") == true)

-- the cap scales with the damage: the same price passes for a lethal tool and fails for a
-- forgery, which is the whole point of weighing one against the other
TWP_ENEMY_SHOP_PRICE["BlackWidowPoison"] = TWP_BF_ENEMY_GOLD * 5
TWP_ENEMY_SHOP_PRICE["HexerdokumentI"] = TWP_BF_ENEMY_GOLD * 5
check("a lethal tool justifies its own cap", WorthBuyingFromEnemy("BlackWidowPoison", "Shop") == true)
check("the same coin for a forgery does not", WorthBuyingFromEnemy("HexerdokumentI", "Shop") == false)
TWP_ENEMY_SHOP_PRICE = {}
-- the HTN: decomposition, the reason it gives, and the pull it puts on one leaf -----------
dofile("Scripts/Library/aihtn.lua")
aihtn_Plan, aihtn_Step, aihtn_CountArtefacts = Plan, Step, CountArtefacts
UTILITY_LOG = true                       -- the HTN line is telemetry; assert on it
check("load marker is logged at include time", has(lastLog(), "::TWP::LOADED aihtn.lua"))

-- Every knob the library reads must exist: a misspelled one is nil inside a closure and
-- surfaces as "compare number with nil" mid-game, the failure class this file exists to
-- end. Comments and strings are stripped first so alias names do not count as knobs.
local NL, Q = string.char(10), string.char(34)
local Src = io.open("Scripts/Library/aihtn.lua"):read("*a")
Src = string.gsub(Src, "%-%-[^" .. NL .. "]*", "")
Src = string.gsub(Src, Q .. "[^" .. Q .. NL .. "]*" .. Q, "")
local Unknown = nil
for Name in string.gmatch(Src, "[A-Za-z_][A-Za-z0-9_]*") do
	if string.find(Name, "^AIHTN_") or string.find(Name, "^TWP_") or string.find(Name, "^UTILITY_") then
		if _G[Name] == nil and not Unknown then
			Unknown = Name
		end
	end
end
check("every AIHTN_/TWP_/UTILITY_ knob the library reads is defined", Unknown == nil)

-- The real table, structurally: a step naming a leaf that does not exist would plan a
-- chain the engine can never run, and a space in any name breaks the analyzer's kv().
local RealTasks = AIHTN_TASKS
local BadStep, BadName = nil, nil
local TaskNames = { "Feud", "HaveEvidence" }
for t = 1, #TaskNames do
	local Methods = RealTasks[TaskNames[t]]
	for m = 1, #Methods do
		if string.find(Methods[m].name, "%s") then
			BadName = Methods[m].name
		end
		for w = 1, #Methods[m].when do
			if string.find(Methods[m].when[w][1], "%s") then
				BadName = Methods[m].when[w][1]
			end
		end
		for st = 1, #Methods[m].steps do
			local StepName = Methods[m].steps[st]
			if not RealTasks[StepName] then
				local Leaf = io.open("Scripts/AI/BaseTree/BloodFeud/" .. StepName .. ".lua")
				if Leaf then
					Leaf:close()
				else
					BadStep = StepName
				end
			end
		end
	end
end
check("every step names a task or a BloodFeud leaf that exists", BadStep == nil)
check("no method or predicate name carries a space", BadName == nil)

-- the decomposer, against an injected table: the real predicates need the engine
local Gate = { m1 = false, sub = true }
AIHTN_TASKS = {
	Feud = {
		{ name = "m1", when = { { "P1", function() return Gate.m1 end } }, steps = { "bf_A" } },
		{ name = "m2", when = {}, steps = { "Sub", "bf_B" } },
	},
	Sub = {
		{ name = "ready", when = { { "SubReady", function() return Gate.sub end } }, steps = {} },
		{ name = "make", when = {}, steps = { "bf_C" } },
	},
}
local Chain, Fail = {}, {}
check("the first method whose preconditions hold wins", Plan("d", "p", "Feud", Chain, Fail) == "m2")
check("a satisfied compound adds no step and the parent carries on", #Chain == 1 and Chain[1] == "bf_B")
check("the method that did not apply names the precondition that fell", Fail[1] == "Feud.m1:P1")
Gate.m1 = true
Chain, Fail = {}, {}
check("and once it holds, that method is taken instead", Plan("d", "p", "Feud", Chain, Fail) == "m1")
check("with no reason recorded, because none was needed", #Fail == 0 and Chain[1] == "bf_A")
Gate.m1, Gate.sub = false, false
Chain, Fail = {}, {}
Plan("d", "p", "Feud", Chain, Fail)
check("an unsatisfied compound decomposes to its own next method",
	#Chain == 2 and Chain[1] == "bf_C" and Chain[2] == "bf_B")
check("and its reason is recorded under the subtask", Fail[2] == "Sub.ready:SubReady")

-- a method that fails half way must not leave its steps behind for the next one
AIHTN_TASKS = {
	Feud = {
		{ name = "m1", when = {}, steps = { "bf_A", "Dead" } },
		{ name = "m2", when = {}, steps = { "bf_B" } },
	},
	Dead = { { name = "never", when = { { "Never", function() return false end } }, steps = {} } },
}
Chain, Fail = {}, {}
check("a method that fails part-way falls through", Plan("d", "p", "Feud", Chain, Fail) == "m2")
check("and leaves no half-built chain behind", #Chain == 1 and Chain[1] == "bf_B")

AIHTN_TASKS = {
	Feud = { { name = "only", when = { { "Nope", function() return false end } }, steps = { "bf_A" } } },
}
Chain, Fail = {}, {}
check("no applicable method returns nil", Plan("d", "p", "Feud", Chain, Fail) == nil)
check("and the chain stays empty", #Chain == 0 and Fail[1] == "Feud.only:Nope")
Props = {}
check("so Step reports no step at all", Step("d") == "-")
check("and files it, so utility_Score gives nothing the x3", Props.AI_HTN_Step == "-")

-- the line: one per changed step, then throttled to AIHTN_LOG_HOURS
AIHTN_TASKS = { Feud = { { name = "go", when = {}, steps = { "bf_Procure" } } } }
Props = {}
Logged = {}
check("a plan reports the step it chose", Step("d") == "bf_Procure")
check("the HTN line is stamped like every other channel",
	has(lastLog(), "::TWP::HTN t=" .. string.format("%.2f", Now) .. " dyn="))
check("and names task, method, step, chain and the reasons",
	has(lastLog(), "task=Feud method=go step=bf_Procure chain=bf_Procure fail=-"))
local Tokens = 0
for _Word in string.gmatch(lastLog(), "%S+") do
	Tokens = Tokens + 1
end
check("and splits into exactly the 8 fields the analyzer reads", Tokens == 8)
Logged = {}
Step("d")
check("an unchanged step does not repeat the line", #Logged == 0)
Now = Now + AIHTN_LOG_HOURS
Step("d")
check("until the throttle lapses", #Logged == 1)
AIHTN_TASKS = { Feud = { { name = "go", when = {}, steps = { "bf_Taunt" } } } }
Logged = {}
Step("d")
check("a changed step is logged at once, throttle or not", #Logged == 1 and has(lastLog(), "step=bf_Taunt"))
UTILITY_LOG = false
Props = {}
Logged = {}
Step("d")
check("and nothing is emitted while the log is off", #Logged == 0)
UTILITY_LOG = true

-- the focus effect: the planned leaf outweighs its siblings, nothing else moves
Props = {}
Props.AI_HTN_Step = "bf_Procure"
Logged = {}
check("the leaf the plan named is worth UTILITY_HTN_FACTOR", near(Score("d", 10, {}, "bf_Procure"), 30))
check("and its W line says so", has(lastLog(), "h=step"))
check("a sibling off the plan is untouched", near(Score("d", 10, {}, "bf_Taunt"), 10))
check("and says that too", has(lastLog(), "h=-"))
Logged = {}
check("a node outside the feud is not scaled", near(Score("d", 10, {}, "ApplyForOffice"), 10))
check("and its line carries no h= at all, so no existing replay moves",
	lastLog() ~= nil and string.find(lastLog(), "h=", 1, true) == nil)
AIHTN_TASKS = RealTasks
UTILITY_LOG = nil

aitwp_DipLadder, aitwp_NextFoeStep = DipLadder, NextFoeStep
-- the diplomatic step: one band down per call, and nil once there is nowhere left.
-- Deliberately not the 0..3 the engine uses, so the test proves the code reads the order
-- of aitwp_DipLadder and not the numbers, which is the whole point of that table.
Dyn[11] = { favor = 20, dip = DIP_ALLIANCE, player = true }
Aliases.p = 11
check("an alliance with a blood enemy steps down to NAP", NextFoeStep("d", "p") == 2)
Dyn[11].dip = DIP_NAP
check("NAP steps down to neutral", NextFoeStep("d", "p") == 1)
Dyn[11].dip = DIP_NEUTRAL
check("neutral steps down to foe", NextFoeStep("d", "p") == 0)
Dyn[11].dip = DIP_FOE
check("and foe has nowhere left to go", NextFoeStep("d", "p") == nil)
check("the ladder is the four bands, hostile first",
	#DipLadder() == 4 and DipLadder()[1] == DIP_FOE and DipLadder()[4] == DIP_ALLIANCE)
-- the step is the InitResult ms_047_AdministrateDiplomacy branches on: 0 feud, 1 neutral,
-- 2 NAP. A step that fell outside 0..2 would be silently ignored by that measure.
Dyn[11].dip = DIP_ALLIANCE
local Step = NextFoeStep("d", "p")
check("the step is a legal InitResult", Step >= 0 and Step <= 2)

if Failures > 0 then
	io.stderr:write("FAILED: " .. Failures .. " check(s) on utility scoring\n")
	os.exit(1)
end
print("ok: utility scoring, goal blackboard, telemetry, scored targets, attitude ladder, supply chain, order guard, scored pickers, HTN, diplomatic step")
