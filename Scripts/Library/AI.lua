-- -----------------------
-- StartBuildingAction
-- -----------------------
function StartBuildingAction(FirstSim, SecondSim, BuildingClass, BuildingType, BuildingAlias)

	local IsOk1
	local IsOk2
	local BuildingAlias1
	local BuildingAlias2
	
	IsOk1, BuildingAlias1 = ai_CheckInsideBuilding(FirstSim, BuildingClass, BuildingType, BuildingAlias)
	IsOk2, BuildingAlias2 = ai_CheckInsideBuilding(SecondSim, BuildingClass, BuildingType, BuildingAlias)
	
	if not BuildingAlias then
		if BuildingAlias1 then
			BuildingAlias = BuildingAlias1
		else
			BuildingAlias = BuildingAlias2
		end
	end
	
	if not BuildingAlias then
		if not GetNearestSettlement(FirstSim, "__SBA_City") then
			return false
		end
	
		if not CityGetRandomBuilding("__SBA_City", BuildingClass, BuildingType, -1, -1, FILTER_IGNORE, "__SBA_BUILDING") then
			return false
		end
		
		BuildingAlias = "__SBA_BUILDING"
	end
	
	if not IsOk1 and IsOk2 then
		if not BlockChar(SecondSim) then
			return false
		end
		
		if not f_MoveTo(FirstSim, BuildingAlias) then
			return false
		end
		
	elseif not IsOk2 then
		local checkers = {BlockChar(SecondSim),f_MoveToBuildingAction(FirstSim, SecondSim, -1, 200),f_FollowNoWait(SecondSim, FirstSim, GL_MOVESPEED_MOVE, 100),f_MoveTo(FirstSim, BuildingAlias)}
		for i = 1,4 do
			if not checkers[i] then return false end
		end

	else
		if not BlockChar(SecondSim) then
			return false
		end
	end	
	
	return true
end

-- -----------------------
-- CheckInsideBuilding
-- -----------------------
function CheckInsideBuilding(SimAlias, BuildingClass, BuildingType, BuildingAlias)

	local InsideAlias = "__CIB_BUILDING_"..GetID(SimAlias)
	
	if not GetInsideBuilding(SimAlias, InsideAlias) then
		return false, nil
	end
	
	if BuildingAlias then
		if GetID(InsideAlias)==GetID(BuildingAlias) then
			return true, BuildingAlias
		end
		return false, BuildingAlias
	end
		
	if BuildingClass and BuildingClass~=-1 then
		if (BuildingGetClass(InsideAlias )~=BuildingClass) then
			return false, nil
		end
	end
	
	if BuildingType and BuildingType~=-1 then
		if (BuildingGetType(InsideAlias )~=BuildingType) then
			return false, nil
		end
	end
	
	return true, InsideAlias
end

-- -----------------------
-- GoInsideBuilding
-- -----------------------
function GoInsideBuilding(SimAlias, CityObject, BuildingClass, BuildingType, BuildingAlias)

	local IsOk
	local InsideAlias
	local CityID = -1
	
	if AliasExists(CityObject) then
		if not GetSettlement(CityObject, "__GIB_City") then
			return false
		end
	else
		if not GetSettlement(SimAlias, "__GIB_City") then
			return false
		end
	end
	
	IsOk, InsideAlias = ai_CheckInsideBuilding(SimAlias, BuildingClass, BuildingType, BuildingAlias)
	if IsOk then
		if GetSettlementID(InsideAlias)==GetID("__GIB_City") then
			CopyAlias(InsideAlias, BuildingAlias)
			return true
		end
	end

	if not BuildingAlias then
		BuildingAlias = "__GIB_Build"
	end

	if not AliasExists(BuildingAlias) then
		if not CityGetRandomBuilding("__GIB_City", BuildingClass, BuildingType, -1, -1, FILTER_IGNORE, BuildingAlias) then
			return false
		end
	end
	
	if GetInsideBuildingID(SimAlias) == GetID(BuildingAlias) then
		return true
	end
	
	return f_WeakMoveTo(SimAlias, BuildingAlias)
end

