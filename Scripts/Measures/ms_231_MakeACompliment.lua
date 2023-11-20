-------------------------------------------------------------------------------
----
----	OVERVIEW "ms_231_MakeACompliment"
----
----	with this measure the player can make a compliment to another sim
----
-------------------------------------------------------------------------------

function Run()
	
	if not AliasExists("Destination") then
		return
	end
	
	-- The time in hours until the measure can be repeated
	local MeasureID = GetCurrentMeasureID("")
	local TimeOut = mdata_GetTimeOut(MeasureID)
	
	local IsMale = (SimGetGender("") == GL_GENDER_MALE) -- male charactes may get slapped
	local IsLover = false
	if SimGetSpouse("", "Spouse") and GetID("Spouse") == GetID("Destination") then
		IsLover = true
	elseif SimGetLiaison("", "Liaison") and GetID("Liaison") == GetID("Destination") then
		IsLover = true
	end
	
	local IsCourtLover = false
	if not IsLover then 
		if SimGetCourtLover("", "CourtLover") then
			if GetID("CourtLover") == GetID("Destination") then
				IsCourtLover = true
			end
		end
	end
	
	local DestGender = SimGetGender("Destination")
	local CurrentFavor = GetFavorToSim("Destination", "")
	local MinFavor = gameplayformulas_CalcMinFavor("", "Destination", MeasureID)
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
	
	if IsLover or IsCourtLover then
		if FavorWon < 0 then
			CourtingProgress = FavorWon
		end
		
		if CourtingProgress < 1 and FavorWon > 0 then
			FavorWon = -2
		end
	end
	
	local VariationFactor = gameplayformulas_GetCourtingMeasureVariation(MeasureID, "Destination", Class) -- only for courting
	local EnoughVariation = (VariationFactor > 0.5)
	
	local time1 = 0

	-- The distance between both sims to interact with each other
	local InteractionDistance = 128

	if not ai_StartInteraction("", "Destination", 800, InteractionDistance) then
		return
	end	
	
	SetAvoidanceGroup("", "Destination")
	MoveSetActivity("", "converse")
	MoveSetActivity("Destination", "converse")
	
	AlignTo("Owner", "Destination")
	AlignTo("Destination", "Owner")
	SetMeasureRepeat(TimeOut)
	
	CreateCutscene("default", "cutscene")
	CutsceneAddSim("cutscene", "")
	CutsceneAddSim("cutscene", "Destination")
	CutsceneCameraCreate("cutscene", "")			
	
	camera_CutscenePlayerLock("cutscene", "")
	
	-- hello, I need to talk to you
	MsgSay("", talk_StartCompliment(IsLover, chr_GetSkillValue("", RHETORIC), DestGender));
	
	-- Does the destination want to talk?
	local Started = false
	if CurrentFavor >= MinFavor or IsLover then
		Started = true
	end
	
	camera_CutscenePlayerLock("cutscene", "Destination")	
	MsgSay("Destination", talk_AnswerCompliment(IsLover, chr_GetSkillValue("Destination", RHETORIC), DestGender, Started));
	
	if not Started then
		IsLover = false
		ms_231_makeacompliment_End(Started, IsCourtLover, IsLover, MinFavor, FavorWon, CourtingProgress)
	else
		-- do it
		camera_CutscenePlayerLock("cutscene", "")
		MsgSay("", talk_CommitCompliment(chr_GetSkillValue("", RHETORIC), DestGender), "COMPLIMENT")
		
		-- result
		local Positive = true

		if IsCourtLover or IsLover then -- need variation
			AddImpact("Destination", "ReceivedCompliment", 1, 3)
			camera_CutscenePlayerLock("cutscene", "Destination")
			if VariationFactor <= 0.5 then
				FavorWon = -1
				CourtingProgress = -5
				
				MsgSay("Destination", talk_AnswerMissingVariation(DestGender, GetSkillValue("Destination", RHETORIC)));
				
				ms_231_makeacompliment_End(Started, IsCourtLover, IsLover, MinFavor, FavorWon, CourtingProgress)
			else
				Positive = (CourtingProgress > 0)
				
				if (CourtingProgress < -6 and IsMale) then
					camera_CutsceneBothLock("cutscene", "Destination")
					chr_MultiAnim("", "got_a_slap", "Destination", "give_a_slap", InteractionDistance, 0.4)
					ModifyHP("", -30, true, 10)
				elseif (CourtingProgress < 1) then
					camera_CutscenePlayerLock("cutscene", "Destination")
					PlayAnimationNoWait("Destination", "propel")
				else
					camera_CutscenePlayerLock("cutscene", "Destination")
				end
				
				MsgSay("Destination", talk_FavorCompliment(chr_GetSkillValue("Destination", RHETORIC), DestGender, Positive));
				ms_231_makeacompliment_End(Started, IsCourtLover, IsLover, MinFavor, FavorWon, CourtingProgress)
			end

		else -- social talk is harder, no need of variation
			camera_CutscenePlayerLock("cutscene", "Destination")
			Positive = (FavorWon > 0)
			
			if (FavorWon < -6 and IsMale) then
				camera_CutsceneBothLock("cutscene", "Destination")
				chr_MultiAnim("", "got_a_slap", "Destination", "give_a_slap", InteractionDistance, 0.4)
				ModifyHP("", -30, true, 10)
			elseif (FavorWon < 1) then
				camera_CutscenePlayerLock("cutscene", "Destination")
				PlayAnimationNoWait("Destination", "propel")
			else
				camera_CutscenePlayerLock("cutscene", "Destination")
			end
			
			MsgSay("Destination", talk_FavorCompliment(chr_GetSkillValue("Destination", RHETORIC), DestGender, Positive));
			ms_231_makeacompliment_End(Started, IsCourtLover, IsLover, MinFavor, FavorWon, CourtingProgress)
		end
	end
