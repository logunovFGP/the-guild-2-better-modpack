-- -----------------------
-- Init
-- -----------------------
function Init()
	--needed for caching
end

-- -----------------------
-- GetActivity
-- 0 = no activity, 100 = full activity of the sims
-- -----------------------
function GetActivity()

	if not GetSettlement("", "MyCity") then
		return 0
	end

	local CitizenCount = CityGetCitizenCount("MyCity")
	local Activity = 0
	
	if CitizenCount <= 100 then
		Activity = 95
	elseif CitizenCount < 150 then
		Activity = 85
	elseif CitizenCount < 200 then
		Activity = 75
	elseif CitizenCount < 250 then
		Activity = 65
	elseif CitizenCount < 300 then
		Activity = 55
	elseif CitizenCount < 350 then
		Activity = 45
	elseif CitizenCount < 400 then
		Activity = 35
	else
		Activity = 20
	end
	
	if (HasProperty("", "SchuldenGeb")) and (Activity < 80) then
		Activity = 80
	end

	return Activity
end

-- -----------------------
-- CheckWeather
-- -----------------------
function CheckWeather()
	local RainValue = Weather_GetValue(0)
	local CloudValue = Weather_GetValue(1)
	local WindValue = Weather_GetValue(3)
	
	local Weather = (RainValue*7) + CloudValue + (WindValue*2) --0(good) - 10(bad)
	local Activity = 0
	if Weather <=1  then		--sun is shining, everything is allright
		Activity = 100
	elseif Weather <=3 then	--cloudy sky
		Activity = 70
	elseif Weather <=7 then	--rain or snow
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
-- Sleep
-- -----------------------
function Sleep(SleepStart, SleepEnd)
	MsgDebugMeasure("Sleeping...")
	if not GetHomeBuilding("", "HomeBuilding") then
		Sleep(Gametime2Realtime(1))
		return false
	end

	if not GetInsideBuilding("", "Inside") or GetID("Inside")~=GetID("HomeBuilding") then
		if not f_MoveTo("", "HomeBuilding", GL_MOVESPEED_RUN) then
			Sleep(3)
			StopMeasure()
		end
	end

	if GetLocatorByName("HomeBuilding", "Bed1", "SleepPosition") then
		if not f_BeginUseLocator("", "SleepPosition", GL_STANCE_LAY, true) then
			RemoveAlias("SleepPosition")
			if IsDynastySim("") then
				if GetHPRelative("")<1 then
					if GetSettlement("", "MyCity") then
						if CityGetRandomBuilding("MyCity", GL_BUILDING_CLASS_PUBLICBUILDING, 32, -1, -1, FILTER_IGNORE, "Destination") then
							if f_MoveTo("","Destination") then
								MeasureRun("", "Destination", "Linger", true)
								return
							end
						end
					end
				else
					return
				end
			end
		end
	end
	
	local SleepTime = Gametime2Realtime(EN_RECOVERFACTOR_HOME/60)
	local	ContinueSleeping = true
	SetState("", STATE_SLEEPING,true)
	while ContinueSleeping do
	
		ContinueSleeping = false
		
		Sleep(SleepTime)

		if GetHPRelative("") < 1 then
			ModifyHP("", 1)
			ContinueSleeping = true
		end
		
		local time = math.mod(GetGametime(),24)
		if time>SleepStart or time<SleepEnd then
			ContinueSleeping = true
		end
		Sleep(1)
	end
	SetState("",STATE_SLEEPING,false)
	if AliasExists("SleepPosition") then
		f_EndUseLocatorNoWait("", "SleepPosition", GL_STANCE_STAND)
		RemoveAlias("SleepPosition")
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
end

-- -----------------------
-- RobberIdle
-- -----------------------
function RobberIdle(Workbuilding)
	GetLocatorByName(Workbuilding, "Entry1", "WaitingPos")
	
	if GetDistance("", "WaitingPos") > 115 then
		local dist = Rand(100)+10	
		f_MoveTo("", "WaitingPos", GL_MOVESPEED_RUN, dist)
	end

	Sleep(5)
end

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
	
	if BuildingGetType("HomeBuilding") == GL_BUILDING_TYPE_RESIDENCE then
		MeasureRun("", nil, "GoToSleep")
		return
	end
	
	Sleep(Rand(60)+120)
	
	-- random fire
	if Rand(500) == 1 then
		SetState("HomeBuilding", STATE_BURNING, true)
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
			Sleep((Rand(10)+5))
		else
			Sleep((Rand(20)+10))
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
		Sleep(Rand(8)+3)
	elseif ThingsToDo == 2 then
		CarryObject("", "Handheld_Device/ANIM_beaker.nif", false)
		PlayAnimationNoWait("", "use_potion_standing")
		Sleep(5)
		CarryObject("", "", false)
		Sleep(Rand(8)+3)
	elseif ThingsToDo == 3 then
		if IsDynastySim("") and not GetInsideBuilding("", "inside") then
			-- talk to someone
			Sleep(5)
			local TalkPartners = Find("", "__F((Object.GetObjectsByRadius(Sim)==1500)AND NOT(Object.GetStateImpact(no_idle))AND(Object.IsDynastySim())AND(Object.CanBeInterrupted(StartDialog))AND NOT(Object.HasImpact(Hidden))AND(Object.IsNotInBuilding()))","TalkPartner", -1)
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
		Sleep((Rand(20)+10))
	end
end

