-------------------------------------------------------------------------------
----
----	OVERVIEW "ms_057_KissCharacter"
----
----	with this measure the player can kiss a character of the other gender
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
	
	local IsMale = (SimGetGender("") == GL_GENDER_MALE) -- male charactes may get slapped
	local DestGender = SimGetGender("Destination")
	local FavorWon = gameplayformulas_CalcFavorWon("", "Destination", MeasureID)
	
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
	
	-- if Favor is below MinFavor, FavorWon will be lower than CourtingProgress and the action will be rejected
	if FavorWon < CourtingProgress then
		CourtingProgress = FavorWon
	end
	
	if CourtingProgress < 1 and FavorWon > 0 then
		FavorWon = -2
	end
	
	local VariationFactor = gameplayformulas_GetCourtingMeasureVariation(MeasureID, "Destination", Class) 
	local	time1 = 0
	
	-- The distance between both sims to interact with each other
	local InteractionDistance = 128

	if not ai_StartInteraction("", "Destination", 500, InteractionDistance) then
		return
	end

	SetAvoidanceGroup("", "Destination")
	MoveSetActivity("", "converse")
	MoveSetActivity("Destination", "converse")
	
	CreateCutscene("default", "cutscene")
	CutsceneAddSim("cutscene", "")
	CutsceneAddSim("cutscene", "Destination")
	CutsceneCameraCreate("cutscene", "")			
	
	-- do it
	camera_CutsceneBothLock("cutscene", "")
	chr_MultiAnim("", "kiss_male", "Destination", "kiss_female", InteractionDistance)
	
	local WasCourtLover = 0	
	
	-------------------------
	------ Court Lover ------
	-------------------------
	if (SimGetCourtLover("", "CourtLover")) then
		if GetID("CourtLover") == GetID("Destination") then
			
			SetMeasureRepeat(TimeOut)
			WasCourtLover = 1
			local Slap = false
			
			if CourtingProgress < FavorWon then
				FavorWon = CourtingProgress
			end
			
			if VariationFactor <= 0.5 then
				FavorWon = -1
				CourtingProgress = -5
				camera_CutscenePlayerLock("cutscene", "Destination")
				
				time1 = PlayAnimationNoWait("Destination", "propel")
				Sleep(time1 * 0.1)
				
				MsgSay("Destination", talk_AnswerMissingVariation(DestGender, GetSkillValue("Destination", RHETORIC)))
			else
				
				if (CourtingProgress < -6 and IsMale) then
					camera_CutsceneBothLock("cutscene", "Destination")
					chr_MultiAnim("", "got_a_slap", "Destination", "give_a_slap", InteractionDistance, 0.4)
					ModifyHP("", -30, true, 10)
					Slap = true
				elseif (CourtingProgress < 1) then
					camera_CutscenePlayerLock("cutscene", "Destination")
					PlayAnimationNoWait("Destination", "propel")
				else
					camera_CutscenePlayerLock("cutscene", "Destination")
				end
			
				MsgSay("Destination", talk_AnswerCourtingMeasure("KISS", GetSkillValue("Destination", RHETORIC), DestGender, CourtingProgress))
			end
			
			-- Add the achieved progress
			if AliasExists("cutscene") then
				DestroyCutscene("cutscene")
			end
			
			chr_ModifyFavor("Destination", "", FavorWon)
			Sleep(0.4)
			feedback_OverheadCourtProgress("Destination", CourtingProgress)
			AddImpact("Destination", "ReceivedKiss", 1, 3)
			gameplayformulas_CourtingProgress("", CourtingProgress) 
		end
	end
	
	----------------------------
	------ No Court Lover ------
	----------------------------
	if (WasCourtLover == 0) then
		
		SetMeasureRepeat(TimeOut*2)
		local Slap = false
		local Outraged = false
		
		-- React negativ if the destination married or if the favor is not high enough
		if SimGetSpouse("Destination", "Spouse") and not SimGetLiason("Destination", "Liason") then
			if (GetID("Spouse") ~= GetID("")) then
				Outraged = true
				FavorWon = -10
			end
		elseif FavorWon < -6 then
			if Rand(20) > 14 then
				Slap = true
			end
		elseif Rand(10) == 1 then
			Outraged = true
			if FavorWon > -1 then
				FavorWon = -5
			end
		end
		
		camera_CutsceneBothLock("cutscene", "Destination")
		SetMeasureRepeat(TimeOut)
		
		if Slap then
			
			-- Set the favor here so that the player will not be able to cancel the measure if he recognizes the defeat (cheat)
			chr_MultiAnim("", "got_a_slap", "Destination", "give_a_slap", InteractionDistance, 1.0, true)
			ModifyHP("", -30, true, 10)
			MsgSay("Destination", talk_SocialMeasureFailedBeforeStart(DestGender, GetSkillValue("Destination", RHETORIC), "Slap"))
			chr_ModifyFavor("Destination", "", FavorWon)
		elseif Outraged then
			
			-- Set the favor here so that the player will not be able to cancel the measure if he recognizes the defeat (cheat)
			chr_ModifyFavor("Destination", "", FavorWon)
			chr_MultiAnim("", "devotion", "Destination", "propel", InteractionDistance, 0.3, true)
			MsgSay("Destination", talk_SocialMeasureFailedBeforeStart(DestGender, GetSkillValue("Destination", RHETORIC), "Outraged"))
		else
			
			chr_MultiAnim("", "bow", "Destination", "curtsy", InteractionDistance, 0.3, true)
			MsgSay("Destination", talk_AnswerCourtingMeasure("KISS", GetSkillValue("Destination", RHETORIC), DestGender, 6))
			
			-- Set the favor here so that the player will not be able to cancel the measure if he recognizes the success in order to save time (cheat)
			chr_ModifyFavor("Destination", "", FavorWon)
			AddImpact("Destination", "ReceivedKiss", 1, 4)
			
			-- lovelevel
			if SimGetSpouse("Destination", "Spouse") then
				if (GetID("Spouse") == GetID("")) then
					AddImpact("", "LoveLevel", 2, 24) -- add some love for the next 24 hours
					AddImpact("Destination", "LoveLevel", 2, 24)
					if GetImpactValue("Destination", "LoveLevel") >= 10 then
						MsgNewsNoWait("", "Destination", "", "schedule", -1,
								"@L_FAMILY_2_COHIBITATION_FULLOFLOVE_HEAD_+0",
								"@L_FAMILY_2_COHIBITATION_FULLOFLOVE_BODY_+0", GetID("Destination"))
					end
				end
			end
		end
	end
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
	
	if AliasExists("Destination") then
		MoveSetActivity("Destination")
		if  GetDynastyID("") ~= GetDynastyID("Destination") then
			SimLock("Destination", 0.3)
		end
	end
end

function GetOSHData(MeasureID)
	--can be used again in:
	OSHSetMeasureRepeat("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+2", Gametime2Total(mdata_GetTimeOut(MeasureID)))
end

