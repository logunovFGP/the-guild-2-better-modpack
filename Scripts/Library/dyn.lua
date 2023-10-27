-------------------------------------------------------------------------------
----
----	OVERVIEW "dyn"
----
----	Script functions library for dynasty issues
----
-------------------------------------------------------------------------------

-- -----------------------
-- Init
-- -----------------------
function Init()
 --needed for caching
end

-- -----------------------
-- IsLocalPlayer
-- -----------------------
function IsLocalPlayer(Object)
	GetLocalPlayerDynasty("LocPlayDyn")
	if GetID("LocPlayDyn") == GetDynastyID(Object) then
		return true
	else
		return false
	end
end

-- -----------------------
-- BlockEvilMeasures
-- -----------------------
function BlockEvilMeasures(BlockerDynAlias, BlockerDynID, Duration)

	if HasProperty(BlockerDynAlias, "NoEvilFrom"..BlockerDynID) then
		local ref = GetProperty(BlockerDynAlias, "NoEvilFrom"..BlockerDynID)
		SetProperty(BlockerDynAlias, "NoEvilFrom"..BlockerDynID, ref+1)
	else
		SetProperty(BlockerDynAlias, "NoEvilFrom"..BlockerDynID, 1)
	end
		
	-- This scriptcall will reset the effect
	CreateScriptcall("RemoveBlockEvilMeasures", Duration, "Library/dyn.lua", "RemoveBlockEvilMeasures", BlockerDynAlias, nil, BlockerDynID)
end

-- -----------------------
-- RemoveBlockEvilMeasures
-- -----------------------
function RemoveBlockEvilMeasures(BlockerDynID)

	if HasProperty("", "NoEvilFrom"..BlockerDynID) then
		
		local ref = GetProperty("", "NoEvilFrom"..BlockerDynID)
			
		if (ref == 1) then
			RemoveProperty("", "NoEvilFrom"..BlockerDynID)
		else
			SetProperty("", "NoEvilFrom"..BlockerDynID, ref-1)
			return true
		end
	end
		
	return false
end

-- -----------------------
-- EvilMeasuresBlocked
-- -----------------------
function EvilMeasuresBlocked(Blocked, Blocker)

	GetDynasty(Blocker, "DestDyn")
	if HasProperty("DestDyn", "NoEvilFrom"..GetDynastyID(Blocked)) then			
		GetDynasty(Blocked, "DestDyn")
		MsgBoxNoWait(Blocked, Blocker, "_GENERAL_ERROR_HEAD_+0", "@L_GENERAL_MEASURES_FAILURES_+17", GetID("DestDyn"))
		return true
	else
		return false
	end						
end

-- -----------------------
-- GetValidMember (return: ID)
-- -----------------------
function GetValidMember(Dynasty)

	local Count = DynastyGetFamilyMemberCount(Dynasty)
	local BossID = -1
	
	for i=0, Count-1 do
		if DynastyGetFamilyMember(Dynasty, i, "Member") then
			if AliasExists("Member") then
				if GetDynastyID(Dynasty) == GetDynastyID("Member") then
					if not GetState("Member", STATE_DYING) then
						if not GetState("Member", STATE_DEAD) then
							if SimGetAge("Member") >= 16 then
								CopyAlias("Member", "DynastyBoss")
								break
							end
						end
					end
				end
			end
		end
	end
	
	if not AliasExists("DynastyBoss") and AliasExists("Member") then
		CopyAlias("Member", "DynastyBoss")
	end
	
	BossID = GetID("DynastyBoss")
	return BossID
end

-- -----------------------
-- GetWorkshopCount
-- -----------------------
function GetWorkshopCount(SimAlias)

	local buildingcount = 0
	local Count = DynastyGetBuildingCount2(SimAlias)
	local Class
	
	for l=0, Count-1 do
		if DynastyGetBuilding2(SimAlias, l, "Check") then
			Class = BuildingGetClass("Check")
			if Class == GL_BUILDING_CLASS_WORKSHOP then
				buildingcount = buildingcount + 1
			end
		end
	end
	
	return buildingcount
end

-- -----------------------
-- CheckForWorkshop
-- -----------------------
function CheckForWorkshop(SimAlias, BuildingType)

	local Found = false
	local Count = DynastyGetBuildingCount2(SimAlias)
	for i=0, Count-1 do
		if DynastyGetBuilding2(SimAlias, i, "CheckWorkshop") then
			if BuildingGetType("CheckWorkshop") == BuildingType then
				Found = true
				break
			end
		end
	end
	
	return Found
end