-- -----------------------
-- GoToRandomPosition
-- -----------------------
function GoToRandomPosition()
	MsgDebugMeasure("Walking around...")
	local class
	local offset = 75+Rand(250)

	if GetSettlement("", "City") then
		local RandVal = Rand(7)
		if RandVal < 2 then
			class = GL_BUILDING_CLASS_MARKET
		elseif RandVal < 4 then
			class = GL_BUILDING_CLASS_PUBLICBUILDING
		else
			class = GL_BUILDING_CLASS_WORKSHOP
		end
		
		if CityGetRandomBuilding("City", class, -1, -1, -1, FILTER_IGNORE, "Destination") then
			if GetOutdoorMovePosition("", "Destination", "MoveToPosition") then
				-- Don't move there if it is too far
				if GetDistance("", "Destination") > 12000 then
					SatisfyNeed("", 5, 0.25)
					Sleep((Rand(6)+1))
					return
				end
				
				f_MoveTo("", "MoveToPosition", GL_MOVESPEED_WALK, offset)
				-- Satisfy the need
				SatisfyNeed("", 5, 0.5)
				-- Add some XP
				IncrementXPQuiet("", 5)
				Sleep((Rand(10)+1))
			end
		end
	end
end

-- -----------------------
-- ForceAFight
-- -----------------------
function ForceAFight(Enemy)
	if BattleIsFighting(Enemy) then
		return
	end
	MsgDebugMeasure("Force a Fight")
	SimStopMeasure(Enemy)
	StopAnimation(Enemy) 
	MoveStop(Enemy)
	AlignTo("",Enemy)
	AlignTo(Enemy,"")
	Sleep(1)
	PlayAnimationNoWait("","threat")
	PlayAnimation(Enemy,"insult_character")
	SetProperty(Enemy,"Berserker",1)
	SetProperty("","Berserker",1)
	BattleJoin("",Enemy,false,false)
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
				idlelib_SnowballBattle("FightPartner")
				return
			end
		else
			MsgDebugMeasure("Relax in the cold")
			local SleepTime = 10 + Rand(30)
			Sleep(SleepTime)
		end
	else
		if GetSettlement("", "City") then
			if CityGetNearestBuilding("City", "", GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_LINGERPLACE, -1, -1, FILTER_IGNORE, "Destination") then
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
						end
					end

					if not found then
						return
					end

				end
					
				local EndTime = GetGametime()+2
				
				while GetGametime() < EndTime do				
					if GuestCount > 1 then
						if Stance == 1 then
							local SleepTime = 2 + Rand(6)
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
							
							Sleep(2)
							
							if Rand(5) == 1 then
								PlayAnimationNoWait("", "use_book_standing")
								Sleep(1)
								PlaySound3D("", "Locations/wear_clothes/wear_clothes+1.wav", 0.5)
								CarryObject("", "Handheld_Device/Anim_openscroll.nif", false)
								Sleep(1)
								
								PlaySound3D("","Locations/wear_clothes/wear_clothes+1.wav", 0.5)
								CarryObject("", "", false)
							end
							
							Sleep(2+Rand(10))
						end
					end
					Sleep(Rand(10)+10)
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
-- Graveyard
-- -----------------------
function Graveyard()
	MsgDebugMeasure("Cry around at the Graveyard")
	if GetSettlement("", "City") then
		economy_GetRandomBuildingByRanking("City", "Destination", 0, GL_BUILDING_TYPE_GRAVEYARD)
		if not f_MoveTo("","Destination", GL_MOVESPEED_RUN, Rand(40) + 120) then
			return
		end
		MoveSetStance("",GL_STANCE_KNEEL)
		Sleep(Rand(10) + 5)
		PlayAnimation("","knee_pray")
		Sleep(Rand(12) + 6)
		MoveSetStance("",GL_STANCE_STAND)
		SatisfyNeed("", 4, 0.2)
		if BuildingGetOwner("Destination", "Sitzer") then
			local Tip = Rand(10)+1
			chr_CreditMoney("Destination", Tip, "tip")
			economy_UpdateBalance("Destination", "Service", Tip)
		end
		Sleep(6)
	end
end

-- -----------------------
-- GetCorn
-- -----------------------
function GetCorn()
	MsgDebugMeasure("Get Corn from the farm")
	if GetSettlement("", "City") then
		economy_GetRandomBuildingByRanking("City", "Destination", 0, GL_BUILDING_TYPE_FARM)
		if not AliasExists("Destination") or not f_MoveTo("","Destination") then
			return
		end
		if not GetHomeBuilding("", "HomeBuilding") then	
			return
		end
		if not GetInsideBuilding("", "Inside") or GetID("Inside")~=GetID("HomeBuilding") then
			Sleep(2)
			
			local ItemCount = economy_BuyRandomItems("Destination", "", 100, Rand(5)+1)				
			if ItemCount and ItemCount > 0 then
				MoveSetActivity("","carry")
				Sleep(2)
				CarryObject("","Handheld_Device/ANIM_Bag.nif",false)	
				if not f_MoveTo("", "HomeBuilding") then
					MoveSetActivity("")
				    CarryObject("","",false)
					return
				end
				MoveSetActivity("")
				CarryObject("","",false)
			else
				if not f_MoveTo("", "HomeBuilding") then
					return
				end
			end
			
		end
		Sleep(Rand(10)+5)
	end
end

-- -----------------------
-- CollectWater
-- -----------------------
function CollectWater()
	MsgDebugMeasure("Collecting Water from a Well")
	if GetSettlement("", "City") then
		if FindNearestBuilding("", -1,24,-1,false, "Destination") then
			if not f_MoveTo("","Destination", GL_MOVESPEED_RUN, 170) then
				return
			end
			PlayAnimationNoWait("","manipulate_middle_low_r")
			Sleep(2)
			if (GetImpactValue("Destination","polluted")>0) then
				if Rand(100)>70 then
					Disease.Pox:infectSim("")
				else
					Disease.Cold:infectSim("")
				end
			end
			
			if not GetHomeBuilding("", "HomeBuilding") then	
				return
			end
			if not GetInsideBuilding("", "Inside") or GetID("Inside")~=GetID("HomeBuilding") then
				PlaySound3DVariation("","measures/putoutfire",1)
				CarryObject("Owner", "Handheld_Device/ANIM_Bucket.nif", false)
				Sleep(3)
				if not f_MoveTo("", "HomeBuilding", GL_MOVESPEED_WALK) then
					return
				end
				CarryObject("","",false)
			end
			Sleep(Rand(10)+5)
		end
	end
