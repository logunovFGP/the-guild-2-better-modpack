-- -----------------------
-- Init
-- -----------------------
function Init()
	--needed for caching
end

-- -----------------------
-- CheckWeather
-- -----------------------
function CheckWeather()
	local RainValue = Weather_GetValue(0)
	local CloudValue = Weather_GetValue(1)
	local WindValue = Weather_GetValue(3)
	
	local Weather = (RainValue * 7) + CloudValue + (WindValue * 2) --0(good) - 10(bad)
	local Activity = 0
	if Weather <= 1  then --sun is shining, everything is allright
		Activity = 100
	elseif Weather <= 3 then --cloudy sky
		Activity = 70
	elseif Weather <= 7 then --rain or snow
		Activity = 35
	else				--stormy weather, bah
		Activity = 10
	end
	
	if Rand(100) < Activity then
		return true
	else
		return false
	end
end

-- -----------------------
-- GetCurious
-- -----------------------
function GetCurious()
	if GetSettlement("", "MyCity") then
		chr_CityFindCrowdedPlace("MyCity", "", true, "Destination")
	end
	
	if AliasExists("Destination") then
		f_MoveTo("", "Destination", GL_WALKSPEED_WALK)
		f_Stroll("", 600, 3)
		local RandWait = Rand(20) + 3
		Sleep(RandWait)
	end
end

-- -----------------------
-- GoSleep
-- -----------------------
function GoSleep()
	MsgDebugMeasure("Go sleeping...")

	local MinMoney = 500  --enough money for tavern?
	local GoToTavern = 3  --3% chance to go to tavern just for fun
	local Chance = Rand(100) + 1
	
	if Chance <= GoToTavern and chr_GetBudget("", 2) >= MinMoney then
		
		chr_FindInterestingWorkshop("", GL_BUILDING_TYPE_TAVERN, "fireplacebench", 900, 4000, "DestTavern")
	
		if not AliasExists("DestTavern") then
			return
		end	
			
		if not f_MoveTo("", "DestTavern", GL_MOVESPEED_RUN) then
			return
		end
		
		if GetFreeLocatorByName("DestTavern", "Berth", 1, 2, "SleepingBerth") then  -- sleep in tavern if possible
			MeasureRun("", nil, "RentSleepingBerth")
			return
		else
			idlelib_GoToTavern()
			return
		end
	else
		idlelib_GoHome()
		return
	end
end	

-- -----------------------
-- Sleep (for workers)
-- -----------------------
function Sleep()
	MsgDebugMeasure("Sleeping...")
	if not GetHomeBuilding("", "HomeBuilding") then
		Sleep(60)
		return false
	end

	if not GetInsideBuilding("", "Inside") or GetID("Inside") ~= GetID("HomeBuilding") then
		if not f_MoveTo("", "HomeBuilding", GL_MOVESPEED_RUN) then
			Sleep(3)
			StopMeasure()
		end
	end
	
	local SleepTime = 5
	local EndSleep = math.mod(GetGametime(),24) + SleepTime
	local ContinueSleeping = true
	SetState("", STATE_SLEEPING, true)
	
	while ContinueSleeping do
	
		ContinueSleeping = false
		Sleep(SleepTime)

		if GetHPRelative("") < 1 then
			ModifyHP("", 2)
			ContinueSleeping = true
		end
		
		if GetImpactValue("", "Sickness") > 0 then
			if GetItemCount("", "Blanket") > 0 then
				RemoveItems("", "Blanket", 1)
				local list = { "Cold", "Influenza"}
				for i = 1,2 do
					if GetImpactValue("", list[i]) == 1 then
						Disease[list[i]]:cureSim("")
					end
				end
			elseif GetItemCount("", "HerbTea") > 0 then
				RemoveItems("", "HerbTea", 1)
				local list = { "Cold", "Influenza"}
				for i = 1,2 do
					if GetImpactValue("", list[i]) == 1 then
						Disease[list[i]]:cureSim("")
					end
				end
			end
		end
		
		local time = math.mod(GetGametime(),24)
		if time > EndSleep  then
			ContinueSleeping = false
		end
	end
	
	SetState("", STATE_SLEEPING, false)
end

-- -----------------------
-- GoHome
-- -----------------------
function GoHome()
	MsgDebugMeasure("Going Home")
	if not GetHomeBuilding("", "HomeBuilding") then
		Sleep(6)
		return
	end

	if not GetInsideBuilding("", "Inside") or GetID("Inside")~= GetID("HomeBuilding") then
		f_MoveTo("", "HomeBuilding", GL_MOVESPEED_WALK)
	end
	
	if gameplayformulas_GetDayTime() == "NIGHT" or GetImpactValue("", "Sickness") > 0 then
		if BuildingGetType("HomeBuilding") == GL_BUILDING_TYPE_RESIDENCE then
			MeasureRun("", nil, "GoToSleep")
			return
		else
			idlelib_Sleep()
		end
	end
	
	Sleep(Rand(60)+120)
	
	-- random fire
	if Rand(500) == 1 then
		SetState("HomeBuilding", STATE_BURNING, true)
	end
end

-- -----------------------
-- ThiefIdle
-- -----------------------
function ThiefIdle(Workbuilding)
	-- AI controlled thiefs should not go idle
	local Time = math.mod(GetGametime(), 24)
	if BuildingGetAISetting(Workbuilding, "Enable") > 0 then
		if GetHPRelative("") < 0.7 then
			-- Heal
			GetSettlement(Workbuilding, "City")
			CityGetNearestBuilding("City", "", -1, GL_BUILDING_TYPE_LINGERPLACE, -1, -1, FILTER_IGNORE, "LingerPlace")
			MeasureRun("", "LingerPlace", "Linger")
			return
		end
		if Rand(5) > 1 then
			thief_CheckInForWork(Workbuilding, "")
			return
		end
	end
	
	-- aliases are lost if the call to thief script is executed!
	local WhatToDo = Rand(5)
	if WhatToDo == 0 then
		if GetFreeLocatorByName(Workbuilding, "Chair", 1, 4, "ChairPos") then
			if not f_BeginUseLocator("", "ChairPos", GL_STANCE_SIT, true) then
				RemoveAlias("ChairPos")
				return
			end
			while true do
				local WhatToDo2 = Rand(4)
				if WhatToDo2 == 0 then
					Sleep(10) 
				elseif WhatToDo2 == 1 then
					return
				elseif WhatToDo2 == 2 then
					PlayAnimation("", "sit_talk")
				else
					PlayAnimation("", "sit_laugh")					
				end
				Sleep(1)
			end
		end
	elseif WhatToDo == 1 then
		if GetLocatorByName(Workbuilding, "Chair_Cellwatch", "ChairPos") then
			if not f_BeginUseLocator("", "ChairPos", GL_STANCE_SIT, true) then
				RemoveAlias("ChairPos")
				return
			end
			PlayAnimation("", "sit_laugh")
			Sleep(Rand(12)+1)
		end
	elseif WhatToDo == 2 then
		if GetLocatorByName(Workbuilding, "Fistfight", "ChairPos") then
			if not f_BeginUseLocator("", "ChairPos", GL_STANCE_STAND, true) then
				RemoveAlias("ChairPos")
				return
			end
			PlayAnimation("", "point_at")
			PlayAnimation("", "fistfight_in")
			PlayAnimation("", "fistfight_punch_01")
			PlayAnimation("", "fistfight_punch_05")
			PlayAnimation("", "fistfight_punch_02")
			PlayAnimation("", "fistfight_punch_06")
			PlayAnimation("", "fistfight_punch_03")
			PlayAnimation("", "fistfight_punch_07")
			PlayAnimation("", "fistfight_punch_04")
			PlayAnimation("", "fistfight_punch_08")
			PlayAnimation("", "fistfight_out")
		end
	elseif WhatToDo == 3 then
		if GetLocatorByName("WorkingPlace", "Pickpocket", "ChairPos") then
			if not f_BeginUseLocator("", "ChairPos", GL_STANCE_STAND, true) then
				RemoveAlias("ChairPos")
				return
			end
			PlayAnimation("", "pickpocket")
		end
	else
		if GetLocatorByName("WorkingPlace", "Cell_Outside", "ChairPos") then
			if not f_BeginUseLocator("", "ChairPos", GL_STANCE_STAND, true) then
				RemoveAlias("ChairPos")
				return
			end
			PlayAnimation("", "sentinel_idle")
		end
	end
	
	Sleep(20)
end

-- -----------------------
-- RobberIdle
-- -----------------------
function RobberIdle(Workbuilding)

	GetLocatorByName(Workbuilding, "Entry1", "WaitingPos")
	
	if GetDistance("", "WaitingPos") > 115 then
		local dist = Rand(100)+10	
		f_MoveTo("Sim", "WaitingPos", GL_MOVESPEED_RUN, dist)
	end

	Sleep(30)
end

-- -----------------------
-- CocotteIdle
-- -----------------------
function CocotteIdle(Cocotte)

	SimGetWorkingPlace(Cocotte, "Divehouse")
	-- AI controlled cocottes do not go idle
	local Lvl = BuildingGetLevel("Divehouse")
	local GuestCount = BuildingGetSimCount("Divehouse")
	if BuildingGetAISetting("Divehouse", "Enable") > 0 then
		-- offer services if not already offered
		if not HasProperty("Divehouse", "ServiceActive") and not HasProperty("Divehouse", "GoToService") then
			SetProperty("Divehouse","GoToService",1)
			MeasureCreate("Measure")
			MeasureAddData("Measure", "TimeOut", Rand(3)+2)
			MeasureStart("Measure", Cocotte, "Divehouse", "AssignToServiceDivehouse")
		elseif Lvl >= 2 and GuestCount > 4 and not HasProperty("Divehouse", "DanceShow") and not HasProperty("Divehouse", "GoToDance") then
			SetProperty("Divehouse","GoToDance",1)
			MeasureCreate("Measure")
			MeasureAddData("Measure", "TimeOut", Rand(3)+3)
			MeasureStart("Measure", Cocotte, "Divehouse", "AssignToDanceDivehouse")
		else
			MeasureRun(Cocotte,"Divehouse","AssignToLaborOfLove",false)
		end
	end
	return 
end