function StartInteraction(FirstPerson, TargetPerson, ReactionDistance, ActionDistance, CommandFunction, bForceNoErrorOnBlock)
	if not TargetPerson or not GetID(TargetPerson) then
		return
	end

	if IsType(TargetPerson, "Building") then
		GetOutdoorMovePosition(FirstPerson, TargetPerson, "_SI__MoveToPosition")
		local RetVal = f_MoveTo(FirstPerson, "_SI__MoveToPosition", GL_MOVESPEED_RUN, ActionDistance)
		if not (RetVal) then
			return false
		end
		AlignTo(FirstPerson, TargetPerson)
		Sleep(0.7)
		return true
	end

	local Distance
	local success = false
	-- timeout 8 hours
	local timeout = GetGametime() + 8

	ReactionDistance = ReactionDistance * 1.5

	while success == false do
	
		if not f_Follow(FirstPerson,TargetPerson,GL_MOVESPEED_RUN,ReactionDistance, true) then
			if not bForceNoErrorOnBlock then		
				return false
			end
		end
	
		if CommandFunction then
			success = SendCommandNoWait(TargetPerson, CommandFunction)
		else
			success = BlockChar(TargetPerson)
		end
			
		if not success then
		  -- check for timeout
		  local curGametime = GetGametime()
		  if timeout < GetGametime() then
			  if not bForceNoErrorOnBlock then
					if IsType(TargetPerson,"Building") then
						if IsPartyMember(FirstPerson) then
							MsgQuick(FirstPerson,"@L_GENERAL_MEASURES_FAILURES_+1", GetID(TargetPerson))
						end
					else
						if IsPartyMember(FirstPerson) then
							MsgQuick(FirstPerson,"@L_GENERAL_MEASURES_FAILURES_+0", GetID(TargetPerson), GetID(FirstPerson))
						end
					end
					return false
				end
			end
			
			if not bForceNoErrorOnBlock then
				Sleep(1)
			end
		end
	end
	
	-- move to destinaton
	if not (f_MoveTo(FirstPerson,TargetPerson, GL_MOVESPEED_WALK, ActionDistance)) then
		return false
	end
	
	if not (bForceNoErrorOnBlock) then
		AlignTo(FirstPerson, TargetPerson)
		AlignTo(TargetPerson, FirstPerson)
	end

	Sleep(1.0)
	
	return true
end

function ShowMoveError(result) 

	if result == nil then
		MsgMeasure("", "@L_GENERAL_MEASURES_FAILURES_+2")
	end

	if result == GL_MOVERESULT_ERROR_NOT_ENTERABLE then
		if AliasExists("Destination") then
			if GetState("", STATE_FIGHTING) then
				MsgMeasure("", "@L_NEWSTUFF_NOENTER_FIGHTING")
			elseif GetState("Destination", STATE_LEVELINGUP) then
				MsgMeasure("", "@L_NEWSTUFF_NOENTER_LEVELUP")
			elseif GetState("Destination", STATE_BUILDING) then
				MsgMeasure("", "@L_NEWSTUFF_NOENTER_BUILDING")
			elseif GetState("Destination", STATE_BURNING) then
				MsgMeasure("", "@L_NEWSTUFF_NOENTER_BURNING")
			--elseif GetState("Destination", STATE_CONTAMINATED) then
				--MsgQuick("", "@L_NEWSTUFF_NOENTER_CONTAMINATED")
			elseif GetState("Destination", STATE_CUTSCENE) then
				MsgMeasure("","@L_NEWSTUFF_NOENTER_SESSION")
			elseif GetState("Destination", STATE_DEAD) then
				MsgMeasure("","@L_NEWSTUFF_NOENTER_DEAD")
			elseif (GetHPRelative("Destination")<=0.2) then
				MsgMeasure("", "@L_NEWSTUFF_NOENTER_CRITICALDAMAGE")
			--elseif (SimGetProfession("") == GL_PROFESSION_MYRMIDON) then
			--	MsgMeasure("", "@L_NEWSTUFF_NOENTER_NOFIGHTERS")
			--MsgQuick("", "@L_NEWSTUFF_NOENTER_CLOSED")
			else
				MsgMeasure("", "@L_GENERAL_MEASURES_FAILURES_+3", GetID(""))
			end
		else
			MsgMeasure("", "@L_GENERAL_MEASURES_FAILURES_+3", GetID(""))
		end
	elseif result == GL_MOVERESULT_ERROR_MOVEMENT_ABORTED then
		--MsgMeasure("", "@LMOVE_OVERHEAD_CANNOT_REACH_TARGET@T%1SN: Bewegungsabbruch.")
	elseif result == GL_MOVERESULT_ERROR_NOT_ENTERABLE_ILLEGAL_DEST then 
		MsgMeasure("", "@L_GENERAL_MEASURES_FAILURES_+4", GetID(""))
	elseif result == GL_MOVERESULT_ERROR_TRANSITION_FAILED then 
		MsgMeasure("", "@L_GENERAL_MEASURES_FAILURES_+5", GetID(""))	
	elseif result == GL_MOVERESULT_ERROR_TARGET_GONE then 
		MsgMeasure("", "@L_GENERAL_MEASURES_FAILURES_+6", GetID(""))
	elseif result == GL_MOVERESULT_ERROR_TARGET_INACCESSIBLE then 
		MsgMeasure("", "@L_GENERAL_MEASURES_FAILURES_+7", GetID(""))		
	elseif result == GL_MOVERESULT_ERROR_TARGET_UNREACHABLE then 
		MsgMeasure("", "@L_GENERAL_MEASURES_FAILURES_+8", GetID(""))		
	elseif result == GL_MOVERESULT_ERROR_NOT_INITIALIZED then 
		MsgMeasure("", "@L_GENERAL_MEASURES_FAILURES_+9", GetID(""))				
	elseif result == GL_MOVERESULT_ERROR_UNKNOWN_PATHFINDER then 
		MsgMeasure("", "@L_GENERAL_MEASURES_FAILURES_+10", GetID(""))	
	else
		--strange things
		--	feedback_OverheadFadeText("", "@LMOVE_OVERHEAD_CANNOT_REACH_TARGET@T%1SN: Es wurde ein MoveTask unterbrochen der den Zustand IDLE hatte?!", false)
		--elseif result == GL_MOVERESULT_TARGET_REACHED then
		--	feedback_OverheadFadeText("", "@LMOVE_OVERHEAD_CANNOT_REACH_TARGET@T%1SN: Habe Ziel erreicht, aber es wurde Fehlerbehandlung aufgerufen?!", false)
		--else
	
		MsgMeasure("", "@L_GENERAL_MEASURES_FAILURES_+11")
		
		--end
	end
	Sleep(1)	
