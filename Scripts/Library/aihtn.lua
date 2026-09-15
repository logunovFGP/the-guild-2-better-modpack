---
-- aihtn.lua - which chain of BloodFeud leaves the house is on, and why not the others.
--
-- The engine's selector picks one leaf per tick by roulette over Weight(), and the
-- thirteen bf_ leaves gate themselves with 47 separate "return 0"s. That works, but it
-- answers no question: when the feud stalls, nothing in the log says which precondition
-- fell. This is the thin HTN of docs/AI_ARCHITECTURE.md section 4 over exactly that chain.
--
-- A task decomposes into an ordered list of methods; the first method whose every
-- precondition holds wins, and its steps are the chain. A step names either another task
-- or a leaf, so "charge" reads "have a case, then bring it" and expands to
-- bf_ForgeEvidence > bf_Charge while the evidence is thin, and to bf_Charge once it is
-- not. BloodFeud.lua asks for the first step, weighs 0 when there is none, and
-- utility.lua gives that one leaf UTILITY_HTN_FACTOR. The leaves are untouched: they
-- stay the primitives and keep their own gates, and the scorer still chooses within the
-- chain. This narrows the candidates; it does not decide.
--
-- SOUNDNESS, the rule the table lives by: every precondition on the way to a step is a
-- *necessary* condition of that leaf's own Weight(). Then "no method applies" proves
-- every child weighs 0 and the root may skip the tick. The converse is not claimed -
-- leaves keep incidental gates (a target in reach this hour, the win chance), so an
-- entry can still find nothing, which is what BloodFeud.lua's own dampener is for.
-- A leaf gate that changes must change its method's "when"; no checker can see that.
--
-- Deterministic: no Rand, no pairs(), arrays walked by index, so peers agree. The
-- predicates are the same aitwp_ helpers the leaves call, so the planner learns nothing
-- the tree did not already know.
-- Registered in Library/stdafx.lua. Functions are reached as aihtn_<Name> in game.

-- How stale a ::TWP::HTN line may be, in game hours. The plan itself is recomputed on
-- every call; this only throttles the log, which would otherwise repeat one line every
-- tick. A changed step always prints at once, whatever this says.
AIHTN_LOG_HOURS = 1

-- A predicate is { "Name", fn }: Name is what the HTN line prints when fn() returns
-- false, so it reads as the reason. No spaces in it - the analyzer splits fields on them.
-- A method is { name, when = { predicates }, steps = { subtasks } }; "do" is a keyword.
-- A subtask is a key of AIHTN_TASKS or a leaf tag "bf_X". Empty steps = already done.
-- Predicates inside one method may share the scratch aliases TWP_HTN / TWP_HTN2;
-- Plan drops both after every method, applied or not.

local function Ready(Alias, Timer)
	return ReadyToRepeat(Alias, Timer)
end

local function Rich(DynAlias, Least)
	return GetMoney(DynAlias) >= Least
end

