---
-- Utility scoring for AI BaseTree nodes (a cut-down Infinite Axis Utility System).
--
-- The engine picks a child node by weighted random over Weight() (AIWeightedRandom.h
-- in GuildII.exe), so a weight is a probability share, not a priority. A node keeps
-- its tuned base weight and multiplies it by one factor per consideration. Each
-- factor lies in UTILITY_LO..UTILITY_HI (0.5..1.5), so a consideration at 0.5 leaves
-- the base untouched and the extremes move it by half either way.
--
--   return utility_Score("dynasty", 20, {
--       utility_Priority("dynasty", "Political"),        -- 0..1 from AITWP_Political
--       utility_Trait("dynasty", "ambition"),             -- 0..1 from AIPersonality.dbt
--       { value = utility_Norm(Money, 0, 20000), curve = "quad" },
--   }, "ApplyForOffice", "Politics")                     -- trace tag, goal served
--
-- The goal blackboard is three dynasty properties: AI_Goal (Economy, Politics,
-- Family or Conflict), AI_GoalTarget (dynasty id, 0 when none) and AI_GoalUntil
-- (game time in hours). utility_ChooseGoal picks one every UTILITY_GOAL_HOURS from
-- the daily Priorities node; a node that names a Goal is scaled x3 when it serves
-- the current goal and x0.3 when it does not, which is what keeps a dynasty on one
-- thread between ticks instead of courting, suing and building at random.
--
-- Telemetry: with Log = 1 under [AI] in configs/config.ini every instrumented
-- Weight() logs its inputs (::TWP::W) and every Execute() its pick (::TWP::PICK), so
-- tools/modding_helpers/ai_telemetry.py can replay the roulette under any other
-- UTILITY_* setting from one session. Goal choices (::TWP::GOAL) are always logged.
-- Nothing in the telemetry touches game state, so peers may differ in the setting.
--
-- Deterministic: no Rand, numeric loops only, so it is safe for lockstep multiplayer.
-- Functions are reached as utility_<Name> in game (the engine prefixes library
-- files with their lower-cased file name).

UTILITY_LO = 0.5
UTILITY_HI = 1.5
UTILITY_GOAL_ALIGNED = 3
UTILITY_GOAL_OTHER = 0.3
UTILITY_GOAL_HOURS = 72

-- telemetry --------------------------------------------------------------------

function LogEnabled()
	if UTILITY_LogEnabled == nil then
		-- Log = 1 under [AI] in configs/config.ini; AILog = 1 under [OPTIONS] works too,
		-- that being the section the campaign scripts are known to read.
		UTILITY_LogEnabled = (GetSettingNumber("AI", "Log", 0) or 0) > 0
			or (GetSettingNumber("OPTIONS", "AILog", 0) or 0) > 0
	end
	return UTILITY_LogEnabled
end

function Stamp(DynAlias)
	return "t=" .. string.format("%.2f", GetGametime()) .. " dyn=" .. GetID(DynAlias)
end

-- Root-level evaluations per dynasty since the last snapshot. A plain Lua table:
-- volatile, never saved, never read by a decision.
UTILITY_Ticks = {}

function Tick(DynAlias)
	local ID = GetID(DynAlias)
	UTILITY_Ticks[ID] = (UTILITY_Ticks[ID] or 0) + 1
end

function TakeTicks(DynAlias)
	local ID = GetID(DynAlias)
	local N = UTILITY_Ticks[ID] or 0
	UTILITY_Ticks[ID] = 0
	return N
end

-- Weight() of a node that is not utility-scored: log it and hand it back unchanged,
-- so the whole sibling set of a level is on record and the roulette can be replayed.
function Trace(DynAlias, Tag, Weight)
	if utility_LogEnabled() then
		LogMessage("::TWP::W " .. utility_Stamp(DynAlias) .. " node=" .. Tag .. " base=" .. Weight .. " c= g=none w=" .. Weight)
	end
	return Weight
end

-- First statement of Execute(): the node the engine actually picked.
function Picked(DynAlias, Tag)
	if utility_LogEnabled() then
		LogMessage("::TWP::PICK " .. utility_Stamp(DynAlias) .. " node=" .. Tag)
	end
end

-- scoring ----------------------------------------------------------------------