end

function MultiMoveTo(...)
	-- always alternating Owner and Target

	local speed = arg[1]
	local range = arg[2]

	--count args
	local argoffset = 2
	local number = argoffset
	while arg[number+1]~=nil do
		number = number + 2
	end
	-- ignore the first args 
	number = number - argoffset
	number  = number / 2

	--start moving
	local steps
	local pos
	local MMResultName
	local objectarray = {}
	for steps = 0, number-1 do
		pos = argoffset + 1 + steps*2
		MMResultName = "mmresult_"..pos
		f_MoveToNoWait(arg[pos], arg[pos+1], speed, MMResultName, range)
		--copy objects to new array
		objectarray[steps] = MMResultName
	end
		
	while (number > 0) do
		-- check results of the objects
		for steps = 0, number-1 do
			local result = GetData(objectarray[steps])
			if (result == GL_MOVERESULT_TARGET_REACHED) then
				--copy to end
				objectarray[steps] = objectarray[number-1]
				--shorten list
				number = number-1
			elseif (result ~= nil) then
				if (result > GL_MOVERESULT_ERROR_UNKNOWN) then
					return false
				end
			end				
		end
		Sleep(0.5)
	end
	return true 
end

function CanBuyItem(SimAlias, Item, Count, CityAlias, PlaceAlias)
	Count = Count or 1
	PlaceAlias = PlaceAlias or "__AI_CBI_PLACE"
	CityAlias = CityAlias or "__AI_CBI_CITY"

	if not CanAddItems(SimAlias, Item, Count, INVENTORY_STD) then
		return -1
	end
	
	if not GetNearestSettlement(SimAlias, CityAlias) then
		return -1
	end
	
	local Price = CityGetSeller(CityAlias, SimAlias, Item, 1, PlaceAlias)
	-- TODO ToM: Check if this return only markets. If so, extend to workshops. 

	return Price
end