AIHTN_TASKS = {
	-- Everything the blood rival can be doing to the player, best first.
	Feud = {
		{ name = "artefact", when = {
			{ "ReadyArtefacts>=1", function(d, p) local R = {} return aihtn_CountArtefacts(d, p, "character", R) >= 1 end },
		}, steps = { "bf_UseArtefact" } },
		{ name = "building", when = {
			{ "BuildingArtefact>=1", function(d, p) local R = {} return aihtn_CountArtefacts(d, p, "building", R) >= 1 end },
		}, steps = { "bf_UseBuildingArtefact" } },
		{ name = "charge", when = {}, steps = { "HaveEvidence", "bf_Charge" } },
		{ name = "attack", when = {
			{ "Allowed(thug_attack)", function(d, p) return aitwp_Allowed(d, p, "thug_attack") end },
			{ "Ready(AI_BF_Attack)", function(d) return Ready(d, "AI_BF_Attack") end },
			{ "Target(outside)", function(d, p) return aitwp_FindPlayerTarget(p, "outside", "TWP_HTN") end },
			{ "Fighters>=1", function(d)
				local Side = {}
				local N = aitwp_GatherFighters(d, "TWP_HTNF", Side, TWP_ATTACK_PARTY_MAX)
				aitwp_ClearFighters("TWP_HTNF", N)
				return N >= 1
			end },
		}, steps = { "bf_ThugAttack" } },
		{ name = "razzia", when = {
			{ "Myrmidon", function() return AliasExists("MYRM") end },
			{ "Allowed(razzia)", function(d, p) return aitwp_Allowed(d, p, "razzia") end },
			{ "Ready(AI_BF_Razzia)", function() return Ready("MYRM", "AI_BF_Razzia") end },
			{ "Evidence>=threshold", function(d, p) return GetDynastyEvidenceValues(d, p) >= TWP_BF_RAZZIA_EVIDENCE end },
		}, steps = { "bf_Razzia" } },
		{ name = "duel", when = {
			{ "Allowed(duel)", function(d, p) return aitwp_Allowed(d, p, "duel") end },
			{ "FitDuelist", function(d) return aitwp_FindFitDuelist(d, "TWP_HTN") end },
		}, steps = { "bf_Provoke" } },
		{ name = "taunt", when = {
			{ "Allowed(taunt_letter)", function(d, p) return aitwp_Allowed(d, p, "taunt_letter") end },
			{ "NotFoe", function(d, p) return DynastyGetDiplomacyState(d, p) ~= DIP_FOE end },
			{ "Ready(AI_BF_Taunt)", function() return Ready("SIM", "AI_BF_Taunt") end },
		}, steps = { "bf_Taunt" } },
		-- bf_Recruit is a method of its own, not a subtask of the attack: its gates are
		-- none of the attack's, so hanging it under one would stop the house hiring
		-- below rung 4 and for three hours after every attack.
		{ name = "gang", when = {
			{ "Ready(AI_BF_Recruit)", function(d) return Ready(d, "AI_BF_Recruit") end },
			{ "Money>=recruit", function(d) return Rich(d, TWP_BF_RECRUIT) end },
			{ "ResidenceHires", function(d)
				return aitwp_Residence(d, "TWP_HTN") and BuildingGetType("TWP_HTN") == GL_BUILDING_TYPE_RESIDENCE
					and BuildingCanHireNewWorker("TWP_HTN")
			end },
			{ "Thugs<cap", function(d) return DynastyGetWorkerCount(d, GL_PROFESSION_MYRMIDON) < 2 + GetNobilityTitle("SIM") end },
		}, steps = { "bf_Recruit" } },
		{ name = "arm", when = {
			{ "Ready(AI_BF_Equip)", function(d) return Ready(d, "AI_BF_Equip") end },
			-- aitwp_FindUnequipped only offers a piece the store actually holds, so this
			-- needs no HaveItem in front of it
			{ "Unequipped", function(d)
				local Tier = aitwp_EquipmentTier(d)
				return Tier ~= nil and aitwp_FindUnequipped(d, Tier, "TWP_HTN")
			end },
		}, steps = { "bf_Equip" } },
		{ name = "fund", when = {
			{ "Allowed(fund_allies)", function(d, p) return aitwp_Allowed(d, p, "fund_allies") end },
			{ "Ready(AI_BF_Fund)", function(d) return Ready(d, "AI_BF_Fund") end },
			{ "Money>=fund", function(d) return Rich(d, TWP_BF_FUND) end },
			{ "Ally", function(d) return aitwp_FindAllyMember(d, "TWP_HTN") end },
		}, steps = { "bf_FundAllies" } },
		{ name = "hideout", when = {
			{ "Rung>=2", function(d, p) return aitwp_Rung(d, p) >= 2 end },
			{ "Ready(AI_BF_Hideout)", function(d) return Ready(d, "AI_BF_Hideout") end },
			{ "NoThiefDen", function(d) return DynastyGetBuildingCount(d, GL_BUILDING_CLASS_WORKSHOP, GL_BUILDING_TYPE_THIEF) < 1 end },
			{ "Money>=hideout", function(d) return Rich(d, TWP_BF_HIDEOUT) end },
			{ "ResidenceTown", function(d) return aitwp_Residence(d, "TWP_HTN") and GetSettlement("TWP_HTN", "TWP_HTN2") end },
		}, steps = { "bf_Hideout" } },
		-- Last on purpose. Shopping is what the house does when it has nothing better,
		-- and it is the one method whose leaf does not act on the player at all. Putting
		-- it first (it was, briefly) made every rich house plan a cart run while it had
		-- evidence in hand and thugs to spare. bf_Procure still competes on its own
		-- weight every tick; this only decides who gets UTILITY_HTN_FACTOR.
		{ name = "restock", when = {
			{ "Ready(AI_BF_Supply)", function(d) return Ready(d, "AI_BF_Supply") end },
			{ "Money>=supply", function(d) return Rich(d, TWP_BF_SUPPLY) end },
			{ "Residence", function(d)
				return aitwp_Residence(d, "TWP_HTN") and BuildingGetType("TWP_HTN") == GL_BUILDING_TYPE_RESIDENCE
			end },
			{ "ShoppingList>0", function(d, p) local Needs = {} return aitwp_ShoppingList(d, p, Needs) > 0 end },
			{ "Cart", function(d)
				local Total, _Busy, Idle = aitwp_ResidenceCarts(d, "TWP_HTN")
				return Idle or (Total < 5 and GetMoney(d) >= TWP_BF_SUPPLY + gameplayformulas_CalcCartBuyPrice(EN_CT_HORSE))
			end },
		}, steps = { "bf_Procure" } },
	},

	-- A case that will stand up: evidence already in hand, or the forgery that makes it.
	HaveEvidence = {
		{ name = "ready", when = {
			{ "Allowed(charge)", function(d, p) return aitwp_Allowed(d, p, "charge") end },
			{ "EvidenceTarget", function(d, p) return aitwp_EvidenceTarget(d, p, "TWP_HTN") end },
			{ "CanBeCharged", function() return SimCanBeCharged("TWP_HTN") end },
			{ "Accuser>=1", function(d) return aitwp_FindAccuser(d, "TWP_HTN", "TWP_HTN2") >= 1 end },
		}, steps = {} },
		{ name = "forge", when = {
			{ "EvidenceTarget", function(d, p) return aitwp_EvidenceTarget(d, p, "TWP_HTN") end },
			{ "ForgeryDocument", function(d, p) return aitwp_ForgeryDocument("SIM", d, p) ~= nil end },
		}, steps = { "bf_ForgeEvidence" } },
	},
}

