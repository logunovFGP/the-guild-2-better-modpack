-- The AI blackboard: the state the BaseTree decides from, and the handoff from a
-- node's Weight() to its Execute(). Reached as aiboard_<Name> in game.
--
-- Named aiboard, not blackboard. Library files and the object scripts the engine binds
-- by basename (Buildings among them) all register <basename>_<Function> globals, and
-- Scripts/Buildings/BlackBoard.lua - the town notice board - already owned blackboard_.
-- A library whose basename is taken is skipped without a word: three game starts on
-- 2026-09-10, no load marker. The team met the same rule for AI nodes in August 2025
-- (README, Stability notes); check_unresolved_calls.py fails on such a name now.
--
-- Two failures are what this file exists to stop, both of them silent.
--
-- Keys were bare strings at sixty-odd call sites. A typo reads nil, the node weighs
-- 0, and nothing is logged - the same shape as every other bug this AI has had.
-- BLACKBOARD_KEYS below is every key with its owner and default; a read or write of
-- one that is not listed says so in the log, and basetree_stats.py fails on it.
--
-- And the engine runs every sibling's Weight() before the winner's Execute(), so an
-- alias written during Weight() belongs to whichever sibling happened to run last.
-- Six BloodFeud leaves each resolved a different victim into the shared alias
-- "Victim" that way: the winner scored one target and acted on another.
-- aiboard_Stash and aiboard_Claim carry a target across that gap by id, filed
-- under the node's own name, so a sibling cannot take it.
--
-- Deterministic: no Rand, no iteration over the key table, so it is safe for
-- lockstep multiplayer and for this engine's pairs()-less Lua.

-- Every key the AI keeps on a dynasty or a sim. "prefix" means an index is appended
-- (AI_Courier1..3), so the check matches the stem instead of the whole name.
BLACKBOARD_KEYS = {
	-- the goal blackboard, rewritten once per window by Priorities
	AI_Goal = { owner = "utility_ChooseGoal", default = nil },
	AI_GoalTarget = { owner = "utility_ChooseGoal", default = 0 },
	AI_GoalUntil = { owner = "utility_ChooseGoal", default = 0 },
	-- who this house is, and who it hates
	AI_PERSONA = { owner = "Priorities", default = -1 },
	AI_BloodEnemy = { owner = "Priorities", default = 0 },
	AI_BloodEnemyOf = { owner = "Priorities", default = 0 },
	AITWP_Enemies = { owner = "aitwp_GetCurrentEnemies", default = "" },
	-- the priority axes utility_Priority reads, 0..100
	AITWP_Political = { owner = "Priorities", default = 50 },
	AITWP_Agressive = { owner = "Priorities", default = 50 },
	AITWP_Intrigue = { owner = "Priorities", default = 50 },
	AITWP_Money = { owner = "Priorities", default = 50 },
	AITWP_Mission = { owner = "Priorities", default = 0 },
	-- blood feud bookkeeping
	AI_EvidenceTarget = { owner = "aitwp_EvidenceTarget", default = 0 },
	AI_BF_DuelRogues = { owner = "bf_Provoke", default = 0 },
	AI_BF_CartFailed = { owner = "bf_Procure", default = 0 },
	AI_HTN_Step = { owner = "aihtn_Step", default = "-" },
	AI_HTN_At = { owner = "aihtn_Step", default = nil },
	AI_Ordered_ = { owner = "aitwp_ClaimOrder", default = -1, prefix = true },
	AI_Courier = { owner = "aitwp_CourierOrders", default = 0, prefix = true },
	-- economy bookkeeping
	AI_DynMoney = { owner = "ai_DynastyMoney", default = 0 },
	AI_DynMoney_LastCheck = { owner = "ai_DynastyMoney", default = 0 },
	AI_IncomeLast = { owner = "IncomeForAI", default = 0 },
	AI_Reserve_ = { owner = "economy reserve", default = 0, prefix = true },
	AI_ReserveTaken_ = { owner = "economy reserve", default = 0, prefix = true },
	AI_ReserveDay = { owner = "economy reserve", default = 0 },
	AI_Turn_ = { owner = "economy turnover", default = 0, prefix = true },
	AI_HO_Count = { owner = "aitwp_HandOversToday", default = 0 },
	AI_HO_Round = { owner = "aitwp_HandOversToday", default = 0 },
	-- family and household
	AI_MainClass = { owner = "Priorities", default = 0 },
	AI_ApprenticeClass = { owner = "behavior_apprenticeship", default = 0 },
	AI_NaturalTryUntil = { owner = "Reproduce", default = 0 },
	AI_DDyn = { owner = "ai_DefendRogue", default = 0 },
}

local Warned = {}

-- The stem of a key, so AI_Courier2 checks against AI_Courier.
function Stem(Key)
	if BLACKBOARD_KEYS[Key] then
		return Key
	end
	local Trimmed = string.gsub(Key, "[0-9]+$", "")
	if BLACKBOARD_KEYS[Trimmed] and BLACKBOARD_KEYS[Trimmed].prefix then
		return Trimmed
	end
	return nil
end

-- An unregistered key is a typo, or one somebody forgot to declare. Say so once -
-- the whole point is that this stops being silent - then carry on.
function Known(Key, Where)
	local Found = aiboard_Stem(Key)
	if Found then
		return Found
	end
	if not Warned[Key] then
		Warned[Key] = true
		LogMessage("::TWP::BB unregistered key " .. tostring(Key) .. " in " .. tostring(Where)
			.. " - add it to BLACKBOARD_KEYS in Scripts/Library/aiboard.lua")
	end
	return nil
end

-- Read a key, falling back to its declared default rather than nil, so no caller has
-- to write "or 0" and none silently treats "missing" as zero by accident.
function Recall(Alias, Key)
	local Found = aiboard_Known(Key, "Recall")
	local Value = GetProperty(Alias, Key)
	if Value ~= nil then
		return Value
	end
	if Found then
		return BLACKBOARD_KEYS[Found].default
	end
	return nil
end

function Remember(Alias, Key, Value)
	aiboard_Known(Key, "Remember")
	SetProperty(Alias, Key, Value)
end

function Forget(Alias, Key)
	aiboard_Known(Key, "Forget")
	if HasProperty(Alias, Key) then
		RemoveProperty(Alias, Key)
	end
end

-- The Weight() -> Execute() handoff. Weight resolves its target and stashes the id
-- under the node's own name; Execute claims it back into an alias of its own choosing.
-- Nothing a sibling writes can reach it, because the key carries the node name.
function Stash(Node, Alias)
	if not AliasExists(Alias) then
		SetData("BB_" .. Node, 0)
		return false
	end
	SetData("BB_" .. Node, GetID(Alias))
	return true
end

-- Sets OutAlias to whatever Stash filed for this node; false when it is gone - the
-- target died, left the dynasty, or Weight() never got that far.
function Claim(Node, OutAlias)
	local ID = GetData("BB_" .. Node) or 0
	if ID < 1 then
		return false
	end
	return GetAliasByID(ID, OutAlias) and AliasExists(OutAlias)
end

function Drop(OutAlias)
	RemoveAlias(OutAlias)
end

LogMessage("::TWP::LOADED aiboard.lua")