end

-- -----------------------
-- BuySomething
-- -----------------------
function BuySomethingAtTheMarket(art)
	MsgDebugMeasure("Buying Stuff at the Market")
	if GetSettlement("", "City") then
		local Market = Rand(5)+1
		if CityGetRandomBuilding("City", 5,14,Market,-1, FILTER_IGNORE, "Destination") then
			if not f_MoveTo("","Destination",GL_MOVESPEED_RUN, 200) then
				return
			end
			PlayAnimation("","cogitate")
			if SimGetGender("")==GL_GENDER_MALE then
				PlaySound3DVariation("","CharacterFX/male_neutral",1)
			else
				PlaySound3DVariation("","CharacterFX/female_neutral",1)
			end
			Sleep(Rand(5)+2)

			if not GetHomeBuilding("", "HomeBuilding") then	
				return
			end
			if not GetInsideBuilding("", "Inside") or GetID("Inside")~=GetID("HomeBuilding") then
				MoveSetActivity("","carry")
				Sleep(2)
				local Amount = 1
				if SimGetGender("")==GL_GENDER_MALE then
					Amount = 2
				end
					if art == 1 then
					    SatisfyNeed("",1,0.5)
					else
					    SatisfyNeed("",7,0.5)
					end
				
				local list = {"holzscheite","Boxvegetable","Breadbasket","Barrel","Bottlebox","Tailorbasket"}
				PlaySound3DVariation("","Effects/digging_box",1)
				CarryObject("","ANIM_"..list[Rand(6)+1]..".nif",false)	
				if not f_MoveTo("", "HomeBuilding") then
				    MoveSetActivity("")
				    CarryObject("","",false)
					return
				end
				MoveSetActivity("")
				CarryObject("","",false)
				
			end
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
	local fDuration = ThrowObject("", Target, "Handheld_Device/ANIM_snowball.nif",0.1,"snowball",0,150,0)
	Sleep(fDuration)
	GetPosition(Target, "ParticleSpawnPos")
	
	StartSingleShotParticle("particles/snowball.nif", "ParticleSpawnPos", 1, 5)
	AlignTo(Target, "")
	Sleep(0.7)
	PlayAnimation(Target, "threat")
end

-- -----------------------
-- GoTownhall
-- -----------------------
function GoTownhall()
	MsgDebugMeasure("Watching, whats going on in the townhall")
	if GetSettlement("", "City") then
		if CityGetRandomBuilding("City", 3, GL_BUILDING_TYPE_TOWNHALL, -1, -1, FILTER_IGNORE, "Destination") then
			if f_MoveTo("","Destination") then
			    if not GetFreeLocatorByName("Destination","Wait",1,8,"SitPos") then
				    f_Stroll("",300,10)
				    return
			    end
				-- if not f_MoveTo("","SitPos") then
					-- f_Stroll("",300,10)
				    -- return
				-- end
			    if f_BeginUseLocator("","SitPos",GL_STANCE_SITBENCH,true) then
					local anim = { "bench_talk","bench_talk_short","bench_talk_offended" }
					Sleep(Rand(5)+10)
					PlayAnimation("",anim[Rand(3)+1])
				    Sleep(Rand(5)+15)
					f_EndUseLocator("","SitPos",GL_STANCE_STAND)
					f_Stroll("",300,10)
					if Rand(3) == 1 then
						f_ExitCurrentBuilding("")
						idlelib_GoToRandomPosition()
					end
					return
				else
				    f_Stroll("",300,10)
				    return
			    end
			end			
		end
	end
end

-- -----------------------
-- Illness
-- -----------------------
function Illness()
	MsgDebugMeasure("Buying HerbTea or Blanket")
	if GetSettlement("", "City") then
		CityGetLocalMarket("City","Market")
		local ItemToBuy
		if GetImpactValue("","Caries")==1 then
			ItemToBuy = "HerbTea" --buy herbtea
		elseif GetImpactValue("","Fever")==1 or GetImpactValue("","Cold")==1 then
			ItemToBuy = "Blanket" --or blanket
		else
			ItemToBuy = "Soap" -- or soap
		end
		
		if ItemToBuy and CityGetRandomBuilding("City", 5, GL_BUILDING_TYPE_MARKET,-1,-1, FILTER_IGNORE, "Destination") then
			f_MoveTo("","Destination", GL_MOVESPEED_RUN, 100)
			f_Transfer("", "", INVENTORY_STD, "Market", INVENTORY_STD, ItemToBuy,1)
		end
		
		PlayAnimation("", "talk")
		Sleep(Rand(5)+2)
		if Rand(100) > 60 then
			local list = {"Cold","Caries","BurnWound"}
			for i = 1,3 do
				if GetImpactValue("",list[i])==1 then
					Disease[list[i]]:cureSim("")
				end
			end
		end
		idlelib_GoHome()
	end
end