function BuyItem(SimAlias, Item, ItemCount)
	ItemCount = ItemCount or 1
	local PlaceAlias = "__AI_CBI_PLACE"
	local CityAlias = "__AI_CBI_CITY"
	local Price = ai_CanBuyItem(SimAlias, Item, ItemCount, CityAlias, PlaceAlias)
	
	if Price < 0 then
		return false
	end
	
	local MoveToPos	= "__AI_CBI_MoveTo"
	local eInv
	
	if IsType(PlaceAlias , "Building") then
		GetOutdoorMovePosition(SimAlias, PlaceAlias, MoveToPos)
		eInv = INVENTORY_SELL
	elseif IsType(PlaceAlias, "Market") then
		CityGetNearestBuilding(CityAlias, SimAlias, -1, GL_BUILDING_TYPE_MARKET, -1, -1, FILTER_IGNORE, MoveToPos)
		eInv = INVENTORY_STD
	end
	
	if not AliasExists(MoveToPos) then
		return false
	end
	
	if not f_MoveTo(SimAlias, MoveToPos) then
		return false
	end
	
	local E, Done
	
	if eInv == INVENTORY_STD then -- market
		E, Done = f_Transfer(SimAlias, SimAlias, INVENTORY_STD, PlaceAlias, eInv, Item, ItemCount)
	else
		Done = economy_BuyItems(PlaceAlias, SimAlias, Item, ItemCount, INVENTORY_STD)
	end
	
	return (Done >= ItemCount)
end

function CreateMutex(BaseAlias)
	local	PropertyName = "_MUTEX_"..SystemGetMeasureName()
	if HasProperty(BaseAlias, PropertyName) then
		return false
	end
	SetProperty(BaseAlias, PropertyName, GetID(""))
	return true
end

function CheckMutex(BaseAlias, MeasureName)
	local	PropertyName = "_MUTEX_"..MeasureName
	if HasProperty(BaseAlias, PropertyName) then
		return false
	end
	return true
end

function ReleaseMutex(BaseAlias)
	local	PropertyName = "_MUTEX_"..SystemGetMeasureName()
	local	Value = GetProperty(BaseAlias, PropertyName)
	
	if not Value or Value~=GetID("") then
		return fals
	end
	RemoveProperty(BaseAlias, PropertyName)
end

function IsDeploymentInProgress(SimAlias)

	local CurrentDeplicant
	local OfficeTask
	local SimID = GetID(SimAlias)
	local Alias
	
	ListAllCutscenes("cutscene_list")
	local NumCutscenes = ListSize("cutscene_list")
	for iCutscene = 0, NumCutscenes-1 do
		if ListGetElement("cutscene_list", iCutscene, "my_cutscene") and GetID("my_cutscene") ~= -1 then
	
			local DepList_Count
			CutsceneGetData("my_cutscene","DepList_Count")
			DepList_Count = GetData("DepList_Count")
			
			if DepList_Count ~= nil then
				for UseOffice = 1, DepList_Count, 1 do

					Alias = "DepList_"..(UseOffice).."_ID"
					CutsceneGetData("my_cutscene",Alias)
					OfficeTask = GetData(Alias)

					Alias = "DepList_"..(OfficeTask).."_DepID"
					CutsceneGetData("my_cutscene",Alias)
					CurrentDeplicant = GetData(Alias)

					if CurrentDeplicant == SimID then
						return true
					end
					
				end
			end
		end
	end
	return false
end

function GetPower(SimAlias)

	local WeaponDamage = SimGetWeaponDamage(SimAlias)
	local Damage = gameplayformulas_GetDamage(SimAlias, WeaponDamage)
	local Defence = gameplayformulas_GetArmorValue(SimAlias)
	
	return Damage, Defence
end

function GetNearestDynastyBuilding(Owner,BuildingClass,BuildingType)
	if not GetDynasty(Owner,"BuildingDynasty") then
		return false
	end
	local NumBuildings = DynastyGetBuildingCount("BuildingDynasty",BuildingClass,BuildingType)
	if NumBuildings <= 0 then
		return false
	end
	if GetInsideBuilding(Owner,"CurrentBuilding") then
		GetOutdoorMovePosition(Owner,"CurrentBuilding","CurrentPosition")
	else
		GetPosition(Owner,"CurrentPosition")
	end
	local CurrentDistance = 0
	local OldDistance = 500000
	for i=0,NumBuildings do
		if DynastyGetRandomBuilding("BuildingDynasty",BuildingClass,BuildingType,"RandomBuilding") then
			if GetOutdoorMovePosition(Owner,"RandomBuilding","MovePos") then
				CurrentDistance = GetDistance("CurrentPosition","MovePos")
			end
			if CurrentDistance < OldDistance then
				CopyAlias("RandomBuilding","NextBuilding")
				OldDistance = CurrentDistance
			end
		end		
	end
	if AliasExists("NextBuilding") then
		return "NextBuilding"
	else
		return false
	end	