-- -----------------------
-- MyrmidonIdle
-- -----------------------
function MyrmidonIdle(MyrmAlias)

	--LogMessage("::TOM::AI Myrmidon going idle: ".. GetName(MyrmAlias))
	SimGetWorkingPlace(MyrmAlias, "WorkingPlace")
	GetDynasty("WorkingPlace", "DynAlias")
	local IsManageEmployee = GetProperty(MyrmAlias, "TWP_ManageEmployee") or 0
	if DynastyIsAI("DynAlias") or IsManageEmployee > 0 then
		if GetHPRelative(MyrmAlias) < 0.7 then
			-- Heal
			GetSettlement("WorkingPlace", "City")
			CityGetNearestBuilding("City", "", -1, GL_BUILDING_TYPE_LINGERPLACE, -1, -1, FILTER_IGNORE, "LingerPlace")
			MeasureRun("", "LingerPlace", "Linger")
			return
		end
		-- patrol or escort or gather evidence or check outfit
		local Decision = Rand(11)
		if Decision < 4 then
			-- escort
			local PartyCount = DynastyGetMemberCount("DynAlias")
			DynastyGetFamilyMember("DynAlias", Rand(PartyCount), "ProtectMe")
			--LogMessage("::TOM::AI Myrmidon ".. GetName(MyrmAlias).." escorting: ".. GetName("ProtectMe"))
			MeasureRun(MyrmAlias, "ProtectMe", "EscortCharacterOrTransport")
		elseif Decision < 8 then -- 4, 5, 6, 7
			-- patrol
			DynastyGetRandomBuilding("DynAlias", -1, -1, "PatrolPlace")
			--LogMessage("::TOM::AI Myrmidon ".. GetName(MyrmAlias).." patroling: ".. GetName("PatrolPlace"))
			MeasureRun(MyrmAlias, "PatrolPlace", "PatrolTheTown")
		elseif Decision < 10 and BuildingHasUpgrade("WorkingPlace", "Commode") then -- 8, 9
			-- gather evidence
			--LogMessage("::TOM::AI Myrmidon ".. GetName(MyrmAlias).." gathering evidence...")
			if GetSettlement("WorkingPlace", "City") and chr_CityFindCrowdedPlace("City", MyrmAlias, false, "GatherDestination") then
				f_ExitCurrentBuilding(MyrmAlias)
				f_MoveTo(MyrmAlias, "GatherDestination", GL_MOVESPEED_RUN, 500)
				MeasureRun(MyrmAlias, 0, "OrderCollectEvidence")
			end
		end -- Decision 10
	elseif GetFreeLocatorByName("WorkingPlace", "backroom_sit_",1,3, "ChairPos") 
	    or GetFreeLocatorByName("WorkingPlace", "chair",1,4, "ChairPos") then
		--LogMessage("::TOM::AI Myrmidon ".. GetName(MyrmAlias).." is bored.")
		if not f_BeginUseLocator(MyrmAlias, "ChairPos", GL_STANCE_SIT, true) then
			RemoveAlias("ChairPos")
			--LogMessage("::TOM::AI Myrmidon ".. GetName(MyrmAlias).." did not find a chair.")
			return
		end
		for i=1,7 do
			local WhatToDo2 = Rand(4)
			if WhatToDo2 == 0 then
				Sleep(10) 
			elseif WhatToDo2 == 1 then
				Sleep(5)
			elseif WhatToDo2 == 2 then
				PlayAnimation(MyrmAlias,"sit_talk")
			else
				PlayAnimation(MyrmAlias,"sit_laugh")					
			end
			Sleep(10)
		end
		if DynastyIsAI("DynAlias") then
			-- I'm rested now, check equipment and get going
			MeasureRun(MyrmAlias, nil, "CheckOutfit")
		end
	end
	Sleep(3)
end

-- -----------------------
-- LeibwacheIdle
-- -----------------------
function LeibwacheIdle(Workbuilding)

	SimGetWorkingPlace("", "WorkingPlace")
	while true do
		if Rand(2) == 0 then
			if GetFreeLocatorByName("WorkingPlace", "GuardPos", 1, 4, "WachPos") then
				if not f_BeginUseLocator("", "WachPos", GL_STANCE_STAND, true) then
					RemoveAlias("WachPos")
					return
				end
			    
				if Rand(2) == 0 then
					Sleep(15) 
				else
					PlayAnimationNoWait("", "sentinel_idle")
				end
			else
				f_Stroll("", 300, 10)
			end
		else
			if GetFreeLocatorByName("WorkingPlace", "Walledge", 1, 4, "WachPos") then
				if not f_BeginUseLocator("", "WachPos", GL_STANCE_STAND, true) then
					RemoveAlias("WachPos")
					return
				end
				
				local WhatToDo2 = Rand(3)
				if WhatToDo2 == 0 then
					Sleep(20) 
				elseif WhatToDo2 == 1 then
					PlayAnimationNoWait("", "sentinel_idle")
				else
					CarryObject("", "", false)
					CarryObject("", "Handheld_Device/ANIM_telescope.nif", false)
					PlayAnimation("", "scout_object")
					CarryObject("", "", false)					
				end
			else
				f_Stroll("", 300, 10)
			end
		end
		Sleep(30)
		if AliasExists("WachPos") then
			f_EndUseLocator("", "WachPos", GL_STANCE_STAND)
		end
	end
end

-- -----------------------
-- DoNothing
-- -----------------------
function DoNothing()
	MsgDebugMeasure("I'm really bored")
	if GetInsideBuildingID("") ~= -1 then
		if Rand(12) == 0 then
			CarryObject("", "Handheld_Device/ANIM_besen.nif", false)
			PlayAnimation("", "hoe_in")	
			for i=0, 5 do
				local waite = PlayAnimationNoWait("", "hoe_loop")
				Sleep(0.5)
				PlaySound3DVariation("", "Locations/herbs", 1.0)
				Sleep(waite-0.5)
			end
			PlayAnimation("", "hoe_out")
			CarryObject("", "", false)
			Sleep((Rand(20)+5))
		else
			Sleep((Rand(30)+10))
		end
	end
	
	local ThingsToDo = Rand(5)
	if ThingsToDo == 0 then
		PlayAnimation("", "cogitate")
		Sleep(5)
	elseif ThingsToDo == 1 then
		CarryObject("", "Handheld_Device/ANIM_Pretzel.nif", false)
		PlayAnimationNoWait("", "eat_standing")
		Sleep(5)
		CarryObject("", "", false)
		Sleep(Rand(10)+3)
	elseif ThingsToDo == 2 then
		CarryObject("", "Handheld_Device/ANIM_beaker.nif", false)
		PlayAnimationNoWait("", "use_potion_standing")
		Sleep(5)
		CarryObject("", "", false)
		Sleep(Rand(10)+3)
	elseif ThingsToDo == 3 then
		if IsDynastySim("") and not GetInsideBuilding("", "inside") then
			-- talk to someone
			Sleep(5)
			local TalkPartners = Find("", "__F((Object.GetObjectsByRadius(Sim)==1500)AND NOT(Object.GetStateImpact(no_idle))AND(Object.IsDynastySim())AND(Object.CanBeInterrupted(StartDialog))AND NOT(Object.HasImpact(Hidden))AND NOT(Object.GetInsideBuilding()))","TalkPartner", -1)
			if TalkPartners >0 then
				MeasureRun("", "TalkPartner"..Rand(TalkPartners), "StartDialog" )
				return
			else
				Sleep(6)
				if Rand(3) == 0 then
					local RandAnim = Rand(4)
					if RandAnim == 0 then
						PlayAnimation("", "cogitate")
					elseif RandAnim == 1 then
						PlayAnimation("", "cough")
					elseif RandAnim == 2 then
						PlayAnimation("", "guard_object")
					elseif RandAnim == 3 then
						PlayAnimation("", "talk_short")
					else
						PlayAnimation("", "nod")
					end
				end
				Sleep(4)
			end
		end
	else
		Sleep((Rand(25)+10))
	end
end

-- -----------------------
-- GoToRandomPosition
-- -----------------------
function GoToRandomPosition()
	MsgDebugMeasure("Walking around...")
	local class
	local offset =100+Rand(250)

	if GetSettlement("", "City") then
		local RandVal = Rand(7)
		if RandVal < 2 then
			class = GL_BUILDING_CLASS_MARKET
		elseif RandVal < 4 then
			class = GL_BUILDING_CLASS_PUBLIC
		else
			class = GL_BUILDING_CLASS_WORKSHOP
		end
		
		if CityGetRandomBuilding("City", class, -1, -1, -1, FILTER_IGNORE, "Destination") then
			if GetOutdoorMovePosition("", "Destination", "MoveToPosition") then
				-- Don't move there if it is too far
				if GetDistance("", "Destination") > 8000 then
					Sleep((Rand(10)+1))
					return
				end
				
				f_MoveTo("", "MoveToPosition", GL_MOVESPEED_WALK, offset)
				-- Add some XP
				IncrementXPQuiet("", 5)
				Sleep((Rand(10)+1))
			end
		end
	end
end