-- -----------------------
-- CheckInsideStore
-- -----------------------
function CheckInsideStore(Type)
	local Workshop = "Workshop" 
	if not GetHomeBuilding("", "HomeBld") then
		return
	end
	if not BuildingGetCity("HomeBld", "City") then
		return
	end
	
	-- TODO include type in filter 
	economy_GetRandomBuildingByRanking("City", Workshop)
	--GetRandomBuildingByRanking(CityAlias, ResultAlias, Ranking, Type)
	
	-- Don't move there if it is too far
	if not AliasExists(Workshop) or GetDistance("", Workshop) > 15000 then
		return
	end
	
	-- move near the shop
	local offset = 50 + Rand(101)
	if not f_MoveTo("", Workshop, GL_MOVESPEED_RUN, offset) then -- Move
		return
	end
	
	-- calculate available budget (up to 10% of current money)
	local Budget
	if IsDynastySim("") then
		math.min(2000, math.floor(GetMoney("") / 10))
	else
		Budget = SimGetRank("") * 100
	end
	-- Buy items up to budget, but no more than 5 (prevents outsales of lower items)
	local ItemId, ItemCount = economy_BuyRandomItems(Workshop, "", Budget, Rand(5)+1)
	if ItemId and ItemId > 0 then
		local ProdName = ItemGetLabel(ItemId, ItemCount == 1)
		if ItemCount <= 0 then
		-- nothing available for my budget -- lets shout
			local ProdType
			if Type == 1 then 
				ProdType = "GETGOOD" 
			else 
				ProdType = "GETFOOD" 
			end 
			PlayAnimationNoWait("","propel")
			if Rand(2) == 0 then
				MsgSay("","@L_HPFZ_IDLELIB_"..ProdType.."_SPRUCH_+2",ProdName)
			else
				MsgSay("","@L_HPFZ_IDLELIB_"..ProdType.."_SPRUCH_+3",ProdName)
			end
			if GetProperty(Workshop,"MsgSell")~=0 then
				MsgNewsNoWait("ShopOwner","","","building",-1,
				"@L_MEASURES_BUYSTUFF_HEAD",
				"@L_MEASURES_BUYSTUFF_FAIL",ProdName, GetID(""), GetID(Workshop))
			end
			Sleep(Rand(4)+1) -- cool down before you leave ;)
			return
		end
		BuildingGetOwner(Workshop, "BldOwner")
		local ProdType
		if GL_CLASS_PATRON == SimGetClass("BldOwner") then
			ProdType = "GETFOOD"
			SatisfyNeed("", 1, 0.5)
		else
			ProdType = "GETGOOD"
			SatisfyNeed("", 7, 0.5)
		end
		if Rand(2) == 0 then
			PlayAnimationNoWait("","manipulate_middle_twohand")
			MsgSay("","@L_HPFZ_IDLELIB_"..ProdType.."_SPRUCH_+0",ProdName)
		else
			if ProdType == "GETFOOD" then -- only eat food
				MsgSayNoWait("","@L_HPFZ_IDLELIB_GETFOOD_SPRUCH_+1",ProdName)
				CarryObject("", "Handheld_Device/ANIM_Pretzel.nif", false)
				PlayAnimationNoWait("","eat_standing")
				Sleep(6)
				CarryObject("","",false)
			else
				MsgSayNoWait("","@L_HPFZ_IDLELIB_GETGOOD_SPRUCH_+1",ProdName)
			end
		end
		IncrementXPQuiet("",10)
	end
	Sleep(Rand(4)+1)
end