end

function GetWorkBuilding(SimAlias, BuildingType, BuildAlias)
	if AliasExists(SimAlias) then
		if not IsPartyMember(SimAlias) then
			return SimGetWorkingPlace(SimAlias, BuildAlias)
		end
	
		if GetInsideBuilding(SimAlias, BuildAlias) then
			if BuildingGetType(BuildAlias)==BuildingType then
				if SimCanWorkHere(SimAlias, BuildAlias) then
					return true
				end
			end
		end
		
		local Count = DynastyGetBuildingCount2(SimAlias)
		for l=0,Count-1 do
			if DynastyGetBuilding2(SimAlias, l, BuildAlias) then
				if BuildingGetType(BuildAlias)==BuildingType then
					if SimCanWorkHere(SimAlias, BuildAlias) then
						return true
					end
				end
			end
		end
	end
	
	return false
end

function HasAccessToItem(SimAlias, ItemName)
	if GetItemCount(SimAlias, ItemName, INVENTORY_STD)>0 then
		return true
	end
	
	if GetItemCount(SimAlias, ItemName, INVENTORY_EQUIPMENT)>0 then
		return true
	end
	
	if SimGetWorkingPlace(SimAlias, "aihati_Place") then
	
		if GetItemCount("aihati_Place", ItemName, INVENTORY_STD)>0 then
			return true
		end
		
		if GetItemCount("aihati_Place", ItemName, INVENTORY_SELL)>0 then
			return true
		end
		
		if BuildingGetType("aihati_Place") == GL_BUILDING_TYPE_HOSPITAL then
			if HasProperty("aihati_Place", "MiracleCures") then
				local Cures = GetProperty("aihati_Place", "MiracleCures")
				if Cures > 0 then
					return true
				end
			end
		end
		
	end
	
	return false
end


function CheckTitleVSJewellery(SimAlias, ItemLevel, ModVal)

	local ReturnValue = 0
	local Title = GetNobilityTitle(SimAlias, false)
	local Level = SimGetLevel(SimAlias)
	
	if Title==ItemLevel then
		ReturnValue = ModVal
	elseif Title<ItemLevel then
		ReturnValue = ModVal - Title - (ItemLevel * 2)
	elseif Title>ItemLevel then
		if ItemLevel>4 then
			ReturnValue = ModVal
		else
			ReturnValue = ModVal - ItemLevel - (Title * 2)
		end
	end

	if ReturnValue==nil then
		return 0
	end

	if ReturnValue>0 then
		return ReturnValue
	else
		return 0
	end
end


function AICheckAction()

	local check = false
	local Difficulty = ScenarioGetDifficulty()
	local Round = GetRound()
	
	if Difficulty == 0 then
		if Round > 3 then
			check = true
		end
	elseif Difficulty == 1 then
		if Round > 2 then
			check = true
		end
	elseif Difficulty == 2 then
		if Round > 1 then
			check = true
		end
	elseif Difficulty == 3 then
		if Round > 0 then
			check = true
		end
	else
		check = true
	end

	return check
end

-------------------------------------------------------
-- Check Priority Functions
-------------------------------------------------------

function CalcNextDynastyGoal(DynastyAlias)
	-- removed due to new system
	SetProperty(DynastyAlias, "Priority1", "title")
	return
end

function CalcBuildingGoal(DynastyAlias)
	-- removed due to new system
	return 0
end

function CalcTitleGoal(DynastyAlias)
	-- removed due to new system
	return 0
end

function CalcBuildingLevelGoal(DynastyAlias)
	-- removed due to new system
	return 0
end

function GetBestNumberOfWorkshops(DynastyAlias)
	DynastyGetMemberRandom(DynastyAlias, "member")
	local Title = GetNobilityTitle("member")
	local BestNumber = 1
	if Title >=3 and Title <= 4 then
		BestNumber = 2
	elseif Title >=5 and Title <= 6 then
		BestNumber = 3
	elseif Title >=7 and Title <= 8 then
		BestNumber = 4
	elseif Title >=9 and Title <= 10 then
		BestNumber = 5
	else
		BestNumber = 6
	end

	return BestNumber
end

function CalcItemBudget(DynastyAlias)
	-- removed due to new system
	return