-- -----------------------
-- FindGoodWorkshopType
-- -----------------------
function FindGoodWorkshopType(SimAlias, CityAlias, BuildNew)
	LogMessage("Looking for a good workshop type")
	
	if not AliasExists(SimAlias) then
		LogMessage("Workshop-Type: No Alias")
		return 0
	end
	
	if not AliasExists(CityAlias) then
		LogMessage("Workshop-Type: No City Alias")
		return 0
	end
	
	if not GetDynasty(SimAlias, "MyDyn") then
		LogMessage("Workshop-Type: No Dynasty found")
		return 0
	end
	
	local BestType = 0
	local Count = DynastyGetBuildingCount2(SimAlias)
	
	-- get all the group members for their character classes
	local PartySize = DynastyGetMemberCount(SimAlias)
	local PartyPatrons = 0
	local PartyScholars = 0
	local PartyRogues = 0
	local PartyCraftsmen = 0
	local CheckClass = 0

	for i=0, PartySize-1 do
		DynastyGetMember(SimAlias, i, "CheckSim")
		CheckClass = SimGetClass("CheckSim")
		
		if CheckClass == GL_CLASS_PATRON then
			PartyPatrons = PartyPatrons + 1
		elseif CheckClass == GL_CLASS_ARTISAN then
			PartyCraftsmen = PartyCraftsmen + 1
		elseif CheckClass == GL_CLASS_SCHOLAR then
			PartyScholars = PartyScholars + 1
		elseif CheckClass == GL_CLASS_CHISELER then
			PartyRogues = PartyRogues + 1
		end
	end
	
	-- add all the buildings to this list
	local BuildingList = {}
	local FoundType
	local FoundPatrons = 0
	local FoundScholars = 0
	local FoundRogues = 0
	local FoundCraftsmen = 0
	
	for i=0, Count-1 do
		if DynastyGetBuilding2(SimAlias, i, "AddBuilding") then
			FoundType = BuildingGetType("AddBuilding")
			BuildingList[i+1] = FoundType
			local FoundClass = BuildingGetCharacterClass("AddBuilding")
			if FoundClass == GL_CLASS_PATRON then
				FoundPatrons = FoundPatrons + 1
			elseif FoundClass == GL_CLASS_ARTISAN then
				FoundCraftsmen = FoundCraftsmen + 1
			elseif FoundClass == GL_CLASS_SCHOLAR then
				FoundScholars = FoundScholars + 1
			elseif FoundClass == GL_CLASS_CHISELER then
				FoundRogues = FoundRogues + 1
			end
		end
	end
	
	-- check if we have at least one building for each class of our party
	local EnoughPatrons = false
	if PartyPatrons <= FoundPatrons then
		EnoughPatrons = true
	end
	
	local EnoughScholars = false
	if PartyScholars <= FoundScholars then
		EnoughScholars = true
	end
	
	local EnoughCraftsmen = false
	if PartyCraftsmen <= FoundCraftsmen then
		EnoughCraftsmen = true
	end
	
	local EnoughRogues = false
	if PartyRogues <= FoundRogues then
		EnoughRogues = true
	end
	
	-- First, check if we have classes in our group without a proper workshop.
	local BestCount = 5
	
	if not EnoughPatrons then
		-- if possible, choose a building which is only present max. once in the city already
		local PatronBuildingTypes = { GL_BUILDING_TYPE_BAKERY, GL_BUILDING_TYPE_FARM, GL_BUILDING_TYPE_FRUITFARM, GL_BUILDING_TYPE_MILL, GL_BUILDING_TYPE_TAVERN, GL_BUILDING_TYPE_FISHINGHUT }
		local PatronBuildingTypesCount = 6
		
		for i=1, PatronBuildingTypesCount do
			local ChooseType = PatronBuildingTypes[i]
			local CheckCount = CityGetBuildingCount(CityAlias, -1, ChooseType, -1, -1, FILTER_HAS_DYNASTY)
			if CheckCount < 3 then -- max 2 already existing of the same type in the same city
				if not BuildNew then
					local AvailableCount = CityGetBuildingCount(CityAlias, -1, ChooseType, -1, -1, FILTER_NO_DYNASTY)
					if AvailableCount <= BestCount then
						BestType = ChooseType
						BestCount = CheckCount
						break
					end
				else
					-- exclude types the AI can't properly build
					if ChooseType == GL_BUILDING_TYPE_FARM or GL_BUILDING_TYPE_FRUITFARM or GL_BUILDING_TYPE_FISHINGHUT then
						local AvailableCount = CityGetBuildingCount(CityAlias, -1, ChooseType, -1, -1, FILTER_NO_DYNASTY)
						if AvailableCount <= BestCount then
							BestType = ChooseType
							BestCount = CheckCount
							break
						end
					else
						if CheckCount <= BestCount then
							BestType = ChooseType
							BestCount = CheckCount
							break
						end
					end
				end
			end
		end
	end
	
	if BestType == 0 then -- still no best type? then check next class
		if not EnoughScholars then
			-- if possible, choose a building which is only present max. once in the city already
			local ScholarBuildingTypes = { GL_BUILDING_TYPE_ALCHEMIST, GL_BUILDING_TYPE_CHURCH_CATH, GL_BUILDING_TYPE_CHURCH_EV, GL_BUILDING_TYPE_NEKRO, 
									GL_BUILDING_TYPE_BANKHOUSE, GL_BUILDING_TYPE_HOSPITAL }
			local ScholarBuildingTypesCount = 6
			
			for i=1, ScholarBuildingTypesCount do
				local ChooseType = ScholarBuildingTypes[i]
				local CheckCount = CityGetBuildingCount(CityAlias, -1, ChooseType, -1, -1, FILTER_HAS_DYNASTY)
				if CheckCount < 3 then -- max 2 already existing of the same type in the same city
					if not BuildNew then
						local AvailableCount = CityGetBuildingCount(CityAlias, -1, ChooseType, -1, -1, FILTER_NO_DYNASTY)
						if AvailableCount <= BestCount then
							BestType = ChooseType
							BestCount = CheckCount
							break
						end
					else
						if CheckCount <= BestCount then
							BestType = ChooseType
							BestCount = CheckCount
							break
						end
					end
				end
			end
		end
	end
	
	if BestType == 0 then -- still no best type? then check next class
		if not EnoughCraftsmen then
			-- if possible, choose a building which is only present max. once in the city already
			local CraftsmenBuildingTypes = { GL_BUILDING_TYPE_MINE, GL_BUILDING_TYPE_RANGERHUT, GL_BUILDING_TYPE_SMITHY, GL_BUILDING_TYPE_TAILORING, GL_BUILDING_TYPE_JOINERY, 
									GL_BUILDING_TYPE_STONEMASON }
			local CraftsmenBuildingTypesCount = 6
			
			for i=1, CraftsmenBuildingTypesCount do
				local ChooseType = CraftsmenBuildingTypes[i]
				local CheckCount = CityGetBuildingCount(CityAlias, -1, ChooseType, -1, -1, FILTER_HAS_DYNASTY)
				if CheckCount < 3 then -- max 2 already existing of the same type in the same city
					if not BuildNew then
						local AvailableCount = CityGetBuildingCount(CityAlias, -1, ChooseType, -1, -1, FILTER_NO_DYNASTY)
						if AvailableCount <= BestCount then
							BestType = ChooseType
							BestCount = CheckCount
							break
						end
					else
						if CheckCount <= BestCount then
							BestType = ChooseType
							BestCount = CheckCount
							break
						end
					end
				end
			end
		end
	end
	
	if BestType == 0 then -- still no best type? then check next class
		if not EnoughRogues then
			-- if possible, choose a building which is only present max. once in the city already
			local RoguesBuildingTypes = { GL_BUILDING_TYPE_ROBBER, GL_BUILDING_TYPE_PIRATESNEST, GL_BUILDING_TYPE_THIEF, GL_BUILDING_TYPE_DIVEHOUSE, GL_BUILDING_TYPE_JUGGLER, 
									GL_BUILDING_TYPE_MERCENARY }
			local RoguesBuildingTypesCount = 6
			
			for i=1, RoguesBuildingTypesCount do
				local ChooseType = RoguesBuildingTypes[i]
				local CheckCount = CityGetBuildingCount(CityAlias, -1, ChooseType, -1, -1, FILTER_HAS_DYNASTY)
				if CheckCount < 3 then -- max 2 already existing of the same type in the same city
					if not BuildNew then
						local AvailableCount = CityGetBuildingCount(CityAlias, -1, ChooseType, -1, -1, FILTER_NO_DYNASTY)
						if AvailableCount <= BestCount then
							BestType = ChooseType
							BestCount = CheckCount
							break
						end
					else
						-- exclude types the AI can't properly build
						if ChooseType == GL_BUILDING_TYPE_ROBBER or GL_BUILDING_TYPE_PIRATESNEST then
							local AvailableCount = CityGetBuildingCount(CityAlias, -1, ChooseType, -1, -1, FILTER_NO_DYNASTY)
							if AvailableCount <= BestCount then
								BestType = ChooseType
								BestCount = CheckCount
								break
							end
						else
							if CheckCount <= BestCount then
								BestType = ChooseType
								BestCount = CheckCount
								break
							end
						end
					end
				end
			end
		end
	end
	
	if BestType == 0 then
		-- If we do have buildings for everyone, if you still need more get a random one we don't already own
		local NewBuildingList = {}
		local NewBuildingListCount = 0
		if PartyPatrons > 0 then -- add patron buildings
			local PatronBuildingTypes = { GL_BUILDING_TYPE_BAKERY, GL_BUILDING_TYPE_FARM, GL_BUILDING_TYPE_FRUITFARM, GL_BUILDING_TYPE_MILL, GL_BUILDING_TYPE_TAVERN, GL_BUILDING_TYPE_FISHINGHUT }
			local PatronBuildingTypesCount = 6
			
			for i=1, PatronBuildingTypesCount do
				if not dyn_CheckForWorkshop(SimAlias, PatronBuildingTypes[i]) then -- only add if we do not have that in our dynasty already
					NewBuildingList[i] = PatronBuildingTypes[i]
					NewBuildingListCount = NewBuildingListCount + 1
				end
			end
		end
		
		if PartyScholars > 0 then -- add scholar buildings
			local ScholarBuildingTypes = { GL_BUILDING_TYPE_ALCHEMIST, GL_BUILDING_TYPE_CHURCH_CATH, GL_BUILDING_TYPE_CHURCH_EV, GL_BUILDING_TYPE_NEKRO, 
									GL_BUILDING_TYPE_BANKHOUSE, GL_BUILDING_TYPE_HOSPITAL }
			local ScholarBuildingTypesCount = 6
			
			for i=NewBuildingListCount, ScholarBuildingTypesCount do
				if not dyn_CheckForWorkshop(SimAlias, ScholarBuildingTypes[i]) then -- only add if we do not have that in our dynasty already
					NewBuildingList[i] = ScholarBuildingTypes[i]
					NewBuildingListCount = NewBuildingListCount + 1
				end
			end
		end
		
		if PartyCraftsmen > 0 then -- add craftsmen buildings
			local CraftsmenBuildingTypes = { GL_BUILDING_TYPE_MINE, GL_BUILDING_TYPE_RANGERHUT, GL_BUILDING_TYPE_SMITHY, GL_BUILDING_TYPE_TAILORING, GL_BUILDING_TYPE_JOINERY, 
									GL_BUILDING_TYPE_STONEMASON }
			local CraftsmenBuildingTypesCount = 6
			
			for i=NewBuildingListCount, CraftsmenBuildingTypesCount do
				if not dyn_CheckForWorkshop(SimAlias, CraftsmenBuildingTypes[i]) then -- only add if we do not have that in our dynasty already
					NewBuildingList[i] = CraftsmenBuildingTypes[i]
					NewBuildingListCount = NewBuildingListCount + 1
				end
			end
		end
		
		if PartyRogues > 0 then -- add rouges buildings
			local RoguesBuildingTypes = { GL_BUILDING_TYPE_ROBBER, GL_BUILDING_TYPE_PIRATESNEST, GL_BUILDING_TYPE_THIEF, GL_BUILDING_TYPE_DIVEHOUSE, GL_BUILDING_TYPE_JUGGLER, 
									GL_BUILDING_TYPE_MERCENARY }
			local RoguesBuildingTypesCount = 6
			
			for i=NewBuildingListCount, RoguesBuildingTypesCount do
				if not dyn_CheckForWorkshop(SimAlias, RoguesBuildingTypes[i]) then -- only add if we do not have that in our dynasty already
					NewBuildingList[i] = RoguesBuildingTypes[i]
					NewBuildingListCount = NewBuildingListCount + 1
				end
			end
		end

		if NewBuildingListCount == 0 then
			LogMessage("Workshop Type: NewBuildingList is empty")
			return 0
		end
	
		-- select at random now
		local Randomizer = Rand(NewBuildingListCount) + 1
		BestType = NewBuildingList[Randomizer]
	end
	
	--LogMessage("BestType is "..BestType)
	return BestType