-- -----------------------
-- GoToTavern
-- -----------------------
function GoToTavern()
	MsgDebugMeasure("Have some drink in a Tavern")
	if GetSettlement("", "City") then

		local stage = GetData("#MusicStage")
		if stage ~= nil and GetAliasByID(stage, "stageobj") then
			BuildingGetCity("stageobj", "stageCity")
			if GetID("City") == GetID("stageCity") and (Rand(100)>39) then
				if BuildingGetType("stageobj") == GL_BUILDING_TYPE_DIVEHOUSE then
					idlelib_GoToDivehouse()
					return
				end
			end
		end
		
		-- TODO calculation of attractivity needs to be increased when versengold is giving a concert
		economy_GetRandomBuildingByRanking("City", "Destination", 0, GL_BUILDING_TYPE_TAVERN)
		
		if not AliasExists("Destination") or not f_MoveTo("","Destination") then
			return
		end

		if Rand(4)==0 then
			if HasProperty("Destination","Versengold") then
				MeasureRun("", nil, "CheerMusicians")
			else
				idlelib_KissMeHonza()
			end
		end
		
		local SimFilter = "__F((Object.GetObjectsByRadius(Sim) == 10000))"
		local NumSims = Find("", SimFilter,"Sim", -1)
		if NumSims > 30 then
			f_ExitCurrentBuilding("")
			idlelib_GoToRandomPosition()
			return
		end
		
		if IsDynastySim("") then
			if not GetFreeLocatorByName("Destination","SitRich",1,5,"SitPos") then
				f_Stroll("",150,2)
				return
			end
			
			if not f_BeginUseLocator("","SitPos",GL_STANCE_SIT,true) then
				return
			end			
		else
			if not GetFreeLocatorByName("Destination", "SitInn", 1, 15, "SitPos") then
				f_Stroll("", 150, 2)
				return
			end
			
			if not f_BeginUseLocator("","SitPos",GL_STANCE_SIT,true) then
				return
			end
		end
		
		local Hour = math.mod(GetGametime(), 24)
		local verweile = 0
		local basicvalue = 1

		if Hour > 6 and Hour < 20 then
			verweile = Rand(3)+2
		else
			verweile = Rand(6)+2
		end

		if HasProperty("Destination", "DanceShow") then
			verweile = verweile + 3
		end
		if HasProperty("Destination", "ServiceActive") then
			verweile = verweile + 2
		end
		if HasProperty("Destination", "Versengold") then
			basicvalue = basicvalue + 1
			verweile = verweile + 3
		end
		
		while verweile > 0 do

			if HasProperty("Destination","Versengold") and Rand(10)>7 then
				f_EndUseLocator("","SitPos",GL_STANCE_STAND)
				MeasureRun("", nil, "CheerMusicians")
			end
		
			local AnimTime
			local AnimType = Rand(3)
			PlaySound3DVariation("","Locations/tavern_people",1)
			local WhatToBuy = "drink"
			if Rand(3) > 0 then
				AnimTime = PlayAnimationNoWait("","sit_drink")
				Sleep(1)
				CarryObject("","Handheld_Device/ANIM_beaker_sit_drink.nif",false)
				Sleep(1)
				PlaySound3DVariation("","CharacterFX/drinking",1)
				Sleep(AnimTime-1.5)
				CarryObject("","",false)
				
				if SimGetGender("")==GL_GENDER_MALE then
					PlaySound3DVariation("","CharacterFX/male_belch",1)
				else
					PlaySound3DVariation("","CharacterFX/female_belch",1)
				end
				Sleep(1.5)
			else
				WhatToBuy = "eat"
				PlayAnimation("","sit_eat")
			end
			
			if AnimType == 0 then
				PlayAnimation("","sit_talk")
			elseif AnimType == 1 then
				AnimTime = PlayAnimationNoWait("", "sit_cheer")
				Sleep(1)
				PlaySound3D("","Locations/tavern/cheers_01.wav",1)
				CarryObject("","Handheld_Device/ANIM_beaker_sit_drink.nif", false)
				Sleep(1)
				PlaySound3DVariation("", "CharacterFX/drinking", 1)
				Sleep(AnimTime-1.5)
				CarryObject("", "", false)
				Sleep(1.5)
			else
				PlayAnimationNoWait("", "sit_laugh")
				Sleep(2)
				if Rand(2)==0 then
					PlaySound3D("","Locations/tavern/laugh_01.wav",1)
				else
					PlaySound3D("","Locations/tavern/laugh_02.wav",1)
				end
				Sleep(5)	
			end
			
	--		if SimGetNeed("", 8) > 0.3 or  SimGetNeed("", 1) > 0.3 then
			local NumItems = 1
			if HasProperty("Destination","DanceShow") then
				NumItems = 2
			end
				
			local Items, needo
			if WhatToBuy == "drink" then
				Items = { "SmallBeer", "WheatBeer" }
				needo = 8
			else
				Items = { "GrainPap", "RoastBeef" }
				needo = 1
			end
				
			local Choice = Items[Rand(2)+1]	
			local ItemCount, TotalPrice = economy_BuyItems("Destination", "", Choice, NumItems, true)
			if ItemCount > 0 then
				--SatisfyNeed("", needo, 0.3)
				if HasProperty("Destination","ServiceActive") then
					local TavernLevel = BuildingGetLevel("Destination")
					local TavernAttractivity = GetImpactValue("Destination", "Attractivity")
					local Tip = math.floor(TavernLevel * (5 + (Rand(20)+1) * (TavernAttractivity + basicvalue)))
					chr_CreditMoney("Destination", Tip, "WaresSold")
					economy_UpdateBalance("Destination", "Service", Tip)
				end
			else
				local Tip = 3 * chr_GetRank("") + 1
				chr_CreditMoney("Destination", Tip, "WaresSold")
				economy_UpdateBalance("Destination", "Service", Tip)
			end

			verweile = verweile - 1
		end
		f_EndUseLocator("","SitPos",GL_STANCE_STAND)

		Hour = math.mod(GetGametime(), 24)
		if Hour > 21 or Hour < 4 then
			if Rand(100) > 80 then
				--LoopAnimation("","idle_drunk",10)
				AddImpact("","totallydrunk",1,6)
				AddImpact("","MoveSpeed",0.7,6)
				SetState("",STATE_TOTALLYDRUNK,true)
				StopMeasure()
			end
		end
	end
end

-- -----------------------
-- UseCocotte
-- -----------------------
function UseCocotte()

	MsgDebugMeasure("Search a cocotte to fullfill your need")
	-- leave current building
	if GetInsideBuilding("", "Inside") then
		f_ExitCurrentBuilding("")
	end
	-- search cocotte in range
	
	local CocottsCnt = Find("","__F((Object.GetObjectsByRadius(Sim)==20000) AND (Object.GetProfession() == 30) AND (Object.Property.CocotteProvidesLove == 1) AND (Object.Property.CocotteHasClient == 0) AND (Object.HasDifferentSex()))","Cocotte", -1)
	if(CocottsCnt == 0) then
		Sleep(Rand(10)+5)
		return false
	end

	-- go to random cocotte
	ChangeAlias("Cocotte"..Rand(CocottsCnt),"Target")
	if AliasExists("Target") then
		MeasureCreate("UseLaborOfLove")
		MeasureStart("UseLaborOfLove", "", "Target", "UseLaborOfLove", true)
		return
	end
end

-- -----------------------
-- KissMeHonza
-- -----------------------
function KissMeHonza()
	if HasProperty("","KissMeHoney") then
		local Musician = GetProperty("","KissMeHoney")
		if GetAliasByID(Musician,"Musician") then
			if not HasProperty("Musician","Moving") and not HasProperty("Musician","KissMe") and (GetDistance("","Musician")<6001) then
				SetProperty("Musician","KissMe",GetID(""))

				if f_MoveTo("", "Musician", GL_MOVESPEED_RUN, 500) then
					if not HasProperty("Musician","Moving") and not HasProperty("Musician","MusicStage") then
						
						while true do
							if not HasProperty("Musician","KissMe") or HasProperty("Musician","Moving") or HasProperty("Musician","MusicStage") then
								RemoveProperty("", "KissMeHoney")
								SatisfyNeed("", 2, 0.2)
								IncrementXP("", 15)
								break
							end
							if Rand(100)<5 then
								local AnimTime = PlayAnimationNoWait("","giggle")
								Sleep(1)
								MsgSay("",GetName("Musician"))
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
end