function Clamp01(x)
	if x == nil or x < 0 then
		return 0
	end
	if x > 1 then
		return 1
	end
	return x
end

-- Maps x from Min..Max onto 0..1, clamped.
function Norm(x, Min, Max)
	if Max <= Min then
		if x >= Max then
			return 1
		end
		return 0
	end
	return utility_Clamp01((x - Min) / (Max - Min))
end

-- Response curves over 0..1. "quad" only rewards high inputs, "sqrt" rewards early,
-- "invert" turns a cost into a benefit.
function Curve(x, Kind)
	x = utility_Clamp01(x)
	if Kind == "quad" then
		return x * x
	elseif Kind == "sqrt" then
		return math.sqrt(x)
	elseif Kind == "invert" then
		return 1 - x
	end
	return x
end

-- Base weight times one factor per consideration, times the goal factor when Goal
-- is given. A consideration is a number in 0..1 or a table
-- { value = 0..1, curve = "linear"|"quad"|"sqrt"|"invert", lo, hi }.
-- Tag names the node in the trace; with a Tag the inputs are logged so any other
-- UTILITY_* setting can be replayed offline from the same session.
function Score(DynAlias, Base, Considerations, Tag, Goal)
	if Base == nil or Base <= 0 then
		return 0
	end
	local Result = Base
	local Inputs = ""
	for i = 1, #Considerations do
		local C = Considerations[i]
		local x, Kind, Lo, Hi = C, "linear", UTILITY_LO, UTILITY_HI
		if type(C) == "table" then
			x = C.value
			Kind = C.curve or Kind
			Lo = C.lo or Lo
			Hi = C.hi or Hi
		end
		x = utility_Clamp01(x)
		Result = Result * (Lo + (Hi - Lo) * utility_Curve(x, Kind))
		if i > 1 then
			Inputs = Inputs .. ";"
		end
		Inputs = Inputs .. string.format("%.2f", x) .. ":" .. Kind
	end
	local GoalState = "none"
	if Goal then
		local Factor = utility_GoalFactor(DynAlias, Goal)
		if Factor == UTILITY_GOAL_ALIGNED then
			GoalState = "aligned"
		elseif Factor == UTILITY_GOAL_OTHER then
			GoalState = "other"
		end
		Result = Result * Factor
	end
	if Tag and utility_LogEnabled() then
		LogMessage("::TWP::W " .. utility_Stamp(DynAlias) .. " node=" .. Tag .. " base=" .. Base
			.. " c=" .. Inputs .. " g=" .. GoalState .. " w=" .. string.format("%.2f", Result))
	end
	return Result
end

-- AIPersonality.dbt column as 0..1 (bribes, greed, ambition, arrogance, trust,
-- loyalty, patience, discord, sabotage, bloodlust).
function Trait(DynAlias, TraitName)
	return utility_Clamp01((ai_CheckPersonalityWeight(DynAlias, TraitName) or 50) / 100)
end

-- Daily TWP priority as 0..1: "Political", "Agressive" or "Intrigue". Neutral (0.5)
-- until the first Priorities run has written the property.
function Priority(DynAlias, Name)
	local Value = GetProperty(DynAlias, "AITWP_" .. Name)
	if Value == nil then
		return 0.5
	end
	return utility_Clamp01(Value / 100)
end

-- Dynasty money as 0..1, saturating at Comfortable.
function Money(DynAlias, Comfortable)
	return utility_Norm(GetMoney(DynAlias), 0, Comfortable)
end

-- goals ------------------------------------------------------------------------

-- x3 when the dynasty's current goal is Goal, x0.3 when it is another goal, x1 when
-- no goal is set or the goal has expired.
function GoalFactor(DynAlias, Goal)
	local Current = GetProperty(DynAlias, "AI_Goal")
	if Current == nil or Current == "" then
		return 1
	end
	if GetGametime() >= (GetProperty(DynAlias, "AI_GoalUntil") or 0) then
		return 1
	end
	if Current == Goal then
		return UTILITY_GOAL_ALIGNED
	end
	return UTILITY_GOAL_OTHER
end

