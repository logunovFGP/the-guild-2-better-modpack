-------------------------------------------------------------------------------
----
----	OVERVIEW "ms_010_GoToSleep"
----
----	with this measure the character can go to Sleep in his home building
----
-------------------------------------------------------------------------------

function Run() 
	
	local MeasureID = GetCurrentMeasureID("")
	local duration = 6

	if SimGetProfession("")==GL_PROFESSION_MYRMIDON then
		if not SimGetWorkingPlace("","HomeBuilding") then
			MsgQuick("","@L_GENERAL_MEASURES_010_GOTOSLEEP_FAILURES_+0", GetID(""))
			StopMeasure()
		end
	elseif not(GetHomeBuilding("", "HomeBuilding")) then
		MsgDebugMeasure("GoToSleep - No homebuilding found for sleeping")
		if IsDynastySim("Owner") then
			MsgQuick("","@L_GENERAL_MEASURES_010_GOTOSLEEP_FAILURES_+0", GetID(""))
			StopMeasure()
		end
		StopMeasure()
	end
	
	-- Not sleepy?
	if GetImpactValue("","GoodDream")>0 or GetImpactValue("", "BadDream") > 0 then
		MsgQuick("","@L_GENERAL_MEASURES_010_GOTOSLEEP_FAILURES_+2", GetID(""))
		StopMeasure()
	end

	if not GetInsideBuilding("", "Inside") or GetID("Inside")~=GetID("HomeBuilding") then
		if GetImpactValue("","Sickness")>0 then
			if not f_MoveTo("", "HomeBuilding", GL_MOVESPEED_WALK) then
				StopMeasure()
			end
		else
			if not f_MoveTo("", "HomeBuilding", GL_MOVESPEED_RUN) then
				StopMeasure()
			end
		end
	end
	if GetImpactValue("", "SleepRecoverBonus") > 0 then
		duration = duration - ((GetImpactValue("", "SleepRecoverBonus")*0.01)*duration)
	end
	local CurrentHP = GetHP("")
	local MaxHP = GetMaxHP("")
	local ToHeal = MaxHP - CurrentHP
	local HealPerTic = ToHeal / (duration * 12)
	local UseLocator = false

	if not AliasExists("HomeBuilding") then
		StopMeasure()
	end

	if GetFreeLocatorByName("HomeBuilding", "Bed",1,3, "SleepPosition") then
		if not f_BeginUseLocator("", "SleepPosition", GL_STANCE_LAY, true) then
			MsgQuick("", "@L_GENERAL_MEASURES_010_GOTOSLEEP_FAILURES_+1", GetID(""))
			StopMeasure()
		end
	else
		if SimGetProfession("") == GL_PROFESSION_MYRMIDON then
			MsgQuick("", "@L_GENERAL_MEASURES_010_GOTOSLEEP_FAILURES_+1", GetID(""))
			StopMeasure()
		end
		if GetDynastyID("") ~= -1 and IsDynastySim("Owner") then
			-- member from a dynasty must sleep in the right way
			MsgQuick("","@L_GENERAL_MEASURES_010_GOTOSLEEP_FAILURES_+1", GetID(""))
			return
		end
		RemoveAlias("SleepPosition")
	end
	
	local CurrentTime = GetGametime()
	SetData("StartTime", CurrentTime)
	if GetImpactValue("","Sickness")>0 then
		duration = duration * 2
	end
	SetData("Duration", duration)
	local EndTime = CurrentTime + duration
	
	while GetGametime()<EndTime do
		Sleep(5)
		-- increase the hp due to the recover factor for the residence
		if GetHP("") < MaxHP then
			ModifyHP("", HealPerTic,false)
			PlaySound3DVariation("","measures/gotosleep",1)
		end
	end
		
	if IsPartyMember("") then	
		feedback_MessageCharacter("",
		"@L_GENERAL_MEASURES_010_GOTOSLEEP_WAKEUP_HEAD",
		"@L_GENERAL_MEASURES_010_GOTOSLEEP_WAKEUP_BODY", GetID(""))
	end
end