-- -----------------------
-- VisitDoc
-- -----------------------
function VisitDoc(HospitalID)

	SetRepeatTimer("", "ai_VisitDoc", 1)
	local DistanceBest = -1
	local Attractivity
	local Distance
	local FavorBonus = 0
	local Level

	if gameplayformulas_CheckMoneyForTreatment("") == 0 then
		if GetInsideBuilding("", "CurrentBuilding") then
			if BuildingGetType("CurrentBuilding") == GL_BUILDING_TYPE_HOSPITAL then
				f_ExitCurrentBuilding("")
			end
		end
		return
	end

	if GetInsideBuilding("", "CurrentBuilding") then
		if BuildingGetType("CurrentBuilding") == GL_BUILDING_TYPE_HOSPITAL then
			if HasProperty("", "WaitingForTreatment") then
				return
			end
		end
		GetSettlement("CurrentBuilding", "City")

	elseif not GetNearestSettlement("", "City") then
		return
	end
	
	if HospitalID then
		GetAliasByID(HospitalID, "Destination")
	else
		RemoveAlias("Destination")
	end
	
	local MinLevel = 1
	local impactLevels = {
					{"Influenza", 2},
					{"Pox", 2},
					{"Pneumonia", 2},
					{"BurnWound", 3},
					{"Blackdeath", 3},
					{"Caries", 3},
					{"Fracture", 3},
					}

	for i = 1,7 do
		if GetImpactValue("", impactLevels[i][1]) > 0 then
			MinLevel = impactLevels[i][2]
		end
	end

	if not AliasExists("Destination") then	
		economy_GetRandomBuildingByRanking("City", "Destination", 0, GL_BUILDING_TYPE_HOSPITAL, MinLevel)
		if not AliasExists("Destination") then
			return
		end
		
		local IgnoreID
		if HasProperty("", "IgnoreHospital") then
			local Time = GetProperty("", "IgnoreHospitalTime")
			if Time < GetGametime() then
				RemoveProperty("", "IgnoreHospital")
				RemoveProperty("", "IgnoreHospitalTime")
			else
				IgnoreID = GetProperty("", "IgnoreHospital")
			end
		end 
		
		if IgnoreID and IgnoreID == GetID("Destination") then
			-- go home and sleep
			if GetHomeBuilding("", "HomeBuilding") and GetFreeLocatorByName("HomeBuilding", "Bed",1,3, "SleepPosition") then
				MeasureRun("", nil, "GoToSleep")
				return
			else
				return
			end
		end
	end
		
	if not f_MoveTo("", "Destination", GL_MOVESPEED_RUN) then
		return
	end

	--go home if there are too much sick sims
	if not DynastyIsPlayer("") then
		local SickSimFilter = "__F((Object.GetObjectsByRadius(Sim) == 10000) AND (Object.Property.WaitingForTreatment == 1))"
		local NumSickSims = Find("", SickSimFilter,"SickSim", -1)
		if NumSickSims > 10 then
			f_ExitCurrentBuilding("")
			return
		end
	end
		
	if GetFreeLocatorByName("Destination", "bench", 1, 6, "BenchPos") then
		f_BeginUseLocator("", "BenchPos", GL_STANCE_SITBENCH, true)
	end
		
	if ((GetImpactValue("", "Sickness") > 0) or (GetHP("") < GetMaxHP(""))) then
		RemoveOverheadSymbols("")
			
		SetProperty("", "WaitingForTreatment", 1)
		
		-- Send a message if no healer is working right now
		if BuildingGetOwner("Destination", "MasterDoc") and DynastyIsPlayer("MasterDoc") then
			if BuildingGetProducerCount("Destination", PT_MEASURE, "MedicalTreatment") < 1 then
				-- check the boss aswell
				if GetCurrentMeasureName("MasterDoc") ~= "MedicalTreatment" then
					if GetImpactValue("MasterDoc", "SuppressMedicalMessage") == 0 then
						MsgNewsNoWait("MasterDoc", "Destination", "", "building", -1,
									"@L_IDLE_VISITDOC_NODOC_HEAD", "@L_IDLE_VISITDOC_NODOC_BODY", GetID(""),
									GetID("Destination"))
						AddImpact("MasterDoc", "SuppressMedicalMessage", 1, 1)
					end
				end
			end
		end
		
		local Waittime = GetGametime() + 6
		while GetGametime() < Waittime do
			if HasProperty("", "StartTreat") then
				Sleep(25)
			else
				Sleep(5*Rand(10)+1)
				if AliasExists("BenchPos") then
					if (LocatorGetBlocker("BenchPos") ~= GetID("")) then
						if GetFreeLocatorByName("Destination", "bench", 1, 6, "BenchPos") then
							f_BeginUseLocator("", "BenchPos", GL_STANCE_SITBENCH, true)
						end
					end
				else
					if GetFreeLocatorByName("Destination", "bench", 1, 6, "BenchPos") then
						f_BeginUseLocator("", "BenchPos", GL_STANCE_SITBENCH, true)
					end
				end
			end
		end
			
		if HasProperty("", "WaitingForTreatment") then
			RemoveProperty("", "WaitingForTreatment")
		end
	end
		
	--go home if you were not treated
	if not DynastyIsPlayer("") then
		f_ExitCurrentBuilding("")
		idlelib_GoToRandomPosition()
		return
	end
end

-- -----------------------
-- Illness
-- -----------------------
function Illness()

	MsgDebugMeasure("I'm sick and no doc available ...")
	if GetSettlement("", "City") then
		
		CityGetLocalMarket("City", "Market")
		local ItemList = { "HerbTea", "Blanket", "Soap" }
		
		if CityGetRandomBuilding("City", 5, GL_BUILDING_TYPE_MARKET, -1, -1, FILTER_IGNORE, "Destination") then
			f_MoveTo("", "Destination", GL_MOVESPEED_RUN, 150)
		end
		
		local Found = false
		for i=1, 3 do
			if GetItemCount("Destination", ItemList[i]) > 0 then
				local Price = ItemGetPriceSell(ItemList[i], "Market")
				if chr_GetBudget("", 1) >= Price then
					Found = ItemList[i]
					Transfer(nil, nil, INVENTORY_STD, "Destination", INVENTORY_STD, Found, 1)
					chr_UseBudget("", 1, Price, "WaresBought")
					AddItems("", Found, 1, INVENTORY_STD)
					break
				end
			end
		end
		
		if Found == "Soap" then
			Sleep(3)
			RemoveItems("", "Soap", 1)
			AddImpact("", "Resist", 6)
			AddImpact("", "Soap", 6)
		end
		
		-- go home
		idlelib_GoHome()
	end
end

-- -----------------------
-- GetCorn
-- -----------------------
function GetCorn()

	MsgDebugMeasure("Get Corn from the farm")
	if GetSettlement("", "City") then
		if Rand(2) == 0 then
			if not chr_FindInterestingWorkshop("", GL_BUILDING_TYPE_FARM, 0, 1000, 10000, "Destination") then
				return
			end
		else
			if not chr_FindInterestingWorkshop("", GL_BUILDING_TYPE_FRUITFARM, 0, 1000, 10000, "Destination") then
				return
			end
		end
		
		f_MoveTo("", "Destination", GL_MOVESPEED_WALK, 200)
			
		if not GetHomeBuilding("", "HomeBuilding") then	
			return
		end
		
		local Budget = (chr_GetBudget("", 1) / 4) -- don't spend more than 25% of your basic purse
		local ItemCount = economy_BuyRandomItems("Destination", "", Budget, Rand(5)+1)				
			
		if ItemCount and ItemCount > 0 then
			MoveSetActivity("", "carry")
			Sleep(2)
			CarryObject("", "Handheld_Device/ANIM_Bag.nif", false)	
			if not f_MoveTo("", "HomeBuilding") then
				MoveSetActivity("")
				CarryObject("", "", false)
				return
			end
			
			MoveSetActivity("")
			CarryObject("", "", false)
		else
			if not f_MoveTo("", "HomeBuilding") then
				return
			end
		end
			
		Sleep(Rand(12)+5)
	end
end

