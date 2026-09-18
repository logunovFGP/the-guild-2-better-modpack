---
-- This script bundles the functions used in the reworked AI BaseTree of TradeWarPolitics.
-- That includes the priority calculation for dynasties and current enemy lists.
-- It may also include functions related to AI and game difficulty. 
-- 


-- -----------------------
-- Init
-- -----------------------
function Init()
 --needed for caching (or something...) 
end


--- 
-- intended to be called by ScriptCall:
-- Boolean CreateScriptcall(Name, Timer, ScriptFilename, Function, Alias ( of type simobject) pOwner)
-- CreateScriptcall("CalcAIPriorities", 1, "Library/aitwp.lua", "CalculatePriorities", "dynasty")
-- 
function CalculatePriorities(DynAlias)
	-- initialize priorities from dyn properties 
	local Political = GetProperty(DynAlias, "AITWP_Political") or 0
	local Agressive = GetProperty(DynAlias, "AITWP_Agressive") or 0
	local Intrigue = GetProperty(DynAlias, "AITWP_Intrigue") or 0
	
	-- reinitialize enemies
	local MCount, MilitaryEnemies = aitwp_InitEnemies(DynAlias)

	-- get dynasty members
	local MemberCount = DynastyGetMemberCount(DynAlias)
	local MemPolitical, MemAgressive, MemIntrigue
	for i = 0, MemberCount - 1 do
		DynastyGetMember(DynAlias, i, "Member")
		MemPolitical, MemAgressive, MemIntrigue = aitwp_CalculatePrioritiesForMember(DynAlias, "Member", MCount)
		-- factor member result into current values
		Political = aitwp_CalcNewPriority(Political, MemPolitical) 
		Agressive = aitwp_CalcNewPriority(Agressive, MemAgressive) 
		Intrigue = aitwp_CalcNewPriority(Intrigue, MemIntrigue)
	end
	SetProperty(DynAlias, "AITWP_Political", Political)
	SetProperty(DynAlias, "AITWP_Agressive", Agressive)
	SetProperty(DynAlias, "AITWP_Intrigue", Intrigue)
	-- the values are logged by aitwp_Snapshot, which Priorities.lua calls right after this
end

-- result will be <= 100
function CalcNewPriority(CurrentValue, NewValue)
	-- Diff may be positive or negative
	local Diff = math.abs(CurrentValue - NewValue) 
	-- add part of the new value directly
	local Change = math.floor(Diff / 2)
	Change = Change + Rand(Diff - Change)
	Change = math.floor(Change / 2)
	-- add or subtract change
	if NewValue > CurrentValue then
		return math.min(100, CurrentValue + Change)
	else
		return math.min(100, CurrentValue - Change)
	end
end

---
-- Each priority is a value between 0 and 100 that can be used for weighting in AI BaseTree.
function CalculatePrioritiesForMember(DynAlias, SimAlias, MCount)
	local Political = aitwp_CalcPoliticalAmbition(DynAlias, SimAlias)
	local Agressive = aitwp_CalcAgressiveness(DynAlias, SimAlias, MCount)
	local Intrigue = aitwp_CalcIntrigue(DynAlias, SimAlias, Political)
	return Political, Agressive, Intrigue	
end

---
-- Calculates current political ambition of the sim based on:
-- current office level (medium impact)
-- skill values: rhetoric, charisma (low impact)
-- game mode: political (high impact)
function CalcPoliticalAmbition(DynAlias, SimAlias)
	GetSettlement(SimAlias, "City")
	local Political = 0  
	local RhetChar = GetSkillValue(SimAlias, RHETORIC) + GetSkillValue(SimAlias, CHARISMA) -- 2 < n < 20/32
	if RhetChar >= 7 then
		Political = Political + RhetChar 
	end

	local CurrentApplication = SimIsAppliedForOffice(SimAlias) -- Boolean
	local MaxOfficeLevel = math.max(0, SimGetMaxOfficeLevel(SimAlias)) -- 0 < n < 7
	if CurrentApplication then
		Political = Political + 40
	elseif MaxOfficeLevel > 0 then -- no ambition if I can't be elected
		local HighestOfficeLevel = math.max(0, CityGetHighestOfficeLevel("City")) -- 0 < n < 7
		local OfficeLevel = math.max(0, SimGetOfficeLevel(SimAlias)) -- 0 < n < 7
		local Diff = math.min(MaxOfficeLevel, HighestOfficeLevel)
		Political = Political + (Diff * (OfficeLevel + 1))
	end
	-- game mode: political adds up to 40 points
	GetScenario("Scenario")
	local Mission = GetProperty("Scenario", "AITWP_Mission") or 99
	if Mission == 21 then
		local Difficulty = 5 - ScenarioGetDifficulty()
		Political = Political + math.floor(40 / Difficulty) -- 40 on highest, 8 on lowest difficulty
	end
	return math.min(100, Political)
end

