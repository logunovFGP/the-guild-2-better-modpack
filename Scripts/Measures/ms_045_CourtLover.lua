-------------------------------------------------------------------------------
----
----	OVERVIEW "ms_045_CourtLover"
----
----	with this measure the player can court a lover for his character
----
-------------------------------------------------------------------------------

-- -----------------------
-- AIInit
-- -----------------------
function AIInit()

	local Selection
	local BestValue = -1
	local Partners = Find("", "__F((Object.GetObjectsFromCity(Sim))AND(Object.CanBeCourted())AND(Object.CanBeInterrupted(CourtLover)))", "Partner", 50)

	if Partners > 0 then
		local Value
		local Alias
		local CharismaSkill = GetSkillValue("", CHARISMA)
		local RhetoricSkill = GetSkillValue("", RHETORIC)
		local TotalSkill = CharismaSkill + RhetoricSkill
		local MyTitle = GetNobilityTitle("")
		local MyClass = SimGetClass("")
		local Skip = false
		
		for i = 0, Partners-1 do
			Alias = "Partner"..i
			Skip = false
			
			-- check party or heir
			if HasProperty(Alias, "DynastyHeir") or (IsPartyMember(Alias) and not DynastyIsShadow(Alias)) then
				Skip = true
			end
			
			if not Skip then
				-- check dynasty decision and employee status
				if GetDynasty(Alias, "DestDyn") and GetImpactValue("DestDyn", "NoPlayerCourt") == 1 then
					Skip = true
				elseif SimGetWorkingPlaceID(Alias) > 0 then
					Skip = true
				end
			end
			
			if not Skip then
				-- check class
				local DestClass = SimGetClass(Alias)
				if DestClass > 4 or DestClass == MyClass then
					Skip = true
				end
			end
			
			-- check min favor
			local DestinationTitle = 0
			if IsDynastySim(Alias) then
				DestinationTitle = GetNobilityTitle(Alias)
			end
	
			local TitleDifference = (MyTitle - DestinationTitle) * 2
			local MinFavor = GL_COURT_LOVER_MINFAVOR - TotalSkill - TitleDifference
			
			if GetFavorToSim(Alias, "") < MinFavor then
				Skip = true
			end
			
			-- check for circular marriages
			if (not Skip) and (not enginebugchecks_CanSafelyUseSimMarry("", Alias)) then
				Skip = true
			end

			if not Skip then
				Value = SimGetLevel(Alias)*10
					
				if TitleDifference < 0 then
					Value = Value * 2
				end
					
				local AgeDiff = SimGetAge(Alias) - SimGetAge("")
				if AgeDiff < 0 then
					AgeDiff = -AgeDiff
				end
					
				if AgeDiff > 20 then
					Value = Value / 5
				elseif AgeDiff > 10 then
					Value = Value / 3
				elseif AgeDiff < 5 then
					Value = Value * 1.5
				end
					
				if not Selection or Value > BestValue then
					Selection = Alias
					BestValue = Value
				end
			end
		end
	end
	
	if not Selection then
		return false
	end
		
	CopyAlias(Selection, "Destination")	
	return true
end