-- -----------------------
-- BuySomething
-- -----------------------
function BuySomethingFromMarket(Type)
	MsgDebugMeasure("Buying Stuff at the Market")
	if GetSettlement("", "City") then
		CityGetLocalMarket("City", "Market")
		local Market = Rand(5)+1
		if CityGetRandomBuilding("City", 5,14,Market,-1, FILTER_IGNORE, "Destination") then
			local RandPos = Rand(200)
			GetFleePosition("", "Destination", (130+RandPos), "DestPos")
			if not f_MoveTo("", "DestPos",GL_WALKSPEED_WALK) then
				return
			end
			PlayAnimation("", "cogitate")
			if SimGetGender("") == GL_GENDER_MALE then
				PlaySound3DVariation("", "CharacterFX/male_neutral", 1)
			else
				PlaySound3DVariation("", "CharacterFX/female_neutral",1)
			end
			Sleep(Rand(5)+2)
			
			local AniObj = ""
			local success = false
			
			if Type == "Food" then
				local ItemList = { "Honey", "Fruit", "Fungi", "Barleybread", "Wheatbread", "BreadRoll", "GrainPap", "SalmonFilet", "RoastBeef", "FriedHerring", "Shellsoup", "SmokedSalmon"}
				local ItemCounter = 12
				local CheckItem
				
				local Amount = chr_GetRank("") -- higher rank = multiple items bought if budget is enough
				for i=0, Amount do
					CheckItem = ItemList[Rand(ItemCounter)+1]
					if CheckItem then
						local Available = GetItemCount("Market", CheckItem)
						local PriceTag = ItemGetPriceBuy(CheckItem, "Market")
						if Available > 0 then -- we got something, but can you pay?
							if chr_GetBudget("", 1) >= PriceTag then
								if not success then
									success = true
								end
								LogMessage("Idle: "..GetName("").." bought food at the market ("..CheckItem..")")
								Transfer(nil, nil, INVENTORY_STD, "Destination", INVENTORY_STD, CheckItem, 1)
								chr_UseBudget("", 1, PriceTag, "WaresBought")
								-- AddItems("", Found, 1, INVENTORY_STD) no need to actually add items here, but we could
							end
						end
					end
				end
				
				CarryObject("", "Handheld_Device/ANIM_Breadbasket.nif", false)
			elseif Type == "Religion" then
				local ItemList = { "Parchment", "Schadelkerze", "Amulet", "Chaplet", "Housel" }
				local ItemCounter = 5
				local CheckItem
				
				local Amount = chr_GetRank("") -- higher rank = multiple items bought if budget is enough
				for i=0, Amount do
					CheckItem = ItemList[Rand(ItemCounter)+1]
					if CheckItem then
						local Available = GetItemCount("Market", CheckItem)
						local PriceTag = ItemGetPriceBuy(CheckItem, "Market")
						if Available > 0 then -- we got something, but can you pay?
							if chr_GetBudget("", 1) >= PriceTag then
								if not success then
									success = true
								end
								LogMessage("Idle: "..GetName("").." bought religious stuff at the market ("..CheckItem..")")
								Transfer(nil, nil, INVENTORY_STD, "Destination", INVENTORY_STD, CheckItem, 1)
								chr_UseBudget("", 1, PriceTag, "WaresBought")
								-- AddItems("", Found, 1, INVENTORY_STD) no need to actually add items here, but we could
							end
						end
					end
				end
				
				CarryObject("", "Handheld_Device/ANIM_holzscheite.nif", false)
			elseif Type == "Luxury" then
				local ItemList = { "Grindingbrick", "vase", "Tool", "SilverRing", "GemRing", "GoldChain", "OakwoodRing", "BuildMaterial", "MoneyBag", "Gold", "Gemstone", "Shellchain", "Pearlchain", "Knochenarmreif" }
				local ItemCounter = 14
				local CheckItem
				
				local Amount = chr_GetRank("") + 1 -- higher rank = multiple items bought if budget is enough
				for i=0, Amount do
					CheckItem = ItemList[Rand(ItemCounter)+1]
					if CheckItem then
						local Available = GetItemCount("Market", CheckItem)
						local PriceTag = ItemGetPriceBuy(CheckItem, "Market")
						if Available > 0 then -- we got something, but can you pay?
							if chr_GetBudget("", 2) >= PriceTag then
								if not success then
									success = true
								end
								LogMessage("Idle: "..GetName("").." bought luxury stuff at the market ("..CheckItem..")")
								Transfer(nil, nil, INVENTORY_STD, "Destination", INVENTORY_STD, CheckItem, 1)
								chr_UseBudget("", 2, PriceTag, "WaresBought")
								-- AddItems("", Found, 1, INVENTORY_STD) no need to actually add items here, but we could
							end
						end
					end
				end
				
				CarryObject("", "Handheld_Device/ANIM_Bag.nif", false)
			elseif Type == "Clothing" then
				local ItemList = { "Cloth", "Wool", "Leather", "Blanket", "FarmersClothes", "CitizensClothes", "NoblesClothes" }
				local ItemCounter = 7
				local CheckItem
				
				local Amount = chr_GetRank("") -- higher rank = multiple items bought if budget is enough
				for i=0, Amount do
					CheckItem = ItemList[Rand(ItemCounter)+1]
					if CheckItem then
						local Available = GetItemCount("Market", CheckItem)
						local PriceTag = ItemGetPriceBuy(CheckItem, "Market")
						if Available > 0 then -- we got something, but can you pay?
							if chr_GetBudget("", 2) >= PriceTag then
								if not success then
									success = true
								end
								LogMessage("Idle: "..GetName("").." bought clothing stuff at the market ("..CheckItem..")")
								Transfer(nil, nil, INVENTORY_STD, "Destination", INVENTORY_STD, CheckItem, 1)
								chr_UseBudget("", 2, PriceTag, "WaresBought")
								-- AddItems("", Found, 1, INVENTORY_STD) no need to actually add items here, but we could
							end
						end
					end
				end
				
				CarryObject("", "Handheld_Device/ANIM_Tailorbasket.nif", false)
			
			elseif Type == "Weapon" then
				local ItemList = { "Dagger", "Shortsword", "Mace"}
				local ItemCounter = 14
				local CheckItem
				
				local Amount = chr_GetRank("") + 1 -- higher rank = multiple items bought if budget is enough
				for i=0, Amount do
					CheckItem = ItemList[Rand(ItemCounter)+1]
					if CheckItem then
						local Available = GetItemCount("Market", CheckItem)
						local PriceTag = ItemGetPriceBuy(CheckItem, "Market")
						if Available > 0 then -- we got something, but can you pay?
							if chr_GetBudget("", 2) >= PriceTag then
								if not success then
									success = true
								end
								LogMessage("Idle: "..GetName("").." bought luxury stuff at the market ("..CheckItem..")")
								Transfer(nil, nil, INVENTORY_STD, "Destination", INVENTORY_STD, CheckItem, 1)
								chr_UseBudget("", 2, PriceTag, "WaresBought")
								AddItems("", CheckItem, 1, INVENTORY_EQUIPMENT)
							end
						end
					end
				end
				
				if success then
					PlayAnimation("", "hold_middle_in")
					CarryObject("", "weapons/broadsword_01.nif", true)
					PlayAnimation("", "hold_middle_out")
					CarryObject("", "", true)
				end
				return
			end
				
			-- nothing found, buy random stuff instead
			if not success then
				LogMessage("Idle: Nothing found, "..GetName("").." tries to buy a random object instead")
				local alt1, alt2, alt3 = economy_BuyRandomItems("Market", "", chr_GetBudget("", 2), 2)
				if alt1 == nil then
					LogMessage("Idle: Nothing bought for "..GetName(""))
					CarryObject("", "", false)
					return
				end
			end
			
			-- animation stuff
			MoveSetActivity("", "carry")
			Sleep(2)
			PlaySound3DVariation("", "Effects/digging_box", 1)

			if not GetHomeBuilding("", "HomeBuilding") then
				MoveSetActivity("")
				CarryObject("", "", false)
				return
			end
				
			if not f_MoveTo("", "HomeBuilding") then
				MoveSetActivity("")
				CarryObject("", "", false)
				return
			end
				
			MoveSetActivity("")
			CarryObject("", "", false)
			Sleep(Rand(10)+5)
		end
	end
end

-- -----------------------
-- AttendMass (find a church)
-- -----------------------
function AttendMass()
	local SimFaith = SimGetReligion("") --  RELIGION_NONE (-1)=error, RELIGION_CATHOLIC (0)=catholic,RELIGION_EVANGELIC (1)=protestantic
	
	if SimFaith == RELIGION_CATHOLIC then
		chr_FindInterestingWorkshop("", GL_BUILDING_TYPE_CHURCH_CATH, 0, 3000, 30000, "MyChurch")
	else
		chr_FindInterestingWorkshop("", GL_BUILDING_TYPE_CHURCH_EV, 0, 3000, 30000, "MyChurch")
	end
	
	if AliasExists("MyChurch") then
		MeasureRun("", "MyChurch", "AttendMass")
		return
	end
end

-- -----------------------
-- ForceAFight
-- -----------------------
function ForceAFight()
	
	if GetScenario("World") then
		if HasProperty("World", "static") then
			return
		end
	end
	
	local FightPartners = Find("", "__F((Object.GetObjectsByRadius(Sim)==2000)AND(Object.ActionAdmissible())AND NOT(Object.HasDynasty())AND NOT(Object.HasImpact(Unantastbar))AND NOT(Object.GetState(child))AND NOT(Object.GetState(npc))AND NOT(Object.GetState(animal))", "FightPartner", -1)
	if FightPartners < 1 then
		return
	end
	
	if BattleIsFighting("FightPartner0") then
		return
	end
	
	MsgDebugMeasure("Force a Fight")
	SimStopMeasure("FightPartner0")
	StopAnimation("FightPartner0") 
	MoveStop("FightPartner0")
	AlignTo("", "FightPartner0")
	AlignTo(Enemy, "")
	Sleep(1)
	PlayAnimationNoWait("", "threat")
	PlayAnimation("FightPartner0", "insult_character")
	SetProperty("FightPartner0", "Berserker", 1)
	SetProperty("", "Berserker", 1)
	LogMessage("Idle: "..GetName("").." ID: "..GetID("").." forces a fight against "..GetName("FightPartner0").." ID: "..GetID("FightPartner0"))
	BattleJoin("", "FightPartner0", false, false)
end

-- -----------------------
-- SitDown
-- -----------------------
function SitDown()
	MsgDebugMeasure("Sit down and enjoy the season")
	
	if GetSeason() == EN_SEASON_WINTER then
		if Rand(100) > 50 then
			local FightPartners = Find("", "__F((Object.GetObjectsByRadius(Sim)==2000) AND NOT (Object.HasDynasty()))", "FightPartner", -1)
			if FightPartners >0 then
				idlelib_SnowballBattle("FightPartner0")
				return
			end
		else
			MsgDebugMeasure("Relax in the cold")
			local SleepTime = 10 + Rand(30)
			Sleep(SleepTime)
		end
	else
		if GetSettlement("", "City") then
			if CityGetNearestBuilding("City", "", GL_BUILDING_CLASS_PUBLIC, GL_BUILDING_TYPE_LINGERPLACE, -1, -1, FILTER_IGNORE, "Destination") then
				local Stance = 2 --0=sitground, 1=sitbench, 2=stand
				local LingerLevel = BuildingGetLevel("Destination") or 1
				local GuestCount = GetProperty("Destination", "Guests") or 0
				
				if LingerLevel == 1 then -- lingerplace with fire
					if GetFreeLocatorByName("Destination", "idle_Sit", 1, 6, "SitPos") then
						f_BeginUseLocator("", "SitPos", GL_STANCE_SITBENCH, true)
						Stance = 1
						if GetLocatorByName("Destination", "campfire", "CampFirePos") then
							if GetImpactValue("Destination", "torch") == 0 then
								AddImpact("Destination", "torch", 1, 1)
								GfxStartParticle("Campfire", "particles/Campfire2.nif", "CampFirePos", 3)
							end
							
							GuestCount = GuestCount + 1
							SetProperty("Destination", "Guests", GuestCount)
						end
					elseif GetFreeLocatorByName("Destination", "idle_SitGround", 1, 3, "SitPos") then
						Stance = 0
						f_BeginUseLocator("", "SitPos", GL_STANCE_SITGROUND, true)
						GuestCount = GuestCount + 1
						SetProperty("Destination", "Guests", GuestCount)
					elseif GetFreeLocatorByName("Destination", "idle_Stand", 1, 4, "SitPos") then
						Stance = 2
						f_BeginUseLocator("", "SitPos", GL_STANCE_STAND, true)
						GuestCount = GuestCount + 1
						SetProperty("Destination", "Guests", GuestCount)
					else
						return
					end
				
				elseif LingerLevel ~= 1 then -- lingerplace crates
					local list =
					{
						{3,3,4},
						{2,2,4},
						{2,2,4},
						{5,3,5}
					}

					local subList =
					{
						{"Sit","SitGround","Stand"},
						{GL_STANCE_SITBENCH,GL_STANCE_SITGROUND,GL_STANCE_STAND},						
						{1,0,2}
					}

					local data = list[LingerLevel-1]							
					local found = false

					for i = 1,3 do
						if GetFreeLocatorByName("Destination", "idle_"..subList[1][i], 1, data[i], "SitPos") then
							f_BeginUseLocator("", "SitPos", subList[2][i], true)
							SetProperty("Destination", "Guests", GuestCount)
							GuestCount = GuestCount + 1
							Stance = subList[3][i]
							found = true
							break
						end
					end

					if not found then
						return
					end

				end
					
				local EndTime = math.mod(GetGametime(),24) + 1
				
				while (math.mod(GetGametime(),24)) < EndTime do				
					if GuestCount > 1 then
						if Stance == 1 then
							local SleepTime = 5 + Rand(11)
							Sleep(SleepTime)
							local AnimTime = 0
							local idx = Rand(3)
							
							if idx == 0 then
								PlayAnimation("", "bench_sit_offended")
							elseif idx == 1 then
								PlayAnimation("", "bench_sit_talk_short")
							else
								PlayAnimation("", "bench_talk")						
							end
						elseif Stance == 2 then
							if Rand(3) == 0 then
								PlayAnimation("", "cogitate")
							end
							
							local SleepTime = 5 + Rand(11)
							Sleep(SleepTime)
							
							if Rand(5) == 1 then
								PlayAnimationNoWait("", "use_book_standing")
								Sleep(2)
								PlaySound3D("", "Locations/wear_clothes/wear_clothes+1.wav", 0.5)
								CarryObject("", "Handheld_Device/Anim_openscroll.nif", false)
								Sleep(1)
								
								PlaySound3D("","Locations/wear_clothes/wear_clothes+1.wav", 0.5)
								CarryObject("", "", false)
							end
							
							Sleep(2+Rand(10))
						end
					end
					Sleep(Rand(11)+10)
				end
				
				if LingerLevel == 1 and GetImpactValue("Destination", "torch") == 0 then
					GfxStopParticle("Campfire")
				end
				
				GuestCount = GuestCount - 1
				SetProperty("Destination", "Guests", GuestCount)
				f_EndUseLocator("", "SitPos", GL_STANCE_STAND)
				return
			end
		end
	end
