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
		LogMessage("::TWP::ENEMY " .. utility_Stamp(DynAlias) .. " goaltarget=" .. GoalTarget .. " cand=" .. Cands .. " pick=" .. BestID)
	end
	return BestID
end

---
-- Picks a building owned by OwnerAlias (a dynasty or one of its sims) into OutAlias.
-- Class filters by building class, -1 for any; resources are never returned.
-- Mode "strongest" takes the highest level (workshops first) - the target that
-- hurts most; "weakest" the lowest - the one to give up in a forced sale.
-- Ties fall to the lower index, so every peer picks the same building.
function FindTargetBuilding(OwnerAlias, Class, Mode, OutAlias)
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
			if BClass ~= GL_BUILDING_CLASS_RESOURCE and (Class == -1 or BClass == Class) then
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
		LogMessage("::TWP::BLD t=" .. string.format("%.2f", GetGametime()) .. " owner=" .. GetID(Owner)
			.. " mode=" .. Mode .. " class=" .. Class .. " cand=" .. Cands .. " pick=" .. Best)
	end
	local Found = false
	if Best >= 0 then
		Found = DynastyGetBuilding2(Owner, Best, OutAlias)
	end
	RemoveAlias("TWP_Owner")
	return Found
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
		LogMessage("::TWP::BELIEVER t=" .. string.format("%.2f", GetGametime()) .. " actor=" .. MyID .. " victim=" .. VictimID
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
			LogMessage("::TWP::MEMBER dyn=" .. DynID .. " sim=" .. GetName("TWP_Snap"))
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
	LogMessage("::TWP::SNAPSHOT t=" .. math.floor(GetGametime()) .. " round=" .. GetRound()
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
					LogMessage("::TWP::BLOODENEMY player=" .. PlayerID .. " enemy=" .. GetID(Cand) .. " name=" .. GetName(Cand))
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

-- Outdoors and further than TWP_TOWN_RADIUS from the nearest settlement: on the
-- road, in the fields, at the mine - where a party of thugs can reach someone.
TWP_TOWN_RADIUS = 6000
function IsOutsideTown(Alias)
	if SimIsInside(Alias) then
		return false
	end
	if not GetNearestSettlement(Alias, "TWP_Town") then
		return true
	end
	local Far = GetDistance(Alias, "TWP_Town") > TWP_TOWN_RADIUS
	RemoveAlias("TWP_Town")
	return Far
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

-- The forgery the SIM can use now: a Hexerdokument it holds, else one the market
-- sells and the treasury covers (II before I). nil when neither.
function ForgeryDocument(SimAlias, DynAlias, PlayerDyn)
	local Documents = { "HexerdokumentII", "HexerdokumentI" }
	local Tools = { "forge2", "forge1" }
	for i = 1, 2 do
		local Item = Documents[i]
		if aitwp_Allowed(DynAlias, PlayerDyn, Tools[i]) and GetRepeatTimerLeft(SimAlias, GetMeasureRepeatName2("Use" .. Item)) <= 0 then
			if GetItemCount(SimAlias, Item, INVENTORY_STD) > 0 then
				return Item
			end
			local Price = ai_CanBuyItem(SimAlias, Item)
			if Price >= 0 and GetMoney(DynAlias) >= Price then
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

-- Someone in the house lacking a piece of the tier. Party members and thugs buy at
-- the market ("buyweapon"/"buyarmor"); employees are issued theirs ("issue").
-- Sets OutAlias plus data EquipItem/EquipMode; returns true on success.
function FindUnequipped(DynAlias, Tier, OutAlias)
	local Count = DynastyGetMemberCount(DynAlias)
	for i = 0, Count - 1 do
		if DynastyGetMember(DynAlias, i, "TWP_Eq") and dyn_IsIdleMember("TWP_Eq") and SimGetAge("TWP_Eq") >= 16 then
			local Item, Kind = aitwp_MissingEquipment("TWP_Eq", Tier)
			if Item and ai_CanBuyItem("TWP_Eq", Item) >= 0 then
				CopyAlias("TWP_Eq", OutAlias)
				RemoveAlias("TWP_Eq")
				SetData("EquipItem", Item)
				SetData("EquipMode", "buy" .. Kind)
				return true
			end
		end
	end
	Count = DynastyGetWorkerCount(DynAlias, GL_PROFESSION_MYRMIDON)
	for i = 0, Count - 1 do
		if DynastyGetWorker(DynAlias, GL_PROFESSION_MYRMIDON, i, "TWP_Eq") and GetState("TWP_Eq", STATE_IDLE) then
			local Item, Kind = aitwp_MissingEquipment("TWP_Eq", Tier)
			if Item and ai_CanBuyItem("TWP_Eq", Item) >= 0 then
				CopyAlias("TWP_Eq", OutAlias)
				RemoveAlias("TWP_Eq")
				SetData("EquipItem", Item)
				SetData("EquipMode", "buy" .. Kind)
				return true
			end
		end
	end
	Count = DynastyGetWorkerCount(DynAlias, -1)
	for i = 0, Count - 1 do
		if DynastyGetWorker(DynAlias, -1, i, "TWP_Eq") and SimGetProfession("TWP_Eq") ~= GL_PROFESSION_MYRMIDON then
			local Item = aitwp_MissingEquipment("TWP_Eq", Tier)
			if Item and CanAddItems("TWP_Eq", Item, 1, INVENTORY_EQUIPMENT) then
				CopyAlias("TWP_Eq", OutAlias)
				RemoveAlias("TWP_Eq")
				SetData("EquipItem", Item)
				SetData("EquipMode", "issue")
				return true
			end
		end
	end
	RemoveAlias("TWP_Eq")
	return false
end

-- Hands the piece over: a market purchase by the sim itself, or an issue from the
-- treasury at base price (paid by a party member) straight into the equipment.
function Equip(DynAlias, Alias, Item, Mode)
	if Mode == "buyweapon" then
		SetProperty(Alias, "AIBuyWeapon", Item)
		MeasureRun(Alias, nil, "AIBuyWeapon")
	elseif Mode == "buyarmor" then
		SetProperty(Alias, "AIBuyArmor", Item)
		MeasureRun(Alias, nil, "AIBuyArmor")
	else
		local Price = ItemGetBasePrice(Item) or 0
		if GetMoney(DynAlias) < Price + 2000 then
			return
		end
		if dyn_GetIdleMember(DynAlias, "TWP_Payer") or DynastyGetMember(DynAlias, 0, "TWP_Payer") then
			chr_SpendMoney("TWP_Payer", Price, "Equipment", true)
		end
		RemoveAlias("TWP_Payer")
		AddItems(Alias, Item, 1, INVENTORY_EQUIPMENT)
	end
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
	{ name = "toad_slime", rung = 4, class = "P", item = "Toadslime", target = "building" }, { name = "ambush", rung = 4, class = "P" },
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
end
-- classes each attitude may use; neutrals and friends use none
TWP_ATTITUDE_CLASSES = { blood = "REPLOD", feud = "EPLO", enemy = "EPLO", friend = "", neutral = "" }

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
		if T.item and T.target and aitwp_Allowed(DynAlias, PlayerDyn, T.name) then
			N = N + 1
			OutList[N] = T.item
		end
	end
	return N
end

-- true when a party member, a thug or the residence already holds the item
function HasStock(DynAlias, Item)
	if GetHomeBuilding(DynAlias, "TWP_HS") and GetItemCount("TWP_HS", Item, INVENTORY_STD) > 0 then
		RemoveAlias("TWP_HS")
		return true
	end
	RemoveAlias("TWP_HS")
	local Count = DynastyGetMemberCount(DynAlias)
	for i = 0, Count - 1 do
		if DynastyGetMember(DynAlias, i, "TWP_HS") and GetItemCount("TWP_HS", Item, INVENTORY_STD) > 0 then
			RemoveAlias("TWP_HS")
			return true
		end
	end
	Count = DynastyGetWorkerCount(DynAlias, GL_PROFESSION_MYRMIDON)
	for i = 0, Count - 1 do
		if DynastyGetWorker(DynAlias, GL_PROFESSION_MYRMIDON, i, "TWP_HS") and GetItemCount("TWP_HS", Item, INVENTORY_STD) > 0 then
			RemoveAlias("TWP_HS")
			return true
		end
	end
	RemoveAlias("TWP_HS")
	return false
end

-- true when Alias carries any artefact of the ladder
function CarriesArtefact(Alias)
	for i = 1, #TWP_TOOL_LIST do
		local Item = TWP_TOOL_LIST[i].item
		if Item and GetItemCount(Alias, Item, INVENTORY_STD) > 0 then
			return true
		end
	end
	return false
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
	LogMessage("::TWP::AI:: " .. Who .. Message)
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
