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
STATE_DEAD = 99

local Props = {}
function GetProperty(Alias, Name) return Props[Name] end
function SetProperty(Alias, Name, Value) Props[Name] = Value end
function HasProperty(Alias, Name) return Props[Name] ~= nil end

local Now = 1000
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
utility_LogEnabled, utility_Stamp, utility_Tick, utility_TakeTicks = LogEnabled, Stamp, Tick, TakeTicks

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
Trace("d", "BuildHome", 5)
check("Trace logs a W line with no inputs", has(lastLog(), "node=BuildHome base=5 c= g=none w=5"))
Picked("d", "Dynasty")
check("PICK line", has(lastLog(), "::TWP::PICK t=1000.00 dyn=1 node=Dynasty"))
UTILITY_LogEnabled = false

-- ChooseGoal -----------------------------------------------------------------------
Props = { AITWP_Political = 10, AITWP_Agressive = 80 }
World = { money = 8000, members = 3, workshops = 3, wanted = 3, enemies = 2 }
Logged = {}
check("enemies plus aggression choose Conflict", ChooseGoal("d") == "Conflict")
check("Conflict records the best enemy as target", Props.AI_GoalTarget == 42)
check("goal runs for UTILITY_GOAL_HOURS", Props.AI_GoalUntil == Now + UTILITY_GOAL_HOURS)
check("GOAL line is logged even with Log off", has(lastLog(), "::TWP::GOAL t=1000.00 dyn=1 P=10 A=80 ambition=80"))
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

-- aitwp_IsFitToDuel: the duel rule ------------------------------------------------------
FIGHTING, DEXTERITY = 1, 2
local Skills, HP = { 3, 3 }, 1.0
function GetSkillValue(Alias, Skill) return Skills[Skill] or 0 end
function GetHPRelative(Alias) return HP end
check("martial arts and dexterity both under 5: no duel", IsFitToDuel("s") == false)
Skills[1] = 5
check("martial arts 5 is enough", IsFitToDuel("s") == true)
Skills[1], Skills[2] = 2, 6
check("dexterity 5 or more is enough on its own", IsFitToDuel("s") == true)
HP = 0.79
check("under 80% health: no duel whatever the talents", IsFitToDuel("s") == false)

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

if Failures > 0 then
	io.stderr:write("FAILED: " .. Failures .. " check(s) on utility scoring\n")
	os.exit(1)
end
print("ok: utility scoring, goal blackboard, telemetry, scored targets, attitude ladder")