end

-- -----------------------
-- VisitMarket
-- -----------------------
function VisitMarket()
	MsgDebugMeasure("Looking for chatter at the market")
	if GetSettlement("", "City") then
		CityGetLocalMarket("City", "Market")
		local Market = Rand(5)+1
		if CityGetRandomBuilding("City", 5,14, Market, -1, FILTER_IGNORE, "Destination") then
			if not f_MoveTo("", "Destination", GL_WALKSPEED_WALK, 300) then
				return
			end
			PlayAnimation("", "cogitate")
			
			if GetFleePosition("", "Destination", 550, "NewPos") then
				f_MoveTo("", "NewPos", GL_WALKSPEED_WALK)
			end
			
			-- look for someone to chat
			local TalkPartners = Find("", "__F((Object.GetObjectsByRadius(Sim)==1500)AND NOT(Object.GetStateImpact(no_idle))AND(Object.CanBeInterrupted(Babble)))", "TalkPartner", -1)
			if TalkPartners > 0 then
				MeasureRun("", "TalkPartner"..Rand(TalkPartners), "Babble" )
				return
			end
		end
	end
	
	if Rand(3) == 0 then
		idlelib_GoToTavern()
		return
	end
	
	if Rand(4) == 0 then
		idlelib_GoToDivehouse()
		return
	end
end

-- -----------------------
-- VisitBlackboard
-- -----------------------
function VisitBlackboard()
	MsgDebugMeasure("Visiting the black board")
	if GetSettlement("", "City") then
		if CityGetNearestBuilding("City", "", -1, GL_BUILDING_TYPE_BLACKBOARD, -1, -1, FILTER_IGNORE, "Destination") then
			if not f_MoveTo("", "Destination", GL_WALKSPEED_WALK, 100) then
				return
			end
			PlayAnimation("", "cogitate")
			
			Sleep(10)
		end
	end
	
	if Rand(3) == 0 then
		idlelib_GoToTavern()
		return
	end
	
	if Rand(4) == 0 then
		idlelib_GoToDivehouse()
		return
	end
end

-- -----------------------
-- Graveyard
-- -----------------------
function Graveyard()
	MsgDebugMeasure("Cry around at the Graveyard")
	local Pay = true
	if GetSettlement("", "City") then
		if not chr_FindInterestingWorkshop("", GL_BUILDING_TYPE_NEKRO, 0, 500, 9000, "Destination") then
			Pay = false
			CityGetRandomBuilding("City", -1, GL_BUILDING_TYPE_GRAVEYARD, -1, -1, FILTER_IGNORE, "Destination")
		end
		
		if not AliasExists("Destination") then
			return
		end
		
		f_MoveTo("", "Destination", GL_MOVESPEED_WALK, Rand(250) + 120)
		
		MoveSetStance("", GL_STANCE_KNEEL)
		
		if Pay then
			if chr_GetBudget("", 1) > 50 then
				local val = chr_GetRank("") * Rand(6) + 1
				CreditMoney("Destination", val, "BuildingSold")
				chr_UseBudget("", 1, val)
			end
		end
		
		Sleep(Rand(10) + 5)
		PlayAnimation("", "knee_pray")
		Sleep(Rand(12) + 6)
		PlayAnimation("", "knee_pray")
		MoveSetStance("", GL_STANCE_STAND)
		
		if Pay then
			if chr_GetBudget("", 1) > 50 then
				local val = chr_GetRank("") * Rand(6) + 1
				CreditMoney("Destination", val, "BuildingSold")
				chr_UseBudget("", 1, val)
			end
		end
	end
end

-- -----------------------
-- CollectWater
-- -----------------------
function CollectWater()
	MsgDebugMeasure("Collecting Water from a Well")
	if GetSettlement("", "City") then
		if FindNearestBuilding("", -1,24,-1,false, "Destination") then
			if not f_MoveTo("","Destination", GL_MOVESPEED_WALK, 25) then
				return
			end
			PlayAnimationNoWait("", "manipulate_middle_low_r")
			Sleep(2)
			if (GetImpactValue("Destination", "polluted") > 0) then
				if Rand(100)>70 then
					Disease.Pox:infectSim("")
				else
					diseases_Fever("", true)
				end
			end
			
			if not GetHomeBuilding("", "HomeBuilding") then	
				return
			end
			if not GetInsideBuilding("", "Inside") or GetID("Inside") ~= GetID("HomeBuilding") then
				PlaySound3DVariation("", "measures/putoutfire", 1)
				CarryObject("Owner", "Handheld_Device/ANIM_Bucket.nif", false)
				Sleep(3)
				if not f_MoveTo("", "HomeBuilding", GL_MOVESPEED_WALK) then
					return
				end
				CarryObject("", "", false)
			end
			SetRepeatTimer("", "CollectWater", 8)
			IncrementXPQuiet("", 10)
			Sleep(Rand(10)+5)
		end
	end
end

-- -----------------------
-- SnowballBattle
-- -----------------------
function SnowballBattle(Target)
	if not AliasExists(Target) then
		return
	end

	MsgDebugMeasure("Throwing Snowballs...")
	AlignTo("", Target)
	Sleep(1.7)
	PlayAnimationNoWait("", "manipulate_bottom_r")
	Sleep(1.5)
	SimStopMeasure(Target)
	MoveStop(Target)
	StopAnimation(Target)
	IncrementXPQuiet("", 10)	

	CarryObject("", "Handheld_Device/ANIM_snowball.nif", false)
	Sleep(1)
	PlayAnimationNoWait("", "throw")
	Sleep(1.8)
	CarryObject("", "" ,false)
	local fDuration = ThrowObject("", Target, "Handheld_Device/ANIM_snowball.nif", 0.1, "snowball", 0, 150, 0)
	Sleep(fDuration)
	GetPosition(Target, "ParticleSpawnPos")
	
	StartSingleShotParticle("particles/snowball.nif", "ParticleSpawnPos", 1, 5)
	AlignTo(Target, "")
	Sleep(0.7)
	PlayAnimation(Target, "threat")
end