end

-- -----------------------
-- Guildhouse Fame Functions
-- -----------------------
function GetFame(SimAlias)
	
	if not IsDynastySim(SimAlias) then
		return -1
	end
	
	local fame = 0

	if GetDynasty(SimAlias, "family") then
		if GetProperty("family", "Fame") then
			fame = GetProperty("family", "Fame")
		else
			SetProperty("family", "Fame", 0)
		end
	end

	return fame
end

function AddFame(SimAlias, Amount)
	
	if not IsDynastySim(SimAlias) then
		return
	end
	
	local fame = 0 + dyn_GetFame(SimAlias)
	
	-- amount is increased by abilities
	local GuildAbil = GetImpactValue(SimAlias, "GuildMasterI")
	Amount = Amount + GuildAbil
	
	-- new family fame
	if GetDynasty(SimAlias, "family") then
		SetProperty("family", "Fame", (fame+Amount))
	end
	
	-- save personal fame
	if not HasProperty(SimAlias, "GuildFame") then
		SetProperty(SimAlias, "GuildFame", 0)
	end
	local SimFame = GetProperty(SimAlias, "GuildFame") or 0
	SetProperty(SimAlias, "GuildFame", (SimFame+Amount))
end

function RemoveFame(SimAlias, Amount)
	
	if not IsDynastySim(SimAlias) then
		return
	end
	
	local fame = 0 + dyn_GetFame(SimAlias)
	
	if GetDynasty(SimAlias, "family") then
		SetProperty("family", "Fame", (fame-Amount))
	end
	
	-- save the fame earned by the sim
	if not HasProperty(SimAlias, "GuildFame") then
		SetProperty(SimAlias, "GuildFame", 0)
	end
	
	local SimFame = 0 + GetProperty(SimAlias, "GuildFame")
	SetProperty(SimAlias, "GuildFame", (SimFame-Amount))