-- -----------------------
-- CleanUp
-- -----------------------
function CleanUp()
	
	if AliasExists("SleepPosition") then
		f_EndUseLocator("", "SleepPosition", GL_STANCE_STAND)
	end
	
	local Time = GetGametime()
	local Start = Time
	if HasData("StartTime") and GetData("StartTime")~=nil then
		Start = GetData("StartTime")
	else
		return
	end
	local duration = 6
	if HasData("Duration") and GetData("Duration")~=nil then
		duration = GetData("Duration")
	else
		return
	end
	
	local Factor = (Time - Start) / duration
	if Factor>1 then
		Factor = 1
	elseif Factor<0.05 then
		return
	end
	
	Factor=Factor*Factor*100
		
	local HealChance = 0 --50%
	local HeavySleep = SimHasAbility("",32)  --Deep Sleep ability
	
	if IsDynastySim("Owner") then
	
		if GetImpactValue("","Sickness")>0 and Factor>Rand(100) then
			if GetImpactValue("","Cold")>0 then
				if (HeavySleep == true) or (Rand(6) > 4) then  -- no items with ability or if very lucky
					diseases_Cold("",false)
				elseif RemoveItems("HomeBuilding","Blanket",1,INVENTORY_STD)==1 then
					diseases_Cold("",false)
				end
			end
			if GetImpactValue("","Influenza")>0 then
				if RemoveItems("HomeBuilding","Blanket",1,INVENTORY_STD)==1 then
					if HeavySleep == true then  -- no need for tea with ability
						HealChance = 1 --100%
					elseif RemoveItems("HomeBuilding","HerbTea",1,INVENTORY_STD)==1 then
						HealChance = 1 --100%
					end
					if HealChance >= Rand(2) then
						diseases_Influenza("",false)
					end
				end
			end
			if GetImpactValue("","Pneumonia")>0 then
				if RemoveItems("HomeBuilding","Blanket",1,INVENTORY_STD)==1 then
					if RemoveItems("HomeBuilding","HerbTea",1,INVENTORY_STD)==1 then					
						if HeavySleep == true then  -- 100% chance and no need for honey and bandage with ability
							diseases_Pneumonia("",false)
						elseif RemoveItems("HomeBuilding","Honey",1,INVENTORY_STD)==1 then
							if RemoveItems("HomeBuilding","Bandage",1,INVENTORY_STD)==1 then -- you need a lot of stuff
								if Rand(2)>0 then -- but you still need to be lucky (50%)
									diseases_Pneumonia("",false)
								end
							end
						end
					end
				end
			end
		end
		
		local SleepBonus=3

		if HeavySleep == true then
			Factor=Factor+20
			SleepBonus=5
		end
		if (Factor-20)>Rand(100) then
			if SimGetClass("")==1 then
				AddImpact("","constitution",1,12)
				AddImpact("","empathy",1,12)
				AddImpact("","bargaining",1,12)
			elseif SimGetClass("")==2 then
				AddImpact("","constitution",1,12)
				AddImpact("","dexterity",1,12)
				AddImpact("","craftsmanship",1,12)
			elseif SimGetClass("")==3 then
				AddImpact("","charisma",1,12)
				AddImpact("","rhetoric",1,12)
				AddImpact("","secret_knowledge",1,12)
			elseif SimGetClass("")==4 then
				AddImpact("","constitution",1,12)
				AddImpact("","fighting",1,12)
				AddImpact("","shadow_arts",1,12)
			end
			
			if Rand(100)>96 then
				AddImpact("","LifeExpanding",SleepBonus,-1)
			elseif Rand(3)>1 then
				AddImpact("","Resist",1,SleepBonus*Factor/50)
				AddImpact("","ResistDream",1,SleepBonus*Factor/50)
			else
				chr_GainXP("", Factor)
			end
			AddImpact("","GoodDream",1,12)
		else 
			chr_GainXP("", Factor)
			AddImpact("","BadDream",1,12)
		end
	end	
end		

function GetOSHData(MeasureID)
	
	--active time:
	OSHSetMeasureRuntime("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+0",Gametime2Total(mdata_GetDuration(MeasureID)))
end

