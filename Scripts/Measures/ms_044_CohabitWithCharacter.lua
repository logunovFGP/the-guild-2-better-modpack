-------------------------------------------------------------------------------
----
----	OVERVIEW "ms_044_CohabitWithCharacter"
----
----	With this measure the player can beget new blood with his spouse
----
-------------------------------------------------------------------------------

-- -----------------------
-- Run
-- -----------------------
function Run()

	local MeasureID = GetCurrentMeasureID("")
	local TimeOut = mdata_GetTimeOut(MeasureID)
	local InteractionDistance = 80
	
	-- Get the spouse and call it "Destination" because the older version of the measure worked with a selection
	if not SimGetSpouse("", "Destination") then
		return
	end

	if not GetHomeBuilding("", "HomeBuilding") then
		return
	end
	
	if not CanBeInterruptetBy("Destination", "", "CohabitWithCharacter") then
		return
	end

	GetScenario("World")
	if not HasProperty("World", "static") or GetProperty("World", "static") == 0 then
		if not f_SimIsValid("Destination") then
			return
		end
	end
	
	if not f_MoveToNoWait("", "HomeBuilding", GL_MOVESPEED_RUN) then
		return
	end

	if GetDistance("Destination","HomeBuilding") < 2000 or DynastyIsPlayer("Destination") then
		MsgMeasure("", "@L_GENERAL_MSGMEASURE_COHABIT_+0")
		if not f_MoveTo("Destination", "HomeBuilding", GL_MOVESPEED_RUN) then
			return
		end
	else
		GetLocatorByName("HomeBuilding", "Walledge1", "entry")
		SimBeamMeUp("Destination", "entry", false)
		f_MoveTo("Destination", "HomeBuilding", GL_MOVESPEED_RUN)
	end

	local WaitTime = math.mod(GetGametime(),24) + 2
	local check = true
	while check do
		Sleep(2)

		if not AliasExists("Destination") then
			StopMeasure()
			break
		end

		if math.mod(GetGametime(),24) > WaitTime then
			StopMeasure()
			break
		end

		if GetInsideBuilding("", "Building1") and GetInsideBuilding("Destination", "Building2") then
			if (GetID("Building1")==GetID("Building2")) then
				check = false
			else
				-- check again to be sure
				if CanBeInterruptetBy("Destination", "", "CohabitWithCharacter") then
					if GetDistance("Destination","HomeBuilding") < 2000 or DynastyIsPlayer("Destination") then
						if not f_MoveTo("Destination", "HomeBuilding", GL_MOVESPEED_RUN) then
							StopMeasure()
						end
					else
						GetLocatorByName("HomeBuilding", "Walledge1", "entry")
						SimBeamMeUp("Destination", "entry", false)
						f_MoveTo("Destination", "HomeBuilding", GL_MOVESPEED_RUN)
					end
				end
				Sleep(15)
			end
		else
			-- check again to be sure
			if CanBeInterruptetBy("Destination", "", "CohabitWithCharacter") then
				if GetDistance("Destination", "HomeBuilding") < 2000 or DynastyIsPlayer("Destination") then
					if not f_MoveTo("Destination", "HomeBuilding", GL_MOVESPEED_RUN) then
						StopMeasure()
						break
					end
				else
					GetLocatorByName("HomeBuilding", "Walledge1", "entry")
					SimBeamMeUp("Destination", "entry", false)
					f_MoveTo("Destination", "HomeBuilding", GL_MOVESPEED_RUN)
				end
			end
			Sleep(15)
		end
	end

	if ai_StartInteraction("", "Destination", 200, InteractionDistance) then
		

		-- Ask the question
		MsgSay("", talk_AskCohabit(GetSkillValue("", RHETORIC), SimGetGender("")));
					
		-- Check the success
		local Success = 0
		local Favor = 0
		if GetImpactValue("Destination", "LoveLevel") > 0 then
			Favor = GetImpactValue("Destination", "LoveLevel")
		end

		-- not for AI
		if not DynastyIsPlayer("") then
			Favor = 10
		end
		
		local Chance = Rand(10)
		SetRepeatTimer("Dynasty", GetMeasureRepeatName(), TimeOut)

		if (Favor > Chance) then
			MsgSay("Destination", talk_AnswerCohabit(GetSkillValue("Destination", RHETORIC), SimGetGender("Destination"), 1));
			Success = 1
		else 
			if Favor > 2 then
				MsgSay("Destination", talk_AnswerCohabit(GetSkillValue("Destination", RHETORIC), SimGetGender("Destination"), 2));
				OwnerAnimLength = PlayAnimationNoWait("", "talk")
				DestinationAnimLength = PlayAnimationNoWait("Destination", "shake_head")
			else
				MsgSay("Destination", talk_AnswerCohabit(GetSkillValue("Destination", RHETORIC), SimGetGender("Destination"), 3));
				OwnerAnimLength = PlayAnimationNoWait("", "got_a_slap")
				DestinationAnimLength = PlayAnimationNoWait("Destination", "give_a_slap")
			end
		end
		
		if (Success == 1) then
			
			if (SimGetGender("") == GL_GENDER_MALE) then
				CopyAlias("Owner", "male")
				CopyAlias("Destination", "female")
			else
				CopyAlias("Owner", "female")
				CopyAlias("Destination", "male")
			end
			
			if not GetInsideBuilding("", "Residence") then
				MsgQuick("", "@L_FAMILY_2_COHABITATION_FAILURES_+0", GetID("Building"))
				return
			end
			
			if not GetLocatorByName("Residence", "Cohabit1", "CohabitPos1") then
				MsgQuick("", "@L_FAMILY_2_COHABITATION_FAILURES_+1", GetID("Building"))
				return
			end
			
			if not GetLocatorByName("Residence", "Cohabit2", "CohabitPos2") then
				MsgQuick("", "@L_FAMILY_2_COHABITATION_FAILURES_+1", GetID("Building"))
				return
			end
	
			-----------------------------
			------ Go to the bed ------
			-----------------------------
			f_MoveToNoWait("male", "CohabitPos1")
			f_BeginUseLocator("female", "CohabitPos2", GL_STANCE_STAND, true)
			f_BeginUseLocator("male", "CohabitPos1", GL_STANCE_STAND, true)
			
			if GetLocatorByName("Residence", "Curtain", "CurtainPos") then
				GfxAttachObject("Curtain", "Locations/Residence/Curtain_Residence.nif")
				GfxSetPositionTo("Curtain", "CurtainPos")
				GfxSetRotation("Curtain", 0, 0 ,0, true)
			end
			
			SetData("Cohabit1LocatorInUse", 1)
			PlaySound3D("", "measures/cohabit/cohabit+0.wav", 1)
			Sleep(1.5)
			PlaySound3DVariation("", "CharacterFX/female_cohabit", 1)
			Sleep(2)
			PlaySound3DVariation("", "CharacterFX/male_cohabit", 1)
			Sleep(3)
			if Rand(2) == 0 then
				PlaySound3D("", "measures/cohabit/cohabit+0.wav", 1)
				PlaySound3DVariation("", "CharacterFX/female_cohabit", 1)
			else
				PlaySound3D("", "measures/cohabit/cohabit+0.wav", 1)
				PlaySound3DVariation("", "CharacterFX/male_cohabit", 1)
			end
			Sleep(6)
			
			-----------------------------
			------ Pregnant chance ------
			-----------------------------
			local PregnantChance = 95
			local MaleAge = SimGetAge("male")
			if MaleAge >= 60 then 
				PregnantChance = 70
			elseif MaleAge >= 40 then
				PregnantChance = 80
			end
			local FemaleAge = SimGetAge("female")
			if (FemaleAge > 30) then
				PregnantChance = PregnantChance - (FemaleAge - 30)*3
			end
			
			-- ImpactValue 42
			PregnantChance = PregnantChance + GetImpactValue("male", "CreateChild") + GetImpactValue("female", "CreateChild")
			
			-- Ability bonus
			if SimHasAbility("male", 3) then
				PregnantChance = PregnantChance * 1.5
			end
			if SimHasAbility("female", 3) then
				PregnantChance = PregnantChance * 1.5
			end

			if FemaleAge >= 47 then
				PregnantChance = 0
			end
			
			-- If maximum number of childs is reached, PregnantChance = 0
			local Count = SimGetChildCount("")
			local MaxChilds = GL_MAX_CHILD_COUNT
			if Count >= MaxChilds then
				PregnantChance = 0
			end
			
			--------------------------------
			------ Initiate Pregnancy ------
			--------------------------------
			if (PregnantChance > Rand(100)) then
				
				f_EndUseLocator("female", nil, GL_STANCE_LAY)
				MsgSay("", feedback_PregnancySuccess(SimGetGender(""), 1));
				SimGetPregnant("female")
				
				-- Add xp
				xp_CohabitWithCharacter("male", SimGetChildCount("male"))
				xp_CohabitWithCharacter("female", SimGetChildCount("female"))
				
			else				
				MsgSay("", feedback_PregnancySuccess(SimGetGender(""), 0));				
			end

			f_EndUseLocator("male", "CohabitPos1", GL_STANCE_STAND)
			SetData("Cohabit1LocatorInUse", 0)
			GfxDetachObject("Curtain")
		else
			MsgBoxNoWait("","Destination","@L_FAMILY_2_COHABITATION_FAIL_HEAD_+0",
						"@L_FAMILY_2_COHABITATION_FAIL_BODY_+0", GetID(""), GetID("Destination"))
		
		end
	end
end

function CleanUp()

	if AliasExists("Curtain") then
		GfxDetachObject("Curtain")
	end
	GfxDetachAllObjects()
	
	if IsStateDriven() then
		MeasureRun("", nil, "DynastyIdle")
		MeasureRun("Destination", nil, "DynastyIdle")
	end
end

function GetOSHData(MeasureID)
	--can be used again in:
	OSHSetMeasureRepeat("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+2",Gametime2Total(mdata_GetTimeOut(MeasureID)))
end