end

function GetFameLevel(SimAlias)

	if not IsDynastySim(SimAlias) then
		return -1
	end
	
	local fame = 0 + dyn_GetFame(SimAlias)

	if fame < GL_FAME_POINTS_KNOWN then
		return 0
	elseif fame < GL_FAME_POINTS_NOTED then
		return 1
	elseif fame < GL_FAME_POINTS_RESPECTED then
		return 2
	elseif fame < GL_FAME_POINTS_LIKED then
		return 3
	elseif fame < GL_FAME_POINTS_FAMOUS then
		return 4
	else
		return 5
	end
end

-- -----------------------
-- Imperial Fame Functions
-- -----------------------
function GetImperialFame(SimAlias)
	
	if not IsDynastySim(SimAlias) then
		return -1
	end
	
	local fame = 0

	if GetDynasty(SimAlias, "family") then
		if GetProperty("family", "ImperialFame") then
			fame = GetProperty("family", "ImperialFame")
		else
			SetProperty("family", "ImperialFame", 0)
		end
	end

	return fame
end

function AddImperialFame(SimAlias, Amount)
	
	if not IsDynastySim(SimAlias) then
		return
	end
	
	local fame = 0 + dyn_GetImperialFame(SimAlias)
	
	if GetDynasty(SimAlias, "family") then
		SetProperty("family", "ImperialFame", (fame+Amount))
	end
end

function RemoveImperialFame(SimAlias, Amount)
	if not IsDynastySim(SimAlias) then
		return
	end
	
	local fame = 0 + dyn_GetImperialFame(SimAlias)
	
	if GetDynasty(SimAlias, "family") then
		SetProperty("family", "ImperialFame", (fame-Amount))
	end
end


function GetImperialFameLevel(SimAlias)

	if not IsDynastySim(SimAlias) then
		return -1
	end
	
	local fame = 0 + dyn_GetImperialFame(SimAlias)

	if fame < GL_IMPERIAL_FAME_POINTS_KNOWN then
		return 0
	elseif fame < GL_IMPERIAL_FAME_POINTS_NOTED then
		return 1
	elseif fame < GL_IMPERIAL_FAME_POINTS_RESPECTED then
		return 2
	elseif fame < GL_IMPERIAL_FAME_POINTS_LIKED then
		return 3
	elseif fame < GL_IMPERIAL_FAME_POINTS_FAMOUS then
		return 4
	else
		return 5
	end
