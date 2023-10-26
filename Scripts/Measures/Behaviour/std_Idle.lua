function Run()
	
	-- **********************
	-- **  PREPARATIONS **
	-- **********************
	chr_CheckHome("") -- make sure we have a home
	
	local Sickness = GetImpactValue("", "Sickness")
	if Sickness < 1 then
		MoveSetActivity("") -- cleanup moveset
	end
	
	if GetState("", STATE_WORKING) then -- some workers have special behavior when they are idle
		std_idle_Worker()
		return
	end
	
	local DoNothing = Rand(20) + 1 -- Do nothing for a while
	if SimGetClass("") == 0 then 
		DoNothing = DoNothing * 4
	end
	Sleep(DoNothing)
	
	-- random diseases
	GetSettlement("", "City")
	local CityLevel = CityGetLevel("City")
	local SicknessChance = Rand(100)
	local Season = GetSeason()
	if season == EN_SEASON_AUTUMN or EN_SEASON_WINTER then
		SicknessChance = Rand(50)
	end
	
	if CityLevel > 4 then
		if SicknessChance == 1 then
			Disease.Cold:infectSim("")
		elseif SicknessChance == 2 then
			Disease.Sprain:infectSim("")	
		elseif SicknessChance == 6 then
			Disease.Fracture:infectSim("")
		elseif SicknessChance == 7 then
			Disease.Influenza:infectSim("")
		end
	elseif CityLevel > 2 then
		if SicknessChance < 6 then
			Disease.Cold:infectSim("")
		elseif SicknessChance < 9 then
			Disease.Sprain:infectSim("")
		elseif SicknessChance < 11 then
			Disease.Influenza:infectSim("")
		end
	else
		if SicknessChance < 10 then
			Disease.Cold:infectSim("")
		elseif SicknessChance < 15 then
			Disease.Sprain:infectSim("")
		end
	end
	
	
	-- *********************
	-- ** CHOOSE NEED **
	-- *********************
	
	local NeedList = { "Health", "Entertainment", "Food", "Religion", "Luxury", "Clothes", "Protection", "Money" }
	local NeedSum = 8
	local Random = Rand(8) + 1
	local CheckNeed
	
	for i=1, NeedSum do
		CheckNeed = NeedList[Random]
		if std_idle_CheckNeed(NeedList[CheckNeed]) then
			std_idle_ChooseNeed(NeedList[CheckNeed])
			break
		else
			Random = Random + 1
			if Random > NeedSum then
				Random = 1
			end
		end
	end
end

function Worker()
	
	local AtPlace = SimGetAssignedAreaID("") == SimGetWorkingPlaceID("")
	local IsManageEmployee = GetProperty("", "TWP_ManageEmployee") or 0
	local MyProfession = SimGetProfession("")
	
	if HasProperty("", "StartWorkingTime") then -- check once per day
		RemoveProperty("", "StartWorkingTime")
		
		if SimGetWorkingPlace("", "WorkingPlace") then
			f_MoveTo("", "WorkingPlace", GL_MOVESPEED_RUN)
		end
		
		-- RandomIllness (default: 1%)
		local Rand = Rand(100)
		if Rand == 1 then
			Disease.Sprain:infectSim("")
		elseif Rand == 2 then
			Disease.Cold:infectSim("")
		end

		if (GetImpactValue("","Sickness") > 0 or GetHP("") < GetMaxHP("") / 4) then
			if gameplayformulas_CheckMoneyForTreatment("") == 1 then
				if ReadyToRepeat("", "ai_VisitDoc") and chr_NeedsTreatment("") then
					idlelib_VisitDoc()
				end
			end

		end
		
		return
	end
	
	if SimGetWorkingPlace("", "WorkingPlace") then
		if AtPlace or BuildingGetAISetting("WorkingPlace", "Enable") > 0 or IsManageEmployee > 0 then
			if MyProfession == GL_PROFESSION_THIEF then
				idlelib_ThiefIdle("WorkingPlace")
				return
			elseif MyProfession == GL_PROFESSION_ROBBER then
				idlelib_RobberIdle("WorkingPlace")
				return
			elseif MyProfession == GL_PROFESSION_COCOTTE then
				idlelib_CocotteIdle("")
				return
			elseif MyProfession == GL_PROFESSION_MYRMIDON then
				idlelib_MyrmidonIdle("")
				return
			elseif MyProfession == GL_PROFESSION_PRIVATEGUARD then
				idlelib_LeibwacheIdle("WorkingPlace")
				return
			elseif MyProfession == GL_PROFESSION_MERCENARY then
				idlelib_LeibwacheIdle("WorkingPlace")
				return
			end	
		end
	end
	
	Sleep(90)
	return
