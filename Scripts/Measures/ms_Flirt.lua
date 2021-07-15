-------------------------------------------------------------------------------
----
----	OVERVIEW "ms_Flirt"
----
----	With this measure the player can flirt with another sim
----
----
-------------------------------------------------------------------------------


function Run()
	
	if not AliasExists("Destination") then
		return
	end
	
	-- stop it if office session is about to begin soon
	local officetime = math.mod(GetGametime(), 24)
	if SimGetOfficeLevel("Destination") > 0 then
		if officetime > 16.6 and officetime <= 17 then
			return
		end
	end
	
	-- The time in hours until the measure can be repeated
	local MeasureID = GetCurrentMeasureID("")
	local TimeUntilRepeat = mdata_GetTimeOut(MeasureID)
	
	local OwnerGender = SimGetGender("")
	local DestGender = SimGetGender("Destination")
	
	-- The minimum favor for this action to success
	local TitleDifference = (GetNobilityTitle("Destination") - GetNobilityTitle(""))*2
	local RhetoricSkill = (GetSkillValue("", RHETORIC))*2
	local MinimumFavor = 50 + TitleDifference - RhetoricSkill
	local FavorWon = 7 + (RhetoricSkill/2)
	local FavorLoss = -10 - TitleDifference
	if FavorLoss > -5 then
		FavorLoss = -5
	end
	
	local FlirtBonus = GetImpactValue("", "FlirtBonus")		-- 52 = FlirtProfi
	FavorWon = FavorWon + FavorWon * FlirtBonus * 0.01
	
	-- The action number for the courting
	local CourtingActionNumber = 0

	-- The distance between both sims to interact with each other
	local InteractionDistance=128

	if not ai_StartInteraction("", "Destination", 500, InteractionDistance) then
		return
	end	
	
	SetAvoidanceGroup("", "Destination")
	MoveSetActivity("", "converse")
	MoveSetActivity("Destination", "converse")
	
	CreateCutscene("default","cutscene")
	CutsceneAddSim("cutscene","")
	CutsceneAddSim("cutscene","destination")
	CutsceneCameraCreate("cutscene","")			
	
	-- Actually do the flirting
	camera_CutscenePlayerLock("cutscene", "")
	MsgSay("", chr_FlirtSaying1(GetSkillValue("", RHETORIC), OwnerGender))
	camera_CutscenePlayerLock("cutscene", "Destination")
	MsgSay("Destination", chr_FlirtAnswer(GetSkillValue("Destination", RHETORIC), DestGender))
	camera_CutscenePlayerLock("cutscene", "")
	MsgSay("", chr_FlirtSaying2(GetSkillValue("", RHETORIC), OwnerGender))
	
	local WasCourtLover = 0
	
	chr_BlockSocialMeasures("")
	
	-------------------------
	------ Court Lover ------
	-------------------------
	if SimGetCourtLover("", "CourtLover") then
		if GetID("CourtLover")==GetID("Destination") then
		
			WasCourtLover = 1
			local ModifyFavor = FavorWon
		
			local EnoughVariation, CourtingProgress = SimDoCourtingAction("", CourtingActionNumber)
			if (EnoughVariation == false) then
				
				camera_CutscenePlayerLock("cutscene", "Destination")
				
				local DestinationAnimationLength = PlayAnimationNoWait("Destination", "cheer_01")
				Sleep(DestinationAnimationLength * 0.4)
				
				feedback_OverheadCourtProgress("Destination", CourtingProgress)
				MsgSay("Destination", chr_AnswerMissingVariation(DestGender, GetSkillValue("Destination", RHETORIC)))
				Sleep(DestinationAnimationLength * 0.2)
				
			else
				
				if (CourtingProgress < -5) then
					camera_CutsceneBothLock("cutscene", "Destination")
					chr_MultiAnim("", "got_a_slap", "Destination", "give_a_slap", InteractionDistance, 0.4)
					ModifyFavor = FavorLoss
				elseif (CourtingProgress < 1) then
					camera_CutscenePlayerLock("cutscene", "Destination")
					chr_MultiAnim("", "talk", "Destination", "cheer_01", InteractionDistance, 0.4)
					ModifyFavor = FavorLoss
				else
					camera_CutscenePlayerLock("cutscene", "Destination")
				end
				
				feedback_OverheadCourtProgress("Destination", CourtingProgress)				
				MsgSay("Destination", chr_AnswerCourtingMeasure("TALK", GetSkillValue("Destination", RHETORIC), DestGender, CourtingProgress))
				
			end
			
			-- Add the achieved progress
			chr_ModifyFavor("Destination", "", ModifyFavor)
			SimAddCourtingProgress("")
			
		end			
	end
		
	----------------------------
	------ No Court Lover ------
	----------------------------
	if (WasCourtLover==0) then
	
		local IsMale = (OwnerGender == GL_GENDER_MALE)
		if (GetFavorToSim("Destination", "") < MinimumFavor) then
			
			-- Set the repeat timer and the favor loss prior to the animations so that the player cannot cancel the measure and try it instantly again
			SetRepeatTimer("Destination", GetMeasureRepeatName2("Flirt"), TimeUntilRepeat)
			chr_ModifyFavor("Destination", "", FavorLoss)
			
			if (IsMale) then				
				camera_CutsceneBothLock("cutscene", "Destination")
				PlayAnimationNoWait("", "got_a_slap")
				PlayAnimationNoWait("Destination", "give_a_slap")
				chr_AlignExact("", "Destination", InteractionDistance)
			else
				camera_CutscenePlayerLock("cutscene", "Destination")
				PlayAnimationNoWait("Destination", "shake_head")
			end

			MsgSay("Destination", chr_AnswerCourtingMeasure("TALK", GetSkillValue("Destination", RHETORIC), DestGender, -10))
			
		else
			-- ToDo: Make this feature optional
			if SimGetSpouse("Destination", "Spouse") then
				if (GetID("Spouse") == GetID("")) then
					AddImpact("","LoveLevel", 3, 24) -- add some love for the next 24 hours
					AddImpact("Destination", "LoveLevel", 3, 24)
					if GetImpactValue("Destination","LoveLevel") >= 10 then
						MsgNewsNoWait("", "Destination", "", "schedule", -1,
								"@L_FAMILY_2_COHIBITATION_FULLOFLOVE_HEAD_+0",
								"@L_FAMILY_2_COHIBITATION_FULLOFLOVE_BODY_+0", GetID("Destination"))
					end
				end
			end
			
			camera_CutscenePlayerLock("cutscene", "Destination")
			
			if (IsMale) then
				PlayAnimationNoWait("Destination", "giggle")
			else
				PlayAnimationNoWait("Destination", "bow")
			end		
			
			MsgSay("Destination", chr_AnswerCourtingMeasure("TALK", GetSkillValue("Destination", RHETORIC), DestGender, 10))			
			
			-- Set the repeat timer and the favor won after the animation so that the player will not be able to cancel the measure if he recognizes the success in order to save time (cheat)
			SetRepeatTimer("", GetMeasureRepeatName2("Flirt"), TimeUntilRepeat)
			chr_ModifyFavor("Destination", "", FavorWon)
			
		end
			
	end
end

-- -----------------------
-- CleanUp
-- -----------------------
function CleanUp()
	
	DestroyCutscene("cutscene")
	ReleaseAvoidanceGroup("")
	MoveSetActivity("")
	StopAnimation("")
		
	if AliasExists("Destination") then
		MoveSetActivity("Destination")
		SimLock("Destination", 0.25)
	end		
end

function GetOSHData(MeasureID)
	--can be used again in:
	OSHSetMeasureRepeat("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+2", Gametime2Total(mdata_GetTimeOut(MeasureID)))
end