end

function DynastyCheckForRival(DynastyAlias, TargetDynasty)
	
--	LogMessage("Check Rival. "..GetName(DynastyAlias).." checks for "..GetName(TargetDynasty))
	local IsRival = 0 -- no rival
	local MyCount = DynastyGetMemberCount(DynastyAlias)
	local MyBuildings = DynastyGetBuildingCount2(DynastyAlias)
	
	local TargetCount = DynastyGetMemberCount(TargetDynasty)
	local TargetBuildings = DynastyGetBuildingCount2(TargetDynasty)
	
	local Type, TargetType
	-- Check for same buisnesses in the dynasties
	
	if MyBuildings > 0 and TargetBuildings > 0 then
		for i=0, MyBuildings-1 do
			if DynastyGetBuilding2(DynastyAlias, i, "Building") then -- check every building
				Type = BuildingGetType("Building")
				
				if Type ~= GL_BUILDING_TYPE_RESIDENCE then -- we don't look for houses
					if DynastyGetRandomBuilding(TargetDynasty, GL_BUILDING_CLASS_WORKSHOP, Type, "TargetBuilding") then
						if GetSettlementID("TargetBuilding") == GetSettlementID("Building") then
							-- workshops in same city
							CopyAlias("TargetBuilding", "RivalBuilding")
						--	LogMessage("CheckForRival: Your "..GetName("TargetBuilding").." has Type "..BuildingGetType("TargetBuilding").." same as my "..GetName("Building").." which has Type "..Type)
							break
						end
					end
				end
			end
		end
	end
	
	if AliasExists("RivalBuilding") then
		IsRival = GetID("RivalBuilding")
	end
	
	-- check for political ambitions
	
	for i=0, MyCount-1 do
		if DynastyGetMember(DynastyAlias, i, "Member"..i) then -- check every member
			local OfficeLevel = SimGetOfficeLevel("Member"..i)
			if OfficeLevel >= 0 then -- we found someone
				for y=0, TargetCount-1 do -- check every member of target
					if DynastyGetMember(TargetDynasty, y, "TargetMember"..i) then
						if SimGetOfficeLevel("TargetMember"..i) == (OfficeLevel+1) then 
							if GetSettlementID("TargetMember"..i) == GetSettlementID("Member"..i) then
								-- you have the office I want and we live in the same city
							--	LogMessage(GetName("TargetMember"..i).." holds the office seat I want!")
								CopyAlias("TargetMember"..i, "RivalOfficeHolder")
								break
							end
						end
					end
				end
			end
		end
	end
	
	if AliasExists("RivalOfficeHolder") then
		IsRival = GetID("RivalOfficeHolder")
	end
	
	return IsRival
end

function DynastyCalcThreat(SimAlias, TargetAlias)

	local MyMoney = GetMoney(SimAlias)
	local TargetMoney = GetMoney(TargetAlias)
	
	local MyTitle = GetNobilityTitle(SimAlias)
	local TargetTitle = GetNobilityTitle(TargetAlias)
	
	local MyEnemyCount = dyn_GetEnemies(SimAlias) or 0
	local TargetEnemyCount = dyn_GetEnemies(TargetAlias) or 0
	
	local HighestOffice = dyn_GetHighestOfficeLevel(SimAlias) or 0
	local HighestOfficeTarget = dyn_GetHighestOfficeLevel(TargetAlias) or 0
	
	local ThreatLevel = 0
	local Difference = 0
	
	if TargetMoney > 50000 then
		TargetMoney = 50000
	end
	
	TargetMoney = TargetMoney - (TargetEnemyCount * 2500)
	
	if MyMoney > 50000 then
		MyMoney = 50000
	end
	
	MyMoney = MyMoney - (MyEnemyCount * 2500)
	
	Difference = TargetMoney - MyMoney
	Difference = Difference + ((TargetTitle - MyTitle) * 5000)
	Difference = Difference + ((HighestOfficeTarget - HighestOffice) * 5000)
	
	if Difference > 50000 then -- very high threat
		ThreatLevel = 4
	elseif Difference > 20000 then -- high threat
		ThreatLevel = 3
	elseif Difference > 12500 then -- threat
		ThreatLevel = 2
	elseif Difference > 2500 then -- barely a threat
		ThreatLevel = 1
	else -- no threat at all
		ThreatLevel = 0
	end
	
	return ThreatLevel