-- -----------------------
-- RepairHome
-- -----------------------
function RepairHome(Building)
	if not AliasExists(Building) then
		return
	end

	MsgDebugMeasure("Buying Buildmaterial at the Market")
	if not GetSettlement("", "City") then
		return
	end
	local Market = Rand(5)+1
	if not CityGetRandomBuilding("City", 5, GL_BUILDING_TYPE_MARKET, Market, -1, FILTER_IGNORE, "Destination") then
		return
	end
	if not f_MoveTo("","Destination",GL_MOVESPEED_RUN, 200) then
		return
	end
	GetOutdoorMovePosition("",Building,"WorkPos2")
	if not GetInsideBuilding("", "Inside") or GetID("Inside")~=GetID(Building) then
		-- buy some material at market		
		if Rand(100)<50 then
			f_Transfer("","",INVENTORY_STD,"Destination",INVENTORY_STD,"BuildMaterial",1)
		else
			f_Transfer("","",INVENTORY_STD,"Destination",INVENTORY_STD,"Tool",1)
		end
		
		MoveSetActivity("","carry")
		Sleep(2)
		CarryObject("","Handheld_Device/ANIM_holzscheite.nif",false)

		if not f_MoveTo("", "WorkPos2",GL_MOVESPEED_RUN, 200) then
			return
		end
		MoveSetActivity("")
		Sleep(2)
		CarryObject("","",false)
	end
	MsgDebugMeasure("Repairing My Home")
	if not GetFreeLocatorByName(Building,"bomb",1,3,"WorkPos",true) then
		return
	end
	
	if not f_BeginUseLocator("","WorkPos",GL_STANCE_STAND,true) then
		if not f_MoveTo("","WorkPos2") then
			return
		end
	end
	AlignTo("",Building)
	Sleep(0.7)
	SetContext("","rangerhut")
	CarryObject("","Handheld_Device/Anim_Hammer.nif", false)
	PlayAnimation("","chop_in")
	local RepairPerTick = GetMaxHP(Building)/400
	for i=0,20 do
		PlayAnimation("","chop_loop")
		ModifyHP(Building,RepairPerTick,false)
	end
	f_EndUseLocator("","WorkPos",GL_STANCE_STAND)
	PlayAnimation("","chop_out")
	CarryObject("","",false)
		
	
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
			if GetSettlement("WorkingPlace", "City") and chr_CityFindCrowdedPlace("City", MyrmAlias, "GatherDestination") then
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
	    {"Influenza",2},
	    {"Pox",2},
	    {"Pneumonia",2},
	    {"BurnWound",3},
	    {"Blackdeath",3},
	    {"Caries",3},
	    {"Fracture",3},
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
				Sleep(Rand(10)+1*5)
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
-- ChangeReligion
-- -----------------------
function ChangeReligion(FinalReligion)
	MsgDebugMeasure("Changing my religion")
	if not AliasExists("MyCity") then
		AddImpact("","WasInChurch",1,4)
		return
	end
	local ChurchType = 19
	if FinalReligion == RELIGION_CATHOLIC then
		ChurchType = 20
	end
	if not CityGetRandomBuilding("MyCity",-1,ChurchType,2,-1,FILTER_IGNORE,"Church") then
		AddImpact("","WasInChurch",1,4)
		return
	end
	if not f_MoveTo("", "Church", GL_MOVESPEED_RUN) then
		AddImpact("", "WasInChurch", 1, 4)
		return
	end
	MeasureRun("","Church","ChangeFaith",true)
	return
	
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
			SatisfyNeed("", 8, 0.5)
			SatisfyNeed("", 2, 0.5)
			return
		end

		if Rand(5)==0 then
			if HasProperty("Destination","Versengold") then
				MeasureRun("", nil, "CheerMusicians")
			else
				idlelib_KissMeHonza()
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
				chr_CreditMoney("Destination",grundBetrag,"Offering")
				economy_UpdateBalance("Destination", "Service", grundBetrag)
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
				chr_CreditMoney("Destination",grundBetrag,"Offering")
				economy_UpdateBalance("Destination", "Service", grundBetrag)
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
			SatisfyNeed("", 8, 0.1)
			
			local NumItems = Rand(2)+1
			if HasProperty("Destination", "DanceShow") then
				NumItems = Rand(3)+2
			end

			local	Items = { "SmallBeer", "WheatBeer", "PiratenGrog", "Schadelbrand" }
			local Choice = Items[Rand(4)+1]	
			
			local ItemId = ItemGetID(Choice)
			local ItemCount, TotalPrice = economy_BuyItems("Destination", "", ItemId, NumItems)
			
			if ItemCount and ItemCount > 0 then
				if HasProperty("Destination","ServiceActive") then
					local TavernLevel = BuildingGetLevel("Destination")
					local TavernAttractivity = GetImpactValue("Destination", "Attractivity")	

					local Tip = math.floor(TavernLevel * (10 + (Rand(20)+1) * (TavernAttractivity + basicvalue)))
					chr_CreditMoney("Destination",Tip,"tip")
					economy_UpdateBalance("Destination", "Service", Tip)
				end
			end
			verweile = verweile - 1
		end
		if lokalPos == 0 then
		    f_EndUseLocator("","SitPos",GL_STANCE_STAND)
		else
		    f_EndUseLocator("","StandPos",GL_STANCE_STAND)
		end
		
		Hour = math.mod(GetGametime(), 24)
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

	MsgDebugMeasure("Go to the bank and take a credit")

	if not GetSettlement("", "City") then
		return
	end

	local NumBankhouses = CityGetBuildings("City", 2, 43, -1, -1, FILTER_HAS_DYNASTY, "Bank")

	if NumBankhouses > 0 then
		for i = 0, NumBankhouses - 1 do
			local Attractivity = GetImpactValue("Bank"..i, "Attractivity")
			if HasProperty("Bank"..i, "OfferCreditNow") then
				Attractivity = Attractivity + 0.25
				CopyAlias("Bank"..i, "Destination")
			end
		end
	end

	if not AliasExists("Destination") then
		SatisfyNeed("", 9, 1)
		return
	end
	
	if not BuildingGetOwner("Destination", "MyBoss") then
		return
	end

	if AliasExists("Destination") then
		GetLocatorByName("Destination", "exit1", "MoveTo")

		if not f_MoveTo("","MoveTo") then
			return
		end
		
		if not GetFreeLocatorByName("Destination", "wait", 1, 2, "SitPos") then
			Sleep(1)
			idlelib_GoToRandomPosition()
			return
		end
		
		if AliasExists("SitPos") then
			if (LocatorGetBlocker("SitPos") ~= GetID("")) then
				if GetFreeLocatorByName("Destination", "wait", 1, 2, "SitPos") then
					f_BeginUseLocator("", "SitPos", GL_STANCE_SIT, true)
				end
			end
		else
			if GetFreeLocatorByName("Destination", "wait", 1, 2, "SitPos") then
				f_BeginUseLocator("", "SitPos", GL_STANCE_SIT, true)
			else
				Sleep(1)
				return
			end
		end
		
		SetProperty("", "WaitForCredit", 1)
		local WaitTime = GetGametime() + 3
		while GetGametime() < WaitTime do
			Sleep(5)
		end
			
		f_EndUseLocator("", "SitPos", GL_STANCE_STAND)
			
		if HasProperty("", "WaitForCredit") then
			RemoveProperty("", "WaitForCredit")
		end
		
		f_ExitCurrentBuilding("")
	end

	-- idlelib_BuySomeCoin()
	Sleep(2)
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
				chr_CreditMoney("Destination",bankkonto,"tip")
				economy_UpdateBalance("Destination", "Service", bankkonto)
			else
				local bankkonto = GetProperty("Destination","KreditKonto") + schuld
				SetProperty("Destination","KreditKonto",bankkonto)
				chr_CreditMoney("Destination",ecost,"tip")
				economy_UpdateBalance("Destination", "Service", ecost)
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
			    local tip = Rand(90)+10
					chr_CreditMoney("Destination",tip,"tip")
					economy_UpdateBalance("Destination", "Service", tip)
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
		if economy_GetRandomBuildingByRanking("City", "Destination", 0, GL_BUILDING_TYPE_DIVEHOUSE) then
			if f_MoveTo("","Destination") then
			    if not GetFreeLocatorByName("Destination","DiceCEO",-1,-1,"StandPos") then
				    f_Stroll("",300,10)
				    return
			    end
			  	if not f_BeginUseLocator("Owner","StandPos",GL_STANCE_STAND,true) then
						return
					else
				    Sleep(1)
			      PlaySound3D("","measures/shake_dices/shake_dices+0.wav", 1.0)
			      local wfallen = PlayAnimationNoWait("","manipulate_middle_low_r")
			      Sleep(wfallen-1)
			      PlaySound3D("","measures/throw_dices/throw_dices+0.wav", 1.0)
			    local tip = Rand(20) + 5
					chr_CreditMoney("Destination",tip,"tip")
					economy_UpdateBalance("Destination", "Service", tip)
					
					local newwinner = GetName("")
					local bonus
					if HasProperty("Destination","BestDicePlayer") then
						local altpoint = GetProperty("Destination","BestDicePott")
						bonus = { 2, 5, 10 }
						local neuPott = altpoint + ((altpoint / 100) * bonus[Rand(3)+1])
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
end

