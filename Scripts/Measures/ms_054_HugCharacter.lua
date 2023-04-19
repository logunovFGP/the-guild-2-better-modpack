-------------------------------------------------------------------------------
----
----	OVERVIEW "ms_054_HugCharacter"
----
----	with this measure the player can hug another sim
----
-------------------------------------------------------------------------------

-- -----------------------
-- Run
-- -----------------------
function Run()

	if not AliasExists("Destination") then
		return
	end
	
	-- The time in hours until the measure can be repeated
	local MeasureID = GetCurrentMeasureID("")
	local TimeOut = mdata_GetTimeOut(MeasureID)
	
	local DestGender = SimGetGender("Destination")
	
	-- The minimum favor for this action to success
	local TitleDifference = (GetNobilityTitle("Destination") - GetNobilityTitle(""))*2
	local CharismaSkill = GetSkillValue("", CHARISMA)
	local MinimumFavor = GL_HUG_MINFAVOR + TitleDifference - (CharismaSkill * 3)
	local Favor = 0
	if SimGetSpouse("", "Spouse") and GetID("Destination") == GetID("Spouse") then
		Favor = 100
	else
		Favor = GetFavorToSim("Destination", "")
	end
	local FavorWon = 5 + (CharismaSkill * 0.5)
	local FavorLoss = -5
	local ModifyFavor = 0
	
	-- Courting related
	local Class = SimGetClass("Destination")
	if Class == 0 then
		if HasProperty("Destination", "FakeClass") then
			Class = GetProperty("Destination", "FakeClass")
		else
			Class = Rand(4) + 1
			SetProperty("Destination", "FakeClass", Class)
		end
	end
	
	local CourtingProgress = gameplayformulas_GetCourtingProgress("", "Destination", MeasureID)
	local VariationFactor = gameplayformulas_GetCourtingMeasureVariation(MeasureID, "Destination", Class) 
	
	local time1 = 0
	
	local FlirtBonus = GetImpactValue("", "FlirtBonus") -- ability
	FavorWon = FavorWon * (1 + FlirtBonus)
	CourtingProgress = CourtingProgress * (1 + FlirtBonus)
	
	-- The distance between both sims to interact with each other
	local InteractionDistance = 128

	if not ai_StartInteraction("", "Destination", 500, InteractionDistance) then
		MsgQuick("", "@L_GENERAL_MEASURES_HUGCHARACTER_FAILURES_+0", GetID("Destination"))
		return
	end

	SetAvoidanceGroup("", "Destination")
	MoveSetActivity("", "converse")
	MoveSetActivity("Destination", "converse")
	SetState("", STATE_DUEL, true)
	SetState("Destination", STATE_DUEL, true)
	
	CreateCutscene("default", "cutscene")
	CutsceneAddSim("cutscene", "")
	CutsceneAddSim("cutscene", "Destination")
	CutsceneCameraCreate("cutscene", "")			
	
	-- do it
	camera_CutsceneBothLock("cutscene", "")	
	chr_MultiAnim("", "hug_male", "Destination", "hug_female", InteractionDistance, 0.6)
	SetMeasureRepeat(TimeOut)
	local WasCourtLover = 0
	
	-------------------------
	------ Court Lover ------
	-------------------------
	if (SimGetCourtLover("", "CourtLover")) then
		if GetID("CourtLover") == GetID("Destination") then
			
			WasCourtLover = 1
			local Slap = false
			
			if VariationFactor <= 0.5 then
				ModifyFavor = FavorLoss
				CourtingProgress = -5
				camera_CutscenePlayerLock("cutscene", "Destination")
				
				time1 = PlayAnimationNoWait("Destination", "shake_head")
				Sleep(time1 * 0.2)
				
				MsgSay("Destination", talk_AnswerMissingVariation(DestGender, GetSkillValue("Destination", RHETORIC)))
			else
				if (CourtingProgress < -5) then
					camera_CutsceneBothLock("cutscene", "Destination")
					chr_MultiAnim("", "got_a_slap", "Destination", "give_a_slap", InteractionDistance, 0.4)
					ModifyFavor = FavorLoss
					Slap = true
					ModifyHP("", -30, true, 10)
				elseif (CourtingProgress < 1) or Favor < MinimumFavor then
					camera_CutscenePlayerLock("cutscene", "Destination")
					PlayAnimationNoWait("Destination", "shake_head")
					ModifyFavor = FavorLoss
					if CourtingProgress > 0 then
						CourtingProgress = -1
					end
				else
					ModifyFavor = FavorWon
					camera_CutscenePlayerLock("cutscene", "Destination")
				end

				MsgSay("Destination", talk_AnswerCourtingMeasure("HUG", GetSkillValue("Destination", RHETORIC), DestGender, CourtingProgress))
			end
			
			-- Add the achieved progress
			if AliasExists("cutscene") then
				DestroyCutscene("cutscene")
			end
			
			chr_ModifyFavor("Destination", "", ModifyFavor)
			Sleep(0.3)
			feedback_OverheadCourtProgress("Destination", CourtingProgress)
			AddImpact("Destination", "ReceivedHug", 1, 3)
			gameplayformulas_CourtingProgress("", CourtingProgress) 
		end
	end
	
	----------------------------
	------ No Court Lover ------
	----------------------------
	if (WasCourtLover == 0) then
		
		local Slap = false
		local Outraged = false
		
		-- React negativ if  the favor is not high enough
		if Favor < MinimumFavor then
			if Rand(20) > 14 then
				Slap = true
			end
			ModifyFavor = FavorLoss
		elseif Rand(10) == 5 then
			Outraged = true
			ModifyFavor = FavorLoss
		elseif VariationFactor <= 0.5 then
			MsgSay("Destination", talk_AnswerMissingVariation(DestGender, GetSkillValue("Destination", RHETORIC)))
			Outraged = true
			ModifyFavor = FavorLoss
		end
		
		camera_CutsceneBothLock("cutscene", "Destination")

		if Slap then
			
			-- Set the favor here so that the player will not be able to cancel the measure if he recognizes the defeat (cheat)
			chr_ModifyFavor("Destination", "", (ModifyFavor*2))
			chr_MultiAnim("", "got_a_slap", "Destination", "give_a_slap", InteractionDistance, 1.0, true)
			MsgSay("Destination", talk_SocialMeasureFailedBeforeStart(DestGender, GetSkillValue("Destination", RHETORIC), "Slap"))
		elseif Outraged then
			
			-- Set the favor here so that the player will not be able to cancel the measure if he recognizes the defeat (cheat)
			chr_ModifyFavor("Destination", "", ModifyFavor)
			chr_MultiAnim("", "devotion", "Destination", "propel", InteractionDistance, 1.0, true)
			MsgSay("Destination", talk_SocialMeasureFailedBeforeStart(DestGender, GetSkillValue("Destination", RHETORIC), "Outraged"))
		else
			ModifyFavor = FavorWon
			chr_MultiAnim("", "bow", "Destination", "curtsy", InteractionDistance, 1.0, true)
			MsgSay("Destination", talk_AnswerCourtingMeasure("HUG", GetSkillValue("Destination", RHETORIC), DestGender, 6))
			
			-- Set the favor here so that the player will not be able to cancel the measure if he recognizes the success in order to save time (cheat)
			chr_ModifyFavor("Destination", "", ModifyFavor)
			AddImpact("Destination", "ReceivedHug", 1, 4)
			
			-- lovelevel
			if SimGetSpouse("Destination", "Spouse") then
				if (GetID("Spouse") == GetID("")) then
					AddImpact("", "LoveLevel", 1, 24) -- add some love for the next 24 hours
					AddImpact("Destination", "LoveLevel", 1, 24)
					if GetImpactValue("Destination", "LoveLevel") >= 10 then
						MsgNewsNoWait("", "Destination", "", "schedule", -1,
								"@L_FAMILY_2_COHIBITATION_FULLOFLOVE_HEAD_+0",
								"@L_FAMILY_2_COHIBITATION_FULLOFLOVE_BODY_+0", GetID("Destination"))
					end
				end
			end
		end
	end
	
	SetState("", STATE_DUEL, false)
	SetState("Destination", STATE_DUEL, false)
end

-- -----------------------
-- CleanUp
-- -----------------------
function CleanUp()
	
	if AliasExists("cutscene") then
		DestroyCutscene("cutscene")
	end
	
	ReleaseAvoidanceGroup("")
	MoveSetActivity("")
	StopAnimation("")
	SetState("", STATE_DUEL, false)
	
	if AliasExists("Destination") then
		MoveSetActivity("Destination")
		SetState("Destination", STATE_DUEL, false)
		if  GetDynastyID("") ~= GetDynastyID("Destination") then
			SimLock("Destination", 0.3)
		end
	end
end

function GetOSHData(MeasureID)
	--can be used again in:
	OSHSetMeasureRepeat("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+2", Gametime2Total(mdata_GetTimeOut(MeasureID)))
end
