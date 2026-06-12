function Run()
	
	-- injured player-controlled sims seek treatment first (Library/cu_autoheal.lua)
	if cu_autoheal_Process("") then
		return
	end

	-- dynasty chars have their own behaviour
	if IsDynastySim("") and GetDynastyID("") > 0 then
		MeasureRun("", nil, "DynastyIdle")
		return
	end

	chr_CheckHome("") -- make sure we have a home
	
	-- cleanup properties etc
	if HasProperty("", "Berserker") then
		RemoveProperty("", "Berserker")   
	end
	
	-- cleanup moveset
	local Sickness = GetImpactValue("", "Sickness")
	if Sickness < 1 then
		MoveSetActivity("")
	end
	
	-- no children allowed
	if SimGetAge("") < 16 then
		return
	end	
	
	-- some workers have special behavior when they are idle
	if GetState("", STATE_WORKING) then
		std_idle_Worker()
		return
	end
	
	-- Do nothing once in a while
	local DoNothing = GetProperty("", "_DO_NOTHING_TIME") or 0
	if DoNothing > 0 then
		RemoveProperty("", "_DO_NOTHING_TIME")
		DoNothing = Gametime2Realtime(DoNothing)
		Sleep(DoNothing)
	end 
	
	-- Check activity or go home and do nothing for some time
	local Activity = idlelib_GetActivity()
	local ActiveMovement = false
	if Activity > Rand(100) then
		ActiveMovement = true
	else
		SetProperty("", "_DO_NOTHING_TIME", 3)
	end
	
	if not ActiveMovement then
		-- random infection
		std_idle_RandomInfection()
		if GetHomeBuilding("", "HomeBuilding") and GetDistance("", "HomeBuilding") > 1000 then
			idlelib_GoHome()
			return
		else
			return
		end
	end
	
	--if (SimGetGender("") == GL_GENDER_FEMALE) then
	--	idlelib_KissMeHonza()
	--end
	
	-- check for treatment need
	if chr_NeedsTreatment("") then
		if gameplayformulas_CheckMoneyForTreatment("") == 1 then
			if ReadyToRepeat("", "ai_VisitDoc") then
				idlelib_VisitDoc()
			end
		end
	end
	
	-- check again. If still true, go to the market
	if chr_NeedsTreatment("") then
		idlelib_Illness()
		SetProperty("", "_DO_NOTHING_TIME", 4)
		return
	end
	
	-- WIP
	
	if GetSettlement("","MyCity") then
		if HasProperty("MyCity","InquisitionOnTheRun") then
			if (GetImpactValue("","WasInChurch")~=1) then
				local MyReligion = SimGetReligion("")
				local InquisitionReligion = GetProperty("MyCity","InquisitionOnTheRun")
				if InquisitionReligion ~= MyReligion then
					idlelib_ChangeReligion(InquisitionReligion)
				end
			end
		end
	end

	if ActiveMovement then
		local checkBOK = false
		if HasProperty("", "TimeBank") then
			local gtime = GetProperty("", "TimeBank")
			if gtime < GetGametime() then
				checkBOK = true
			end
		else
			checkBOK = true
		end

		local Fneed = SimGetNeed("", 9)
		if (Fneed > 1) and (checkBOK) then
			idlelib_CheckBank()
			return			
		end
	end

	if GetHomeBuilding("","HomeBuilding") then
		if BuildingHasIndoor("HomeBuilding") and SimIsCourting("")==false then

			local offset 	= math.mod(GetID("Owner"), 30) * 0.1
			local time 		= math.mod(GetGametime(),24)
			local	StartSleep 	= 22+offset
			local EndSleep 	= 6+offset
		
			if time > StartSleep or time < EndSleep then
				-- *******************************************
				--
				-- satisfy need sleep
				--
				-- *******************************************
				
				--debug
				idlelib_Sleep(23+offset, 7+offset)
				return
			end
		end
	end
	
	if not idlelib_CheckWeather() then
		if not SimIsCourting("") and GetHomeBuilding("", "HomeBuilding") then
			idlelib_GoHome()
			Sleep(Rand(10)+10)
			return
		end
	end
	
	if ActiveMovement then
		if (SimGetGender("")==GL_GENDER_FEMALE) then
			idlelib_KissMeHonza()
		end

		if (SimGetNeed("", 4)>1) and (GetImpactValue("","WasInChurch")~=1) then
	
			-- *******************************************
			--
			-- satisfy need religion
			--
			-- *******************************************
			if Rand(50) >= 40 then
      	idlelib_Graveyard()
				return
			else
		    if SimGetProfession("")~=GL_PROFESSION_PRIEST then
			    if idlelib_GetChurchForMass("church") then
				    MeasureRun("", "church", "AttendMass")
				    return
					end
			  end
			end
		end
		if SimGetAge("")>20 then
			if SimGetNeed("", 8)>1 then
				-- *******************************************
				--
				-- satisfy need drinking
				--
				-- *******************************************
        if SimGetClass("") == 4 then
					idlelib_GoToDivehouse()
        else
					if Rand(3) == 1 then
	        	idlelib_GoToDivehouse()
	        else
          	idlelib_GoToTavern()
	        end
        end
				return
			end
			if SimGetNeed("", 2)>1 then
				-- *******************************************
				--
				-- satisfy need pleasure
				--
				-- *******************************************
				if Rand(2) == 0 then
					if SimGetClass("") == 4 then
            idlelib_GoToDivehouse()
        	else
            if Rand(3) == 1 then
            	idlelib_GoToDivehouse()
          	else
            	idlelib_GoToTavern()
          	end
        	end				
				else
					if SimGetGender("")==GL_GENDER_MALE then
						idlelib_UseCocotte()
					else
						idlelib_KissMeHonza()
					end
				end
				
				return
			end
		end
		
		if SimGetNeed("", 1)>1 then
			-- *******************************************
			--
			-- satisfy need eat
			--
			-- *******************************************
			local time = math.mod(GetGametime(),24)
			if time >= 8 and time <= 18 then
				if Rand(2) == 0 then
			  	idlelib_BuySomethingAtTheMarket(1)
					MoveSetActivity("")
					CarryObject("","",false)
			  else
			  	idlelib_CheckInsideStore()
				end
			else
			  idlelib_BuySomethingAtTheMarket(1)
				MoveSetActivity("")
				CarryObject("","",false)
			end
			return
		end

		if SimGetNeed("", 7)>1 then
			-- *******************************************
			--
			-- satisfy need konsum
			--
			-- *******************************************
			local time = math.mod(GetGametime(),24)
			if time >= 7 and time <= 21 then
				if Rand(6) == 0 then
			  	idlelib_BuySomethingAtTheMarket(2)
					MoveSetActivity("")
					CarryObject("","",false)
			  else
			    idlelib_CheckInsideStore()
				end
			else
			  idlelib_BuySomethingAtTheMarket(2)
				MoveSetActivity("")
				CarryObject("","",false)
			end
			return
		end
		
		if SimGetNeed("", 3)>1 then

			-- ******** THANKS TO KINVER ********
			if HasProperty("","SchuldenGeb") then
				SatisfyNeed("", 9, -0.13)
			else
				SatisfyNeed("", 9, -0.1)
			end
			-- **********************************
	
			-- *******************************************
			--
			-- satisfy need talk
			--
			-- *******************************************
			
			
			local TalkPartners = Find("", "__F((Object.GetObjectsByRadius(Sim)==1000)AND NOT(Object.GetStateImpact(no_idle))AND(Object.CanBeInterrupted(Babble)))","TalkPartner", -1)
			if TalkPartners>0 then
				MeasureRun("", "TalkPartner"..Rand(TalkPartners), "Babble" )
				return
			end
			
		end
	end

	if not IsPartyMember("") then
		if ActiveMovement then
			f_ExitCurrentBuilding("")
			Sleep(Rand(10)+5)
			local toast = Rand(3)
			local WhatToDo = Rand(100)
			if GetImpactValue("","Sickness")>0 then
				if WhatToDo > 90 then
					if toast == 0 then
						idlelib_GoToRandomPosition()
					elseif toast == 1 then
					  idlelib_GoToTavern()
					else
					  idlelib_GoToDivehouse()
					end
				elseif WhatToDo > 60 then
					if SimIsCourting("")==false then
						idlelib_GoHome()
					end
				elseif WhatToDo > 30 then	
					idlelib_SitDown()
				elseif WhatToDo > 0 then
					idlelib_DoNothing()
				end
			else
			
				if WhatToDo == 99 then
					if GetHPRelative("")>0.3 then
						local FightPartners = Find("", "__F((Object.GetObjectsByRadius(Sim)==2000)AND(Object.CompareHP()>30)AND(Object.CheckCutscene())AND(Object.MinAge(16))AND NOT(Object.HasDynasty())AND NOT(Object.GetState(npc))AND NOT(Object.GetState(animal))", "FightPartner", -1)
						if FightPartners>0 then
							idlelib_ForceAFight("FightPartner")
							return
						end
					end
				elseif WhatToDo > 85 and not HasProperty("","SchuldenGeb") then
					idlelib_TakeACredit()
				elseif WhatToDo > 85 and HasProperty("", "SchuldenGeb") then
					idlelib_ReturnACredit()
				elseif WhatToDo > 65 then
					if toast == 0 then
						idlelib_GoToTavern()
					else
						idlelib_GoToDivehouse()
					end
				elseif WhatToDo > 50 then
					if idlelib_GetChurchForMass("church") then
						MeasureRun("", "church", "AttendMass")
					end
				elseif WhatToDo > 35 then
					idlelib_Graveyard()
				elseif WhatToDo > 20 then
					idlelib_CheckInsideStore()
				elseif WhatToDo > 15 then
					idlelib_GoTownhall()
				elseif WhatToDo > 10 then
					idlelib_SitDown()
				elseif WhatToDo > 5 then
					idlelib_GetCorn()
				elseif WhatToDo >= 0 then
					idlelib_CollectWater()
				end
			end
		else
			if GetHomeBuilding("", "HomeBuilding") then
				idlelib_GoHome()
			else
				idlelib_GoToRandomPosition()
			end
		end
	end
	--ChangeAnimation("", "idle")
	
	if AliasExists("") and (SimGetGender("")==GL_GENDER_FEMALE) then
		idlelib_KissMeHonza()
	end

	Sleep(Rand(10)+5)
	