end

function CheckNeed(Need)

	if Need == "Health" then
		if chr_NeedsTreatment("") then
			return true
		else
			return false
		end
	elseif Need == "Entertainment" then
		return true
	elseif Need == "Food" then
		if GetBudget("", 1) and ReadyToRepeat("", "Need_"..Need) then
			return true
		else
			return false
		end
	elseif Need == "Religion" then
		if ReadyToRepeat("", "Need_"..Need) then
			return true
		else
			return false
		end
	elseif Need == "Luxury" then
		if GetBudget("", 2) and ReadyToRepeat("", "Need_"..Need) then
			return true
		else
			return false
		end
	elseif Need == "Clothes" then
		if GetBudget("", 1) and ReadyToRepeat("", "Need_"..Need) then
			return true
		else
			return false
		end
	elseif Need == "Protection" then
		if GetBudget("", 2) and ReadyToRepeat("", "Need_"..Need) then
			return true
		else
			return false
		end
	elseif Need == "Money" then
		if ReadyToRepeat("", "Need_"..Need) then
			return true
		else
			return false
		end
	else
		return false
	end
end

function ChooseNeed(Need)

	-- get important data
	local DayTime = gameplayformulas_GetDayTime() -- returns "MORNING", "DAY", "EVENING", "NIGHT" in 6h intervalls
	local Season = GetSeason()
	local ActiveWeather = idlelib_CheckWeather()
	
	local SimClass = SimGetClass("")
	if SimClass == 0 then -- unemployed
		if HasProperty("", "FakeClass") then
			SimClass = GetProperty("", "FakeClass")
		else
			SimClass = Rand(4) + 1
			SetProperty("", "FakeClass", SimClass)
		end
	end

	if Need == "Health" then
		if gameplayformulas_CheckMoneyForTreatment("") == 1 then
			if ReadyToRepeat("", "ai_VisitDoc") then
				idlelib_VisitDoc()
				return
			else
				idlelib_Illness()
				return
			end
		end
	elseif Need == "Entertainment" then
		local Choices = { "DoNothing" }
		local ChoicesCount = 1
		
		if not IsDynastySim("") then
			if ActiveWeather and DayTime ~= "NIGHT" then
				ChoicesCount = ChoicesCount + 1
				Choices[ChoicesCount] = "GoToRandomPosition"
			end
			
			if ActiveWeather and DayTime ~= "NIGHT" and DayTime ~= "EVENING" then
				ChoicesCount = ChoicesCount + 1
				Choices[ChoicesCount] = "GetCorn"
			end
		end
				
				
		
		
	elseif Need == "Food" then
		SetRepeatTimer("", "Need_"..Need, 2)
	elseif Need == "Religion" then
		SetRepeatTimer("", "Need_"..Need, 6)
	elseif Need == "Luxury" then
		SetRepeatTimer("", "Need_"..Need, 4)
	elseif Need == "Clothes" then
		SetRepeatTimer("", "Need_"..Need, 6)
	elseif Need == "Protection" then
		SetRepeatTimer("", "Need_"..Need, 6)
	elseif Need == "Money" then
		SetRepeatTimer("", "Need_"..Need, 6)
	else
		return false
	end
end
	
	--idlelib_CheckBank()
	


				-- *******************************************
				--
				-- satisfy need sleep
				--
				-- *******************************************
				
	
			-- *******************************************
			--
			-- satisfy need religion
			--
			-- *******************************************