-- Picks the dynasty's goal for the next UTILITY_GOAL_HOURS unless one is still
-- running. Scores are argmax with ties resolved in a fixed order, so every peer
-- picks the same goal from the same state. Inputs and scores are always logged.
function ChooseGoal(DynAlias)
	local Now = GetGametime()
	-- a blood enemy has one goal for life: the player it was assigned to
	local Blood = GetProperty(DynAlias, "AI_BloodEnemyOf") or 0
	if Blood > 0 then
		SetProperty(DynAlias, "AI_Goal", "Conflict")
		SetProperty(DynAlias, "AI_GoalTarget", Blood)
		SetProperty(DynAlias, "AI_GoalUntil", Now + UTILITY_GOAL_HOURS)
		LogMessage("::TWP::GOAL " .. utility_Stamp(DynAlias) .. " blood=1 pick=Conflict target=" .. Blood)
		return "Conflict"
	end
	local Current = GetProperty(DynAlias, "AI_Goal")
	if Current and Current ~= "" and Now < (GetProperty(DynAlias, "AI_GoalUntil") or 0) then
		return Current
	end

	local Political = GetProperty(DynAlias, "AITWP_Political") or 0
	local Agressive = GetProperty(DynAlias, "AITWP_Agressive") or 0
	local Ambition = ai_CheckPersonalityWeight(DynAlias, "ambition") or 50
	local Greed = ai_CheckPersonalityWeight(DynAlias, "greed") or 50
	local Bloodlust = ai_CheckPersonalityWeight(DynAlias, "bloodlust") or 50
	local EnemyCount = aitwp_GetCurrentEnemies(DynAlias)
	local Members = DynastyGetMemberCount(DynAlias)
	local Workshops = DynastyGetBuildingCount(DynAlias, GL_BUILDING_CLASS_WORKSHOP, -1)
	local WantedWorkshops = ai_GetBestNumberOfWorkshops(DynAlias)

	local Politics = Political + Ambition / 2
	local Economy = math.max(0, WantedWorkshops - Workshops) * 25 + Greed / 2
	local Conflict = 0
	if EnemyCount > 0 then
		Conflict = Agressive + math.min(3, EnemyCount) * 10 + Bloodlust / 2
	end
	local Family = math.max(0, 3 - Members) * 30

	local Goal, Best = "Economy", Economy
	if Politics > Best then
		Goal, Best = "Politics", Politics
	end
	if Family > Best then
		Goal, Best = "Family", Family
	end
	if Conflict > Best then
		Goal, Best = "Conflict", Conflict
	end

	local Target = 0
	if Goal == "Conflict" then
		Target = math.max(0, aitwp_GetBestEnemy(DynAlias))
	end
	SetProperty(DynAlias, "AI_Goal", Goal)
	SetProperty(DynAlias, "AI_GoalTarget", Target)
	SetProperty(DynAlias, "AI_GoalUntil", Now + UTILITY_GOAL_HOURS)
	LogMessage("::TWP::GOAL " .. utility_Stamp(DynAlias) .. " P=" .. Political .. " A=" .. Agressive
		.. " ambition=" .. Ambition .. " greed=" .. Greed .. " bloodlust=" .. Bloodlust
		.. " enemies=" .. EnemyCount .. " members=" .. Members .. " ws=" .. Workshops .. " wanted=" .. WantedWorkshops
		.. " politics=" .. Politics .. " economy=" .. Economy .. " family=" .. Family .. " conflict=" .. Conflict
		.. " pick=" .. Goal .. " target=" .. Target)
	return Goal
end

-- Load marker and environment probe, once per game start, always on. If LOADED is
-- missing from logfile.log the Include in stdafx.lua failed and every utility_*
-- node silently weighs 0; ENV settles which parts of the Lua stdlib this engine has.
pcall(function()
	-- raw values, not cached: the flag itself is read on first use in game
	LogMessage("::TWP::LOADED utility.lua AI.Log=" .. tostring(GetSettingNumber("AI", "Log", -1))
		.. " OPTIONS.AILog=" .. tostring(GetSettingNumber("OPTIONS", "AILog", -1)))
end)
pcall(function()
	LogMessage("::TWP::ENV lua=" .. tostring(_VERSION)
		.. " table.sort=" .. tostring(type(table) == "table" and type(table.sort) == "function")
		.. " table.insert=" .. tostring(type(table) == "table" and type(table.insert) == "function")
		.. " pairs=" .. type(pairs) .. " unpack=" .. type(unpack) .. " math.random=" .. type(math.random))
end)