-- -----------------------
-- Run
-- -----------------------
function Run()
	
	MeasureSetNotRestartable()
	if not AliasExists("Destination") then
		if not ms_045_courtlover_AIInit() then
			return
		end
	end
	
	-- recently fired employee
	if HasProperty("Destination", "NoMarry") then    
		if GetProperty("Destination", "NoMarryTime") < GetGametime() then -- if time is over, remove property
			RemoveProperty("Destination", "NoMarryTime")
			RemoveProperty("Destination", "NoMarry")
		elseif GetDynastyID("") == GetProperty("Destination", "NoMarry") then -- if our dynasty recently fired the destination Sim, stop measure.
			MsgQuick("", "@L_COURTLOVER_MSG_FAILED_QUICK")
			return
		end
	end
	
	if SimGetCourtingSim("Destination", "blabla") then
		MsgQuick("", "%1SN %2l", GetID("Destination")," @L_FILTER_IS_COURTED")
		StopMeasure()
	end
	
	-- check for circular marriages
	if not enginebugchecks_CanSafelyUseSimMarry("", "Destination") then
		SimReleaseCourtLover("")
		MsgQuick("", "@L_COURTLOVER_MSG_CIRCULARMARRIAGE_QUICK")
		return
	end
	
	-- Calculate the difficulty which will be set as property to the destination and used in the following MsgBox
	-- There are four locations where this property will be removed:
	-- At the CleanUp() in this measure if it is canceled before the SetCourtLover()
	-- at the "BreakUp" measure
	-- at the "ArrangeLiaison" measure or
	-- at the "Marry" measure
	-- The reason why the property must live that long is that the xp points which are spent at the ArrangeLiaison- or Marry measue
	-- have to know the difficulty
	gameplayformulas_CalcCourtingDifficulty("Destination", "")
	
	-- Display the court lover sheet
	SetProperty("", "LoverID", GetID("Destination"))
	if not (MsgBox("", 0, "CourtLover", 0, 0) == "O") then
		RemoveProperty("", "LoverID")
		StopMeasure()
		return
	end
	
	RemoveProperty("", "LoverID")
	
	local CharismaSkill = GetSkillValue("", CHARISMA)
	local RhetoricSkill = GetSkillValue("", RHETORIC)
	local TotalSkill = CharismaSkill + RhetoricSkill

	local MyTitle = GetNobilityTitle("")
	local DestinationTitle = 0
	if IsDynastySim("Destination") then
		DestinationTitle = GetNobilityTitle("Destination")
	end
	
	local TitleDifference = (MyTitle - DestinationTitle) * 2
	local MinimumFavor = GL_COURT_LOVER_MINFAVOR - TotalSkill - TitleDifference
	
	-- get target outside of the current building if building is a worker hut or residence
	if not CanBeInterruptetBy("Destination", "", "CourtLover") then
		return
	end
	
	if GetInsideBuilding("Destination", "DestBuilding") then
		if BuildingGetType("DestBuilding") == GL_BUILDING_TYPE_WORKER_HOUSING or BuildingGetType("DestBuilding") == GL_BUILDING_TYPE_RESIDENCE then
			GetOutdoorMovePosition("", "DestBuilding", "MovePos")
			if not f_MoveTo("", "MovePos", GL_MOVESPEED_RUN, 600) then
				StopMeasure()
			end
			BlockChar("Destination")
			f_ExitCurrentBuilding("Destination")
			Sleep(1)
			f_MoveTo("Destination", "Owner", GL_MOVESPEED_RUN, 300)
		end
	end
	
	local InteractionDistance = 128
	
	if not ai_StartInteraction("", "Destination", 500, InteractionDistance) then
		StopMeasure("")
	end
	
	-- Ask the player for allowance
	if DynastyIsPlayer("Destination") then
		local Allow = 0			
		if not IsOnlyPartyMember("Destination") then
			if IsPartyMember("Destination") then
				local result = MsgNews("Destination", "", "MB_YESNO", ms_045_courtlover_AIInitCourt, "default", 0.5, "@L_INTERFACE_DIALOG_TO_NEWS_HEADER", "@L_FAMILY_7_DYNCOURT_COURT_PARTY_MEMBER_BODY", GetID("Destination"), GetID(""))
				if result == "O" then
					DynastyRemoveMember("Destination")
					Allow = 1
				end
			else
				local result = MsgNews("Destination", "", "MB_YESNO", ms_045_courtlover_AIInitCourt, "default", 0.5, "@L_INTERFACE_DIALOG_TO_NEWS_HEADER", "@L_FAMILY_7_DYNCOURT_COURT_DYN_MEMBER_BODY", GetID("Destination"), GetID(""))
				if result == "O" then
					Allow = 1
				end
			end
		else
			-- This is the last party-member. Do not allow this otherwise the dynasty will be guideless				
			StopMeasure()
			return
		end
		
		-- If it was allowed by the player don´t do the whole animation thing
		if Allow == 1 then
			SetProperty("Destination", "courted", 1)
			SetState("Destination", STATE_INLOVE, true)
			SimSetCourtLover("", "Destination")
			return
		else
			-- Dont ask this sim on and on again
			if GetDynasty("Destination", "DestDyn") then
				AddImpact("DestDyn", "NoPlayerCourt", 1, GL_AI_WAIT_FOR_COURTING_PLAYER)
				StopMeasure() 
				return  
			end
		end 
	end

	SetAvoidanceGroup("", "Destination")
	MoveSetActivity("", "converse")
	MoveSetActivity("Destination", "converse")

	feedback_OverheadActionName("Destination")

	-- get the gender of the owner
	local IsMale = (SimGetGender("") == GL_GENDER_MALE)
	
	-- animation timings
	local time1 = 0
	local time2 = 0
	
	-- check if the favor is high enough for courting
	local success = (GetFavorToSim("Destination", "") >= MinimumFavor)
	local ReasonHeir = false
	
	-- fail if the Dest is employed already
	if SimGetWorkingPlaceID("Destination") > 0 then
		success = false
	end
	
	-- fail if heir
	if HasProperty("Destination", "DynastyHeir") then
		success = false
		ReasonHeir = true
	end
	
	-- fail if group members for coloured
	if IsPartyMember("Destination") and not DynastyIsShadow("Destination") then
		success = false
		ReasonHeir = true
	end
	
	-- Proposal
	PlayAnimationNoWait("", "talk")

	CreateCutscene("default","cutscene")
	CutsceneAddSim("cutscene","")
	CutsceneAddSim("cutscene","destination")
	CutsceneCameraCreate("cutscene","")			
	camera_CutscenePlayerLock("cutscene", "")

	-- Get the gender of the acting character		
	local label = "@L_COURTLOVER_BEGIN_QUESTION"
	if IsMale then
		label = label.."_TOFEMALE"
	else
		label = label.."_TOMALE"
	end

	local label2
	local Rhetoric = GetSkillValue("", RHETORIC)
	if (Rhetoric < 3) then
		label2 = "_WEAK_RHETORIC"
	elseif (Rhetoric < 6) then
		label2 = "_NORMAL_RHETORIC"
	else
		label2 = "_GOOD_RHETORIC"
	end	

	CutsceneShowCharacterPanel("", true)
	MsgSay("", label.."_1ST"..label2)
	MsgSay("", label.."_2ND"..label2)
	CutsceneShowCharacterPanel("", false)
	
	-- Check if it was successfull
	if success then
		
		-- for the AI, wait some time before starting again
		if GetDynasty("", "AI_Dyn") then
			SetRepeatTimer("AI_Dyn", "AI_CourtLover_Start", 48)
		end
		
		-- Check the sex
		if IsMale then
			
			-- Show the appropriate Animation	and save the animation lenghts
			local DestinationAnimationLength = PlayAnimationNoWait("Destination", "curtsy")

			camera_CutscenePlayerLock("cutscene", "Destination")				
			
			local Rhetoric2 = GetSkillValue("Destination", RHETORIC)
			if (Rhetoric2 < 3) then
				MsgSay("Destination", "@L_COURTLOVER_BEGIN_ANSWER_SUCCESS_FEMALE_WEAK_RHETORIC")
			elseif (Rhetoric2 < 6) then
				MsgSay("Destination", "@L_COURTLOVER_BEGIN_ANSWER_SUCCESS_FEMALE_NORMAL_RHETORIC")
			else
				MsgSay("Destination", "@L_COURTLOVER_BEGIN_ANSWER_SUCCESS_FEMALE_GOOD_RHETORIC")
			end	

			StopAnimation("")
			PlayAnimationNoWait("", "bow")
			Sleep(DestinationAnimationLength*0.15)
		else

			-- Show the appropriate Animation	and save the animation lenghts
			local DestinationAnimationLength = PlayAnimationNoWait("Destination", "bow")
			
			camera_CutscenePlayerLock("cutscene", "Destination")
			
			local Rhetoric2 = GetSkillValue("Destination", RHETORIC)
			if (Rhetoric2 < 3) then
				MsgSay("Destination", "@L_COURTLOVER_BEGIN_ANSWER_SUCCESS_MALE_WEAK_RHETORIC")
			elseif (Rhetoric2 < 6) then
				MsgSay("Destination", "@L_COURTLOVER_BEGIN_ANSWER_SUCCESS_MALE_NORMAL_RHETORIC")
			else
				MsgSay("Destination", "@L_COURTLOVER_BEGIN_ANSWER_SUCCESS_MALE_GOOD_RHETORIC")
			end	

			StopAnimation("")
			PlayAnimationNoWait("", "curtsy")
			Sleep(DestinationAnimationLength*0.15)
		end

		-- adds property so that CourtLover cannot be hired
		SetProperty("Destination", "courted", 1)
		SetState("Destination", STATE_INLOVE, true)
		SetData("CourtLoverSet", 1)
		DestroyCutscene("cutscene")

		feedback_MessageCharacter("", 
							"@L_COURTLOVER_MSG_SUCCESS_HEAD_+0",
							"@L_COURTLOVER_MSG_SUCCESS_BODY_+0", GetID("Destination"), GetID("Owner"))
		
		SimSetCourtLover("", "Destination")		
	else
		
		camera_CutscenePlayerLock("cutscene", "Destination")		
		chr_ModifyFavor("Destination", "", -GL_FAVOR_MOD_SMALL)
		
		local Time1 = PlayAnimationNoWait("Destination", "propel")

		if IsMale then
			local Rhetoric2 = GetSkillValue("Destination", RHETORIC)

			if (Rhetoric2 < 3) then
				MsgSay("Destination", "@L_COURTLOVER_BEGIN_ANSWER_FAILED_FEMALE_WEAK_RHETORIC")
			elseif (Rhetoric2 < 6) then
				MsgSay("Destination", "@L_COURTLOVER_BEGIN_ANSWER_FAILED_FEMALE_NORMAL_RHETORIC")
			else
				MsgSay("Destination", "@L_COURTLOVER_BEGIN_ANSWER_FAILED_FEMALE_GOOD_RHETORIC")
			end	
		else
			local Rhetoric2 = GetSkillValue("Destination", RHETORIC)

			if (Rhetoric2 < 3) then
				MsgSay("Destination", "@L_COURTLOVER_BEGIN_ANSWER_FAILED_MALE_WEAK_RHETORIC")
			elseif (Rhetoric2 < 6) then
				MsgSay("Destination", "@L_COURTLOVER_BEGIN_ANSWER_FAILED_MALE_NORMAL_RHETORIC")
			else
				MsgSay("Destination", "@L_COURTLOVER_BEGIN_ANSWER_FAILED_MALE_GOOD_RHETORIC")
			end	
		end
		
		Sleep(Time1*0.3)
		
		if ReasonHeir then
			feedback_MessageCharacter("", 
							"@L_COURTLOVER_MSG_FAILED_HEAD_+0",
							"@L_COURTLOVER_MSG_FAILED_BODY_+1", GetID("Destination"), GetID("Owner"))
		else
			feedback_MessageCharacter("", 
							"@L_COURTLOVER_MSG_FAILED_HEAD_+0",
							"@L_COURTLOVER_MSG_FAILED_BODY_+0", GetID("Destination"), GetID("Owner"))
		end

	end
end

-- -----------------------
-- AIInitCourt
-- -----------------------
function AIInitCourt()
	return "O"
end

-- -----------------------
-- CleanUp
-- -----------------------
function CleanUp()

	DestroyCutscene("cutscene")
	ReleaseAvoidanceGroup("")
	MoveSetActivity("")
	StopAnimation("")
	
	-- Remove the difficulty which was set in the court lover panel and used und the setcourtlover-function
	if AliasExists("Destination") then
		if not HasData("CourtLoverSet") then			
			RemoveProperty("", "CourtingDiff")
		end
		MoveSetActivity("Destination")
		feedback_OverheadActionName("Destination")
		SimLock("Destination", 0.3)
	end
end