--			if Rand(50) >= 40 then
--      	idlelib_Graveyard()
--				return
--			else
--		    if SimGetProfession("")~=GL_PROFESSION_PRIEST then
--			    if SimGetChurch("", "church") then
--						if BuildingGetOwner("church","churchowner") then
--					    MeasureRun("", "church", "AttendMass")
--					    return
--						end
--					end
--			  end
--			end
--		end
				-- *******************************************
				--
				-- satisfy need drinking
				--
				-- *******************************************
     --   if SimGetClass("") == 4 then
	--				idlelib_GoToDivehouse()
        --else
				
          --	idlelib_GoToTavern()
	      
				-- *******************************************
				--
				-- satisfy need pleasure
				--
		
			-- *******************************************
			--
			-- satisfy need eat
			--
			-- *******************************************
			
			  	--idlelib_BuySomethingAtTheMarket(1)
					--MoveSetActivity("")
					--CarryObject("","",false)
			--  else
			  --	idlelib_CheckInsideStore()
			--	end
			
			-- *******************************************
			--
			-- satisfy need konsum
			--
			-- *******************************************
			
			  	--idlelib_BuySomethingAtTheMarket(2)
					
		
	
			-- *******************************************
			--
			-- satisfy need talk
			--
			-- *******************************************
			
			
		--	local TalkPartners = Find("", "__F((Object.GetObjectsByRadius(Sim)==1000)AND NOT(Object.GetStateImpact(no_idle))AND(Object.CanBeInterrupted(Babble)))","TalkPartner", -1)
		--	if TalkPartners>0 then
		--		MeasureRun("", "TalkPartner"..Rand(TalkPartners), "Babble" )
		--		return
		--	end
			
	--	GetSettlement("","City")
	--	local CityLevel = CityGetLevel("City")
	--	local SicknessChance = Rand(100)
	--	local Season = GetSeason()
	--	if season == EN_SEASON_AUTUMN or EN_SEASON_WINTER then
	--		SicknessChance = Rand(50)
	--	end
	--	if CityLevel > 4 then
	--		if SicknessChance == 1 then
	--			Disease.Cold:infectSim("")
	--		elseif SicknessChance == 2 then
	--			Disease.Sprain:infectSim("")
	--		elseif SicknessChance == 6 then
	--			Disease.Fracture:infectSim("")
	--		elseif SicknessChance == 7 then
	--			Disease.Influenza:infectSim("")
	--		end
	--	elseif CityLevel > 2 then
	--		if SicknessChance < 6 then
	--			Disease.Cold:infectSim("")
	--		elseif SicknessChance < 9 then
	--			Disease.Sprain:infectSim("")
	--		elseif SicknessChance < 11 then
	--			Disease.Influenza:infectSim("")
	--		end
	--	else
	--		if SicknessChance < 10 then
	--			Disease.Cold:infectSim("")
	--		elseif SicknessChance < 15 then
	--			Disease.Sprain:infectSim("")
	--		end
	--	end
		
		--
		--				idlelib_GoToRandomPosition()
					
		--			idlelib_SitDown()
		--		elseif WhatToDo > 0 then
		--			idlelib_DoNothing()
		--		end
		--	else
			
		--		if WhatToDo == 99 then
		--			if GetHPRelative("")>0.3 then
		--				local FightPartners = Find("", "__F((Object.GetObjectsByRadius(Sim)==2000)AND(Object.CompareHP()>30)AND(Object.CheckCutscene())AND(Object.MinAge(16))AND NOT(Object.HasDynasty())AND NOT(Object.GetState(npc))AND NOT(Object.GetState(animal))", "FightPartner", -1)
		--				if FightPartners>0 then
		--					idlelib_ForceAFight("FightPartner")
		--					return
		--				end
		--			end
		--		elseif WhatToDo > 85 and not HasProperty("","SchuldenGeb") then
		--			idlelib_TakeACredit()
		--		elseif WhatToDo > 85 and HasProperty("", "SchuldenGeb") then
		--			idlelib_ReturnACredit()
		
				
			--		idlelib_GetCorn()
			
			--		idlelib_CollectWater()
	
end



-- -----------------------
-- CleanUp
-- -----------------------
function CleanUp()
	StopAction("brawl", "")
	ReleaseLocator("")
	StopAnimation("")
	MoveSetStance("", GL_STANCE_STAND)
	CarryObject("", "", true)
	CarryObject("", "", false)
	
	if AliasExists("SitPos") then
		f_EndUseLocator("","SitPos", GL_STANCE_STAND)
	end
	
	if GetState("", STATE_SLEEPING) then
		SetState("", STATE_SLEEPING, false)
	end
	
	if GetImpactValue("", "Sickness") == 0 then
		MoveSetActivity("")
	end
	
	if HasProperty("","WaitingForTreatment") then
		RemoveProperty("", "WaitingForTreatment")
	end
	
	if AliasExists("SleepPosition") then
		f_EndUseLocatorNoWait("", "SleepPosition", GL_STANCE_STAND)
		RemoveAlias("SleepPosition")
	end
	
	if AliasExists("ChairPos") then
		f_EndUseLocatorNoWait("", "ChairPos", GL_STANCE_STAND)
		RemoveAlias("ChairPos")
	end
	
	if HasProperty("","ProTCBank") then
		RemoveProperty("","ProTCBank")
	end
	
	if HasProperty("","ProRCBank") then
		RemoveProperty("","ProRCBank")
	end
	
	if HasProperty("", "KissMeHoney") then
		RemoveProperty("", "KissMeHoney")
	end
end