end

function End(Started, IsCourtLover, IsLover, MinFavor, FavorWon, CourtingProgress)
	
	if AliasExists("cutscene") then
		DestroyCutscene("cutscene")
	end
	
	if not Started then
		chr_ModifyFavor("Destination", "", FavorWon)
		
		if IsCourtLover then 
			Sleep(0.4)
			feedback_OverheadCourtProgress("Destination", CourtingProgress)
			gameplayformulas_CourtingProgress("", CourtingProgress)
		end
		
		MsgNewsNoWait("", "Destination", "", "default", -1,
					"@L_COURTLOVER_MSG_FAILED_HEAD_+0",
					"@L_SOCIAL_INTERACTION_COMPLIMENT_FAIL_BEFORE_START_BODY_+0", GetID("Destination"), GetID(""), MinFavor)
	else
		if FavorWon > 0 then -- success
			chr_ModifyFavor("Destination", "", FavorWon)
			
			if IsCourtLover then 
				Sleep(0.4)
				feedback_OverheadCourtProgress("Destination", CourtingProgress)
				gameplayformulas_CourtingProgress("", CourtingProgress)
			elseif IsLover then
				AddImpact("", "LoveLevel", 1, 24) -- add some love for the next 24 hours
				AddImpact("Destination", "LoveLevel", 1, 24)
				if GetImpactValue("Destination", "LoveLevel") >= 10 then
					MsgNewsNoWait("", "Destination", "", "schedule", -1,
								"@L_FAMILY_2_COHIBITATION_FULLOFLOVE_HEAD_+0",
								"@L_FAMILY_2_COHIBITATION_FULLOFLOVE_BODY_+0", GetID("Destination"))
				end
			end
			Sleep(0.4)
			chr_GainXP("", GL_EXP_GAIN_SIMPLE) -- gain XP for success
		else 
			chr_ModifyFavor("Destination", "", FavorWon)
			SetData("Fail", 1)
			
			if IsCourtLover then 
				Sleep(0.4)
				feedback_OverheadCourtProgress("Destination", CourtingProgress)
				gameplayformulas_CourtingProgress("", CourtingProgress)
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
	
	if (AliasExists("Destination")) then
		MoveSetActivity("Destination")
		if GetDynastyID("") ~= GetDynastyID("Destination") and not HasData("Fail") then
			SimLock("Destination", 0.5)
		end
	end
end

function GetOSHData(MeasureID)
	--can be used again in:
	OSHSetMeasureRepeat("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+2", Gametime2Total(mdata_GetTimeOut(MeasureID)))
end