--- 
-- Enemies should be a table of dynastyID, i.e. {1, 2, 3}
function CalcAgressiveness(DynAlias, SimAlias, Enemies)
	local Agressive = 0 
	-- more agressive if rogue class
	if GL_CLASS_CHISELER == SimGetClass(SimAlias) then
		Agressive = Agressive + 10
	end 
	-- add skill value (fighting)
	Agressive = Agressive + GetSkillValue(SimAlias, FIGHTING)
	-- more agressive if thugs are available (no more than 20 points
	local ThugCount = DynastyGetWorkerCount(DynAlias, GL_PROFESSION_MYRMIDON)
	Agressive = Agressive + math.min(4, ThugCount)
	-- current character equipment
	if GetArmor(SimAlias) > 14 or BattleGetWeaponName(SimAlias) then
		Agressive = Agressive + 5
	end
	-- current enemies (4 points each, up to 20 points)
	Agressive = Agressive + math.min(20, Enemies*4) 
	-- game mode elimination adds 40
	GetScenario("Scenario")
	local Mission = GetProperty("Scenario", "AITWP_Mission") or 99
	if Mission == 0 then
		local Difficulty = 5 - ScenarioGetDifficulty()
		Agressive = Agressive + math.floor(40 / Difficulty) -- 40 on highest, 8 on lowest difficulty
	end
	return math.min(100, Agressive)
end

function CalcIntrigue(DynAlias, SimAlias, Political)
	local Intrigue = 0
	-- up to 30 points for political ambition
	Intrigue = Intrigue + math.floor(Political * 0.3)
	-- current values of stealth and secret knowledge (up to 20)
	local Skill = GetSkillValue(SimAlias, SHADOW_ARTS) + GetSkillValue(SimAlias, SECRET_KNOWLEDGE)
	Intrigue = Intrigue + math.min(20, Skill)
	
	-- game mode accuser (adds 30)
	GetScenario("Scenario")
	local Mission = GetProperty("Scenario", "AITWP_Mission") or 99
	if Mission == 22 then
		local Difficulty = 5 - ScenarioGetDifficulty()
		Intrigue = Intrigue + math.floor(30 / Difficulty) -- 30 on highest, 6 on lowest difficulty
	end
	return math.min(100, Intrigue)
end

---
-- This will read current enemy selection from properties and return Count and List of the current military enemies
-- It will also initialize the lists if necessary.
function GetCurrentEnemies(DynAlias)
	local Enemies = GetProperty(DynAlias, "AITWP_Enemies") or aitwp_InitEnemies(DynAlias)
	local MCount, ME = helpfuncs_StringToIdList(Enemies)
	return MCount, ME
end

function GetRandomEnemy(DynAlias)
	local Count, Enemies = aitwp_GetCurrentEnemies(DynAlias)
	if Count > 0 then
		return Enemies[Rand(Count)+1]
	end
	return -1
end

---
-- The enemy worth feuding with now: the least liked living one, a declared foe
-- before a neutral, a coloured dynasty before a shadow, and the goal target
-- (AI_GoalTarget) above all so a started feud is followed through.
-- Returns a dynasty id, or -1 when the list holds nobody alive.
function GetBestEnemy(DynAlias)
	local Count, Enemies = aitwp_GetCurrentEnemies(DynAlias)
	local GoalTarget = GetProperty(DynAlias, "AI_GoalTarget") or 0
	local Blood = GetProperty(DynAlias, "AI_BloodEnemyOf") or 0
	local BestID, BestScore = -1, nil
	local Cands = ""
	for i = 1, Count do
		local ID = Enemies[i]
		if GetAliasByID(ID, "TWP_Enemy") and AliasExists("TWP_Enemy") and not DynastyIsDead("TWP_Enemy") then
			local Favor = GetFavorToDynasty(DynAlias, "TWP_Enemy")
			local Foe = DynastyGetDiplomacyState(DynAlias, "TWP_Enemy") == DIP_FOE
			local Shadow = DynastyIsShadow("TWP_Enemy")
			local Score = 100 - Favor
			if Foe then
				Score = Score + 50
			end
			if Shadow then
				Score = Score - 30
			end
			if ID == GoalTarget then
				Score = Score + 100
			end
			if ID == Blood then
				Score = Score + 1000
			end
			if BestScore == nil or Score > BestScore then
				BestID, BestScore = ID, Score
			end
			Cands = Cands .. ID .. ":" .. Favor .. ":" .. (Foe and 1 or 0) .. ":" .. (Shadow and 1 or 0) .. ";"
		end
	end
	RemoveAlias("TWP_Enemy")
	if utility_LogEnabled() then
		utility_Emit("::TWP::ENEMY " .. utility_Stamp(DynAlias) .. " goaltarget=" .. GoalTarget .. " cand=" .. Cands .. " pick=" .. BestID)
	end
	return BestID
end

---
-- Picks a building owned by OwnerAlias (a dynasty or one of its sims) into OutAlias.
-- Class filters by building class, -1 for any; resources are never returned.
-- Mode "strongest" takes the highest level (workshops first) - the target that
-- hurts most; "weakest" the lowest - the one to give up in a forced sale.
-- Ties fall to the lower index, so every peer picks the same building.
-- Settlement (optional): only buildings in that town (a sim, building or town alias).
function FindTargetBuilding(OwnerAlias, Class, Mode, OutAlias, Settlement)
	local Owner = OwnerAlias
	local Count = DynastyGetBuildingCount2(Owner) or 0
	-- a sim alias may not enumerate; fall back to the sim's dynasty
	if Count == 0 and GetDynasty(OwnerAlias, "TWP_Owner") then
		Owner = "TWP_Owner"
		Count = DynastyGetBuildingCount2(Owner) or 0
	end
	local Best, BestScore = -1, nil
	local Cands = ""
	for i = 0, Count - 1 do
		if DynastyGetBuilding2(Owner, i, "TWP_Bld") then
			local BClass = BuildingGetClass("TWP_Bld")
			local Level = BuildingGetLevel("TWP_Bld")
			Cands = Cands .. i .. ":" .. BClass .. ":" .. Level .. ";"
			if BClass ~= GL_BUILDING_CLASS_RESOURCE and (Class == -1 or BClass == Class)
					and (Settlement == nil or GetSettlementID("TWP_Bld") == GetSettlementID(Settlement)) then
				local Score = Level * 10
				if BClass == GL_BUILDING_CLASS_WORKSHOP then
					Score = Score + 5
				end
				if Mode == "weakest" then
					Score = -Score
				end
				if BestScore == nil or Score > BestScore then
					Best, BestScore = i, Score
				end
			end
		end
	end
	RemoveAlias("TWP_Bld")
	if utility_LogEnabled() then
		utility_Emit("::TWP::BLD t=" .. string.format("%.2f", GetGametime()) .. " owner=" .. GetID(Owner)
			.. " mode=" .. Mode .. " class=" .. Class .. " cand=" .. Cands .. " pick=" .. Best)
	end
	local Found = false
	if Best >= 0 then
		Found = DynastyGetBuilding2(Owner, Best, OutAlias)
	end
	RemoveAlias("TWP_Owner")
	return Found
end


-- The house's residence, from a dynasty alias or one of its sims. GetHomeBuilding is
-- documented for sims and carts only (engine.d.lua: pObject is cl_Sim/cl_Cart), so a
-- dynasty alias cannot be relied on there and every store, cart, market and courier
-- lookup below goes through here instead. The fallback is the best living room, which
-- is what aitwp_OwnBuilding already resolves for BuildHome and EducateChildren.
function Residence(Alias, OutAlias)
	if GetHomeBuilding(Alias, OutAlias) and BuildingGetType(OutAlias) == GL_BUILDING_TYPE_RESIDENCE then
		return true
	end
	return aitwp_OwnBuilding(Alias, GL_BUILDING_CLASS_LIVINGROOM, GL_BUILDING_TYPE_RESIDENCE, OutAlias)
end

-- The house's own building of Class and Type (-1 for any) into OutAlias: the highest
-- level, ties to the lower index. The deterministic stand-in for DynastyGetRandomBuilding
-- wherever a node needs "one of ours" - Alias may be the dynasty or one of its sims.
function OwnBuilding(Alias, Class, Type, OutAlias)
	if not aitwp_ResolveDynasty(Alias, "TWP_OB") then
		return false
	end
	local Best, BestLevel = -1, -1
	local Count = DynastyGetBuildingCount2("TWP_OB") or 0
	for i = 0, Count - 1 do
		if DynastyGetBuilding2("TWP_OB", i, "TWP_OBB")
				and (Class == -1 or BuildingGetClass("TWP_OBB") == Class)
				and (Type == -1 or BuildingGetType("TWP_OBB") == Type) then
			local Level = BuildingGetLevel("TWP_OBB") or 0
			if Level > BestLevel then
				Best, BestLevel = i, Level
			end
		end
	end
	RemoveAlias("TWP_OBB")
	local Found = false
	if Best >= 0 then
		Found = DynastyGetBuilding2("TWP_OB", Best, OutAlias)
	end
	RemoveAlias("TWP_OB")
	return Found
end

-- Like OwnBuilding, but for a chore that must visit every building of the kind over
-- time (hourly protection, debt collection): the buildings take turns, the counter
-- AI_Turn_<Key> on the dynasty says whose turn it is. Deterministic, no dice.
function OwnBuildingByTurn(Alias, Class, Type, OutAlias, Key)
	if not aitwp_ResolveDynasty(Alias, "TWP_OT") then
		return false
	end
	local Matches, N = {}, 0
	local Count = DynastyGetBuildingCount2("TWP_OT") or 0
	for i = 0, Count - 1 do
		if DynastyGetBuilding2("TWP_OT", i, "TWP_OTB")
				and (Class == -1 or BuildingGetClass("TWP_OTB") == Class)
				and (Type == -1 or BuildingGetType("TWP_OTB") == Type) then
			N = N + 1
			Matches[N] = i
		end
	end
	RemoveAlias("TWP_OTB")
	local Found = false
	if N > 0 then
		local Turn = GetProperty("TWP_OT", "AI_Turn_" .. Key) or 0
		Found = DynastyGetBuilding2("TWP_OT", Matches[math.mod(Turn, N) + 1], OutAlias)
		SetProperty("TWP_OT", "AI_Turn_" .. Key, Turn + 1)
	end
	RemoveAlias("TWP_OT")
	return Found
end

-- The most damaged building of Alias's dynasty into OutAlias; returns its relative
-- health (1 when it has no buildings). A full scan, not five dice rolls.
function MostDamagedBuilding(Alias, OutAlias)
	local Worst = 1.0
	if not aitwp_ResolveDynasty(Alias, "TWP_MD") then
		return Worst
	end
	local Best = -1
	local Count = DynastyGetBuildingCount2("TWP_MD") or 0
	for i = 0, Count - 1 do
		if DynastyGetBuilding2("TWP_MD", i, "TWP_MDB") then
			local HP = GetHPRelative("TWP_MDB")
			if HP and HP < Worst then
				Worst, Best = HP, i
			end
		end
	end
	RemoveAlias("TWP_MDB")
	if Best >= 0 then
		DynastyGetBuilding2("TWP_MD", Best, OutAlias)
	end
	RemoveAlias("TWP_MD")
	return Worst
end

---
-- Picks the second party ("Believer") of a favour-wrecking action against VictimAlias.
-- Candidates are living dynasties other than the actor's and the victim's whose
-- favour from FavorFrom is at most MaxFavor (the bound DynastyGetRandomVictim used).
-- Mode "office": the member holding the highest office, ties by how much the victim
-- likes that dynasty - a favour hit there costs the victim votes.
-- Mode "friend": the dynasty the victim likes most - the rift that hurts most.
-- Sets OutDyn and OutSim; returns true on success.
function FindBeliever(ActorAlias, VictimAlias, FavorFrom, MaxFavor, Mode, OutDyn, OutSim)
	local MyID = GetDynastyID(ActorAlias)
	local VictimID = GetDynastyID(VictimAlias)
	local Count = ScenarioGetObjects("cl_Dynasty", 99, "TWP_Cand")
	local BestDyn, BestSim, BestScore = -1, -1, nil
	local Cands = ""
	for i = 0, Count - 1 do
		local Dyn = "TWP_Cand" .. i
		local DynID = GetID(Dyn)
		if DynID ~= MyID and DynID ~= VictimID and not DynastyIsDead(Dyn) then
			local FromFavor = GetFavorToDynasty(FavorFrom, Dyn)
			local Liking = GetFavorToDynasty(VictimAlias, Dyn)
			local MaxOffice = -1
			if FromFavor <= MaxFavor then
				local Members = DynastyGetMemberCount(Dyn)
				for m = 0, Members - 1 do
					if DynastyGetMember(Dyn, m, "TWP_Member") and not GetState("TWP_Member", STATE_DEAD) then
						local Office = math.max(0, SimGetOfficeLevel("TWP_Member"))
						MaxOffice = math.max(MaxOffice, Office)
						local Score = Liking
						if Mode == "office" then
							Score = Office * 1000 + Liking
						end
						if BestScore == nil or Score > BestScore then
							BestDyn, BestSim, BestScore = i, m, Score
						end
					end
				end
			end
			Cands = Cands .. DynID .. ":" .. FromFavor .. ":" .. Liking .. ":" .. MaxOffice .. ";"
		end
	end
	RemoveAlias("TWP_Member")
	local PickID = -1
	if BestDyn >= 0 then
		PickID = GetID("TWP_Cand" .. BestDyn)
		CopyAlias("TWP_Cand" .. BestDyn, OutDyn)
		DynastyGetMember(OutDyn, BestSim, OutSim)
	end
	for i = 0, Count - 1 do
		RemoveAlias("TWP_Cand" .. i)
	end
	if utility_LogEnabled() then
		utility_Emit("::TWP::BELIEVER t=" .. string.format("%.2f", GetGametime()) .. " actor=" .. MyID .. " victim=" .. VictimID
			.. " mode=" .. Mode .. " maxfavor=" .. MaxFavor .. " cand=" .. Cands .. " pick=" .. PickID)
	end
	return BestDyn >= 0 and AliasExists(OutSim)
end

---
-- One line per dynasty per game day, parsed by tools/modding_helpers/ai_telemetry.py.
-- Space-separated key=value pairs; the free-text name is last on purpose.
function Snapshot(DynAlias)
	local Members = DynastyGetMemberCount(DynAlias)
	local Title, Office = 0, -1
	local DynID = GetID(DynAlias)
	for i = 0, Members - 1 do
		if DynastyGetMember(DynAlias, i, "TWP_Snap") then
			Title = math.max(Title, GetNobilityTitle("TWP_Snap") or 0)
			Office = math.max(Office, SimGetOfficeLevel("TWP_Snap") or -1)
			-- lets the parser map the engine's "Executing Measures ... on <sim>" lines to a dynasty
			utility_Emit("::TWP::MEMBER dyn=" .. DynID .. " sim=" .. GetName("TWP_Snap"))
		end
	end
	RemoveAlias("TWP_Snap")
	local EnemyCount = aitwp_GetCurrentEnemies(DynAlias)
	local Att, Ladder = "-", -1
	if aitwp_FirstPlayer("TWP_SnapP") then
		Att = aitwp_Attitude(DynAlias, "TWP_SnapP")
		Ladder = aitwp_Rung(DynAlias, "TWP_SnapP")
		RemoveAlias("TWP_SnapP")
	end
	utility_Emit("::TWP::SNAPSHOT t=" .. math.floor(GetGametime()) .. " round=" .. GetRound()
		.. " att=" .. Att .. " rung=" .. Ladder
		.. " diff=" .. ScenarioGetDifficulty()
		.. " dyn=" .. GetID(DynAlias) .. " persona=" .. (GetProperty(DynAlias, "AI_PERSONA") or -1)
		.. " money=" .. math.floor(GetMoney(DynAlias) or 0)
		.. " bld=" .. DynastyGetBuildingCount(DynAlias, -1, -1)
		.. " ws=" .. DynastyGetBuildingCount(DynAlias, GL_BUILDING_CLASS_WORKSHOP, -1)
		.. " members=" .. Members .. " title=" .. Title .. " office=" .. Office
		.. " rank=" .. (DynastyGetRanking(DynAlias) or 0) .. " enemies=" .. EnemyCount
		.. " P=" .. aitwp_GetPoliticalAmbititon(DynAlias) .. " A=" .. aitwp_GetAgressiveness(DynAlias)
		.. " I=" .. aitwp_GetIntrigue(DynAlias)
		.. " goal=" .. (GetProperty(DynAlias, "AI_Goal") or "-")
		.. " target=" .. (GetProperty(DynAlias, "AI_GoalTarget") or 0)
		.. " ticks=" .. utility_TakeTicks(DynAlias)
		.. " name=" .. GetName(DynAlias))
end

-- ---------------------------------------------------------------------------
-- House rules: class binding, the fighter, education, enemies from relations
-- ---------------------------------------------------------------------------

---
-- AI_MainClass is the class a dynasty steers its children into and expands its
-- business in: the class of its first living party member, decided once.
-- Class ids: 1 patron, 2 artisan, 3 scholar, 4 rogue (GL_CLASS_CHISELER).
function MainClass(DynAlias)
	local Class = GetProperty(DynAlias, "AI_MainClass") or 0
	if Class >= 1 and Class <= 4 then
		return Class
	end
	Class = GL_CLASS_ARTISAN
	local Count = DynastyGetMemberCount(DynAlias)
	for i = 0, Count - 1 do
		if DynastyGetMember(DynAlias, i, "TWP_Cls") and not GetState("TWP_Cls", STATE_DEAD) then
			local C = SimGetClass("TWP_Cls")
			if C >= 1 and C <= 4 then
				Class = C
				break
			end
		end
	end
	RemoveAlias("TWP_Cls")
	SetProperty(DynAlias, "AI_MainClass", Class)
	return Class
end

-- Rogues the house can count on: living family members of class 4 plus children
-- already steered into a rogue apprenticeship (AI_ApprenticeClass == 4).
function CountRogues(DynAlias)
	local Rogues = 0
	local MyID = GetID(DynAlias)
	local Count = DynastyGetFamilyMemberCount(DynAlias)
	for i = 0, Count - 1 do
		if DynastyGetFamilyMember(DynAlias, i, "TWP_Rog") and GetDynastyID("TWP_Rog") == MyID and not GetState("TWP_Rog", STATE_DEAD) then
			if SimGetClass("TWP_Rog") == GL_CLASS_CHISELER or (GetProperty("TWP_Rog", "AI_ApprenticeClass") or 0) == GL_CLASS_CHISELER then
				Rogues = Rogues + 1
			end
		end
	end
	RemoveAlias("TWP_Rog")
	return Rogues
end

-- The class a child is apprenticed into: the main class, except that the house
-- always keeps at least one rogue as its fighter - two as somebody's blood enemy.
function WantedApprenticeClass(DynAlias)
	local Needed = 1
	if (GetProperty(DynAlias, "AI_BloodEnemyOf") or 0) > 0 then
		Needed = 2
	end
	if aitwp_CountRogues(DynAlias) < Needed then
		return GL_CLASS_CHISELER
	end
	return aitwp_MainClass(DynAlias)
end

-- The member who builds and runs new workshops: an idle member of the main class,
-- else any idle member, else anyone. Sets OutAlias; returns true on success.
function FindBuilder(DynAlias, OutAlias)
	local Main = aitwp_MainClass(DynAlias)
	local Count = DynastyGetMemberCount(DynAlias)
	for i = 0, Count - 1 do
		if DynastyGetMember(DynAlias, i, "TWP_Bldr") and dyn_IsIdleMember("TWP_Bldr") and SimGetClass("TWP_Bldr") == Main then
			CopyAlias("TWP_Bldr", OutAlias)
			RemoveAlias("TWP_Bldr")
			return true
		end
	end
	RemoveAlias("TWP_Bldr")
	if dyn_GetIdleMember(DynAlias, OutAlias) then
		return true
	end
	return DynastyGetMemberRandom(DynAlias, OutAlias) and AliasExists(OutAlias)
end

---
-- Daily enemy list from relations instead of the one-off random draw: the blood
-- target, the trade rival, declared foes, dynasties this one dislikes, and the
-- living entries of the current list. Deterministic order, capped at 5.
function RefreshEnemies(DynAlias)
	local MyID = GetID(DynAlias)
	local IDs, N = {}, 0
	local function add(ID)
		if not ID or ID <= 0 or ID == MyID or N >= 5 then
			return
		end
		for i = 1, N do
			if IDs[i] == ID then
				return
			end
		end
		N = N + 1
		IDs[N] = ID
	end
	add(GetProperty(DynAlias, "AI_BloodEnemyOf") or 0)
	add(GetProperty(DynAlias, "RivalID") or 0)
	local Total = ScenarioGetObjects("cl_Dynasty", 99, "TWP_RD")
	for i = 0, Total - 1 do
		local D = "TWP_RD" .. i
		if GetID(D) ~= MyID and not DynastyIsDead(D) and DynastyGetDiplomacyState(DynAlias, D) == DIP_FOE then
			add(GetID(D))
		end
	end
	for i = 0, Total - 1 do
		local D = "TWP_RD" .. i
		if GetID(D) ~= MyID and not DynastyIsDead(D) and GetFavorToDynasty(DynAlias, D) < 30 then
			add(GetID(D))
		end
	end
	local Count, Old = aitwp_GetCurrentEnemies(DynAlias)
	for i = 1, Count do
		if GetAliasByID(Old[i], "TWP_RE") and AliasExists("TWP_RE") and not DynastyIsDead("TWP_RE") then
			add(Old[i])
		end
	end
	RemoveAlias("TWP_RE")
	for i = 0, Total - 1 do
		RemoveAlias("TWP_RD" .. i)
	end
	local Text = ""
	for i = 1, N do
		Text = Text .. IDs[i] .. ","
	end
	SetProperty(DynAlias, "AITWP_Enemies", Text)
	return N
end

-- ---------------------------------------------------------------------------
-- The blood feud
-- ---------------------------------------------------------------------------

---
-- One coloured AI dynasty per human player is that player's blood enemy: it keeps
-- the Conflict goal, targets the player and runs the BloodFeud subtree. Idempotent
-- and deterministic (the coloured dynasty that likes the player least, ties by
-- position), so every peer and every daily run agrees. Properties: AI_BloodEnemy
-- on the player dynasty (AI id), AI_BloodEnemyOf on the AI dynasty (player id).
function EnsureBloodEnemies()
	local Count = ScenarioGetObjects("cl_Dynasty", 99, "TWP_BE")
	for p = 0, Count - 1 do
		local Player = "TWP_BE" .. p
		if DynastyIsPlayer(Player) and not DynastyIsDead(Player) then
			local PlayerID = GetID(Player)
			local Current = GetProperty(Player, "AI_BloodEnemy") or 0
			local Valid = Current > 0 and GetAliasByID(Current, "TWP_BEcur") and AliasExists("TWP_BEcur")
				and not DynastyIsDead("TWP_BEcur") and (GetProperty("TWP_BEcur", "AI_BloodEnemyOf") or 0) == PlayerID
			if not Valid then
				local Best, BestScore = -1, nil
				-- coloured dynasties first; a shadow only once every coloured one is gone
				for pass = 1, 2 do
					for c = 0, Count - 1 do
						local Cand = "TWP_BE" .. c
						if Best < 0 or pass == 1 then
							if c ~= p and not DynastyIsPlayer(Cand) and not DynastyIsDead(Cand)
									and DynastyIsShadow(Cand) == (pass == 2)
									and (GetProperty(Cand, "AI_BloodEnemyOf") or 0) == 0 then
								local Score = GetFavorToDynasty(Cand, Player)
								if BestScore == nil or Score < BestScore then
									Best, BestScore = c, Score
								end
							end
						end
					end
				end
				if Best >= 0 then
					local Cand = "TWP_BE" .. Best
					SetProperty(Player, "AI_BloodEnemy", GetID(Cand))
					SetProperty(Cand, "AI_BloodEnemyOf", PlayerID)
					utility_Emit("::TWP::BLOODENEMY player=" .. PlayerID .. " enemy=" .. GetID(Cand) .. " name=" .. GetName(Cand))
				end
			end
		end
	end
	RemoveAlias("TWP_BEcur")
	for i = 0, Count - 1 do
		RemoveAlias("TWP_BE" .. i)
	end
end

-- Daily chores of a blood enemy: the 1-in-4 roll that allows duelling the player's
-- rogues today (AI_BF_DuelRogues).
function BloodDaily(DynAlias)
	if (GetProperty(DynAlias, "AI_BloodEnemyOf") or 0) > 0 then
		local Roll = 0
		if Rand(4) == 0 then
			Roll = 1
		end
		SetProperty(DynAlias, "AI_BF_DuelRogues", Roll)
		if GetAliasByID(GetProperty(DynAlias, "AI_BloodEnemyOf"), "TWP_BDP") then
			aitwp_ReturnUnused(DynAlias)
			aitwp_ReserveProduction(DynAlias, "TWP_BDP")
			aitwp_CourierOrders(DynAlias, "TWP_BDP")
			aitwp_MarketReport(DynAlias, "TWP_BDP")
			RemoveAlias("TWP_BDP")
		end
	end
end

-- The duel rule: never provoke or accept with martial arts and dexterity both under
-- 5, or under 80% health - that duel is a death.
function IsFitToDuel(Alias)
	if GetHPRelative(Alias) < 0.8 then
		return false
	end
	return GetSkillValue(Alias, FIGHTING) >= 5 or GetSkillValue(Alias, DEXTERITY) >= 5
end

-- An idle adult party member fit to duel: rogues first, then the best fighter.
function FindFitDuelist(DynAlias, OutAlias)
	local Best, BestScore = -1, nil
	local Count = DynastyGetMemberCount(DynAlias)
	for i = 0, Count - 1 do
		if DynastyGetMember(DynAlias, i, "TWP_Duel") and dyn_IsIdleMember("TWP_Duel") and SimGetAge("TWP_Duel") >= 16
				and ReadyToRepeat("TWP_Duel", "AI_Insult") and aitwp_IsFitToDuel("TWP_Duel") then
			local Score = GetSkillValue("TWP_Duel", FIGHTING) + GetSkillValue("TWP_Duel", DEXTERITY) / 2
			if SimGetClass("TWP_Duel") == GL_CLASS_CHISELER then
				Score = Score + 100
			end
			if BestScore == nil or Score > BestScore then
				Best, BestScore = i, Score
			end
		end
	end
	RemoveAlias("TWP_Duel")
	if Best < 0 then
		return false
	end
	return DynastyGetMember(DynAlias, Best, OutAlias)
end

-- A rough outer edge for a settlement, not its boundary: the engine states none, towns
-- grow with their level, and every map lays them out differently. Both numbers are
-- knobs - too small and thugs brawl on the market, too large and they never engage.
TWP_TOWN_RADIUS = 8000
TWP_TOWN_RADIUS_PER_LEVEL = 1200
function TownRadius(CityAlias)
	return TWP_TOWN_RADIUS + TWP_TOWN_RADIUS_PER_LEVEL * math.max(0, CityGetLevel(CityAlias) or 0)
end

-- Outdoors and past that edge: on the road, in the fields, at the mine - where a party
-- of thugs can reach someone without the town watching.
function IsOutsideTown(Alias)
	if SimIsInside(Alias) then
		return false
	end
	if not GetNearestSettlement(Alias, "TWP_Town") then
		return true
	end
	local Far = GetDistance(Alias, "TWP_Town") > aitwp_TownRadius("TWP_Town")
	RemoveAlias("TWP_Town")
	return Far
end

-- Someone the town guard already wants. Attacking a felon is not what brings the watch
-- down on a house - the same test ms_FightArrest uses to spot one.
function IsWanted(Alias)
	if not GetNearestSettlement(Alias, "TWP_WC") then
		return false
	end
	local Wanted = false
	if CityGetPenalty("TWP_WC", Alias, PENALTY_UNKNOWN, true, "TWP_WP") then
		Wanted = true
	end
	RemoveAlias("TWP_WP")
	RemoveAlias("TWP_WC")
	return Wanted
end

-- A member of the house holding, in that town, the office privilege the game itself uses
-- for this. ps_hauptmann, ps_marschall, ps_obrist and ps_weibel hand out "CommandCityGuard"
-- through chr_SetOfficeImpactList, and the engine's own filters gate every guard order on
-- it (Filter.dbt: CanUseCityGuard, CanDetainCharacterCityGuard). Whoever holds it can have
-- the watch looking the other way.
TWP_GUARD_PRIVILEGE = "CommandCityGuard"
function CommandsGuards(DynAlias, CityAlias)
	local Found = false
	local Count = DynastyGetMemberCount(DynAlias)
	for i = 0, Count - 1 do
		if not Found and DynastyGetMember(DynAlias, i, "TWP_GO")
				and (GetImpactValue("TWP_GO", TWP_GUARD_PRIVILEGE) or 0) > 0
				and SimGetCityOfOffice("TWP_GO", "TWP_GOC")
				and GetID("TWP_GOC") == GetID(CityAlias) then
			Found = true
		end
	end
	RemoveAlias("TWP_GOC")
	RemoveAlias("TWP_GO")
	return Found
end

-- May this house start a fight where the victim is standing? Out of town, always.
-- Inside a settlement only when the watch has no reason to step in: the victim is
-- already wanted, or the house holds the office that commands the watch there.
function MayAttackHere(DynAlias, VictimAlias)
	-- Indoors is indoors, whoever the victim is. A party cannot reach someone through a
	-- wall, and the order stands while they stay in. IsOutsideTown below already implies
	-- this, but the wanted and commands-guards paths said yes without ever asking, so an
	-- attack could be ordered on a player character sitting inside a building.
	if SimIsInside(VictimAlias) then
		return false
	end
	if aitwp_IsOutsideTown(VictimAlias) then
		return true
	end
	if aitwp_IsWanted(VictimAlias) then
		return true
	end
	if not GetNearestSettlement(VictimAlias, "TWP_MAC") then
		return false
	end
	local Ok = aitwp_CommandsGuards(DynAlias, "TWP_MAC")
	RemoveAlias("TWP_MAC")
	return Ok
end

-- Scores one player sim for FindPlayerTarget; nil means not eligible for the mode.
function PlayerTargetScore(Alias, Mode)
	if GetState(Alias, STATE_DEAD) or GetState(Alias, STATE_DYING) then
		return nil
	end
	if Mode == "best" then
		return GetNobilityTitle(Alias) * 10 + math.max(0, SimGetOfficeLevel(Alias)) * 15
			+ GetSkillValue(Alias, RHETORIC) + GetSkillValue(Alias, CHARISMA) + GetSkillValue(Alias, BARGAINING) + GetSkillValue(Alias, EMPATHY)
	elseif Mode == "duel" or Mode == "rogue" then
		local IsRogue = SimGetClass(Alias) == GL_CLASS_CHISELER
		if IsRogue ~= (Mode == "rogue") or SimIsInside(Alias) or SimGetAge(Alias) < 16 then
			return nil
		end
		return -(GetSkillValue(Alias, FIGHTING) + GetSkillValue(Alias, CONSTITUTION) / 2 + GetSkillValue(Alias, DEXTERITY) / 2)
	end
	if not aitwp_IsOutsideTown(Alias) then
		return nil
	end
	return -GetHP(Alias)
end

---
-- Player-side target for the blood feud. Mode:
--   "best"    the most valuable party member (title, office, social talents): evidence goes here
--   "duel"    a non-rogue party member outdoors, the weakest fighter first
--   "rogue"   a rogue party member outdoors, the weakest fighter first
--   "outside" any party member or employee outdoors and away from town: an ambush target
-- Sets OutAlias, returns true on success. Deterministic: ties fall to the lower index.
function FindPlayerTarget(PlayerDyn, Mode, OutAlias)
	local Best, BestScore, BestWorker = -1, nil, false
	local Count = DynastyGetMemberCount(PlayerDyn)
	for i = 0, Count - 1 do
		if DynastyGetMember(PlayerDyn, i, "TWP_PT") then
			local Score = aitwp_PlayerTargetScore("TWP_PT", Mode)
			if Score and (BestScore == nil or Score > BestScore) then
				Best, BestScore, BestWorker = i, Score, false
			end
		end
	end
	if Mode == "outside" then
		Count = DynastyGetWorkerCount(PlayerDyn, -1)
		for i = 0, Count - 1 do
			if DynastyGetWorker(PlayerDyn, -1, i, "TWP_PT") then
				local Score = aitwp_PlayerTargetScore("TWP_PT", Mode)
				if Score and (BestScore == nil or Score > BestScore) then
					Best, BestScore, BestWorker = i, Score, true
				end
			end
		end
	end
	RemoveAlias("TWP_PT")
	if Best < 0 then
		return false
	end
	if BestWorker then
		return DynastyGetWorker(PlayerDyn, -1, Best, OutAlias)
	end
	return DynastyGetMember(PlayerDyn, Best, OutAlias)
end

-- The fixed evidence target (AI_EvidenceTarget): kept while it lives and still
-- belongs to the player, otherwise the player's best character is chosen anew.
function EvidenceTarget(DynAlias, PlayerDyn, OutAlias)
	local ID = GetProperty(DynAlias, "AI_EvidenceTarget") or 0
	if ID > 0 and GetAliasByID(ID, OutAlias) and AliasExists(OutAlias)
			and not GetState(OutAlias, STATE_DEAD) and GetDynastyID(OutAlias) == GetID(PlayerDyn) then
		return true
	end
	if not aitwp_FindPlayerTarget(PlayerDyn, "best", OutAlias) then
		return false
	end
	SetProperty(DynAlias, "AI_EvidenceTarget", GetID(OutAlias))
	return true
end

-- The forgery the SIM can use now: a Hexerdokument it holds or the store can hand over
-- (II before I). nil when neither; the feud cart brings the papers, nobody walks.
function ForgeryDocument(SimAlias, DynAlias, PlayerDyn)
	local Documents = { "HexerdokumentII", "HexerdokumentI" }
	local Tools = { "forge2", "forge1" }
	for i = 1, 2 do
		local Item = Documents[i]
		if aitwp_Allowed(DynAlias, PlayerDyn, Tools[i]) and GetRepeatTimerLeft(SimAlias, GetMeasureRepeatName2("Use" .. Item)) <= 0 then
			if GetItemCount(SimAlias, Item, INVENTORY_STD) > 0 then
				return Item
			end
			if aitwp_InStore(DynAlias, Item) and aitwp_CanHandOver(DynAlias, SimAlias) then
				return Item
			end
		end
	end
	return nil
end

-- The idle party member holding the most evidence against Victim; sets OutAlias
-- and returns that value (0 when nobody holds any).
function FindAccuser(DynAlias, Victim, OutAlias)
	local Best, BestValue = -1, 0
	local Count = DynastyGetMemberCount(DynAlias)
	for i = 0, Count - 1 do
		if DynastyGetMember(DynAlias, i, "TWP_Acc") and dyn_IsIdleMember("TWP_Acc") and ReadyToRepeat("TWP_Acc", "AI_ChargeCharacter") then
			local Value = GetEvidenceValues("TWP_Acc", Victim) or 0
			if Value > BestValue then
				Best, BestValue = i, Value
			end
		end
	end
	RemoveAlias("TWP_Acc")
	if Best >= 0 then
		DynastyGetMember(DynAlias, Best, OutAlias)
	end
	return BestValue
end

---
-- Equipment tiers by the head's nobility title, each gated by the treasury, and
-- the ladders that say what counts as "at least" a piece.
TWP_EQUIPMENT = {
	{ title = 0, money = 5000, weapon = "Dagger", armor = "LeatherArmor" },
	{ title = 4, money = 20000, weapon = "Shortsword", armor = "Chainmail", head = "IronCap" },
	{ title = 7, money = 60000, weapon = "Longsword", armor = "Platemail", head = "FullHelmet" },
}
TWP_LADDER = {
	weapon = { "Dagger", "Shortsword", "Mace", "Longsword", "Axe" },
	armor = { "LeatherArmor", "Chainmail", "Platemail" },
	head = { "IronCap", "FullHelmet" },
}

function EquipmentTier(DynAlias)
	local Title = 0
	local Count = DynastyGetMemberCount(DynAlias)
	for i = 0, Count - 1 do
		if DynastyGetMember(DynAlias, i, "TWP_Ttl") then
			Title = math.max(Title, GetNobilityTitle("TWP_Ttl") or 0)
		end
	end
	RemoveAlias("TWP_Ttl")
	local Money = GetMoney(DynAlias)
	local Tier = nil
	for i = 1, #TWP_EQUIPMENT do
		if Title >= TWP_EQUIPMENT[i].title and Money >= TWP_EQUIPMENT[i].money then
			Tier = TWP_EQUIPMENT[i]
		end
	end
	return Tier
end

-- true when Alias carries Item or anything above it on its ladder
function HasAtLeast(Alias, Slot, Item)
	local Ladder = TWP_LADDER[Slot]
	local From = 1
	for i = 1, #Ladder do
		if Ladder[i] == Item then
			From = i
		end
	end
	for i = From, #Ladder do
		if GetItemCount(Alias, Ladder[i], INVENTORY_EQUIPMENT) > 0 or GetItemCount(Alias, Ladder[i], INVENTORY_STD) > 0 then
			return true
		end
	end
	return false
end

-- The first piece of the tier that Alias lacks: item name and "weapon"/"armor".
function MissingEquipment(Alias, Tier)
	if not aitwp_HasAtLeast(Alias, "weapon", Tier.weapon) then
		return Tier.weapon, "weapon"
	end
	if not aitwp_HasAtLeast(Alias, "armor", Tier.armor) then
		return Tier.armor, "armor"
	end
	if Tier.head and not aitwp_HasAtLeast(Alias, "head", Tier.head) then
		return Tier.head, "armor"
	end
	return nil
end

-- Someone in the house lacking a piece of the tier that the residence holds (the
-- feud cart brought it): party members, thugs and employees alike. Sets OutAlias
-- and data EquipItem; true on success. Nobody walks to the smithy any more
-- (session 2: eight armour trips by one member, no armour).
function FindUnequipped(DynAlias, Tier, OutAlias)
	if not aitwp_Residence(DynAlias, "TWP_EqH") then
		return false
	end
	local Found = false
	local Count = DynastyGetMemberCount(DynAlias)
	for i = 0, Count - 1 do
		if not Found and DynastyGetMember(DynAlias, i, "TWP_Eq") and SimGetAge("TWP_Eq") >= 16 then
			local Item = aitwp_MissingEquipment("TWP_Eq", Tier)
			if Item and GetItemCount("TWP_EqH", Item, INVENTORY_STD) > 0 then
				CopyAlias("TWP_Eq", OutAlias)
				SetData("EquipItem", Item)
				Found = true
			end
		end
	end
	Count = DynastyGetWorkerCount(DynAlias, -1)
	for i = 0, Count - 1 do
		if not Found and DynastyGetWorker(DynAlias, -1, i, "TWP_Eq") then
			local Item = aitwp_MissingEquipment("TWP_Eq", Tier)
			if Item and GetItemCount("TWP_EqH", Item, INVENTORY_STD) > 0 then
				CopyAlias("TWP_Eq", OutAlias)
				SetData("EquipItem", Item)
				Found = true
			end
		end
	end
	RemoveAlias("TWP_Eq")
	RemoveAlias("TWP_EqH")
	return Found
end

-- Puts Item on: a lesser piece of the same ladder makes room (it goes to the spare
-- inventory), and when the slot is still taken the piece waits in the spare inventory.
function SwapIn(Alias, Item)
	if GetRemainingInventorySpace(Alias, Item, INVENTORY_EQUIPMENT) <= 0 then
		local Slots = { "weapon", "armor", "head" }
		for s = 1, 3 do
			local Ladder = TWP_LADDER[Slots[s]]
			local Idx = 0
			for i = 1, #Ladder do
				if Ladder[i] == Item then
					Idx = i
				end
			end
			for i = 1, Idx - 1 do
				if GetItemCount(Alias, Ladder[i], INVENTORY_EQUIPMENT) > 0 then
					RemoveItems(Alias, Ladder[i], 1, INVENTORY_EQUIPMENT)
					AddItems(Alias, Ladder[i], 1, INVENTORY_STD)
				end
			end
		end
	end
	if GetRemainingInventorySpace(Alias, Item, INVENTORY_EQUIPMENT) > 0 then
		AddItems(Alias, Item, 1, INVENTORY_EQUIPMENT)
	else
		AddItems(Alias, Item, 1, INVENTORY_STD)
	end
end

-- Issues the piece from the residence store; false when the store has none.
function Equip(DynAlias, Alias, Item)
	if not aitwp_Residence(DynAlias, "TWP_EqH") or GetItemCount("TWP_EqH", Item, INVENTORY_STD) <= 0 then
		RemoveAlias("TWP_EqH")
		return false
	end
	RemoveItems("TWP_EqH", Item, 1, INVENTORY_STD)
	RemoveAlias("TWP_EqH")
	aitwp_SwapIn(Alias, Item)
	return true
end

-- ---------------------------------------------------------------------------
-- Attitude towards a human player, and the ladder of tools against them
-- ---------------------------------------------------------------------------

-- Any alias (dynasty, sim or building) to its dynasty in OutAlias; false if none.
function ResolveDynasty(Alias, OutAlias)
	if not AliasExists(Alias) then
		return false
	end
	if IsType(Alias, "Building") then
		if not BuildingGetOwner(Alias, "TWP_RDOwner") then
			return false
		end
		local Ok = GetDynasty("TWP_RDOwner", OutAlias)
		RemoveAlias("TWP_RDOwner")
		return Ok
	end
	if IsType(Alias, "Sim") then
		return GetDynasty(Alias, OutAlias)
	end
	CopyAlias(Alias, OutAlias)
	return true
end

-- Attitude of an AI dynasty towards a player: "blood" (its assigned rival), "feud"
-- (a declared feud), "enemy" (in its enemy list or favour under 30), "friend" (favour
-- 70 and above: friend_for_now, never an ally), else "neutral".
function Attitude(DynAlias, PlayerAlias)
	if not aitwp_ResolveDynasty(PlayerAlias, "TWP_AttP") then
		return "neutral"
	end
	local PlayerID = GetID("TWP_AttP")
	local Att = "neutral"
	if (GetProperty(DynAlias, "AI_BloodEnemyOf") or 0) == PlayerID then
		Att = "blood"
	elseif DynastyGetDiplomacyState(DynAlias, "TWP_AttP") == DIP_FOE then
		Att = "feud"
	else
		local Favor = GetFavorToDynasty(DynAlias, "TWP_AttP")
		if Favor < 30 then
			Att = "enemy"
		else
			local Count, Enemies = aitwp_GetCurrentEnemies(DynAlias)
			for i = 1, Count do
				if Enemies[i] == PlayerID then
					Att = "enemy"
				end
			end
			if Att == "neutral" and Favor >= 70 then
				Att = "friend"
			end
		end
	end
	RemoveAlias("TWP_AttP")
	return Att
end

function IsHostile(Att)
	return Att == "blood" or Att == "feud" or Att == "enemy"
end

-- Player title needed for each rung 0..8. A rung also needs that many rounds played,
-- so everything is open by round 8; a shadow dynasty never climbs above rung 4.
TWP_TITLE_RUNGS = { 1, 3, 5, 7, 8, 9, 10, 11, 13 }

function PlayerRung(PlayerDyn)
	local Title = 0
	local Count = DynastyGetMemberCount(PlayerDyn)
	for i = 0, Count - 1 do
		if DynastyGetMember(PlayerDyn, i, "TWP_PR") then
			Title = math.max(Title, GetNobilityTitle("TWP_PR") or 0)
		end
	end
	RemoveAlias("TWP_PR")
	local Rung = 0
	for r = 1, #TWP_TITLE_RUNGS do
		if Title >= TWP_TITLE_RUNGS[r] then
			Rung = r - 1
		end
	end
	return Rung
end

function Rung(DynAlias, PlayerDyn)
	local R = math.min(aitwp_PlayerRung(PlayerDyn), GetRound())
	if DynastyIsShadow(DynAlias) then
		R = math.min(R, 4)
	end
	return R
end

-- The tools, by rung. class: R reputation, E economic, P physical, L legal, O office
-- power, D diplomatic recruitment. item: the artefact that carries the tool, target:
-- how bf_UseArtefact aims it ("best" the most valuable character, "weak" the weakest
-- fighter outdoors, "near" thrown or read wherever a player character stands close,
-- "building" a workshop). An array, not a map: this engine has no pairs().
TWP_TOOL_LIST = {
	{ name = "collect_evidence", rung = 0, class = "L" }, { name = "scout", rung = 0, class = "E" },
	{ name = "threaten", rung = 0, class = "L" }, { name = "rob_unconscious", rung = 0, class = "P" },
	{ name = "pickpocket", rung = 0, class = "E" },
	{ name = "declare_foe", rung = 1, class = "E" }, { name = "taunt_letter", rung = 1, class = "R" },
	{ name = "discord", rung = 1, class = "R", item = "FlowerOfDiscord", target = "best" },
	{ name = "slander", rung = 1, class = "R" }, { name = "scold", rung = 1, class = "R" },
	{ name = "pamphlet", rung = 2, class = "R" }, { name = "hate_letter", rung = 2, class = "R", item = "Hasstirade", target = "best" },
	{ name = "burglary", rung = 2, class = "E" }, { name = "claim", rung = 2, class = "E" },
	{ name = "inspection", rung = 2, class = "O" }, { name = "sales_tax", rung = 2, class = "O" },
	{ name = "charge", rung = 3, class = "L" }, { name = "blackmail", rung = 3, class = "L" },
	{ name = "duel", rung = 3, class = "P" }, { name = "rough_up", rung = 3, class = "P" },
	{ name = "toad_excrement", rung = 3, class = "E", item = "ToadExcrements", target = "building" },
	{ name = "ghostly_fog", rung = 3, class = "P", item = "GhostlyFog", target = "weak" },
	{ name = "protection_money", rung = 3, class = "E" }, { name = "warpact_claim", rung = 3, class = "D" },
	{ name = "sales_ban", rung = 3, class = "O" }, { name = "freeze_kontor", rung = 3, class = "O" }, { name = "bewitch", rung = 3, class = "P" },
	{ name = "kidnap", rung = 4, class = "P" }, { name = "stink_bomb", rung = 4, class = "P", item = "StinkBomb", target = "near" },
	{ name = "poison_drink", rung = 4, class = "P" }, { name = "thief_of_love", rung = 4, class = "E" },
	{ name = "spindle", rung = 4, class = "P", item = "Spindel", target = "weak" },
	{ name = "pendulum", rung = 4, class = "P", item = "Pendel", target = "weak" },
	{ name = "voodoo", rung = 4, class = "P", item = "Voodo", target = "weak" },
	{ name = "thesis", rung = 4, class = "R", item = "ThesisPaper", target = "near" },
	{ name = "letter_rome", rung = 4, class = "R", item = "LetterFromRome", target = "best" },
	{ name = "waylay", rung = 4, class = "P" }, { name = "plunder", rung = 4, class = "E" },
	{ name = "toad_slime", rung = 4, class = "P", item = "Toadslime", target = "building" }, { name = "thug_attack", rung = 4, class = "P" },
	{ name = "fund_allies", rung = 4, class = "D" }, { name = "arrest", rung = 4, class = "O" }, { name = "banish", rung = 4, class = "O" },
	{ name = "confiscate", rung = 4, class = "O" }, { name = "inquisition", rung = 4, class = "O" }, { name = "break_will", rung = 4, class = "O" },
	{ name = "forge1", rung = 5, class = "L", item = "HexerdokumentI" }, { name = "sabotage", rung = 5, class = "E" }, { name = "demolish", rung = 5, class = "E" },
	{ name = "black_widow", rung = 5, class = "P", lethal = true, item = "BlackWidowPoison", target = "weak" },
	{ name = "weapon_poison", rung = 5, class = "P", lethal = true, item = "WeaponPoison", target = "weak" },
	{ name = "mixture", rung = 5, class = "P", lethal = true, item = "Mixture", target = "weak" },
	{ name = "paralysis", rung = 5, class = "P", item = "ParalysisPoison", target = "weak" },
	{ name = "poisoned_cake", rung = 5, class = "P", item = "PoisonedCake", target = "weak" },
	{ name = "finish_off", rung = 5, class = "P", lethal = true }, { name = "pddv", rung = 5, class = "P", lethal = true, item = "Pddv", target = "weak" },
	{ name = "razzia", rung = 5, class = "E" }, { name = "curse", rung = 5, class = "E" }, { name = "ally_bomb", rung = 5, class = "D" },
	{ name = "torture", rung = 5, class = "O" }, { name = "severity", rung = 5, class = "O" }, { name = "teardown", rung = 5, class = "O" },
	{ name = "forge2", rung = 6, class = "L", item = "HexerdokumentII" }, { name = "false_gauntlet", rung = 6, class = "O" }, { name = "repeal_immunity", rung = 6, class = "O" },
	{ name = "disappropriate", rung = 7, class = "O" }, { name = "crusade", rung = 7, class = "O" }, { name = "rage", rung = 7, class = "O" }, { name = "gaze", rung = 7, class = "O" },
}
TWP_TOOLS = {}
for i = 1, #TWP_TOOL_LIST do
	TWP_TOOLS[TWP_TOOL_LIST[i].name] = TWP_TOOL_LIST[i]
	TWP_TOOL_LIST[i].index = i
end
-- classes each attitude may use; neutrals and friends use none
TWP_ATTITUDE_CLASSES = { blood = "REPLOD", feud = "EPLO", enemy = "EPLO", friend = "", neutral = "" }

-- What the BloodFeud leaves demand before they will fire. One copy each, because the
-- HTN methods in aihtn.lua gate on the same numbers: two literals drift apart in
-- silence, and the planner would then promise a step the leaf refuses.
-- Raising one makes that leaf rarer and its HTN method fail more often (the ::TWP::HTN
-- line names it); lowering one makes a poorer house try it.
TWP_BF_SUPPLY = 100000          -- bf_Procure: treasury before a cart goes shopping
TWP_BF_FUND = 200000            -- bf_FundAllies: treasury before money goes to an ally
TWP_BF_HIDEOUT = 30000          -- bf_Hideout: treasury before a thieves' guild is bought
TWP_BF_RECRUIT = 3000           -- bf_Recruit: treasury before another thug is hired
TWP_BF_RAZZIA_EVIDENCE = 35     -- bf_Razzia: the Razzia measure's own evidence threshold
TWP_BF_CARTS = 5                -- bf_Procure: carts the residence may run for the feud
-- Game hours between feud supply runs. Lowered from 2 to 1 on 2026-09-17 so a single
-- game day of testing exercises the cart often enough to see it shop; put it back up
-- once scouting is confirmed, or the carts spend the whole day on the road.
TWP_BF_SUPPLY_HOURS = 1
-- What the house will fund its blood enemy for. Buying at the enemy's own counter hands
-- them the price, so it is only worth it when the goods hurt them more than the coin
-- helps. Severity is aitwp_Severity: 5 lethal, 4 physical, 3 legal (the forged
-- documents), 2 economic, 1 the rest. The gold cap scales with the damage, so a lethal
-- poison may cost more than a forgery before it stops being a bargain.
TWP_BF_ENEMY_SEVERITY = 3
TWP_BF_ENEMY_GOLD = 500

-- May DynAlias use Tool against whoever VictimAlias belongs to? Against AI dynasties
-- always (the ladder is about human players). Against a player: the attitude's classes,
-- the player's rung (title and round), and no lethal tool without a declared feud;
-- shadows never use lethal tools.
function Allowed(DynAlias, VictimAlias, Tool)
	local T = TWP_TOOLS[Tool]
	if not T then
		return true
	end
	if not aitwp_ResolveDynasty(VictimAlias, "TWP_AlV") then
		return true
	end
	local Ok = true
	if DynastyIsPlayer("TWP_AlV") then
		local Att = aitwp_Attitude(DynAlias, "TWP_AlV")
		if not string.find(TWP_ATTITUDE_CLASSES[Att] or "", T.class, 1, true) then
			Ok = false
		elseif T.lethal and (Att == "enemy" or DynastyIsShadow(DynAlias)) then
			Ok = false
		elseif T.rung > aitwp_Rung(DynAlias, "TWP_AlV") then
			Ok = false
		end
	end
	RemoveAlias("TWP_AlV")
	return Ok
end

-- Weight multiplier of the Feud subtree when its victim is a player: the full
-- pipeline for a feud or the blood rival, softer for a plain enemy, half again for a
-- shadow, nothing for neutrals and friends. AI victims: 1.
function AttitudeFactor(DynAlias, VictimAlias)
	if not aitwp_ResolveDynasty(VictimAlias, "TWP_AfV") then
		return 1
	end
	local F = 1
	if DynastyIsPlayer("TWP_AfV") then
		local Att = aitwp_Attitude(DynAlias, "TWP_AfV")
		if Att == "enemy" then
			F = 0.6
		elseif not aitwp_IsHostile(Att) then
			F = 0
		end
		if DynastyIsShadow(DynAlias) then
			F = F * 0.5
		end
	end
	RemoveAlias("TWP_AfV")
	return F
end

-- The first living player dynasty into OutAlias; false when none.
function FirstPlayer(OutAlias)
	local Count = ScenarioGetObjects("cl_Dynasty", 99, "TWP_FP")
	local Found = false
	for i = 0, Count - 1 do
		if not Found and DynastyIsPlayer("TWP_FP" .. i) and not DynastyIsDead("TWP_FP" .. i) then
			CopyAlias("TWP_FP" .. i, OutAlias)
			Found = true
		end
		RemoveAlias("TWP_FP" .. i)
	end
	return Found
end

-- A hostile player dynasty the tool may be used against right now, into OutAlias.
function PreferPlayerDynasty(DynAlias, Tool, OutAlias)
	local Count = ScenarioGetObjects("cl_Dynasty", 99, "TWP_PP")
	local Found = false
	for i = 0, Count - 1 do
		local P = "TWP_PP" .. i
		if not Found and DynastyIsPlayer(P) and not DynastyIsDead(P)
				and aitwp_IsHostile(aitwp_Attitude(DynAlias, P)) and aitwp_Allowed(DynAlias, P, Tool) then
			CopyAlias(P, OutAlias)
			Found = true
		end
		RemoveAlias(P)
	end
	return Found
end

-- The strongest building of class Class of such a player, into OutAlias.
function PreferPlayerBuilding(DynAlias, Tool, Class, OutAlias)
	if not aitwp_PreferPlayerDynasty(DynAlias, Tool, "TWP_PBD") then
		return false
	end
	local Ok = aitwp_FindTargetBuilding("TWP_PBD", Class, "strongest", OutAlias)
	RemoveAlias("TWP_PBD")
	return Ok
end

-- A player this house likes (friend_for_now), into OutAlias.
function FindFriendPlayer(DynAlias, OutAlias)
	local Count = ScenarioGetObjects("cl_Dynasty", 99, "TWP_FR")
	local Found = false
	for i = 0, Count - 1 do
		local P = "TWP_FR" .. i
		if not Found and DynastyIsPlayer(P) and not DynastyIsDead(P) and aitwp_Attitude(DynAlias, P) == "friend" then
			CopyAlias(P, OutAlias)
			Found = true
		end
		RemoveAlias(P)
	end
	return Found
end

-- A living member of an AI dynasty allied with this house, into OutAlias.
function FindAllyMember(DynAlias, OutAlias)
	local Count = ScenarioGetObjects("cl_Dynasty", 99, "TWP_AL")
	local Found = false
	for i = 0, Count - 1 do
		local D = "TWP_AL" .. i
		if not Found and GetID(D) ~= GetID(DynAlias) and not DynastyIsPlayer(D) and not DynastyIsDead(D)
				and DynastyGetDiplomacyState(DynAlias, D) == DIP_ALLIANCE then
			local SimID = dyn_GetValidMember(D)
			if SimID and SimID > 0 and GetAliasByID(SimID, OutAlias) and AliasExists(OutAlias) then
				Found = true
			end
		end
		RemoveAlias(D)
	end
	return Found
end

-- Daily: no alliance with a human player, whatever the favour - a friend stays a
-- friend-for-now on a non-aggression pact.
function PlayerPolicy(DynAlias)
	local Count = ScenarioGetObjects("cl_Dynasty", 99, "TWP_PY")
	for i = 0, Count - 1 do
		local P = "TWP_PY" .. i
		if DynastyIsPlayer(P) and not DynastyIsDead(P) and DynastyGetDiplomacyState(DynAlias, P) == DIP_ALLIANCE then
			dyn_SetDiplomacyState(DynAlias, P, DIP_NAP)
			aitwp_Log("declines the alliance with " .. GetName(P) .. ": friends for now", DynAlias)
		end
		RemoveAlias(P)
	end
end

-- Artefacts of the ladder the house may use against PlayerDyn now, lowest rung first;
-- fills OutList and returns the count.
function ProcureList(DynAlias, PlayerDyn, OutList)
	local N = 0
	for i = 1, #TWP_TOOL_LIST do
		local T = TWP_TOOL_LIST[i]
		if T.item and aitwp_Allowed(DynAlias, PlayerDyn, T.name) then
			N = N + 1
			OutList[N] = T.item
		end
	end
	return N
end

-- true when the residence or a thug holds the item: the store the use nodes draw from
function InStore(DynAlias, Item)
	local Found = aitwp_Residence(DynAlias, "TWP_IS") and GetItemCount("TWP_IS", Item, INVENTORY_STD) > 0
	RemoveAlias("TWP_IS")
	local Count = DynastyGetWorkerCount(DynAlias, GL_PROFESSION_MYRMIDON)
	for i = 0, Count - 1 do
		if not Found and DynastyGetWorker(DynAlias, GL_PROFESSION_MYRMIDON, i, "TWP_IS") and GetItemCount("TWP_IS", Item, INVENTORY_STD) > 0 then
			Found = true
		end
	end
	RemoveAlias("TWP_IS")
	return Found == true
end

-- true when Item is a tool of the ladder (an artefact or forgery paper)
function IsTool(Item)
	for i = 1, #TWP_TOOL_LIST do
		if TWP_TOOL_LIST[i].item == Item then
			return true
		end
	end
	return false
end

-- Hand-overs a house may make per day: its members and thugs plus two. Counted in
-- AI_HO_Count, stamped with the round (the game day) in AI_HO_Round.
function HandOverCap(DynAlias)
	return DynastyGetMemberCount(DynAlias) + DynastyGetWorkerCount(DynAlias, GL_PROFESSION_MYRMIDON) + 2
end

function HandOversToday(DynAlias)
	if (GetProperty(DynAlias, "AI_HO_Round") or -1) ~= GetRound() then
		return 0
	end
	return GetProperty(DynAlias, "AI_HO_Count") or 0
end

-- Ladder tools SimAlias carries: its active feud tools.
function CarriedTools(SimAlias)
	local N = 0
	for i = 1, #TWP_TOOL_LIST do
		if TWP_TOOL_LIST[i].item then
			N = N + GetItemCount(SimAlias, TWP_TOOL_LIST[i].item, INVENTORY_STD)
		end
	end
	return N
end

-- May the store hand SimAlias a tool now? One active tool per unit and the daily cap
-- per house are the two brakes on inventory spam; tools are drawn just in time.
function CanHandOver(DynAlias, SimAlias)
	return aitwp_CarriedTools(SimAlias) < 1 and aitwp_HandOversToday(DynAlias) < aitwp_HandOverCap(DynAlias)
end

-- Every ladder artefact the house could use on the player right now, most severe rung
-- first: allowed by the ladder, off its own measure cooldown, and either in SimAlias's
-- hands or in the store with a hand-over to spare. Out[1..n] holds the TWP_TOOL_LIST
-- rows themselves - the caller needs target, lethal and aitwp_Severity off them.
-- Rows of every target are returned, building ones included; bf_UseArtefact skips those
-- and bf_UseBuildingArtefact takes them, so one pass answers for both leaves and for
-- the HTN preconditions that count them.
-- Walked backwards because TWP_TOOL_LIST is ordered by ascending rung with ties by
-- index: that is the severity order the leaf has always used, and sorting would reorder
-- the six rung-5 poisons.
function ReadyArtefacts(DynAlias, PlayerDyn, SimAlias, Out)
	local N = 0
	for i = #TWP_TOOL_LIST, 1, -1 do
		local T = TWP_TOOL_LIST[i]
		-- the forgery papers carry an item but no target: they are bf_ForgeEvidence's
		if T.item and T.target
				and GetRepeatTimerLeft(SimAlias, GetMeasureRepeatName2("Use" .. T.item)) <= 0
				and aitwp_Allowed(DynAlias, PlayerDyn, T.name)
				and (GetItemCount(SimAlias, T.item, INVENTORY_STD) > 0
					or (aitwp_InStore(DynAlias, T.item) and aitwp_CanHandOver(DynAlias, SimAlias))) then
			N = N + 1
			Out[N] = T
		end
	end
	return N
end

-- The hand-over: Count of Item from the residence store (or a thug still carrying feud
-- goods) straight into SimAlias's inventory, wherever it stands - the last hop of every
-- feud purchase. Ladder tools are rationed (aitwp_CanHandOver) and logged:
-- ::TWP::HANDOVER t= dyn= sim= item= today=<n>/<cap>
function DrawFromStock(SimAlias, Item, Count)
	Count = Count or 1
	if type(Item) == "number" then
		Item = ItemGetName(Item)
	end
	if not GetDynasty(SimAlias, "TWP_DS") then
		return false
	end
	local Tool = aitwp_IsTool(Item)
	if Tool and not aitwp_CanHandOver("TWP_DS", SimAlias) then
		RemoveAlias("TWP_DS")
		return false
	end
	local Done = false
	if aitwp_Residence("TWP_DS", "TWP_DSH") and GetItemCount("TWP_DSH", Item, INVENTORY_STD) >= Count then
		RemoveItems("TWP_DSH", Item, Count, INVENTORY_STD)
		AddItems(SimAlias, Item, Count, INVENTORY_STD)
		Done = true
	end
	RemoveAlias("TWP_DSH")
	local Thugs = DynastyGetWorkerCount("TWP_DS", GL_PROFESSION_MYRMIDON)
	for i = 0, Thugs - 1 do
		if not Done and DynastyGetWorker("TWP_DS", GL_PROFESSION_MYRMIDON, i, "TWP_DST")
				and GetID("TWP_DST") ~= GetID(SimAlias) and GetItemCount("TWP_DST", Item, INVENTORY_STD) >= Count then
			RemoveItems("TWP_DST", Item, Count, INVENTORY_STD)
			AddItems(SimAlias, Item, Count, INVENTORY_STD)
			Done = true
		end
	end
	RemoveAlias("TWP_DST")
	if Done and Tool then
		local Today = aitwp_HandOversToday("TWP_DS") + Count
		SetProperty("TWP_DS", "AI_HO_Round", GetRound())
		SetProperty("TWP_DS", "AI_HO_Count", Today)
		if utility_LogEnabled() then
			utility_Emit("::TWP::HANDOVER t=" .. string.format("%.2f", GetGametime()) .. " dyn=" .. GetID("TWP_DS")
				.. " sim=" .. GetID(SimAlias) .. " item=" .. Item .. " today=" .. Today .. "/" .. aitwp_HandOverCap("TWP_DS"))
		end
	end
	RemoveAlias("TWP_DS")
	return Done
end

-- Adds the piece Alias lacks to the parallel lists Names/Counts (no pairs() here).
function NoteMissing(Alias, Tier, Names, Counts)
	local Item = aitwp_MissingEquipment(Alias, Tier)
	if not Item then
		return
	end
	for i = 1, #Names do
		if Names[i] == Item then
			Counts[i] = Counts[i] + 1
			return
		end
	end
	Names[#Names + 1] = Item
	Counts[#Counts + 1] = 1
end

-- How badly a tool hurts: lethal 5, physical or control 4, legal 3, economic 2,
-- reputation 1. The cart buys in this order, ties to the higher rung.
-- May the cart buy this item at a shop the blood enemy owns? The market is public and
-- the goods are real, but the price funds the house they will be used against, so the
-- trade only pays when the damage justifies the gift. Equipment and anything that is
-- not a ladder tool is never bought there: a breastplate does the enemy no harm at
-- all, and the cart can get one anywhere else.
function WorthBuyingFromEnemy(ItemID, SellerAlias)
	local Name = ItemGetName(ItemID)
	for i = 1, #TWP_TOOL_LIST do
		local T = TWP_TOOL_LIST[i]
		if T.item == Name then
			local Damage = aitwp_Severity(T)
			if Damage < TWP_BF_ENEMY_SEVERITY then
				return false
			end
			-- What the rival actually collects is the price at their own counter, not the
			-- catalogue value: a shop sets its own. ItemGetPriceBuy is the same call
			-- f_Transfer reads when the seller is a market; base price is the fallback
			-- when it cannot answer for a workshop, which is what f_Transfer itself uses.
			local Paid = 0
			if SellerAlias and AliasExists(SellerAlias) then
				Paid = ItemGetPriceBuy(ItemID, SellerAlias) or 0
			end
			if Paid <= 0 then
				Paid = ItemGetBasePrice(Name) or 0
			end
			return Paid <= TWP_BF_ENEMY_GOLD * Damage
		end
	end
	return false
end

function Severity(T)
	if T.lethal then
		return 5
	end
	if T.class == "P" then
		return 4
	elseif T.class == "L" then
		return 3
	elseif T.class == "E" then
		return 2
	end
	return 1
end

-- The ladder tools with an item the house may use against PlayerDyn, most severe
-- first, into OutTools. Returns the count.
function ProcureTools(DynAlias, PlayerDyn, OutTools)
	local N = 0
	for i = 1, #TWP_TOOL_LIST do
		local T = TWP_TOOL_LIST[i]
		if T.item and aitwp_Allowed(DynAlias, PlayerDyn, T.name) then
			N = N + 1
			OutTools[N] = T
		end
	end
	table.sort(OutTools, function(a, b)
		local Sa, Sb = aitwp_Severity(a), aitwp_Severity(b)
		if Sa ~= Sb then
			return Sa > Sb
		end
		if a.rung ~= b.rung then
			return a.rung > b.rung
		end
		return a.index < b.index
	end)
	return N
end

-- Items of Item the house holds anywhere: residence store, party members, thugs.
function StockCount(DynAlias, Item)
	local Total = 0
	if aitwp_Residence(DynAlias, "TWP_SC") then
		Total = Total + GetItemCount("TWP_SC", Item, INVENTORY_STD)
	end
	local Count = DynastyGetMemberCount(DynAlias)
	for i = 0, Count - 1 do
		if DynastyGetMember(DynAlias, i, "TWP_SC") then
			Total = Total + GetItemCount("TWP_SC", Item, INVENTORY_STD)
		end
	end
	Count = DynastyGetWorkerCount(DynAlias, GL_PROFESSION_MYRMIDON)
	for i = 0, Count - 1 do
		if DynastyGetWorker(DynAlias, GL_PROFESSION_MYRMIDON, i, "TWP_SC") then
			Total = Total + GetItemCount("TWP_SC", Item, INVENTORY_STD)
		end
	end
	RemoveAlias("TWP_SC")
	return Total
end

-- What the house can use of one tool in a day: its adults times the tool's uses per
-- day (daily, 1 unless set), 3 at most. Holding more is oversupply: not bought.
function StockCap(DynAlias, T)
	local Users = 0
	local Count = DynastyGetMemberCount(DynAlias)
	for i = 0, Count - 1 do
		if DynastyGetMember(DynAlias, i, "TWP_Cap") and SimGetAge("TWP_Cap") >= 16 then
			Users = Users + 1
		end
	end
	RemoveAlias("TWP_Cap")
	return math.min(3, math.max(1, Users) * (T.daily or 1))
end

-- The feud cart's shopping list, {item id, amount} entries into OutNeeds. Tools most
-- severe first, one of each per run and only while the house holds fewer than it can
-- use in a day (aitwp_StockCap), so the money spreads over tools with separate
-- cooldowns instead of piling one up; then the equipment its people lack (3 of a kind
-- at most, less what the store holds). Budget 7% of cash, 15% at rung 8, at base
-- prices. Returns the entry count.
function ShoppingList(DynAlias, PlayerDyn, OutNeeds)
	local Money = GetMoney(DynAlias)
	local Budget = Money * 0.07
	if aitwp_Rung(DynAlias, PlayerDyn) >= 8 then
		Budget = Money * 0.15
	end
	local Names, Counts, Tools = {}, {}, {}
	local N = aitwp_ProcureTools(DynAlias, PlayerDyn, Tools)
	for i = 1, N do
		if aitwp_StockCount(DynAlias, Tools[i].item) < aitwp_StockCap(DynAlias, Tools[i]) then
			Names[#Names + 1] = Tools[i].item
			Counts[#Counts + 1] = 1
		end
	end
	local Gear0 = #Names
	local Tier = aitwp_EquipmentTier(DynAlias)
	if Tier then
		local Count = DynastyGetMemberCount(DynAlias)
		for i = 0, Count - 1 do
			if DynastyGetMember(DynAlias, i, "TWP_SL") and SimGetAge("TWP_SL") >= 16 then
				aitwp_NoteMissing("TWP_SL", Tier, Names, Counts)
			end
		end
		Count = DynastyGetWorkerCount(DynAlias, -1)
		for i = 0, Count - 1 do
			if DynastyGetWorker(DynAlias, -1, i, "TWP_SL") then
				aitwp_NoteMissing("TWP_SL", Tier, Names, Counts)
			end
		end
		RemoveAlias("TWP_SL")
	end
	local HasHome = aitwp_Residence(DynAlias, "TWP_SLH")
	local Total, Out = 0, 0
	for i = 1, #Names do
		local Amount = math.min(Counts[i], 3)
		if i > Gear0 and HasHome then
			Amount = Amount - GetItemCount("TWP_SLH", Names[i], INVENTORY_STD)
		end
		local Price = (ItemGetBasePrice(Names[i]) or 0) * Amount
		if Amount > 0 and Total + Price <= Budget then
			Out = Out + 1
			OutNeeds[Out] = { ItemGetID(Names[i]), Amount }
			Total = Total + Price
		end
	end
	RemoveAlias("TWP_SLH")
	return Out
end

-- Rounds a hired hand can be pulled off without losing anything: the watch, the escort,
-- the evidence errand, and the underworld's own patrols. A bare STATE_IDLE test skipped
-- every patrolling thug (session 2: seven orders, none run).
TWP_FREE_MEASURES = {
	"PatrolTheTown", "EscortCharacterOrTransport", "OrderCollectEvidence",
	"PickpocketPeople", "ScoutAHouse", "BurgleAHouse", "Linger",
}
function IsFreeForOrders(Alias)
	if GetState(Alias, STATE_DEAD) or GetState(Alias, STATE_DYING) or GetState(Alias, STATE_UNCONSCIOUS) then
		return false
	end
	if GetState(Alias, STATE_IDLE) then
		return true
	end
	local M = GetCurrentMeasureName(Alias)
	for i = 1, #TWP_FREE_MEASURES do
		if M == TWP_FREE_MEASURES[i] then
			return true
		end
	end
	return false
end

-- Fighting ------------------------------------------------------------------------
-- The engine settles a swing in anims_fight_sim: the attacker rolls 1+Rand(50)+FIGHTING*5,
-- the defender 1+Rand(50)+DEXTERITY*5, and the swing misses when the defence wins; what
-- lands then loses the defender's armour as a percentage. Everything below is that model
-- read forwards, so a house can tell a fight it wins from one it walks into.

-- Chance one swing lands. The difference of two Rand(50) rolls is triangular over
-- -49..49, so this is that distribution in closed form.
function HitChance(Fighting, Dexterity)
	local Edge = ((Fighting or 0) - (Dexterity or 0)) * 5
	if Edge >= 50 then
		return 1
	end
	if Edge <= -50 then
		return 0
	end
	if Edge >= 0 then
		local Miss = (50 - Edge) / 50
		return 1 - Miss * Miss * 0.5
	end
	local Hit = (50 + Edge) / 50
	return Hit * Hit * 0.5
end

-- One fighter's numbers: damage per landed swing (weapon, level and FIGHTING, through
-- ai_GetPower), armour as the percentage it takes off an incoming hit, dexterity, HP
-- left and FIGHTING. Anyone down or dying counts for nothing on either side.
function FightStats(Alias)
	if GetState(Alias, STATE_DEAD) or GetState(Alias, STATE_DYING) or GetState(Alias, STATE_UNCONSCIOUS) then
		return 0, 0, 0, 0, 0
	end
	local Damage, Armor = ai_GetPower(Alias)
	local HP = GetHP(Alias) or 0
	if HP < 0 then
		HP = 0
	end
	return Damage or 0, math.min(90, Armor or 0), GetSkillValue(Alias, DEXTERITY) or 0, HP,
		GetSkillValue(Alias, FIGHTING) or 0
end

-- Sides are plain tables so a caller can build one from members, workers, an escort
-- count or a squad without agreeing on an alias scheme first.
function AddFighter(Side, Alias)
	local Damage, Armor, Dex, HP, Fighting = aitwp_FightStats(Alias)
	if HP <= 0 then
		return Side
	end
	Side.n = (Side.n or 0) + 1
	Side.hp = (Side.hp or 0) + HP
	Side.damage = (Side.damage or 0) + Damage
	Side.armor = (Side.armor or 0) + Armor
	Side.dex = (Side.dex or 0) + Dex
	Side.fighting = (Side.fighting or 0) + Fighting
	return Side
end

-- Damage a side puts out per round against the other, times the HP it has to spend
-- doing it. Two equals beat one of the same four to one, not two to one - numbers
-- count twice, once in the output and once in the staying power.
function SidePower(Side, Other)
	if (Side.n or 0) < 1 or (Side.hp or 0) <= 0 then
		return 0
	end
	local TheirDex, TheirArmor = 0, 0
	if (Other.n or 0) > 0 then
		TheirDex = (Other.dex or 0) / Other.n
		TheirArmor = (Other.armor or 0) / Other.n
	end
	local Through = 1 - TheirArmor * 0.01
	if Through < 0.1 then
		Through = 0.1
	end
	return Side.hp * (Side.damage or 0) * aitwp_HitChance((Side.fighting or 0) / Side.n, TheirDex) * Through
end

-- Rough chance Side walks away from Other. Rough on purpose: it cannot see crits,
-- artefacts, or who wanders past and joins in, so a house that clears the bar still
-- loses sometimes. What it rules out is the fight nobody could have won.
function WinChance(Side, Other)
	local Mine = aitwp_SidePower(Side, Other)
	local Theirs = aitwp_SidePower(Other, Side)
	if Mine <= 0 then
		return 0
	end
	if Theirs <= 0 then
		return 1
	end
	return Mine / (Mine + Theirs)
end

-- Everyone the house can put on the road: thugs off the residence, and the marauders,
-- thieves and mercenaries of any camp it owns. Writes them into <Prefix>1..n, adds their
-- numbers to Side and returns n.
TWP_ATTACK_PARTY_MAX = 6
function GatherFighters(DynAlias, Prefix, Side, Max)
	-- built here, not at load time: the GL_PROFESSION_ constants are the engine's, and a
	-- table filled before it has defined them is four nils and no party at all
	local Professions = { GL_PROFESSION_MYRMIDON, GL_PROFESSION_ROBBER, GL_PROFESSION_THIEF, GL_PROFESSION_MERCENARY }
	local Found = 0
	for p = 1, #Professions do
		local Profession = Professions[p]
		local Count = DynastyGetWorkerCount(DynAlias, Profession) or 0
		for i = 0, Count - 1 do
			if Found < Max and DynastyGetWorker(DynAlias, Profession, i, Prefix .. (Found + 1))
					and aitwp_IsFreeForOrders(Prefix .. (Found + 1)) then
				Found = Found + 1
				aitwp_AddFighter(Side, Prefix .. Found)
			end
		end
	end
	RemoveAlias(Prefix .. (Found + 1))
	return Found
end

function ClearFighters(Prefix, Count)
	for i = 1, Count do
		RemoveAlias(Prefix .. i)
	end
end

-- What the victim has around them: their own sheet, the bodyguards walking with them
-- (the escort measure counts itself on the sim it follows), and anyone of their house
-- close enough to join before it is over. Guards stand in at the victim's own strength,
-- because the estimate cannot read their sheets and under-counting an escort is exactly
-- what got single thugs killed.
TWP_ESCORT_RADIUS = 3000
TWP_DEFENCE_MAX = 8
function DefenceOf(PlayerDyn, VictimAlias, Side)
	aitwp_AddFighter(Side, VictimAlias)
	local Escorts = (GetProperty(VictimAlias, "CityBodyguard") or 0) + (GetProperty(VictimAlias, "KIbodyguard") or 0)
	for i = 1, Escorts do
		if (Side.n or 0) < TWP_DEFENCE_MAX then
			aitwp_AddFighter(Side, VictimAlias)
		end
	end
	local VictimID = GetID(VictimAlias)
	local Count = DynastyGetMemberCount(PlayerDyn) or 0
	for i = 0, Count - 1 do
		if (Side.n or 0) < TWP_DEFENCE_MAX and DynastyGetMember(PlayerDyn, i, "TWP_Def")
				and GetID("TWP_Def") ~= VictimID
				and GetDistance("TWP_Def", VictimAlias) <= TWP_ESCORT_RADIUS then
			aitwp_AddFighter(Side, "TWP_Def")
		end
	end
	Count = DynastyGetWorkerCount(PlayerDyn, -1) or 0
	for i = 0, Count - 1 do
		if (Side.n or 0) < TWP_DEFENCE_MAX and DynastyGetWorker(PlayerDyn, -1, i, "TWP_Def")
				and GetID("TWP_Def") ~= VictimID
				and GetDistance("TWP_Def", VictimAlias) <= TWP_ESCORT_RADIUS then
			aitwp_AddFighter(Side, "TWP_Def")
		end
	end
	RemoveAlias("TWP_Def")
	return Side
end

-- The house attacks when it reckons it wins three fights in four.
TWP_ATTACK_WIN_CHANCE = 0.75

-- Carts of the residence: total, how many are on a supply run, and whether an idle
-- one was put into OutAlias.
function ResidenceCarts(DynAlias, OutAlias)
	if not aitwp_Residence(DynAlias, "TWP_RC") then
		return 0, 0, false
	end
	local Total = BuildingGetCartCount("TWP_RC")
	local Busy, Found = 0, false
	for i = 0, Total - 1 do
		if BuildingGetCart("TWP_RC", i, "TWP_RCC") then
			if GetCurrentMeasureName("TWP_RCC") == "FeudSupply" then
				Busy = Busy + 1
			elseif not Found then
				CopyAlias("TWP_RCC", OutAlias)
				Found = true
			end
		end
	end
	RemoveAlias("TWP_RCC")
	RemoveAlias("TWP_RC")
	return Total, Busy, Found
end

-- Telemetry, daily for a blood rival: where each ladder item and forgery paper is on
-- sale - the home town's stock and the total in every other town's market or Kontor.
-- ::TWP::MARKET t= dyn= items=<name>:<home>:<away>;...
-- How much of Item the sellers of one town hold: its workshops and the resource
-- buildings around it, ownerless or foreign, in stock or on offer. The market stall
-- is counted separately by the caller.
function SellerStock(CityAlias, Item)
	local Classes = { GL_BUILDING_CLASS_WORKSHOP, GL_BUILDING_CLASS_RESOURCE }
	local Filters = { FILTER_NO_DYNASTY, FILTER_HAS_DYNASTY }
	local Stock = 0
	for c = 1, 2 do
		for f = 1, 2 do
			local Count = CityGetBuildings(CityAlias, Classes[c], -1, -1, -1, Filters[f], "TWP_SS")
			for i = 0, Count - 1 do
				Stock = Stock + GetItemCount("TWP_SS" .. i, Item, INVENTORY_STD)
					+ GetItemCount("TWP_SS" .. i, Item, INVENTORY_SELL)
				RemoveAlias("TWP_SS" .. i)
			end
		end
	end
	return Stock
end

function MarketReport(DynAlias, PlayerDyn)
	if not utility_LogEnabled() then
		return
	end
	local Items = {}
	local N = aitwp_ProcureList(DynAlias, PlayerDyn, Items)
	local HasHome = aitwp_Residence(DynAlias, "TWP_MRH") and GetSettlement("TWP_MRH", "TWP_MRC")
	local Cities = ScenarioGetObjects("Settlement", 20, "TWP_MRS")
	local Text = ""
	for i = 1, N do
		local Home, Away = 0, 0
		for c = 0, Cities - 1 do
			local City = "TWP_MRS" .. c
			local Count = 0
			if CityGetRandomBuilding(City, -1, GL_BUILDING_TYPE_MARKET, -1, -1, FILTER_IGNORE, "TWP_MRM")
					or CityGetRandomBuilding(City, -1, GL_BUILDING_TYPE_KONTOR, -1, -1, FILTER_IGNORE, "TWP_MRM") then
				Count = GetItemCount("TWP_MRM", Items[i], INVENTORY_STD) + GetItemCount("TWP_MRM", Items[i], INVENTORY_SELL)
			end
			-- the same places ms_bf_FeudSupply actually shops: workshops and the resource
			-- buildings in the surroundings, not only the market stall. Counting the stall
			-- alone reported items as findable "nowhere" while a workshop held them.
			Count = Count + aitwp_SellerStock(City, Items[i])
			if HasHome and GetID(City) == GetID("TWP_MRC") then
				Home = Count
			else
				Away = Away + Count
			end
		end
		Text = Text .. Items[i] .. ":" .. Home .. ":" .. Away .. ";"
	end
	for c = 0, Cities - 1 do
		RemoveAlias("TWP_MRS" .. c)
	end
	RemoveAlias("TWP_MRM")
	RemoveAlias("TWP_MRC")
	RemoveAlias("TWP_MRH")
	utility_Emit("::TWP::MARKET t=" .. string.format("%.2f", GetGametime()) .. " dyn=" .. GetID(DynAlias) .. " items=" .. Text)
end

-- Telemetry for the supply run. CartAlias "" means the running cart itself.
-- ::TWP::CART t= dyn= action=<buy|send|arrive> cart= carts= busy= need= money= result= items=<name,amount;..>
function LogCart(DynAlias, Action, CartAlias, Total, Busy, Needs, N, Result)
	if not utility_LogEnabled() then
		return
	end
	local Text = ""
	for i = 1, N do
		Text = Text .. ItemGetName(Needs[i][1]) .. "," .. Needs[i][2] .. ";"
	end
	local CartID = -1
	if CartAlias == "" or (CartAlias and AliasExists(CartAlias)) then
		CartID = GetID(CartAlias)
	end
	utility_Emit("::TWP::CART t=" .. string.format("%.2f", GetGametime()) .. " dyn=" .. GetID(DynAlias) .. " action=" .. Action
		.. " cart=" .. CartID .. " carts=" .. Total .. " busy=" .. Busy .. " need=" .. N
		.. " money=" .. math.floor(GetMoney(DynAlias) or 0) .. " result=" .. tostring(Result) .. " items=" .. Text)
end

-- Daily: ladder tools left in party members' hands go back to the store (when it has
-- room), so no unit sits on a tool it did not use; the store hands it out again just
-- in time.
function ReturnUnused(DynAlias)
	if not aitwp_Residence(DynAlias, "TWP_RU") then
		return
	end
	local Count = DynastyGetMemberCount(DynAlias)
	for i = 0, Count - 1 do
		if DynastyGetMember(DynAlias, i, "TWP_RUM") then
			for t = 1, #TWP_TOOL_LIST do
				local Item = TWP_TOOL_LIST[t].item
				if Item then
					local Held = GetItemCount("TWP_RUM", Item, INVENTORY_STD)
					if Held > 0 and CanAddItems("TWP_RU", Item, Held, INVENTORY_STD) then
						RemoveItems("TWP_RUM", Item, Held, INVENTORY_STD)
						AddItems("TWP_RU", Item, Held, INVENTORY_STD)
					end
				end
			end
		end
	end
	RemoveAlias("TWP_RUM")
	RemoveAlias("TWP_RU")
end

-- Daily: the first X of the day of every ladder item the house produces itself are
-- kept back for the feud (X = the rival's rung, at least 1): AI_Reserve_<item> on the
-- workshop, honoured by the sales cart (state_twp_autocart), collected free by the
-- feud cart, which caps the collection per item and day (AI_ReserveDay, AI_ReserveTaken_).
function ReserveProduction(DynAlias, PlayerDyn)
	local X = math.max(1, aitwp_Rung(DynAlias, PlayerDyn))
	local Buildings = DynastyGetBuildingCount2(DynAlias)
	for i = 0, Buildings - 1 do
		if DynastyGetBuilding2(DynAlias, i, "TWP_RP") and BuildingGetClass("TWP_RP") == GL_BUILDING_CLASS_WORKSHOP then
			local Count, Products = economy_GetProducedItems("TWP_RP")
			for p = 1, Count do
				local Name = ItemGetName(Products[p])
				if aitwp_IsTool(Name) then
					SetProperty("TWP_RP", "AI_Reserve_" .. Name, X)
				end
			end
		end
	end
	RemoveAlias("TWP_RP")
end

-- Daily, difficulty 4 and 5 only: the courier. While the player's rung is above the
-- rival's, that many reputation and economic tools short of their cap (3 at most) are
-- ordered at base price and a half, paid now and delivered to the residence at the
-- next daily tick - never a lethal tool, never a paper. Orders in flight sit in
-- AI_Courier1..3 as item ids. Logged on the CART channel as action=courier with
-- carts= delivered today, need= ordered today, result= the rung gap.
function CourierOrders(DynAlias, PlayerDyn)
	if ScenarioGetDifficulty() < 4 or not aitwp_Residence(DynAlias, "TWP_CO") then
		RemoveAlias("TWP_CO")
		return
	end
	local Delivered = 0
	for s = 1, 3 do
		local ID = GetProperty(DynAlias, "AI_Courier" .. s) or 0
		if ID > 0 then
			AddItems("TWP_CO", ID, 1, INVENTORY_STD)
			SetProperty(DynAlias, "AI_Courier" .. s, 0)
			Delivered = Delivered + 1
		end
	end
	local Gap = aitwp_PlayerRung(PlayerDyn) - aitwp_PlayerRung(DynAlias)
	local Tools, Needs = {}, {}
	local N = aitwp_ProcureTools(DynAlias, PlayerDyn, Tools)
	local Ordered = 0
	for i = 1, N do
		local T = Tools[i]
		if Ordered < math.min(Gap, 3) and (T.class == "R" or T.class == "E")
				and aitwp_StockCount(DynAlias, T.item) < aitwp_StockCap(DynAlias, T) then
			local Price = math.floor((ItemGetBasePrice(T.item) or 0) * 1.5)
			if GetMoney(DynAlias) >= Price + 100000 and (dyn_GetIdleMember(DynAlias, "TWP_COP") or DynastyGetMember(DynAlias, 0, "TWP_COP")) then
				chr_SpendMoney("TWP_COP", Price, "Equipment", true)
				Ordered = Ordered + 1
				SetProperty(DynAlias, "AI_Courier" .. Ordered, ItemGetID(T.item))
				Needs[Ordered] = { ItemGetID(T.item), 1 }
			end
		end
	end
	RemoveAlias("TWP_COP")
	RemoveAlias("TWP_CO")
	if Delivered > 0 or Ordered > 0 then
		aitwp_LogCart(DynAlias, "courier", nil, Delivered, 0, Needs, Ordered, Gap)
	end
end

-- A living player party member outdoors within Radius of SimAlias, into OutAlias.
function NearbyPlayerSim(SimAlias, PlayerDyn, Radius, OutAlias)
	local Count = DynastyGetMemberCount(PlayerDyn)
	for i = 0, Count - 1 do
		if DynastyGetMember(PlayerDyn, i, "TWP_NP") and not GetState("TWP_NP", STATE_DEAD)
				and not SimIsInside("TWP_NP") and GetDistance(SimAlias, "TWP_NP") <= Radius then
			CopyAlias("TWP_NP", OutAlias)
			RemoveAlias("TWP_NP")
			return true
		end
	end
	RemoveAlias("TWP_NP")
	return false
end

---
-- This will initialize the political and military enemies at game start
function InitEnemies(DynAlias)
	local Difficulty = ScenarioGetDifficulty()
	local TimeOfTruce = 5 - Difficulty -- wait 5 rounds on easy, 1 round on hard

	if IsMultiplayerGame() then
		GetScenario("World")
		if not HasProperty("World", "AITruceRounds") then
			LogMessage("@NAO #W Set AITruceRounds property to default -1 as it was not existing.")
			SetProperty("World", "AITruceRounds",  GetSettingNumber("OPTIONS", "AITruceRounds",  -1))
		end
		local optTruce = GetProperty("World", "AITruceRounds")
		if optTruce and optTruce >= 0 then
			TimeOfTruce = optTruce
		end
	end

	if GetRound() < TimeOfTruce then
		return 0, "" -- no enemies yet
	end
	
	local EnemyCount = 0
	local EnemyIDs = {}
	-- My current rival regarding my workshops
	if HasProperty(DynAlias, "RivalID") then
		EnemyCount = EnemyCount + 1
		EnemyIDs[EnemyCount] = GetProperty(DynAlias, "RivalID")
	end
	
	-- A random victim that we don't like
	-- TODO enbale this only for non-shadows?
	if DynastyGetRandomVictim(DynAlias, 50, "TargetDyn") then
		EnemyCount = EnemyCount + 1
		EnemyIDs[EnemyCount] = GetID("TargetDyn")
	end
	
	-- if we're not shadow, pick another colored dynasty as enemy
	if not DynastyIsShadow(DynAlias) then
		local DynCount = ScenarioGetObjects("cl_Dynasty", 50, "Dyn")
		local DynID, DAli
		for i = 0, 10 do
			DAli = "Dyn"..Rand(DynCount)
			DynID = GetID(DAli)
			if not DynastyIsShadow(DAli) and DynID ~= GetID(DynAlias) then
				EnemyCount = EnemyCount + 1
				EnemyIDs[EnemyCount] = DynID
				break
			end
		end
	end
	
	local EnemyProperty = ""
	for i=1, EnemyCount do
		EnemyProperty = EnemyProperty .. EnemyIDs[i]  .. ","
	end
	aitwp_Log("InitEnemies Setting enemies to: "..EnemyProperty, DynAlias)
	SetProperty(DynAlias, "AITWP_Enemies", EnemyProperty)
	return EnemyCount, EnemyIDs
end

---
-- court an existing lover for this sim
function CourtLover(SimAlias)
	local Beloved = "Beloved"
	-- no beloved, find one and start courting
	if not SimGetCourtLover(SimAlias, Beloved) or not AliasExists(Beloved) then
		-- start courting
		MeasureRun(SimAlias, nil, "CourtLover")
		return
	end
	
	-- beloved is dead, alas
	if GetState(Beloved, STATE_DEAD) then
		SimReleaseCourtLover(SimAlias)
		return
	end
	
	-- beloved is not available
	if GetStateImpact(Beloved, "no_control") 
		or SimGetBehavior(Beloved) == "CheckPresession"
		or SimGetBehavior(Beloved) == "CheckTrial"
		or GetState(Beloved, STATE_UNCONSCIOUS)
		or GetHP(Beloved) == 0 then
		return
	end
	
	-- beloved is ready to marry, congratulations!
	if SimGetProgress(SimAlias) > 98 then
		MeasureRun(SimAlias, Beloved, "Marry")
		return
	end
	
	-- find good courting measure and execute it
	-- use FindCourtingMeasure from gameplayformulas, which uses updated weights
	local MeasureName = gameplayformulas_FindCourtingMeasure(SimAlias, Beloved)
	if MeasureName and MeasureName ~= "none" then
		MeasureRun(SimAlias, Beloved, MeasureName)
	end
end

function GetCourtingMeasure(SimAlias)
	local Count
	local M = {}
	Count, M[1], M[2], M[3] = SimGetFavourableCourtingAction(SimAlias)
	local Forbidden0 = GetProperty("", "_ai_cl_0")
	local Forbidden1 = GetProperty("", "_ai_cl_1")
	
	-- check validity of given measure and return first valid measure
	for m = 1, math.max(3, Count) do
		local BestMeasureId = M[m]
		if (BestMeasureId and BestMeasureId > 0) then
			local MeasureName = CourtingId2Measure(BestMeasureId)
			if MeasureName
					and (GetRepeatTimerLeft(SimAlias, GetMeasureRepeatName2(MeasureName)) <= 0)
					and (MeasureName ~= Forbidden0 and MeasureName ~= Forbidden1) then
				-- update properties with last courting measures
				if Forbidden0 then
					SetProperty(SimAlias, "_ai_cl_1", Forbidden0)
				end
				SetProperty("", "_ai_cl_0", MeasureName)
				return MeasureName 
			end
		end
	end
end

-- Node-level trace. Off unless configs/config.ini has Log = 1 under [AI] (see
-- utility_LogEnabled): it writes several lines per dynasty per tick. ShowMsg is
-- kept for the existing callers and ignored.
function Log(Message, Actor, ShowMsg)
	if not utility_LogEnabled() then
		return
	end
	local Who = ""
	if Actor and Actor ~= "" and AliasExists(Actor) then
		Who = GetName(Actor) .. " "
	end
	utility_Emit("::TWP::AI:: " .. Who .. Message)
end

function GetPoliticalAmbititon(DynAlias)
	return GetProperty(DynAlias, "AITWP_Political") or 0
end
function GetAgressiveness(DynAlias)
	return GetProperty(DynAlias, "AITWP_Agressive") or 0
end
function GetIntrigue(DynAlias)
	return GetProperty(DynAlias, "AITWP_Intrigue") or 0
end


function LogMovementMeasure(SimAlias)
	if GL_ENABLE_LOG > 0 and DynastyIsPlayer(SimAlias) and IsPartyMember(SimAlias) then
		local Measure = GetCurrentMeasureName(SimAlias)
		LogMessage("AITWP::MOVE::"..GetName(SimAlias).." moving in measure: "..Measure)
	end
end


function DynastyGetNumOfEnemies(Sim)
	GetDynasty(Sim,"MyDyn")
	local NumOfEnemies = 0
	if HasProperty("MyDyn","Enemy_No") then
		NumOfEnemies = GetProperty("MyDyn","Enemy_No")
	end
	
	-- we need to save this forever to keep our IDs
	local EnemyTotal = 0 
	if HasProperty("MyDyn", "Enemy_Total") then 
		EnemyTotal = GetProperty("MyDyn", "Enemy_Total")
	end
	
	if NumOfEnemies >0 and EnemyTotal >0 then
		-- check if all are still alive
		for i=0, EnemyTotal-1 do
			if HasProperty("MyDyn","Enemy_"..i) then
				local FoundID = GetProperty("MyDyn","Enemy_"..i)
				GetAliasByID(FoundID, "Enemy_"..i)
				local FoundCount = DynastyGetMemberCount("Enemy_"..i)
				if FoundCount <1 then
					-- no members alive, remove
					RemoveProperty("MyDyn","Enemy_"..i)
					NumOfEnemies = NumOfEnemies-1
					SetProperty("MyDyn","Enemy_No",NumOfEnemies)
				end
			end
		end
	end
	
	return NumOfEnemies
end

function DynastyGetNumOfAllies(Sim)
	GetDynasty(Sim,"MyDyn")
	local NumOfAllies = 0
	if HasProperty("MyDyn","Allies_No") then
		NumOfAllies = GetProperty("MyDyn","Allies_No")
	end
	
	-- we need to save this forever to keep our IDs
	local AlliesTotal = 0 
	if HasProperty("MyDyn", "Allies_Total") then 
		AlliesTotal = GetProperty("MyDyn", "Allies_Total")
	end
	
	if NumOfAllies >0 and AlliesTotal >0 then
		-- check if all are still alive
		for i=0, AlliesTotal-1 do
			if HasProperty("MyDyn","Ally_"..i) then
				local FoundID = GetProperty("MyDyn","Ally_"..i)
				GetAliasByID(FoundID, "Ally_"..i)
				local FoundCount = DynastyGetMemberCount("Ally_"..i)
				if FoundCount <1 then
					-- no members alive, remove
					RemoveProperty("MyDyn","Ally_"..i)
					NumOfAllies = NumOfAllies-1
					SetProperty("MyDyn","Allies_No",NumOfAllies)
				end
			end
		end
	end
	
	return NumOfAllies
end

function DynastyAddEnemy(Sim,Destination)
	GetDynasty(Sim,"MyDyn")
	local DesDynID = GetDynastyID(Destination)
	local NumOfEnemies = 0
	if HasProperty("MyDyn","Enemy_No") then
		NumOfEnemies = GetProperty("MyDyn","Enemy_No")
	end
	
	-- we need to save this forever to keep our IDs
	local EnemyTotal = 0 
	if HasProperty("MyDyn", "Enemy_Total") then 
		EnemyTotal = GetProperty("MyDyn", "Enemy_Total")
	end
	
	-- add it up
	NumOfEnemies = NumOfEnemies + 1
	SetProperty("MyDyn","Enemy_No",NumOfEnemies)
	EnemyTotal = EnemyTotal +1
	SetProperty("MyDyn","Enemy_Total",EnemyTotal)
	
	-- add the new unique id
	SetProperty("MyDyn","Enemy_"..(EnemyTotal-1),DesDynID)
end

function DynastyAddAlly(Sim,Destination)
	GetDynasty(Sim,"MyDyn")
	local DesDynID = GetDynastyID(Destination)
	local NumOfAllies = 0
	if HasProperty("MyDyn","Allies_No") then
		NumOfAllies = GetProperty("MyDyn","Allies_No")
	end
	
	-- we need to save this forever to keep our IDs
	local AlliesTotal = 0 
	if HasProperty("MyDyn", "Allies_Total") then 
		AlliesTotal = GetProperty("MyDyn", "Allies_Total")
	end
	
	-- add it up
	NumOfAllies = NumOfAllies+1
	SetProperty("MyDyn","Allies_No",NumOfAllies)
	AlliesTotal = AlliesTotal +1
	SetProperty("MyDyn","Allies_Total",AlliesTotal)
	
	-- add the new unique ally id
	SetProperty("MyDyn","Ally_"..(AlliesTotal-1),DesDynID)
end

function DynastyRemoveEnemy(Sim,Destination)
	GetDynasty(Sim, "MyDyn")
	local DesDynID = GetDynastyID(Destination)
	local NumOfEnemies = 0
	if HasProperty("MyDyn","Enemy_No") then
		NumOfEnemies = GetProperty("MyDyn","Enemy_No")
	end
	
	-- we need to save this forever to keep our IDs
	local EnemyTotal = 0 
	if HasProperty("MyDyn", "Enemy_Total") then 
		EnemyTotal = GetProperty("MyDyn", "Enemy_Total")
	end
	
	-- remove the id
	for i=0, EnemyTotal-1 do
		if HasProperty("MyDyn","Enemy_"..i) then
			if GetProperty("MyDyn", "Enemy_"..i) == DesDynID then
				RemoveProperty("MyDyn", "Enemy_"..i)
			end
		end
	end
	
	-- substract it
	NumOfEnemies = NumOfEnemies - 1
	SetProperty("MyDyn","Enemy_No",NumOfEnemies)
end

function DynastyRemoveAlly(Sim,Destination)
	GetDynasty(Sim, "MyDyn")
	local DesDynID = GetDynastyID(Destination)
	local NumOfAllies = 0
	if HasProperty("MyDyn","Allies_No") then
		NumOfAllies = GetProperty("MyDyn","Allies_No")
	end
	
		-- we need to save this forever to keep our IDs
	local AlliesTotal = 0 
	if HasProperty("MyDyn", "Allies_Total") then 
		AlliesTotal = GetProperty("MyDyn", "Allies_Total")
	end
	
	-- remove the id
	for i=0, AlliesTotal-1 do
		if HasProperty("MyDyn","Ally_"..i) then
			if GetProperty("MyDyn", "Ally_"..i) == DesDynID then
				RemoveProperty("MyDyn", "Ally_"..i)
			end
		end
	end
	
	-- substract it
	NumOfAllies = NumOfAllies - 1
	SetProperty("MyDyn","Allies_No",NumOfAllies)
end

-- Replace FindOfficeForApplication in Library/aitwp.lua with this:


function CanRunForThisOffice(SimAlias, OfficeAlias)
	-- city alias
	local CityAlias = "AITWP_CanRunForThisOffice_Settlement" 
	if not GetSettlement(SimAlias, CityAlias) then
		return false
	end
	-- nobility check
	local MyTitle = GetNobilityTitle(SimAlias)
	if MyTitle < 4 then
		return false
	elseif MyTitle < 5 and OfficeGetLevel(OfficeAlias) > 1 then
		return false
	end
	-- diplo check
	if OfficeGetHolder(OfficeAlias, "OfficeHolder")  then
		if (GetDynastyID(SimAlias) == GetDynastyID("OfficeHolder") or DynastyGetDiplomacyState(SimAlias,"OfficeHolder")==DIP_ALLIANCE) then
			return false
		end
	end
	
	-- applicant count check
	local ApplicantCount = OfficeGetApplicantCount(OfficeAlias)
	if ApplicantCount >= 4 then
		return false
	end
	if DynastyIsShadow(SimAlias) and OfficeGetShadowApplicantCount(OfficeAlias) >= 3 then
		return false
	end
		
	-- don't run for lower or same level offices
	local SimCurLevel = SimGetOfficeLevel(SimAlias)
	local OfficeLevel = OfficeGetLevel(OfficeAlias)
	if SimCurLevel >= OfficeLevel then
		return false
	end
	
	-- can afford the application cost
	local ChargeCost  = OfficeGetChargeCost(OfficeAlias)
	if GetMoney(SimAlias) < ChargeCost then
		return false
	end
	
	-- sim must go step by step on the office ladder
	local SimMaxLevel = SimGetMaxOfficeLevel(SimAlias)
	if OfficeLevel > SimMaxLevel+1 then
		return false
	end
	
	
	-- checks passed
	return true
end


function FindOfficeForApplication(SimAlias, RetOfficeAlias)
	local CityAlias = "AITWP_OfficeApplicationSettlement" 
	if not GetSettlement(SimAlias, CityAlias) then
		return false
	end

	-- find range of available office levels
	local CityMaxLevel = CityGetHighestOfficeLevel(CityAlias)
	
	local found = false
	
	-- start at max level and go down, looking for a good office to apply to
	for i=CityMaxLevel, 0,-1 do
		local LevelOfficeCount = SettlementGetOfficeCnt(CityAlias, i)
		for j=0, LevelOfficeCount-1 do
			local OfficeAlias = "AITWP_CurrentOfficeToCheck"
			SettlementGetOffice(CityAlias, i, j, OfficeAlias)
			if aitwp_CanRunForThisOffice(SimAlias,OfficeAlias) then
				found = true
				CopyAlias(OfficeAlias, RetOfficeAlias)
				-- we don't want to always select the first office at curent level so there's 50/50 chance to keep searching 
				-- it will fall back to our original find if we don't find anything else
				if Rand(2)==1 then
					return true
				end
			end
		end
	end
	if found then
		return true
	end
	return false
end