end

function Worker(ActiveMovement)

	if HasProperty("", "StartWorkingTime") then
		RemoveProperty("", "StartWorkingTime")
		local	AtPlace	= SimGetAssignedAreaID("") == SimGetWorkingPlaceID("")
		if SimGetWorkingPlace("", "WorkingPlace") then
			if DynastyIsShadow("") and not ActiveMovement then
				SimBeamMeUp("","WorkingPlace",false)
			else
				f_MoveTo("", "WorkingPlace", GL_MOVESPEED_RUN)
			end
			local Rand = Rand(100)
			if Rand == 1 then
				Disease.Sprain:infectSim("")
			elseif Rand == 2 then
				Disease.Cold:infectSim("")
			end

			if ((GetImpactValue("","Sickness")>0) or (GetHP("") < GetMaxHP("")/4)) then
				if gameplayformulas_CheckMoneyForTreatment("") == 1 then
					if ReadyToRepeat("", "ai_VisitDoc") and chr_NeedsTreatment("") then
						idlelib_VisitDoc()
					end
				end
			end

		end
	end
	
	local	AtPlace	= SimGetAssignedAreaID("") == SimGetWorkingPlaceID("")
	local IsManageEmployee = GetProperty("", "TWP_ManageEmployee") or 0
	if SimGetWorkingPlace("", "WorkingPlace") then
		if AtPlace or BuildingGetAISetting("WorkingPlace", "Enable") > 0 or IsManageEmployee > 0 then
			if SimGetProfession("") == GL_PROFESSION_THIEF then
				if HasProperty("","SchuldenGeb") then
					idlelib_ReturnACredit()
				end
				idlelib_ThiefIdle("WorkingPlace")
				return
			elseif SimGetProfession("") == GL_PROFESSION_ROBBER then
				if HasProperty("","SchuldenGeb") then
					idlelib_ReturnACredit()
				end
				idlelib_RobberIdle("WorkingPlace")
				--idlelib_GoToDivehouse()
				return
			elseif SimGetProfession("") == GL_PROFESSION_COCOTTE then
				if HasProperty("","SchuldenGeb") then
					idlelib_ReturnACredit()
				end
				idlelib_CocotteIdle("")
				return
			elseif SimGetProfession("") == GL_PROFESSION_MYRMIDON then
				if HasProperty("","SchuldenGeb") then
					idlelib_ReturnACredit()
				end
				idlelib_MyrmidonIdle("")
				return
			elseif SimGetProfession("") == 74 then
				if HasProperty("","SchuldenGeb") then
					idlelib_ReturnACredit()
				end
				idlelib_LeibwacheIdle("WorkingPlace")
				return
			elseif SimGetProfession("") == 17 then
				if HasProperty("","SchuldenGeb") then
					idlelib_ReturnACredit()
				end
				idlelib_LeibwacheIdle("WorkingPlace")
				return
			elseif SimGetProfession("") == 42 then
				-- juggler: resume a sticky street-begging assignment so it persists
				if HasProperty("","SchuldenGeb") then
					idlelib_ReturnACredit()
				end
				idlelib_JugglerIdle("")
				return
			end
		else
			if HasProperty("","SchuldenGeb") then
				idlelib_ReturnACredit()
			end
		end
	end
	
	Sleep(120)
	return
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

function RandomInfection()
	if not IsPartyMember("") then
		if not GetSettlement("","City") then
			return
		end
		local CityLevel = CityGetLevel("City")
		local SicknessChance = Rand(100)
		if GetState("", STATE_SICK) then
			SicknessChance = 0
		else
			local Season = GetSeason()
			-- was "or EN_SEASON_WINTER" (always true)
			if Season == EN_SEASON_AUTUMN or Season == EN_SEASON_WINTER then
				SicknessChance = Rand(50)
			end
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
	end
end