-- -----------------------
-- GoToTavern
-- -----------------------
function GoToTavern()
	MsgDebugMeasure("Have some drink in a Tavern")
	if GetSettlement("", "City") then
		
		-- check for Versengold
		local stage = GetData("#MusicStage")
		if stage ~= nil and GetAliasByID(stage, "stageobj") then
			BuildingGetCity("stageobj", "stageCity")
			if GetID("City") == GetID("stageCity") then
				if BuildingGetType("stageobj") == GL_BUILDING_TYPE_TAVERN and GetDistance("", "stageobj") < 12000 then
					CopyAlias("stageobj", "Destination")
				end
			end
		end
		
		if not AliasExists("Destination") then
			chr_FindInterestingWorkshop("", GL_BUILDING_TYPE_TAVERN, 0, 3500, 26000, "Destination")
		end
		
		if not AliasExists("Destination") or not f_MoveTo("", "Destination") then
			return
		end

		if Rand(4) == 0 then
			if HasProperty("Destination", "Versengold") then
				MeasureRun("", nil, "CheerMusicians")
			else
				if HasProperty("", "KissMeHoney") then
					idlelib_KissMeHonza()
				end
			end
		end
		
		-- sit down
		--LogMessage("Tavern: Sit down")
		if IsDynastySim("") then
			if not GetFreeLocatorByName("Destination", "SitRich", 1, 6, "SitPos") then
				f_ExitCurrentBuilding("")
				idlelib_GoToRandomPosition()
				return
			end
			
			if not f_BeginUseLocator("", "SitPos", GL_STANCE_SIT, true) then
				f_ExitCurrentBuilding("")
				idlelib_GoToRandomPosition()
			end			
		else
			if not GetFreeLocatorByName("Destination", "SitInn", 1, 15, "SitPos") then
				f_ExitCurrentBuilding("")
				idlelib_GoToRandomPosition()
				return
			end
			
			if not f_BeginUseLocator("", "SitPos", GL_STANCE_SIT, true) then
				f_ExitCurrentBuilding("")
				idlelib_GoToRandomPosition()
				return
			end
		end
		
		SetProperty("", "WaitingForService", 1)
		--LogMessage("Tavern: WaitingForService is "..GetProperty("", "WaitingForService"))
		
		-- Send a message if no bartender is working right now
		if BuildingGetOwner("Destination", "Master") and DynastyIsPlayer("Master") then
			if BuildingGetProducerCount("Destination", PT_MEASURE, "AssignEmployeeToService") < 1 then
				-- check the boss aswell
				if GetCurrentMeasureName("Master") ~= "AssignEmployeeToService" then
					if GetImpactValue("Master", "SuppressServiceMessage") == 0 then
						MsgNewsNoWait("Master", "Destination", "", "building", -1,
									"@L_IDLE_GOTOTAVERN_NOBARTENDER_HEAD", "@L_IDLE_GOTOTAVERN_NOBARTENDER_BODY", GetID(""),
									GetID("Destination"))
						AddImpact("Master", "SuppressServiceMessage", 1, 1)
					end
				end
			end
		end
		
		local WaitTime = GetGametime() + 6
	--	LogMessage("Tavern: WaitTime is "..WaitTime)
		
		if HasProperty("Destination", "DanceShow") then
			WaitTime = WaitTime + 2
		elseif HasProperty("Destination", "Versengold") then
			WaitTime = WaitTime + 4
		end
		
		while GetGametime() < WaitTime do
			--LogMessage("Tavern: lets go")
			if Rand(3) == 0 then
				PlaySound3DVariation("", "Locations/tavern_people", 1)
			end
			
			if HasProperty("Destination", "Versengold") and Rand(10) > 7 then
				f_EndUseLocator("", "SitPos", GL_STANCE_STAND)
				MeasureRun("", nil, "CheerMusicians")
			end
			
			if HasProperty("", "WaitingForService") then
				Sleep(5*Rand(5)+3)
				
				-- make sure we sit correctly
				if AliasExists("SitPos") then
					if (LocatorGetBlocker("SitPos") ~= GetID("")) then
						if IsDynastySim("") then
							if GetFreeLocatorByName("Destination", "SitRich", 1, 5, "SitPos") then
								f_BeginUseLocator("", "SitPos", GL_STANCE_SIT, true)
							end
						else
							if GetFreeLocatorByName("Destination", "SitInn", 1, 15, "SitPos") then
								f_BeginUseLocator("", "SitPos", GL_STANCE_SIT, true)
							end
						end
					end
				else
					if IsDynastySim("") then
						if GetFreeLocatorByName("Destination", "SitRich", 1, 5, "SitPos") then
							f_BeginUseLocator("", "SitPos", GL_STANCE_SIT, true)
						end
					else
						if GetFreeLocatorByName("Destination", "SitInn", 1, 15, "SitPos") then
							f_BeginUseLocator("", "SitPos", GL_STANCE_SIT, true)
						end
					end
				end
				
				local RandAnim = Rand(4) + 1
				local AnimList = { "sit_talk", "sit_talk_short", "sit_yes", "sit_no" }
				PlayAnimation("", AnimList[RandAnim])
				
			elseif HasProperty("", "DrinkSomething") then
				if Rand(2) == 0 then
					WaitTime = WaitTime - 1
				end
				
				for i=0, 2 do
				
					if Rand(2) == 0 then
						local AnimTime = PlayAnimationNoWait("", "sit_drink")
						Sleep(1)
						CarryObject("", "Handheld_Device/ANIM_beaker_sit_drink.nif", false)
						Sleep(1)
						PlaySound3DVariation("", "CharacterFX/drinking", 1)
						Sleep(AnimTime-1.5)
						CarryObject("", "", false)
						if SimGetGender("") == GL_GENDER_MALE then
							PlaySound3DVariation("", "CharacterFX/male_belch", 1)
						else
							PlaySound3DVariation("", "CharacterFX/female_belch", 1)
						end
					else
						local AnimTime = PlayAnimationNoWait("", "sit_cheer")
						Sleep(1)
						PlaySound3D("", "Locations/tavern/cheers_01.wav", 1)
						CarryObject("", "Handheld_Device/ANIM_beaker_sit_drink.nif", false)
						Sleep(1)
						PlaySound3DVariation("", "CharacterFX/drinking", 1)
						Sleep(AnimTime-1.5)
						CarryObject("", "", false)
					end
					local RndSleep = 1+Rand(3)
					Sleep(RndSleep)
				end
				
				for i=0, 1 do
					local RandAnim = Rand(5) + 1
					local AnimList = { "sit_talk", "sit_talk_short", "sit_yes", "sit_no", "sit_laugh" }
					PlayAnimation("", AnimList[RandAnim])
					Sleep(1)
				end
				
				RemoveProperty("", "DrinkSomething")
				SetProperty("", "WaitingForService", 1)
			elseif HasProperty("", "EatSomething") then
				if Rand(2) == 0 then
					WaitTime = WaitTime - 1
				end
				
				for i=0, 3 do
					if Rand(4) > 0 then
						PlayAnimation("", "sit_eat")
						Sleep(1)
					else
						PlayAnimationNoWait("", "sit_laugh")
						Sleep(2)
						if Rand(2) == 0 then
							PlaySound3D("","Locations/tavern/laugh_01.wav", 1)
						else
							PlaySound3D("", "Locations/tavern/laugh_02.wav", 1)
						end
					end
				end
				
				local RndSleep = 1+Rand(3)
				Sleep(RndSleep)
				
				for i=0, 1 do
					local RandAnim = Rand(4) + 1
					local AnimList = { "sit_talk", "sit_talk_short", "sit_yes", "sit_no" }
					PlayAnimation("", AnimList[RandAnim])
					Sleep(1)
				end
				
				RemoveProperty("", "EatSomething")
				SetProperty("", "WaitingForService", 1)
			elseif HasProperty("", "Served") then
				Sleep(3)
			else
				break
			end
		end
		
		if HasProperty("", "WaitingForService") then
			RemoveProperty("", "WaitingForService")
		elseif HasProperty("", "DrinkSomething") then
			RemoveProperty("", "DrinkSomething")
		elseif HasProperty("", "EatSomething") then
			RemoveProperty("", "EatSomething")
		end
		
		if IsDynastySim("") then
			-- improve relations with other present dynasties
			BuildingGetInsideSimList("Destination", "SimList")
			local ListSize = ListSize("SimList")
			for i=0, ListSize-1 do
				ListGetElement("SimList", i, "CheckSim")
				if GetDynasty("CheckSim", "CheckDyn") then
					local DynID = GetID("CheckDyn")
					if ReadyToRepeat("", "DrinkBuddy_"..DynID) then
						SetRepeatTimer("", "DrinkBuddy_"..DynID, 1)
						chr_ModifyFavor("", "CheckSim", 2)
					end
				end
			end
		end
		
		f_EndUseLocator("", "SitPos", GL_STANCE_STAND)
			
		--LogMessage("Tavern: End")

		local Hour = math.mod(GetGametime(), 24)
		if Hour > 20 or Hour < 6 then
			if Rand(100) >= 80 then
				--LoopAnimation("","idle_drunk",10)
				AddImpact("", "totallydrunk", 1, 6)
				AddImpact("", "MoveSpeed", 0.8, 6)
				SetState("", STATE_TOTALLYDRUNK, true)
				return
			end
		end
		
		if IsDynastySim("") then
			f_ExitCurrentBuilding("")
			idlelib_GoHome()
			return
		else
			f_ExitCurrentBuilding("")
			idlelib_GoToRandomPosition()
			return
		end
	end
end

-- -----------------------
-- KissMeHonza
-- -----------------------
function KissMeHonza()
	MsgDebugMeasure("Get a kiss from Versengold")
	local Musician = GetProperty("", "KissMeHoney")
	
	if GetAliasByID(Musician, "Musician") then
		if not HasProperty("Musician", "Moving") and not HasProperty("Musician", "KissMe") and (GetDistance("", "Musician") < 6001) then
			SetProperty("Musician", "KissMe", GetID(""))
			if f_MoveTo("", "Musician", GL_MOVESPEED_WALK, 500) then
				if not HasProperty("Musician", "Moving") and not HasProperty("Musician", "MusicStage") then
						
					while true do
						if not HasProperty("Musician", "KissMe") or HasProperty("Musician", "Moving") or HasProperty("Musician", "MusicStage") then
							RemoveProperty("", "KissMeHoney")
							IncrementXP("", 25)
							break
						end
						if Rand(100) < 5 then
							local AnimTime = PlayAnimationNoWait("", "giggle")
							Sleep(1)
							MsgSay("", GetName("Musician"))
							Sleep(AnimTime)
						else
							Sleep(6)
						end
					end
						
				end
			else
				RemoveProperty("", "KissMeHoney")
				RemoveProperty("Musician", "KissMe")
			end
		else
			RemoveProperty("", "KissMeHoney")
		end
	else
		RemoveProperty("", "KissMeHoney")
	end
end