-- -----------------------
-- LeibwacheIdle
-- -----------------------
function LeibwacheIdle(Workbuilding)
	SimGetWorkingPlace("", "WorkingPlace")
	while true do
	  if Rand(2) == 0 then
	    if GetFreeLocatorByName("WorkingPlace", "GuardPos",1,4, "WachPos") then
		    if not f_BeginUseLocator("", "WachPos", GL_STANCE_STAND, true) then
			    RemoveAlias("WachPos")
			  	return
		    end
			    if Rand(2) == 0 then
					Sleep(10) 
			    else
					PlayAnimationNoWait("","sentinel_idle")
			    end
			else
				f_Stroll("",300,10)
			end
		else
	    if GetFreeLocatorByName("WorkingPlace", "Walledge",1,4, "WachPos") then
		  	if not f_BeginUseLocator("", "WachPos", GL_STANCE_STAND, true) then
			  	RemoveAlias("WachPos")
			    return
		    end
			local WhatToDo2 = Rand(3)
			if WhatToDo2 == 0 then
				Sleep(10) 
			elseif WhatToDo2 == 1 then
				PlayAnimationNoWait("","sentinel_idle")
			else
				CarryObject("","",false)
			    CarryObject("","Handheld_Device/ANIM_telescope.nif",false)
			    PlayAnimation("","scout_object")
			    CarryObject("","",false)					
			end
		else
			f_Stroll("",300,10)
		end
    end
    Sleep(3)
	f_EndUseLocator("", "WachPos", GL_STANCE_STAND)
	end

end