end

function DynastyGetBestDiplomacyState(SimAlias, TargetAlias)

	if not (GetDynasty(SimAlias, "MyDynasty") and GetDynasty(TargetAlias, "TargetDynasty")) then
		return false
	end
	
	--LogMessage(GetName(SimAlias).." asks for "..GetName("MyDynasty").." and "..GetName(TargetAlias).." asks for "..GetName("TargetDynasty"))
	
	local CurrentStatus = DynastyGetDiplomacyState("MyDynasty", "TargetDynasty")
	local Favor = GetFavorToDynasty("MyDynasty", "TargetDynasty")
	local Threat = ai_DynastyCalcThreat(SimAlias, TargetAlias)
	local IsRival = ai_DynastyCheckForRival("MyDynasty", "TargetDynasty")
	
	if CurrentStatus == DIP_ALLIANCE then
		
		if IsRival == 0 then
			if Favor >= 75 then
				return "CurrentState"
			else
				if Threat >= 3 then
					return "CurrentState"
				else
					return "NAP"
				end
			end
		else
			if Favor >= 85 then
				return "CurrentState"
			else
				return "NAP"
			end
		end
		
	elseif CurrentStatus == DIP_NAP then
		
		if IsRival == 0 then
			if Favor >= 70 and Threat >=3 then
				return "ALLIANCE"
			elseif Favor >= 50 and Threat == 4 then
				return "ALLIANCE"
			elseif Favor >= 50 and Threat < 4 then
				return "CurrentState"
			elseif Favor < 50 and Favor >=30 and Threat >=3 then
				return "CurrentState"
			elseif Favor < 50 and Favor >= 30 then
				return "NEUTRAL"
			elseif Favor <= 10 and Threat < 2 then
				return "FOE"
			elseif Threat < 2 then
				return "NEUTRAL"
			end
		else
			if Threat >=3 then
				return "CurrentState"
			else
				return "NEUTRAL"
			end
		end
			
	elseif CurrentStatus == DIP_NEUTRAL then
		
		if IsRival == 0 then
			if Favor >= 65 then 
				return "NAP"
			elseif Favor >= 50 then
				if Threat >= 2 then
					return "NAP"
				else
					return "CurrentState"
				end
			elseif Favor <50 and Favor >=30 then
				if Threat >=3 then
					return "NAP"
				else
					return "CurrentState"
				end
			elseif Favor < 15 then
				if Favor <= 5 then
					return "FOE"
				else
					if Threat < 3 then
						return "FOE"
					else
						return "CurrentState"
					end
				end
			end
		else
			if Favor >= 70 then
				if Threat >=2 then
					return "NAP"
				else 
					return "CurrentState"
				end
			elseif Favor >= 25 then
				return "CurrentState"
			else
				return "FOE"
			end
		end
		
	else -- DIP_FOE
		if IsRival == 0 then
			if Favor > 50 then
				if Threat >= 3 then
					return "NAP"
				elseif Threat == 2 then
					return "NEUTRAL"
				else
					return "CurrentState"
				end
			elseif Favor >= 40 then
				if Threat >= 3 then
					return "NAP"
				elseif Threat == 2 then
					return "NEUTRAL"
				else
					return "CurrentState"
				end
			else
				return "CurrentState"
			end
		else
			if Favor >= 65 then
				if Threat >= 3 then
					return "NAP"
				else
					return "CurrentState"
				end
			elseif Favor >= 45 then
				if Threat >= 2 then
					return "NEUTRAL"
				else
					return "CurrentState"
				end
			elseif Favor > 25 and Threat == 4 then
				return "NEUTRAL"
			else
				return "CurrentState"
			end
		end
	end		
end

function BuildNewWorkshop(Owner, Type)
	 local proto = ScenarioFindBuildingProto(GL_BUILDING_CLASS_WORKSHOP, Type, 1, 0)
	if not GetHomeBuilding(Owner, "home") then
		return false
	end
	if not BuildingGetCity("home", "city") then
		return false
	end

	GetPosition("home", "TargetPosition")
	CityBuildNewBuilding("city", proto, Owner, "building", "TargetPosition", 25000)
end