-- -----------------------
-- GoToDivehouse
-- -----------------------
function GoToDivehouse()
	local DistanceBest = -1
	local Attractivity
	local Distance
	
	MsgDebugMeasure("Have some drink in a Divehouse")
	if GetSettlement("", "City") then

		local stage = GetData("#MusicStage")
		if stage~=nil and GetAliasByID(stage,"stageobj") then
			BuildingGetCity("stageobj","stageCity")
			if GetID("City")==GetID("stageCity") and (Rand(100)>39) then
				if BuildingGetType("stageobj")==GL_BUILDING_TYPE_TAVERN then
					idlelib_GoToTavern()
					return
				end
			end
		end
		
		economy_GetRandomBuildingByRanking("City", "Destination", 0, GL_BUILDING_TYPE_DIVEHOUSE)
		
		if not AliasExists("Destination") or not f_MoveTo("","Destination") or GetState("Destination",STATE_BUILDING) then
			-- no Divehouse found
			return
		end

		if Rand(5)==0 then
			if HasProperty("Destination","Versengold") then
				MeasureRun("", nil, "CheerMusicians")
			else
				if HasProperty("", "KissMeHoney") then
					idlelib_KissMeHonza()
				end
			end
		end
		
		local SimFilter = "__F((Object.GetObjectsByRadius(Sim) == 1000))"
		local NumSims = Find("", SimFilter,"Sim", -1)
		if NumSims > 30 then
			f_ExitCurrentBuilding("")
			idlelib_GoToRandomPosition()
			return
		end
				
		local lokalPos = 0
		
		if Rand(3) == 0 then
		    if GetFreeLocatorByName("Destination", "Bar", 1, 4, "StehPos") then
			    f_BeginUseLocator("", "StehPos", GL_STANCE_STAND, true)
					lokalPos = 1
				else
			    if GetFreeLocatorByName("Destination", "appeal", 1, 4, "StehPos") then
				    f_BeginUseLocator("", "StehPos", GL_STANCE_STAND, true)
					lokalPos = 1
				else
				    local posPlatz = Rand(3)
					if posPlatz == 0 then
		          		GetFreeLocatorByName("Destination", "Sit", 1, 4, "SitPos")
					elseif posPlatz == 1 then
					    GetFreeLocatorByName("Destination", "Sit", 5, 7, "SitPos")
					else
					    GetFreeLocatorByName("Destination", "Sit", 8, 11, "SitPos")
					end
		        	if not f_BeginUseLocator("", "SitPos", GL_STANCE_SIT, true) then
			        	return
		        	end
			    end
			end
		else
	    	local posPlatz = Rand(3)
			if posPlatz == 0 then
			    if not GetFreeLocatorByName("Destination","Sit",1,4,"SitPos") then
				    f_Stroll("",150,2) 
				    return
				end
	   		elseif posPlatz == 1 then
				if not GetFreeLocatorByName("Destination","Sit",5,7,"SitPos") then
			    	f_Stroll("",150,2) 
			    	return				
				end
			else
				if not GetFreeLocatorByName("Destination","Sit",8,11,"SitPos") then
					f_Stroll("", 150, 2) 
				 	return			
				end
			end
			if not f_BeginUseLocator("","SitPos",GL_STANCE_SIT,true) then
				return
			end
    	end			
		
		local Hour = math.mod(GetGametime(), 24)
		local verweile = 0
		local basicvalue = 1

		if Hour > 6 and Hour < 20 then
			verweile = Rand(2)+3
		else
		  	verweile = Rand(4)+4
		end

		if HasProperty("Destination","DanceShow") then
		  	verweile = verweile + 3
		end

		if HasProperty("Destination","ServiceActive") then
		  	verweile = verweile + 2
		end

		if HasProperty("Destination","Versengold") then
			basicvalue = basicvalue + 1
		  	verweile = verweile + 3
		end

    	local simstand = SimGetRank("")
    	local grundBetrag = 0

		if HasProperty("Destination", "ServiceActive") then
		    if simstand == 0 or simstand == 1 then
		    	grundBetrag = Rand(3)+5
		    elseif simstand == 2 then
		      grundBetrag = Rand(5)+5
		    elseif simstand == 3 then
		      grundBetrag = Rand(3)+10
		    elseif simstand == 4 then
		      grundBetrag = Rand(5)+15
		    elseif simstand == 5 then
		      grundBetrag = Rand(10)+20
		    end				
		else
		    if simstand == 0 or simstand == 1 then
			    grundBetrag = 5
		    elseif simstand == 2 then
		       grundBetrag = 5
		    elseif simstand == 3 then
		  	    grundBetrag = 10
		    elseif simstand == 4 then
		        grundBetrag = 15
	     	elseif simstand == 5 then
		        grundBetrag = 20
		     end
		end
		if HasProperty("Destination", "Versengold") then
	    	grundBetrag = grundBetrag + 15
		end
		
		while verweile > 0 do

			if HasProperty("Destination","Versengold") and Rand(10)>7 then
				if lokalPos == 0 then
					f_EndUseLocator("", "SitPos", GL_STANCE_STAND)
				else
					f_EndUseLocator("", "StandPos", GL_STANCE_STAND)
				end
				MeasureRun("", nil, "CheerMusicians")
			end
		
			local AnimTime
			local AnimType = Rand(4)
			if AnimType == 0 then
		    if lokalPos == 0 then
			    AnimTime = PlayAnimationNoWait("","sit_drink")
			    Sleep(1)
			    CarryObject("","Handheld_Device/ANIM_beaker_sit_drink.nif",false)
				else
			    AnimTime = PlayAnimationNoWait("","use_potion_standing")
			    Sleep(1)
			    CarryObject("","Handheld_Device/ANIM_beaker.nif",false)
				end
				CreditMoney("Destination",grundBetrag,"Offering")
				Sleep(1)
				PlaySound3DVariation("","CharacterFX/drinking",1)
				Sleep(AnimTime-1.5)
				CarryObject("","",false)
				PlaySound3DVariation("","CharacterFX/nasty",1)
				Sleep(1.5)
			elseif AnimType == 1 then
		    if lokalPos == 0 then
			    PlayAnimation("","sit_talk")
				else
			    PlayAnimation("","talk")
				end
			elseif AnimType == 2 then
		    if lokalPos == 0 then
			    AnimTime = PlayAnimationNoWait("","sit_cheer")
			    Sleep(1)
			    PlaySound3D("","Locations/tavern/cheers_01.wav",1)
			    CarryObject("","Handheld_Device/ANIM_beaker_sit_drink.nif",false)
				else
			    AnimTime = PlayAnimationNoWait("","cheer_01")
			    Sleep(1)
			    PlaySound3D("","Locations/tavern/cheers_01.wav",1)
			    CarryObject("","Handheld_Device/ANIM_beaker.nif",false)
				end
				CreditMoney("Destination",grundBetrag,"Offering")
				Sleep(1)
				PlaySound3DVariation("","CharacterFX/drinking",1)
				Sleep(AnimTime-1.5)
				CarryObject("","",false)
				Sleep(1.5)
			elseif AnimType == 3 then
		    if lokalPos == 0 then
			    PlayAnimationNoWait("","sit_laugh")
				else
			    PlayAnimationNoWait("","laud_02")
				end
				Sleep(2)
				if Rand(2)==0 then
					PlaySound3D("","Locations/tavern/laugh_01.wav",1)
				else
					PlaySound3D("","Locations/tavern/laugh_02.wav",1)
				end
				Sleep(2)
			end
			
			local NumItems = Rand(2)+1
			if HasProperty("Destination", "DanceShow") then
				NumItems = Rand(3)+2
			end

			local BoughtItem, BoughtAmount = economy_BuyRandomItems("Destination", "", 0, NumItems)
			if BoughtItem and BoughtItem > 0 then
				if HasProperty("Destination","ServiceActive") then
					local TavernLevel = BuildingGetLevel("Destination")
					local TavernAttractivity = GetImpactValue("Destination", "Attractivity")	

					local Tip = math.floor(TavernLevel * (10 + (Rand(20)+1) * (TavernAttractivity + basicvalue)))
					CreditMoney("Destination",Tip,"tip")
				end
			end
			verweile = verweile - 1
		end
		if lokalPos == 0 then
		    f_EndUseLocator("","SitPos",GL_STANCE_STAND)
		else
		    f_EndUseLocator("","StandPos",GL_STANCE_STAND)
		end
		
		local Hour = math.mod(GetGametime(), 24)
		if Hour > 21 or Hour < 4 then
			if Rand(100) > 90 then
				AddImpact("","totallydrunk",1,6)
				AddImpact("","MoveSpeed",0.7,6)
				SetState("",STATE_TOTALLYDRUNK,true)
				StopMeasure()
			end
		end
	end
end

-- -----------------------
-- TakeACredit
-- -----------------------
function TakeACredit()
	if HasProperty("","ProTCBank") then
		return
	end
	SetProperty("","ProTCBank",1)
	local DistanceBest = -1
	local Attractivity
	local Distance

	if GetSettlement("", "City") then
		economy_GetRandomBuildingByRanking("City", "Destination", 0, GL_BUILDING_TYPE_BANKHOUSE)
	
		local IgnoreID
		if HasProperty("", "IgnoreBank") then
			local Time = GetProperty("", "IgnoreBankTime")
			if Time < GetGametime() then
				RemoveProperty("", "IgnoreBank")
				RemoveProperty("", "IgnoreBankTime")
			else
				IgnoreID = GetProperty("", "IgnoreBank")
			end
		end
		if not AliasExists("Destination") or (IgnoreID and IgnoreID == GetID("Destination")) then
			-- no suitable bank found
			return
		end
		
		if f_MoveTo("","Destination") then
			if not GetLocatorByName("Destination","Wait4","SitPos") then
				if not GetLocatorByName("Destination","Wait3","SitPos") then
					if not GetFreeLocatorByName("Destination","Wait",1,4,"SitPos") then
						return
					else
						if not HasProperty("Destination","BankKundschaft") then
							SetProperty("Destination","BankKundschaft",1)
						end	
					end
				else
					if not HasProperty("Destination","BankKundschaft") then
						SetProperty("Destination","BankKundschaft",2)
					end						
				end
			else
				if not HasProperty("Destination","BankKundschaft") then
					SetProperty("Destination","BankKundschaft",2)
				end
			end
			
			local coinCheckEnd = false
			if not f_BeginUseLocator("","SitPos",GL_STANCE_SIT,true) then
			--	if idlelib_BuySomeCoin(1) == "c" then
					while true do
						local WaitSimFilter = "__F(	(Object.GetObjectsByRadius(Sim) == 5000) AND (Object.Property.WaitForCredit==1) AND NOT (Object.Property.StartSay==1)	)"
						local NumWaitSims = Find("", WaitSimFilter,"WaitSim", -1)
						if NumWaitSims < 4 then
							SetProperty("", "WaitForCredit", 1)
							if f_BeginUseLocator("","SitPos",GL_STANCE_SIT,true) then
								break
							else
								local BehaviourRand = Rand(5)
								local AnimTime
								if BehaviourRand == 0 then
									AnimTime = PlayAnimation("","cogitate")
								elseif BehaviourRand == 1 then
									if NumWaitSims == 2 then
										local myID = GetID("")
										local OtherID
										for i=0, NumWaitSims do
											OtherID = GetID("WaitSim"..i)
											if myID ~= OtherID then
												CopyAlias("WaitSim"..i,"OtherSim")
												break
											end
										end
										if AliasExists("OtherSim") then
											SetProperty("", "StartSay", 1)
											SetProperty("OtherSim", "StartSay", 1)
											f_MoveTo("","OtherSim",GL_MOVESPEED_WALK,100)
											AlignTo("","OtherSim")
											AlignTo("OtherSim","")
											Sleep(1.5)
											AnimTime = PlayAnimationNoWait("","talk")
											if SimGetGender("")==GL_GENDER_MALE then
												PlaySound3DVariation("","CharacterFX/male_neutral",1)
											else
												PlaySound3DVariation("","CharacterFX/female_neutral",1)
											end
										end
									end
								end
								Sleep(AnimTime)
								if HasProperty("", "StartSay") then
									RemoveProperty("", "StartSay")
								end
								if AliasExists("OtherSim") then
									if HasProperty("OtherSim", "StartSay") then
										RemoveProperty("OtherSim", "StartSay")
									end
								end
							end
						else
							coinCheckEnd = true
							break
						end
					end
					if HasProperty("", "WaitForCredit") then
						RemoveProperty("", "WaitForCredit")
					end
			--	else
			--		coinCheckEnd = true
			--	end
			end

			if not coinCheckEnd then
				if HasProperty("", "WaitForCredit") then
					RemoveProperty("", "WaitForCredit")
				end
				if HasProperty("Destination","KreditKonto") then
					if HasProperty("Destination","OfferCreditNow") then
						local kreditMeng = GetProperty("Destination","KreditKonto")
						if kreditMeng == 0 then
							f_EndUseLocator("","SitPos",GL_STANCE_STAND)
							f_MoveTo("","Destination")
						--	idlelib_BuySomeCoin()
						else
							local anim = { "sit_talk","sit_talk_02" }
							local dowhat = PlayAnimationNoWait("",anim[Rand(2)+1])
							MsgSayNoWait("","@L_MEASURE_IDLE_TAKECREDIT_SPRUCH")

							local schuldner = SimGetRank("")
							local lev = SimGetLevel("")

							local hmuch = 0
							if kreditMeng >	8000 then  
								hmuch = (lev*40)+(80*((schuldner*2.5)+Rand(9)+1))
							else
								hmuch = (lev*35)+((kreditMeng/100) * ((schuldner*2)+Rand(8)+1))
								if hmuch < 50 then
									hmuch = 50
								end
							end

							local PlaceIs = SimGetWorkingPlaceID("")
							if lev == 1 and not IsDynastySim("") and PlaceIs == -1 then
								hmuch = 30
							end
							if kreditMeng < hmuch then
								hmuch = kreditMeng
							end
							hmuch = math.floor(hmuch)

							kreditMeng = kreditMeng - hmuch
							SetProperty("","SchuldenGeb",GetID("Destination"))
							SetProperty("","SchuldenMeng",hmuch)
							SetProperty("", "TimeBank", GetGametime()+4)

							SetProperty("Destination","KreditKonto",kreditMeng)


							if BuildingGetOwner("Destination", "Glaubiger") then
								chr_ModifyFavor("","Glaubiger", GL_FAVOR_MOD_SMALL)					
							end

							Sleep(dowhat)
							f_EndUseLocator("","SitPos",GL_STANCE_STAND)
						end
					else

						f_EndUseLocator("","SitPos",GL_STANCE_STAND)
						f_MoveTo("","Destination")
						--idlelib_BuySomeCoin()
					end
				else

					f_EndUseLocator("","SitPos",GL_STANCE_STAND)
					f_MoveTo("","Destination")
				--	idlelib_BuySomeCoin()
				end
			end
		end			
	end
	f_ExitCurrentBuilding("")
	if AliasExists("Destination") then
		RemoveProperty("Destination","BankKundschaft")
	end
	RemoveProperty("","ProTCBank")
	idlelib_GoToRandomPosition()