end

-- -----------------------
-- ModifyFavor
-- needs 2 sims of the dynasties
-- no rattle the chains / overhead feedback (see chr_ModifyFavor)
-- -----------------------
function ModifyFavor(source, dest, val)
	
	local SourceTitle = 0
	local DestinationTitle = 0
	local Diplo = DynastyGetDiplomacyState(source, dest)
		
	if Diplo == DIP_ALLIANCE and val < 0 then
	-- harder to lose if you are friends
		val = math.floor(val / 2)
	elseif Diplo == DIP_FOE and val > 0 then
	-- harder to gain if you are enemies
		val = math.floor(val / 2)
	else
		-- check title-difference
		SourceTitle = 0 + GetNobilityTitle(source)
		DestinationTitle = 0 + GetNobilityTitle(dest)
			
		if val > 0 then
		-- harder to gain favor
			if (SourceTitle + 2) < DestinationTitle then
				val = math.floor(val / 2)
				if (SourceTitle + 4) < DestinationTitle then
					val = math.floor(val / 2)
				end
			end
		else
		-- easier to lose favor
			if (SourceTitle + 2) < DestinationTitle then
				val = math.floor(val*1.5)
				if (SourceTitle + 4) < DestinationTitle then
					val = math.floor(val*1.5)
				end
			end
		end
	end
	
	-- grudge and fondness
	if GetDynasty(source, "MyDyn") then
		local TargetID = GetDynastyID(dest)
		if HasProperty("MyDyn", "Grudge"..TargetID) then
			-- grudges reduce positive favor and raise losts
			val = math.ceil(val - (GetProperty("MyDyn", "Grudge"..TargetID))*1.5)
		elseif HasProperty("MyDyn", "Fondness"..TargetID) then
			-- fondness makes your bond stronger
			val = math.floor(val + (GetProperty("MyDyn", "Fondness"..TargetID))*1.5)
		end
	end
	
	if IsDynastySim(source) and IsDynastySim(dest) then
		if GetDynastyID(source) ~= GetDynastyID(dest) then
			-- add new grudges
			if val <= -20 then
				dyn_AddGrudge(source, dest)
			elseif val >= 20 then
			-- add new fondness
				dyn_AddFondness(source, dest)
			end
		end
	end
	
	ModifyFavorToSim(source, dest, val)
end

-- -----------------------
-- AddGrudge. Grudges reduce the favor value in dyn_ModifyFavor and chr_ModifyFavor
-- needs 2 sims of the dynasties
-- -----------------------
function AddGrudge(source, dest)

	if GetDynasty(source, "MyDyn") and GetDynasty(dest, "TargetDyn") then
	
		local TargetID = GetDynastyID(dest)
		local MyDynID = GetDynastyID(source)
		
		-- check for fondness first
		if HasProperty("MyDyn", "Fondness"..TargetID) then
			local FondnessCounter = GetProperty("MyDyn", "Fondness"..TargetID)
			if FondnessCounter > 1 then
				-- we are still friends, no grudge added
				SetProperty("MyDyn", "Fondness"..TargetID, FondnessCounter-1)
				SetProperty("TargetDyn", "Fondness"..MyDynID, FondnessCounter-1)
				
				feedback_FavorReduceFondness(source, dest)
				feedback_FavorReduceFondness(dest, source)
				return
			else
				RemoveProperty("MyDyn", "Fondness"..TargetID)
				RemoveProperty("TargetDyn", "Fondness"..MyDynID)
				
				feedback_FavorRemoveFondness(source, dest)
				feedback_FavorRemoveFondness(dest, source)
				return
			end
		end
		
		--check for grudges now
		if HasProperty("MyDyn", "Grudge"..TargetID) then
			local GrudgeCounter = GetProperty("MyDyn", "Grudge"..TargetID)
			if GrudgeCounter < GL_GRUDGES_MAX then
				-- it can still get worse
				SetProperty("MyDyn", "Grudge"..TargetID, GrudgeCounter+1)
				SetProperty("TargetDyn", "Grudge"..MyDynID, GrudgeCounter+1)
				
				feedback_FavorAddGrudge(source, dest)
				feedback_FavorAddGrudge(dest, source)
				return
			else
				return
			end
			
			return
		else
			-- add first grudge
			SetProperty("MyDyn", "Grudge"..TargetID, 1)
			SetProperty("TargetDyn", "Grudge"..MyDynID, 1)
			
			feedback_FavorGainGrudge(source, dest)
			feedback_FavorGainGrudge(dest, source)
			return
		end
	end
end