function BuyRandomWorkshop(Owner)
	if not GetHomeBuilding(Owner, "home") then
		return false
	end
	if not BuildingGetCity("home", "city") then
		return false
	end
	local money = GetMoney(Owner) - 1000
	-- decide, which building to buy
	local n = CityGetBuildingCount("city", GL_BUILDING_CLASS_WORKSHOP, -1, -1, -1, FILTER_IS_BUYABLE)
	if n >= 1 then 
		CityGetBuildings("city", GL_BUILDING_CLASS_WORKSHOP, -1, -1, -1, FILTER_IS_BUYABLE, "bld")
		for i=0, n-1 do
			local cost = BuildingGetBuyPrice("bld"..i)
			if BuildingCanBeOwnedBy("bld"..i, Owner) and cost < money then		
				MeasureRun("bld"..i, Owner, "BuyBuilding", true)
				return true
			end
		end
	end

	-- no buildings available or not able to buy any of them
	local m = CityGetBuildingCount("city", GL_BUILDING_CLASS_WORKSHOP, -1, -1, -1, FILTER_NO_DYNASTY )
	for i=0, m-1 do
		if not BuildingGetForSale("bld"..i) and BuildingCanBeOwnedBy("bld"..i, Owner)then
			if MeasureRun("bld"..i, Owner, "TakeOverBid", true) then 
				return true
			end
		end
	end
	return false
end

-------------------------------------------------------
-- ChoosePersonality 
-------------------------------------------------------
function ChoosePersonality(Dynasty)
	
	if DynastyIsShadow(Dynasty) then
		SetProperty(Dynasty, "AI_PERSONA", 0)
		return -- set shadow persona
	else
		local RandomChoice = Rand(100)
		local Choice = 0
		if RandomChoice <= 20 then -- 0-20
			Choice = 1 -- goodguy
		elseif RandomChoice <= 35 then -- 21-35
			Choice = 2 -- whiteknight
		elseif RandomChoice <= 55 then -- 36-55
			Choice = 3 -- tactician
		elseif RandomChoice <= 75 then -- 56-75
			Choice = 4 -- overlord
		elseif RandomChoice <= 90 then -- 76-90
			Choice = 5 -- sociopath
		else
			Choice = 6 -- maniac -- 91-99
		end
		
		SetProperty(Dynasty, "AI_PERSONA", Choice)
		return
	end
end

-- -----------------------
-- MakeDecision - this is for AI functions.
-- -----------------------
function MakeDecision(DynastyAlias, Trait1, Mod1, Trait2, Mod2)
	-- Trait must match the columns in AIPersonality.dbt. Trait2 is optional if AI has to weight their traits against each other
	
	if not HasProperty(DynastyAlias, "AI_PERSONA") then
		ai_ChoosePersonality(DynastyAlias)
	end
	
	local PersonalityID = GetProperty(DynastyAlias, "AI_PERSONA")
	local CheckValue = 0
	
	-- get the needed trait
	local Trait1Val = 0
	Trait1Val = GetDatabaseValue("AIPersonality", PersonalityID, Trait1) + Mod1 or 0
	local CheckTrait1 = Rand(Trait1Val)
	
	local Trait2Val = 0
	if Trait2 ~= nil then
		Trait2Val = GetDatabaseValue("AIPersonality", PersonalityID, Trait2) + Mod2 or 0
		local CheckTrait2 = Rand(Trait2Val)
		-- compare
		if CheckTrait1 >= CheckTrait2 then
			return true
		else
			return false
		end
	end
	
	-- random check
	--local CheckValue = Rand(TraitValue) 
	return CheckValue
end

-------------------------------------------------------
-- CheckPersonalityWeight - this is for the base tree
-------------------------------------------------------
function CheckPersonalityWeight(Dynasty, ActionCategory)
	
	if not HasProperty(Dynasty, "AI_PERSONA") then
		ai_ChoosePersonality(Dynasty)
	end
	
	local PersonalityID = GetProperty(Dynasty, "AI_PERSONA")
	local Weight = GetDatabaseValue("AIPersonality", PersonalityID, ActionCategory)
	
	return Weight
end

-- gets children that aren't married off
function GetUsefulChildCount(SimAlias)
	local childCount = SimGetChildCount(SimAlias)
	local usefulChildCount = 0
	for idx=0, childCount-1 do
		if SimGetChild(SimAlias, idx, "AI_UsefulChild") and GetDynastyID("AI_UsefulChild") == GetDynastyID(SimAlias) then
			usefulChildCount = usefulChildCount + 1
		end
	end
	return usefulChildCount
end
