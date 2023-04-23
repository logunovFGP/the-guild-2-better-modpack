-------------------------------------------------------------------------------
----
----	OVERVIEW "ms_053_Flirt"
----
----	With this measure the player can flirt with another sim
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
	camera_CutscenePlayerLock("cutscene", "")
	MsgSay("", talk_FlirtSaying1(GetSkillValue("", RHETORIC), OwnerGender))
	camera_CutscenePlayerLock("cutscene", "Destination")
	MsgSay("Destination", talk_FlirtAnswer(GetSkillValue("Destination", RHETORIC), DestGender))
	camera_CutscenePlayerLock("cutscene", "")
	MsgSay("", talk_FlirtSaying2(GetSkillValue("", RHETORIC), OwnerGender))
	
	local WasCourtLover = 0
	
	-------------------------
	------ Court Lover ------
	-------------------------
	if SimGetCourtLover("", "CourtLover") then
		if GetID("CourtLover") == GetID("Destination") then
			
			SetMeasureRepeat(TimeOut) -- set normal timeout for courtlover
			WasCourtLover = 1
			local Slap = false
		
			if VariationFactor <= 0.5 then

				CourtingProgress = -5
				FavorWon = -1
				
				camera_CutscenePlayerLock("cutscene", "Destination")
				time1 = PlayAnimationNoWait("Destination", "shake_head")
				Sleep(time1 * 0.2)
				
				MsgSay("Destination", talk_AnswerMissingVariation(DestGender, GetSkillValue("Destination", RHETORIC)))
			else
				if (CourtingProgress < -6 and IsMale) then
					camera_CutsceneBothLock("cutscene", "Destination")
					chr_MultiAnim("", "got_a_slap", "Destination", "give_a_slap", InteractionDistance, 0.4)
					Slap = true
					ModifyHP("", -30, true, 10)
				elseif (CourtingProgress < 1) then
					camera_CutscenePlayerLock("cutscene", "Destination")
					PlayAnimationNoWait("Destination", "propel")
				else
					camera_CutscenePlayerLock("cutscene", "Destination")
				end
				
				MsgSay("Destination", talk_AnswerCourtingMeasure("TALK", GetSkillValue("Destination", RHETORIC), DestGender, CourtingProgress))
			end
			
			-- Add the achieved progress
			if AliasExists("cutscene") then
				DestroyCutscene("cutscene")
			end
			
			chr_ModifyFavor("Destination", "", FavorWon)
			Sleep(0.4)
			feedback_OverheadCourtProgress("Destination", CourtingProgress)
			AddImpact("Destination", "ReceivedFlirt", 1, 3)
			gameplayformulas_CourtingProgress("", CourtingProgress) 
		end			
	end
		
	----------------------------
	------ No Court Lover ------
	----------------------------
	if (WasCourtLover == 0) then
		
		SetMeasureRepeat(TimeOut*2) -- double cooldown if no courtlover
		local Slap = false
		
		if FavorWon < 0 then
			if (IsMale and FavorWon < -5) then				
				camera_CutsceneBothLock("cutscene", "Destination")
				PlayAnimationNoWait("", "got_a_slap")
				PlayAnimationNoWait("Destination", "give_a_slap")
				chr_AlignExact("", "Destination", InteractionDistance)
				Slap = true
				Sleep(0.1)
				ModifyHP("", -30, true, 10)
			else
				camera_CutscenePlayerLock("cutscene", "Destination")
				PlayAnimationNoWait("Destination", "shake_head")
			end

			MsgSay("Destination", talk_AnswerCourtingMeasure("TALK", GetSkillValue("Destination", RHETORIC), DestGender, -10))
			
		else
			camera_CutscenePlayerLock("cutscene", "Destination")
			
			if (IsMale) then
				PlayAnimationNoWait("Destination", "giggle")
			else
				PlayAnimationNoWait("Destination", "bow")
			end		
			
			MsgSay("Destination", talk_AnswerCourtingMeasure("TALK", GetSkillValue("Destination", RHETORIC), DestGender, 10))			
			AddImpact("Destination", "ReceivedFlirt", 1, 4)
			
			-- ToDo: Make this feature optional
			if SimGetSpouse("Destination", "Spouse") then
				if (GetID("Spouse") == GetID("")) then
					AddImpact("","LoveLevel", 2, 24) -- add some love for the next 24 hours
					AddImpact("Destination", "LoveLevel", 2, 24)
					if GetImpactValue("Destination","LoveLevel") >= 10 then
						MsgNewsNoWait("", "Destination", "", "schedule", -1,
									"@L_FAMILY_2_COHIBITATION_FULLOFLOVE_HEAD_+0",
									"@L_FAMILY_2_COHIBITATION_FULLOFLOVE_BODY_+0", GetID("Destination"))
					end
				end
			end
		end
		
		chr_ModifyFavor("Destination", "", FavorWon)
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