-- -----------------------
-- AddFondness. Fondness raises the favor in dyn_ModifyFavor and chr_ModifyFavor
-- needs 2 sims of the dynasties
-- -----------------------
function AddFondness(source, dest)

	if GetDynasty(source, "MyDyn") and GetDynasty(dest, "TargetDyn") then
	
		local TargetID = GetDynastyID(dest)
		local MyDynID = GetDynastyID(source)
		
		-- check for grudges first
		if HasProperty("MyDyn", "Grudge"..TargetID) then
			local GrudgeCounter = GetProperty("MyDyn", "Grudge"..TargetID)
			if GrudgeCounter > 0 then
				-- we had grudges from the past. Let's befriend
				if GrudgeCounter > 1 then
					SetProperty("MyDyn", "Grudge"..TargetID, GrudgeCounter-1)
					SetProperty("TargetDyn", "Grudge"..MyDynID, GrudgeCounter-1)
					
					feedback_FavorReduceGrudge(source, dest)
					feedback_FavorReduceGrudge(dest, source)
					return
				else
					RemoveProperty("MyDyn", "Grudge"..TargetID)
					RemoveProperty("TargetDyn", "Grudge"..MyDynID)
					
					feedback_FavorRemoveGrudge(source, dest)
					feedback_FavorRemoveGrudge(dest, source)
					return
				end
			end
		end
		
		--check for fondness now
		if HasProperty("MyDyn", "Fondness"..TargetID) then
			local FondnessCounter = GetProperty("MyDyn", "Fondness"..TargetID)
			if FondnessCounter < GL_FONDNESS_MAX then
				-- it can still get even better
				SetProperty("MyDyn", "Fondness"..TargetID, FondnessCounter+1)
				SetProperty("TargetDyn", "Fondness"..MyDynID, FondnessCounter+1)
				
				feedback_FavorAddFondness(source, dest)
				feedback_FavorAddFondness(dest, source)
				return
			else
				return
			end
			
			return
		else
			-- add first fondness
			SetProperty("MyDyn", "Fondness"..TargetID, 1)
			SetProperty("TargetDyn", "Fondness"..MyDynID, 1)
			
			feedback_FavorGainFondness(source, dest)
			feedback_FavorGainFondness(dest, source)
		end
	end
end

-- ---------------------
-- GetName with flag
-- DO NOT USE inside of buttons 
-- --------------------
function GetName(SimAlias, WithFlag)

	if not AliasExists(SimAlias) then
		return ""
	end

	if WithFlag and GetDynasty(SimAlias, "DynAliasForFlag") then
		local MyFlag = DynastyGetFlagNumber("DynAliasForFlag") + 29
		if DynastyIsShadow("DynAliasForFlag") then
			MyFlag = "@L$S[2045]"
		end
		return "$S[20" .. MyFlag .. "] " .. GetName(SimAlias)
	else 
		return GetName(SimAlias)
	end
end

-- ---------------------
-- GetName with flag in Buttons
-- Usage:
-- Buttons = Buttons .. "@B[" .. i .. "," .. dyn_GetNameLabel(Alias, i) .. ",]"
-- --------------------
function GetNameLabel(SimAlias, ParameterIndex)

	local MyLabel = "@L_DYNASTY_FLAG_SWITCH_+"
	if not AliasExists(SimAlias) or not GetDynasty(SimAlias, "DynAliasForFlag") then
		return MyLabel .. "0"
	end
	
	local MyFlag = DynastyGetFlagNumber("DynAliasForFlag") or 16 
	local Offset = Math.min(16, MyFlag) * 4 + ParameterIndex
	return MyLabel .. Offset
end


-- ---------------------
-- Get just the dynasty flag without Name as a label for usage in other text-labels
-- --------------------
function GetFlagLabel(SimAlias)

	if GetDynasty(SimAlias, "FlagDyn") then
		local BadgeID = DynastyGetFlagNumber("FlagDyn") + 29
		local BadgeLabel = "@L$S[20"..BadgeID.."]"
		if DynastyIsShadow("FlagDyn") then
			BadgeLabel = "@L$S[2045]"
		end
		
		return BadgeLabel
	else
		local BadgeLabel = "@L$S[2045]"
		return BadgeLabel
	end
end

-- -----------------------
-- GetEnemyCounter (slots, may get empty)
-- -----------------------
function GetEnemyCounter(SimAlias)

	GetDynasty(SimAlias, "MyDyn")
	local Enemies = GetProperty("MyDyn", "EnemyCounter") or 0
	
	if not Enemies or Enemies == nil or Enemies == "" then
		Enemies = 0
	end
	
	
	return Enemies
end

-- -----------------------
-- RecountEnemies (clean up the slots). This function has a cooldown for performance
-- -----------------------
function RecountEnemies(SimAlias)

	GetDynasty(SimAlias, "MyDyn")

	local EnemyCounter = 0
	local Enemies = {}
	local DynCount = ScenarioGetObjects("Dynasty", 100, "DynList")
	local CheckDyn
		
	-- check all scenario objects with type Dynasty
	for dyn=0, DynCount-1 do
		if AliasExists("DynList"..dyn) then
			local Alias = "DynList"..dyn
			CheckDyn = GetID(Alias)
			if DynastyGetDiplomacyState("MyDyn", Alias) == DIP_FOE then
				EnemyCounter = EnemyCounter + 1
				Enemies[EnemyCounter] = CheckDyn
			end
		end
	end
		
	-- Delete the old properties
	local OldEnemyCounter = dyn_GetEnemyCounter(SimAlias)
	for i=1, OldEnemyCounter do
		if HasProperty("MyDyn", "EnemyNo"..i) then
			RemoveProperty("MyDyn", "EnemyNo"..i)
		end
	end
		
	RemoveProperty("MyDyn", "EnemyCounter")
		
	-- add new counters and IDs
	if EnemyCounter > 0 then
		for i=1, EnemyCounter do
			local Add = Enemies[i]
			SetProperty("MyDyn", "EnemyNo"..i, Add)
		end
	end
		
	SetProperty("MyDyn", "EnemyCounter", EnemyCounter)
end