-- -----------------------
-- DinnerAtEstate
-- -----------------------
function DinnerAtEstate()

	if DynastyGetRandomBuilding("",8,111,"Schlossie") then
	  if not GetState("Schlossie",STATE_BURNING) and not GetState("Schlossie",STATE_FIGHTING) then
	    if f_MoveTo("","Schlossie") then
        if GetFreeLocatorByName("Schlossie", "Sit",2,12, "DoDinner") then
          if not f_BeginUseLocator("", "DoDinner", GL_STANCE_SIT, true) then
            RemoveAlias("DoDinner")
            return
          end
					local duration = Rand(2)+1
          local CurrentTime = GetGametime()
          local EndTime = CurrentTime + duration
					local AnimTime, dinner
          local CurrentHP = GetHP("")
          local MaxHP = GetMaxHP("")
          local ToHeal = MaxHP - CurrentHP
          local HealPerTic = ToHeal / (duration * 12)	
					while GetGametime()<EndTime do
					  dinner = Rand(4)
						if dinner == 0 then
		          AnimTime = PlayAnimationNoWait("","sit_drink")
		          Sleep(1)
		          CarryObject("","Handheld_Device/ANIM_beaker_sit_drink.nif",false)
		          Sleep(1)
		          PlaySound3DVariation("","CharacterFX/drinking",1)
		          Sleep(AnimTime-1.5)
		          CarryObject("","",false)
		          if SimGetGender("")==GL_GENDER_MALE then
		            PlaySound3DVariation("","CharacterFX/male_belch",1)
		          else
		            PlaySound3DVariation("","CharacterFX/female_belch",1)
		          end
		          SatisfyNeed("", 8, 0.2)
		          Sleep(1.5)
			      elseif dinner == 1 then
							if Rand(2) == 0 then
		            PlayAnimation("","sit_eat")
		            SatisfyNeed("", 1, 0.2)
							else
						    PlayAnimation("","sit_talk")
							end
	          elseif dinner == 2 then			
	            AnimTime = PlayAnimationNoWait("","sit_cheer")
	            Sleep(1)
	            PlaySound3D("","Locations/tavern/cheers_01.wav",1)
	            CarryObject("","Handheld_Device/ANIM_beaker_sit_drink.nif",false)
	            Sleep(1)
	            PlaySound3DVariation("","CharacterFX/drinking",1)
	            Sleep(AnimTime-1.5)
	            CarryObject("","",false)
	            Sleep(1.5)
	          else
	            PlayAnimationNoWait("","sit_laugh")
	            Sleep(2)
	            if Rand(2)==0 then
		            PlaySound3D("","Locations/tavern/laugh_01.wav",1)
	            else
		            PlaySound3D("","Locations/tavern/laugh_02.wav",1)
	            end
	            Sleep(5)					
				    end
						
					  if GetHP("") < MaxHP then
				    	ModifyHP("", HealPerTic,false)
		        end
					end
					f_EndUseLocator("", "DoDinner", GL_STANCE_STAND)
		    end
		  end
		end
	end
	Sleep(2)

end

function CheckBank()
-- ******** THANKS TO KINVER ********
	if not HasProperty("","SchuldenGeb") then
		return idlelib_TakeACredit()
	else
		return idlelib_ReturnACredit()
	end
end

function BuySomeCoin(SplitNumber)
	local bankID=GetID("CurrentBuilding")
	GetAliasByID(bankID,"Destination")
	if BuildingGetOwner("Destination","Glaubiger") then
		local zinsA = GetSkillValue("Glaubiger",BARGAINING)
		local percent = 50 + (zinsA * 3)
		if Rand(100) < percent then
			local Items = { "Goldlowmed", "Goldmedhigh", "Goldveryhigh" }
			local Choice
			local schuldner = SimGetRank("")
			local lrand = Rand(100)
			if schuldner <= 1 then
				Choice=1
			elseif schuldner == 2 then
				if lrand > 75 then
					Choice=2
				else
					Choice=1
				end
			elseif schuldner == 3 then
				if lrand > 85 then
					Choice=3
				elseif lrand > 30 and lrand < 84 then
					Choice=2
				else
					Choice=1
				end
			elseif schuldner == 4 then
				if lrand > 85 then
					Choice=2
				elseif  lrand > 30 and lrand < 84 then
					Choice=3
				else
					Choice=1
				end
			else
				if lrand > 25 then
					Choice=3
				else
					Choice=2
				end
			end
			Choice=Items[Choice]
			local ItemCount, TotalPrice = economy_BuyItems("Destination", "", Choice, 1)
			if ItemCount > 0 then
				CarryObject("Destination","Handheld_Device/ANIM_Smallsack.nif",false)
				local playTime = PlayAnimationNoWait("","use_object_standing")
				local prodNam = ItemGetLabel(Choice,true)
				if Rand(2) == 0 then
					MsgSay("","@L_HPFZ_IDLELIB_GETGOOD_SPRUCH_+0",prodNam)
				else
					MsgSayNoWait("","@L_HPFZ_IDLELIB_GETGOOD_SPRUCH_+1",prodNam)
				end
				PlaySound3D("","Effects/coins_to_moneybag+0.wav", 1.0)
	
				if BuildingGetOwner("Destination","Glaubiger") then
					chr_ModifyFavor("","Glaubiger",GL_FAVOR_MOD_TINY)					
				end
				
				Sleep(playTime-1)
			else
				if SplitNumber then
					return "c"
				else
					if BuildingGetOwner("Destination","Glaubiger") then
						chr_ModifyFavor("","Glaubiger",-GL_FAVOR_MOD_TINY)					
					end
					
					SetProperty("", "IgnoreBank", "Destination")
					SetProperty("", "IgnoreBankTime", GetGametime()+36)
				end
			end
		end
	end

	SatisfyNeed("", 9, 1)
end

-- -----------------------
-- GoSleep
-- -----------------------
function GoSleep()

	local MinMoney = 1500  --enough money for tavern?
	local GoToTavern = 5  --5% chance to go to tavern just for fun
	local Chance = Rand(100) + 1
	
	if Chance <= GoToTavern and GetMoney("") >= MinMoney then
		GetNearestSettlement("", "City")
		economy_GetRandomBuildingByRanking("City", "DestTavern", 0, GL_BUILDING_TYPE_TAVERN)
		
		-- Don't move there if it is too far
		if not AliasExists("DestTavern") or GetDistance("", "DestTavern") > 10000 then
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
