-------------------------------------------------------------------------------
----
----	OVERVIEW "ms_010_GoToSleep"
----
----	with this measure the character can go to Sleep in his home building
----
-------------------------------------------------------------------------------

function Run() 

	if not(GetHomeBuilding("", "HomeBuilding")) then
		LogMessage("GoToSleep - No homebuilding found for sleeping")
		if IsDynastySim("Owner") then
			MsgBoxNoWait("", "", "@L_GENERAL_ERROR_HEAD_+0", "@L_GENERAL_MEASURES_010_GOTOSLEEP_FAILURES_+0", GetID(""))
		end
		return
	end
	
	if not AliasExists("HomeBuilding") then
		return
	end
	
	-- Not sleepy?
	if GetImpactValue("", "GoodDream") > 0 or GetImpactValue("", "VeryGoodDream") > 0 or GetImpactValue("", "BadDream") > 0 then
		MsgBoxNoWait("", "", "@L_GENERAL_ERROR_HEAD_+0", "@L_GENERAL_MEASURES_010_GOTOSLEEP_FAILURES_+2", GetID(""))
		StopMeasure()
	end

	if not GetInsideBuilding("", "Inside") or GetID("Inside") ~= GetID("HomeBuilding") then
		if GetImpactValue("", "Sickness") > 0 then
			if not f_MoveTo("", "HomeBuilding", GL_MOVESPEED_WALK) then
				StopMeasure()
			end
		else
			if not f_MoveTo("", "HomeBuilding", GL_MOVESPEED_RUN) then
				StopMeasure()
			end
		end
	end

	if GetFreeLocatorByName("HomeBuilding", "Bed", 1, 3, "SleepPosition") then
		if not f_BeginUseLocator("", "SleepPosition", GL_STANCE_LAY, true) then
			MsgQuick("", "@L_GENERAL_MEASURES_010_GOTOSLEEP_FAILURES_+1", GetID(""))
			StopMeasure()
		end
	else
		if GetDynastyID("") ~= -1 and IsDynastySim("Owner") then
			-- member from a dynasty must sleep in the right way
			MsgBoxNoWait("", "", "@L_GENERAL_ERROR_HEAD_+0", "@L_GENERAL_MEASURES_010_GOTOSLEEP_FAILURES_+1", GetID(""))
			StopMeasure()
		end
	end
	
	local MeasureID = GetCurrentMeasureID("")
	local duration = 6
	local CurrentHP = GetHP("")
	local MaxHP = GetMaxHP("")
	local ToHeal = MaxHP - CurrentHP
	local HealPerTic = ToHeal / (duration * 12)
	local MaxProgress = duration * 10
	SetProcessMaxProgress("", MaxProgress)
	local UseLocator = false
	local CurrentTime = GetGametime()
	
	SetData("StartTime", CurrentTime)
	SetData("Duration", duration)
	
	local EndTime = CurrentTime + duration
	
	while GetGametime() < EndTime do
		
		Sleep(5)
		SetProcessProgress("", (GetGametime()-CurrentTime)*10)
		-- increase the hp
		if GetHP("") < MaxHP then
			ModifyHP("", HealPerTic, false)
			PlaySound3DVariation("", "measures/gotosleep", 1)
		end
	end
end

-- -----------------------
-- CleanUp
-- -----------------------
function CleanUp()
	
	if AliasExists("SleepPosition") then
		f_EndUseLocator("", "SleepPosition", GL_STANCE_STAND)
	end
	
	ResetProcessProgress("")
	
	local Time = GetGametime()
	local Start = Time
	
	if HasData("StartTime") and GetData("StartTime") ~= nil then
		Start = GetData("StartTime")
	else
		return
	end
	
	local duration = 6
	
	if HasData("Duration") and GetData("Duration") ~= nil then
		duration = GetData("Duration")
	else
		return
	end
	
	local Factor = (Time - Start) / duration
	
	if Factor > 1 then
		Factor = 1
	elseif Factor < 0.05 then
		return
	end
	
	if IsDynastySim("Owner") then
	
		if GetImpactValue("", "Sickness") > 0 and Factor >= 0.9 then
			if GetImpactValaue("", "HerbTea") > 0 then -- herb tea helps
				local CheckDisease = { "Cold", "Sprain", "BurnWound", "Influenza", "Pneumonia", "Pox", "BlackDeath", "Fracture" }
				local SleepBonus = GetImpactValue("", "SleepBonusI")
				
				for i=1, 7 do
					if GetImpactValue("", CheckDisease[i]) > 0 then
						if CheckDisease[i] == "Cold" then
							diseases_giveSickness("Cold","", false)
						else
							if SleepBonus > 0 then
								if CheckDisease[i] == "Sprain" then
									diseases_giveSickness("Sprain","", false)
								elseif CheckDisease[i] == "BurnWound" then
									diseases_giveSickness("BurnWound","", false)
								elseif CheckDisease[i] == "Influenza" then
									diseases_giveSickness("Influenza","", false)
								elseif CheckDisease[i] == "Pneumonia" then
									diseases_giveSickness("Pneumonia","", false)
								elseif CheckDisease[i] == "Pox" then
									diseases_giveSickness("Pox","", false)
								elseif CheckDisease[i] == "BlackDeath" then
									diseases_giveSickness("Blackdeath","", false)
								elseif CheckDisease[i] == "Fracture" then
									diseases_giveSickness("Fracture","", false)
								end
							end
						end
					end
				end
			else -- no tea? then healing is random at 33 %
				if Rand(100) >= 66 then
					if GetImpactValue("", "Cold") > 0 then
						diseases_giveSickness("Cold","", false)
					end
				end
			end
		end
		-- good dream bonus
		if Factor >= 0.8 then
			if SimGetClass("") == 1 then
				AddImpact("", "constitution",1,12)
				AddImpact("", "empathy",1,12)
				AddImpact("", "bargaining",1,12)
			elseif SimGetClass("") == 2 then
				AddImpact("", "constitution",1,12)
				AddImpact("", "dexterity",1,12)
				AddImpact("", "craftsmanship",1,12)
			elseif SimGetClass("") == 3 then
				AddImpact("", "charisma",1,12)
				AddImpact("", "rhetoric",1,12)
				AddImpact("", "secret_knowledge",1,12)
			elseif SimGetClass("") == 4 then
				AddImpact("", "constitution",1,12)
				AddImpact("", "fighting",1,12)
				AddImpact("", "shadow_arts",1,12)
			end
			
			Factor = Factor*100
			chr_GainXP("", Factor)
			AddImpact("", "GoodDream", 1, 12)
		else 
			Factor = Factor*100
			chr_GainXP("", Factor)
			AddImpact("", "BadDream", 1, 12)
		end
		
		if IsPartyMember("") then
			feedback_MessageCharacter("", "@L_GENERAL_MEASURES_010_GOTOSLEEP_WAKEUP_HEAD",
							"@L_GENERAL_MEASURES_010_GOTOSLEEP_WAKEUP_BODY", GetID("Owner"))
		end
	end
end		

function GetOSHData(MeasureID)
	
	--active time:
	OSHSetMeasureRuntime("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+0",Gametime2Total(mdata_GetDuration(MeasureID)))
end