-- -----------------------
-- GetEnemies (actual number)
-- -----------------------
function GetEnemies(SimAlias)
	
	local NumEnemies = 0
	
	GetDynasty(SimAlias, "MyDyn")
	local EnemyCounter = dyn_GetEnemyCounter(SimAlias)
	
	for i=1, EnemyCounter do
		local DynID = GetProperty("MyDyn", "EnemyNo"..i) or 0
		if DynID > 0 then
			NumEnemies = NumEnemies + 1
		end
	end
	
	return NumEnemies
end

-- -----------------------
-- GetRandomEnemy
-- -----------------------
function GetRandomEnemy(SimAlias)
	
	local Enemies = 0
	local EnemyCounter = dyn_GetEnemyCounter(SimAlias)
	local EnemyArray = {}
	GetDynasty(SimAlias, "MyDyn")
	
	if EnemyCounter > 0 then
		for i=1, EnemyCounter do
			local DynID = GetProperty("MyDyn", "EnemyNo"..i) or 0
			if DynID > 0 then
				EnemyArray[i] = DynID
				Enemies = Enemies + 1
			end
		end
	end
	
	if Enemies == 0 then
		return 0
	elseif Enemies == 1 then
		return EnemyArray[1]
	else
		local Random = Rand(Enemies) +1
		return EnemyArray[Random]
	end
end

-- -----------------------
-- AddEnemy
-- -----------------------
function AddEnemy(SimAlias, TargetAlias)

	GetDynasty(SimAlias, "MyDyn")
	GetDynasty(TargetAlias, "TargetDyn")
	local MyID = GetID("MyDyn")
	local TargetID = GetID("TargetDyn")
	
	local MyEnemies = dyn_GetEnemyCounter(SimAlias)
	local MyNewCounter = MyEnemies + 1
	
	SetProperty("MyDyn", "EnemyCounter", MyNewCounter)
	SetProperty("MyDyn", "EnemyNo"..MyNewCounter, TargetID)
	
	local TargetEnemies = dyn_GetEnemyCounter(TargetAlias)
	local TargetNewCounter = TargetEnemies + 1
	
	SetProperty("TargetDyn", "EnemyCounter", TargetNewCounter)
	SetProperty("TargetDyn", "EnemyNo"..TargetNewCounter, MyID)
	return
end

-- -----------------------
-- RemoveEnemy
-- -----------------------
function RemoveEnemy(SimAlias, TargetAlias)
	
	GetDynasty(SimAlias, "MyDyn")
	GetDynasty(TargetAlias, "TargetDyn")
	local MyID = GetID("MyDyn")
	local TargetID = GetID("TargetDyn")
	
	local MyEnemies = dyn_GetEnemyCounter(SimAlias)
	for i=1, MyEnemies do
		if GetProperty("MyDyn", "EnemyNo"..i) == TargetID then
			SetProperty("MyDyn", "EnemyNo"..i, 0)
			break
		end
	end
	
	local TargetEnemies = dyn_GetEnemyCounter(TargetAlias)
	for i=1, TargetEnemies do
		if GetProperty("TargetDyn", "EnemyNo"..i) == MyID then
			SetProperty("TargetDyn", "EnemyNo"..i, 0)
			break
		end
	end
	
	dyn_RecountEnemies(SimAlias)
	dyn_RecountEnemies(TargetAlias)
	return
end

-- -----------------------
-- GetAllyCounter (slots, may get empty)
-- -----------------------
function GetAllyCounter(SimAlias)

	GetDynasty(SimAlias, "MyDyn")
	
	if not HasProperty("MyDyn", "AllyCounter") then
		SetProperty("MyDyn", "AllyCounter", 0)
	end
	
	local Allies = GetProperty("MyDyn", "AllyCounter") or 0
	
	if not Allies or Allies == nil or Allies == "" then
		Allies = 0
	end
	
	-- LogMessage(GetName(SimAlias).." allycounter is "..Allies)
	
	return Allies
end

-- -----------------------
-- GetAllies (actual number)
-- -----------------------
function GetAllies(SimAlias)
	
	local NumAllies = 0
	
	GetDynasty(SimAlias, "MyDyn")
	local AllyCounter = dyn_GetAllyCounter(SimAlias)
	
	if AllyCounter > 0 then
		for i=1, AllyCounter do
			local DynID = GetProperty("MyDyn", "AllyNo"..i) or 0
			if DynID > 0 then
				NumAllies = NumAllies + 1
			end
		end
	end
	
	return NumAllies
end

-- -----------------------
-- RecountAllies (clean up the slots). This function has a cooldown for performance
-- -----------------------
function RecountAllies(SimAlias)

	GetDynasty(SimAlias, "MyDyn")
	
	local AllyCounter = 0
	local Allies = {}
	local DynCount = ScenarioGetObjects("Dynasty", 100, "DynList")
	local CheckDyn
		
	-- check all scenario objects with type Dynasty
	for dyn=0, DynCount-1 do
		if AliasExists("DynList"..dyn) then
			local Alias = "DynList"..dyn
			CheckDyn = GetID(Alias)
			if DynastyGetDiplomacyState("MyDyn", Alias) == DIP_ALLIANCE then
				AllyCounter = AllyCounter + 1
				Allies[AllyCounter] = CheckDyn
			end
		end
	end
		
	-- Delete the old properties
	local OldAllyCounter = dyn_GetAllyCounter(SimAlias)
	for i=1, OldAllyCounter do
		if HasProperty("MyDyn", "AllyNo"..i) then
			RemoveProperty("MyDyn", "AllyNo"..i)
		end
	end
		
	RemoveProperty("MyDyn", "AllyCounter")
		
	-- add new counters and IDs
	if AllyCounter > 0 then
		for i=1, AllyCounter do
			local Add = Allies[i]
			SetProperty("MyDyn", "AllyNo"..i, Add)
		end
	end
		
	SetProperty("MyDyn", "AllyCounter", AllyCounter)
		
	return