-- How many ladder artefacts are usable right now, counting the rows whose target is a
-- building ("building") or a character (anything else). One aitwp_ReadyArtefacts pass
-- answers both, so the planner and bf_UseArtefact read the same store.
function CountArtefacts(DynAlias, PlayerDyn, Kind, Out)
	local N = aitwp_ReadyArtefacts(DynAlias, PlayerDyn, "SIM", Out)
	local Hits = 0
	for i = 1, N do
		if (Kind == "building") == (Out[i].target == "building") then
			Hits = Hits + 1
		end
	end
	return Hits
end

-- Decompose Task. Appends the primitive leaf tags to Chain and, for every method that
-- did not apply, "<Task>.<method>:<Predicate>" to Fail. Returns the name of the method
-- that applied, or nil. A method that fails part-way leaves Chain as it found it: a
-- half-built chain must never leak into the method tried next.
function Plan(DynAlias, PlayerDyn, Task, Chain, Fail)
	local Methods = AIHTN_TASKS[Task]
	if not Methods then
		return nil
	end
	for m = 1, #Methods do
		local M = Methods[m]
		local Ok = true
		for w = 1, #M.when do
			local P = M.when[w]
			if not P[2](DynAlias, PlayerDyn) then
				Fail[#Fail + 1] = Task .. "." .. M.name .. ":" .. P[1]
				Ok = false
				break
			end
		end
		RemoveAlias("TWP_HTN")
		RemoveAlias("TWP_HTN2")
		if Ok then
			local Mark = #Chain
			for s = 1, #M.steps do
				local Step = M.steps[s]
				if AIHTN_TASKS[Step] then
					if not aihtn_Plan(DynAlias, PlayerDyn, Step, Chain, Fail) then
						Ok = false
						break
					end
				else
					Chain[#Chain + 1] = Step
				end
			end
			if Ok then
				return M.name
			end
			for i = #Chain, Mark + 1, -1 do
				Chain[i] = nil
			end
		end
	end
	return nil
end

-- The leaf the house should be running now, or "-" when no method applies - which
-- proves every bf_ child weighs 0, so BloodFeud.lua may skip the tick. Recomputed on
-- every call: the predicates are a subset of the leaves' own gates, so this costs at
-- most what one subtree entry costs, and a cached "-" would go stale the wrong way.
function Step(DynAlias)
	local Chain, Fail = {}, {}
	local Method = aihtn_Plan(DynAlias, "PlayerDyn", "Feud", Chain, Fail) or "-"
	local StepTag = Chain[1] or "-"
	local Was = GetProperty(DynAlias, "AI_HTN_Step")
	SetProperty(DynAlias, "AI_HTN_Step", StepTag)
	-- one line per tick would drown the log; a changed step is always worth one
	local At = GetProperty(DynAlias, "AI_HTN_At")
	if Was ~= StepTag or At == nil or GetGametime() - At >= AIHTN_LOG_HOURS then
		SetProperty(DynAlias, "AI_HTN_At", GetGametime())
		local ChainText = "-"
		for i = 1, #Chain do
			if i == 1 then
				ChainText = Chain[i]
			else
				ChainText = ChainText .. ">" .. Chain[i]
			end
		end
		local FailText = "-"
		for i = 1, #Fail do
			if i == 1 then
				FailText = Fail[i]
			else
				FailText = FailText .. ";" .. Fail[i]
			end
		end
		utility_Emit("::TWP::HTN " .. utility_Stamp(DynAlias) .. " task=Feud method=" .. Method
			.. " step=" .. StepTag .. " chain=" .. ChainText .. " fail=" .. FailText)
	end
	return StepTag
end

pcall(function()
	LogMessage("::TWP::LOADED aihtn.lua")
end)