end

-- -----------------------
-- ReturnACredit
-- -----------------------
function ReturnACredit()
-- ******** THANKS TO KINVER ********
	if HasProperty("","ProRCBank") then
		return
	end
	SetProperty("","ProRCBank",1)
	if not HasProperty("","SchuldenGeb") then
		return false
	end
	local bankID = GetProperty("","SchuldenGeb")
	if GetAliasByID(bankID,"Destination") then
		if f_MoveTo("","Destination") then
		    local playTime = PlayAnimationNoWait("","use_object_standing")
			CarryObject("Destination","Handheld_Device/ANIM_Smallsack.nif",false)
			Sleep(1)
			MsgSayNoWait("","@L_MEASURE_IDLE_RETURNCREDIT_SPRUCH")
			PlaySound3D("","Effects/coins_to_moneybag+0.wav", 1.0)

			if BuildingGetOwner("Destination","Glaubiger") then
				chr_ModifyFavor("","Glaubiger",-GL_FAVOR_MOD_VERYSMALL)					
			end

			local schuld = GetProperty("","SchuldenMeng")
			BuildingGetOwner("Destination","Glaubiger")
			local zinsA = GetSkillValue("Glaubiger",BARGAINING)
			local zinsB = GetSkillValue("Glaubiger",SECRET_KNOWLEDGE)
			local schuldner = SimGetRank("")
			local lev = SimGetLevel("")
			local knowhow = 1.5*(zinsA + zinsB)

			if schuldner <= 1 then
				knowhow=knowhow+3
			elseif schuldner == 2 then
				knowhow=knowhow+4
			elseif schuldner == 3 then
				knowhow=knowhow+6
			elseif schuldner == 4 then
				knowhow=knowhow+8
			else
				knowhow=knowhow+10
			end

			local hecost = (schuld/100) * (knowhow + (lev/2))
			local mecost = 45+(knowhow)+(lev*2)
			local ecost = math.max(hecost,mecost)
			ecost = math.floor(ecost)

			local PlaceIs = SimGetWorkingPlaceID("")
			if PlaceIs ~= -1 then
				ecost = ecost + knowhow
			end
			
			if not HasProperty("Destination","KreditKonto") then
				local bankkonto = schuld + ecost
				CreditMoney("Destination",bankkonto,"tip")
			else
				local bankkonto = GetProperty("Destination","KreditKonto") + schuld
				SetProperty("Destination","KreditKonto",bankkonto)
				CreditMoney("Destination",ecost,"tip")
			end

			if HasProperty("","SchuldenMeng") then
				RemoveProperty("","SchuldenMeng")
			end
			if HasProperty("","SchuldenGeb") then
				RemoveProperty("","SchuldenGeb")
			end
			if HasProperty("", "TimeBank") then
				RemoveProperty("", "TimeBank")
			end
			Sleep(playTime-1)

			f_ExitCurrentBuilding("")

			idlelib_GoToRandomPosition()
			return true
		end
	end
	f_ExitCurrentBuilding("")
	RemoveProperty("","ProRCBank")
	idlelib_GoToRandomPosition()
	return false
end

-- -----------------------
-- BeADrunkChamp
-- -----------------------
function BeADrunkChamp()

	if GetSettlement("", "City") then
		if economy_GetRandomBuildingByRanking("City", "Destination", 0, GL_BUILDING_TYPE_DIVEHOUSE) then
			if f_MoveTo("","Destination") then
		    if not GetFreeLocatorByName("Destination","Bar",1,4,"StehPos") then
			    f_Stroll("",300,10)
			    return
		    end
		    if not f_BeginUseLocator("","StehPos",GL_STANCE_STAND,true) then
			    return
				else
	        Sleep(1)
			    local dowas = PlayAnimationNoWait("","clink_glasses")
			    Sleep(1)
			    CarryObject("","Handheld_Device/ANIM_beaker.nif",false)
			    Sleep(dowas-2)
          if SimGetGender("") == 1 then
            PlaySound3DVariation("","CharacterFX/male_belch",1)
          else
            PlaySound3DVariation("","CharacterFX/female_belch",1)
          end
			    CarryObject("","",false)
					CreditMoney("Destination",Rand(90)+10,"tip")
					local newwinner = GetName("")
					if HasProperty("Destination","BestDrunkPlayer") then
				    local altpoint = GetProperty("Destination","BestDrunkPoints")
						if altpoint > 90 then
					    return
						else
						  RemoveProperty("Destination","BestDrunkPlayer")
							RemoveProperty("Destination","BestDrunkPoints")
					    local bonus = {2,5,10}
					    local newpoints = altpoint + bonus[Rand(3)+1]
              SetProperty("Destination","BestDrunkPlayer",newwinner)
	            SetProperty("Destination","BestDrunkPoints",newpoints)
						end
					else
						local bonus = {10,30,50}
						local newpoints = bonus[Rand(3)+1]
	          SetProperty("Destination","BestDrunkPlayer",newwinner)
		        SetProperty("Destination","BestDrunkPoints",newpoints)
          end
					f_EndUseLocator("","StandPos",GL_STANCE_STAND)
			  end
			end			
		end
	end
end

-- -----------------------
-- BeADiceChamp
-- -----------------------
function BeADiceChamp()

	if GetSettlement("", "City") then
		if CityGetRandomBuilding("City", 2, GL_BUILDING_TYPE_DIVEHOUSE, -1, -1, FILTER_HAS_DYNASTY, "Destination") then
			if f_MoveTo("", "Destination") then
				-- get the position
				if not GetFreeLocatorByName("Destination", "DiceCEO", -1 ,-1, "StandPos") then
					f_Stroll("", 300, 10)
					return
				end
				
				if not f_BeginUseLocator("Owner", "StandPos", GL_STANCE_STAND, true) then
					return
				end
				
				Sleep(1)
				PlaySound3D("", "measures/shake_dices/shake_dices+0.wav", 1.0)
				local wfallen = PlayAnimationNoWait("", "manipulate_middle_low_r")
				Sleep(wfallen-1)
				PlaySound3D("", "measures/throw_dices/throw_dices+0.wav", 1.0)
					
				CreditMoney("Destination", Rand(20)+5,"tip")
				local newwinner = GetName("")
				local bonus
				
				if HasProperty("Destination", "BestDicePlayer") then
					local OldRecord = GetProperty("Destination","BestDicePott")
					bonus = { 2, 5, 10 }
					local neuPott = OldRecord + ((OldRecord / 100) * bonus[Rand(3)+1])
					if neuPott >40000 then
						neuPott = 40000
					end
					RemoveProperty("Destination","BestDicePlayer")
					RemoveProperty("Destination","BestDicePott")

					SetProperty("Destination","BestDicePlayer",newwinner)
					SetProperty("Destination","BestDicePott",neuPott)
				else
					bonus = {50,300,700}
					local newpoints = Rand(300) + bonus[Rand(3)+1]
					SetProperty("Destination","BestDicePlayer",newwinner)
					SetProperty("Destination","BestDicePott",newpoints)
				end
				f_EndUseLocator("","StandPos",GL_STANCE_STAND)
			end
		end			
	end
end