end

-- -----------------------
-- GetRandomAlly
-- -----------------------
function GetRandomAlly(SimAlias)
	local Allies = 0
	local AllyCounter = dyn_GetAllyCounter(SimAlias)
	local AllyArray = {}
	GetDynasty(SimAlias, "MyDyn")
	
	if AllyCounter > 0 then
		for i=1, AllyCounter do
			local DynID = GetProperty("MyDyn", "AllyNo"..i) or 0
			if DynID > 0 then
				AllyArray[i] = DynID
				Allies = Allies + 1
			end
		end
	end
	
	if Allies == 0 then
		return 0
	elseif Allies == 1 then
		return AllyArray[1]
	else
		local Random = Rand(Allies) +1
		return AllyArray[Random]
	end
end

-- -----------------------
-- AddAlly
-- -----------------------
function AddAlly(SimAlias, TargetAlias)

	GetDynasty(SimAlias, "MyDyn")
	GetDynasty(TargetAlias, "TargetDyn")
	local MyID = GetID("MyDyn")
	local TargetID = GetID("TargetDyn")
	
	local MyAllies = dyn_GetAllyCounter(SimAlias)
	local MyNewCounter = MyAllies + 1
	
	SetProperty("MyDyn", "AllyCounter", MyNewCounter)
	SetProperty("MyDyn", "AllyNo"..MyNewCounter, TargetID)
	
	local TargetAllies = dyn_GetAllyCounter(TargetAlias)
	local TargetNewCounter = TargetAllies + 1
	
	SetProperty("TargetDyn", "AllyCounter", TargetNewCounter)
	SetProperty("TargetDyn", "AllyNo"..TargetNewCounter, MyID)
	return
end

-- -----------------------
-- RemoveAlly
-- -----------------------
function RemoveAlly(SimAlias, TargetAlias)
	
	GetDynasty(SimAlias, "MyDyn")
	GetDynasty(TargetAlias, "TargetDyn")
	local MyID = GetID("MyDyn")
	local TargetID = GetID("TargetDyn")
	
	local MyAllies = dyn_GetAllyCounter(SimAlias)
	for i=1, MyAllies do
		if GetProperty("MyDyn", "AllyNo"..i) == TargetID then
			SetProperty("MyDyn", "AllyNo"..i, 0)
			break
		end
	end
	
	local TargetAllies = dyn_GetAllyCounter(TargetAlias)
	for i=1, TargetAllies do
		if GetProperty("TargetDyn", "AllyNo"..i) == MyID then
			SetProperty("TargetDyn", "AllyNo"..i, 0)
			break
		end
	end
	
	dyn_RecountAllies(SimAlias)
	dyn_RecountAllies(TargetAlias)
	return
end

-- -----------------------
-- SetDiplomacyState (set / update new properties for faster counting)
-- -----------------------
function SetDiplomacyState(ObjectA, ObjectB, NewState)
	if IsType(ObjectA, "Dynasty") then
		DynastyGetMember(ObjectA, 0, "MySim")
	else
		CopyAlias(ObjectA, "MySim")
	end
	
	if IsType(ObjectB, "Dynasty") then
		DynastyGetMember(ObjectB, 0, "TargetSim")
	else
		CopyAlias(ObjectB, "TargetSim")
	end
	
	local CurrentState = DynastyGetDiplomacyState("MySim", "TargetSim")
	if CurrentState ~= NewState then
		if CurrentState == DIP_FOE then
			dyn_RemoveEnemy("MySim", "TargetSim")
		elseif CurrentState == DIP_ALLIANCE then
			dyn_RemoveAlly("MySim", "TargetSim")
		end
		
		if NewState == DIP_FOE then
			dyn_AddEnemy("MySim", "TargetSim")
		elseif NewState == DIP_ALLIANCE then
			dyn_AddAlly("MySim", "TargetSim")
		end
		
		-- set the actual state now
		DynastySetDiplomacyState("MySim", "TargetSim", NewState)
	end
end

-- -----------------------
-- GetHighestOfficeLevel
-- -----------------------
function GetHighestOfficeLevel(SimAlias)
	GetDynasty(SimAlias, "MyDyn")
	local Members = DynastyGetMemberCount("MyDyn")
	local HighestLevel = 0
	
	for i=0, Members-1 do
		if DynastyGetMember("MyDyn", i, "CheckMe") then
			local OfficeLevel = SimGetOfficeLevel("CheckMe")
			if OfficeLevel > HighestLevel then
				HighestLevel = OfficeLevel
			end
		end
	end
	
	return HighestLevel
end

-- -----------------------
-- HasAccessToItem
-- -----------------------
function HasAccessToItem(SimAlias, ItemName)
	GetDynasty(SimAlias, "MyDyn")
	local	Count = DynastyGetBuildingCount2("MyDyn")
	local Found = false
	local BldID = 0
	local FoundCount = 0
	for i = 0, Count-1 do
		if DynastyGetBuilding2("dynasty", i, "Check") then
			if GetItemCount("Check", ItemName, INVENTORY_STD) > 0 then
				FoundCount = GetItemCount("Check", ItemName, INVENTORY_STD)
				Found = true
				break
			end
		end
	end
	
	return Found, BldID, FoundCount
end