-------------------------------------------------------------------------------
----
----	OVERVIEW "ms_077_Marry"
----
----	with this measure the player can marry a courted sim
----
-------------------------------------------------------------------------------

-- -----------------------
-- Run
-- -----------------------
function Run()
	local XP = GetData("BaseXP")
	local Title = GetNobilityTitle("")
	local InteractionDistance = 128
	local ProposeInteractionDistance = 116
		
	-- Get the court lover and call it "Destination" because the older version of the measure worked with a selection
	if not SimGetCourtLover("", "Destination") then
		return
	end
	
	if IsDynastySim("Destination") then
		if GetNobilityTitle("Destination") > Title then
			Title = GetNobilityTitle("Destination")
		end
	end
	
	local Cost = (Title * 2) * 300
	
	if not HasProperty("", "ContinueWedding") then
	
		if SimGetProfession("Destination") > 0 then -- don't marry workers please
			if SimGetWorkingPlace("Destination", "MyWork") then
				if BuildingGetOwner("MyWork", "MyBoss") then
					MsgBoxNoWait("", "Destination",  "@L_GENERAL_MEASURES_MARRY_FAILURES_HEAD_+0", "@L_GENERAL_MEASURES_MARRY_FAILURES_+1", GetID("Destination"), GetID("MyWork"), GetID("MyBoss"), GetID(""))
					SimReleaseCourtLover("")
					chr_GainXP("", XP/2)
					StopMeasure()
					return
				end
			end
			
			-- something missing, send alternative message
			MsgBoxNoWait("", "Destination",  "@L_GENERAL_MEASURES_MARRY_FAILURES_HEAD_+0", "@L_GENERAL_MEASURES_MARRY_FAILURES_+2", GetID("Destination"), GetID(""))
			SimReleaseCourtLover("")
			chr_GainXP("", XP/2)
			return
		end
		
		-- destination is already married
		if SimGetSpouse("Destination", "Spouse") then
			SimReleaseCourtLover("")
			LogMessage("Destination has Spouse")
			StopMeasure()
		end
		
		if not ai_StartInteraction("", "Destination", 500, InteractionDistance) then
			MsgQuick("", "@L_GENERAL_MEASURES_MARRY_FAILURES_+0", GetID("Destination"))
			LogMessage("Start Interaction fail Marriage")
			StopMeasure()
			return
		end
		
		SetAvoidanceGroup("", "Destination")
		MoveSetActivity("", "converse")
		MoveSetActivity("Destination", "converse")
		CreateCutscene("default", "cutscene")
		CutsceneAddSim("cutscene", "")
		CutsceneAddSim("cutscene", "Destination")
		CutsceneCameraCreate("cutscene", "")			

		-------------
		-- Propose --
		-------------
		camera_CutsceneBothLock("cutscene", "")
		
		chr_MultiAnim("", "proposal_male", "Destination", "proposal_female", ProposeInteractionDistance, 0.3)
		MsgSay("", talk_AskMarriage(GetSkillValue("", RHETORIC), SimGetGender("")));
		
		
		camera_CutscenePlayerLock("cutscene", "Destination")
		MsgSay("Destination", talk_AnswerMarriage(GetSkillValue("Destination", RHETORIC), SimGetGender("Destination")));
		
		if IsPartyMember("Destination") then
			SetProperty("Destination", "Wedding", 1)
			GetDynasty("Destination", "DesDyn")
			DynastyRemoveMember("Destination", "DesDyn")
		end
		
		ReleaseAvoidanceGroup("")
		DestroyCutscene("cutscene")
	end
	
	--------------------------------
	-- Ask for the place to marry --
	--------------------------------
	
	local choice

	FindNearestBuilding("", -1, GL_BUILDING_TYPE_WEDDINGCHAPEL, -1, false, "Weddingchapel")

	if AliasExists("Weddingchapel") then

		if DynastyIsAI("") then
			if Cost > (GetMoney("") - 1000) then
				choice = 0
			else
				if DynastyIsShadow("") then
					choice = 0
				else
					choice = 1
				end
			end
		else
			if HasProperty("", "ContinueWedding") then
				choice = 1
			else
				
				choice = MsgBox("", "", 
								"@B[0,@L_MEASURE_WEDDING_OPTION_+0]"..
								"@B[1,@L_MEASURE_WEDDING_OPTION_+1]"..
								"@B[2,@L_MEASURE_WEDDING_OPTION_+2]",
								"@L_FAMILY_1_MARRIAGE_MESSAGE_HEAD_LEAVE_+0",
								"@L_MEASURE_WEDDING_QUESTION_+0",
								GetID(""), GetID("Destination"), Cost)
			end
		end
	else
		if DynastyIsAI("") then
			choice = 0
		else
			choice = MsgBox("", "", 
								"@B[0,@L_MEASURE_WEDDING_OPTION_+0]"..
								"@B[2,@L_MEASURE_WEDDING_OPTION_+2]",
								"@L_FAMILY_1_MARRIAGE_MESSAGE_HEAD_LEAVE_+0",
								"@L_MEASURE_WEDDING_QUESTION_+0",
								GetID(""), GetID("Destination"))
		end
	end

	--------------------------------
	--  at this place and nowhere else
	--------------------------------
	if choice == 0 then
		if ai_StartInteraction("", "Destination", 500, InteractionDistance) then
			
			if AliasExists("Weddingchapel") then
				PlaySound3D("Weddingchapel", "locations/bell_stroke_cathedral_loop+0.wav", 1.0)
			end
			
			f_StartHighPriorMusic(MUSIC_MARRIAGE)
			SetState("", STATE_DUEL, true)
			SetState("Destination", STATE_DUEL, true)

			SetAvoidanceGroup("", "Destination")
			CreateCutscene("default", "cutscene")
			CutsceneAddSim("cutscene", "")
			CutsceneAddSim("cutscene", "Destination")
			CutsceneCameraCreate("cutscene", "")
			camera_CutsceneBothLock("cutscene", "")

			ShowOverheadSymbol("", false, true, 0, "@L$S[2001]")
			ShowOverheadSymbol("Destination", false, true, 0, "@L$S[2001]")
			
			local AnimLength = chr_MultiAnim("", "kiss_male", "Destination", "kiss_female", InteractionDistance, 1.0, true)
			
			Sleep(AnimLength * 0.5)
			ShowOverheadSymbol("Destination", false, true, 0, "@L$S[2001]")
			ShowOverheadSymbol("", false, true, 0, "@L$S[2001]")
			
			Sleep(AnimLength * 0.5)
			ShowOverheadSymbol("Destination", false, true, 0, "@L$S[2001]")
			ShowOverheadSymbol("", false, true, 0, "@L$S[2001]")
			
			if not HasProperty("", "CourtingDiff") then			
				gameplayformulas_CalcCourtingDifficulty("Destination", "")
			end
			
			local Difficulty = GetProperty("", "CourtingDiff")
			xp_CourtingSuccess("Owner", Difficulty)
			xp_CourtingSuccess("Destination", Difficulty)
			RemoveProperty("", "CourtingDiff")
	
			MeasureSetNotRestartable()
			RemoveProperty("Destination", "courted")
			if IsDynastySim("Destination") then
				DynastySetMinDiplomacyState("", "Destination", DIP_ALLIANCE, GetID(""), 24)
				DynastyForceCalcDiplomacy("")
				DynastyForceCalcDiplomacy("Destination")
				-- add the new property
				dyn_AddAlly("", "Destination")
				
				-- get a new title if the nob title is higher than yours
				local MyTitle = GetNobilityTitle("") or 1
				local SpouseTitle = GetNobilityTitle("Destination") or 1
				
				if MyTitle > 2 and SpouseTitle > MyTitle then
					SetNobilityTitle("", (MyTitle + 1), true)
				end
			end
			
			-- remember old dynastyID
			local OldDyn = GetDynastyID("Destination")
			SetProperty("Destination", "FamilyID", OldDyn)
			SetState("", STATE_DUEL, false)
			SetState("Destination", STATE_DUEL, false)
			
			AddImpact("", "LoveLevel", 10, 24) -- add some love for the next 24 hours
			AddImpact("Destination", "LoveLevel", 10, 24)
			SetState("Destination", STATE_INLOVE, false)

			if GetImpactValue("Destination", "LoveLevel") >= 10 then -- you are irresistable!
				MsgNewsNoWait("", "Destination", "", "schedule", -1,
							"@L_FAMILY_2_COHIBITATION_FULLOFLOVE_HEAD_+0",
							"@L_FAMILY_2_COHIBITATION_FULLOFLOVE_BODY_+0", GetID("Destination"))
			end
			
			SimMarry("", "Destination")	-- the destination is removed through this function

		else
		
			MsgQuick("", "@L_MEASURE_WEDDING_FAILURE_+0", GetID(""), GetID("Destination"))
		end

	--------------------------------
	--  visit the wedding chapel --
	--------------------------------
	elseif choice == 1 then
		Sleep(1)

		if not SimGetCourtLover("", "Destination") then
			MsgQuick("", "No courted Sim found for "..GetName("").."!")
			return
		end

		if HasProperty("","OCCURING_MARRIAGE") or HasProperty("Destination","OCCURING_MARRIAGE") then
			MsgQuick("","A wedding ceremony is already planned for at least one of these characters!")
			return
		end

		SetProperty("","WEDDING_FORCED",1)
		SetProperty("Destination","WEDDING_FORCED",1)

		SetProperty("","WEDDING_canChat",1)
		SetProperty("Destination","WEDDING_canChat",1)

		SetProperty("","OCCURING_MARRIAGE",GetID("Destination"))
		SetProperty("Destination","OCCURING_MARRIAGE",GetID(""))
		
		CreateCutscene("WeddingCeremony", "Wedding")

		CopyAliasToCutscene("", "Wedding", "#MAIN")
		CopyAliasToCutscene("Destination", "Wedding", "#COURTED")

		CutsceneCallScheduled("Wedding", "Start")
	end
end

function CleanUp()
	EndCutscene("")
	DestroyCutscene("cutscene")
	MoveSetActivity("")
	MoveSetActivity("Destination")
	ReleaseAvoidanceGroup("")
	SetState("", STATE_DUEL, false)
	SetState("Destination", STATE_DUEL, false)
end