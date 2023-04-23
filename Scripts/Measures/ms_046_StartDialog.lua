-------------------------------------------------------------------------------
----
----	OVERVIEW "ms_046_StartDialog"
----
----	with this measure the player can start a dialog with another sim
----
-------------------------------------------------------------------------------

-- -----------------------
-- Run
-- -----------------------

function Run()
	
	if not AliasExists("Destination") then

		local TalkPartners = Find("", "__F((Object.GetObjectsByRadius(Sim)==1200)AND(Object.IsDynastySim())AND NOT(Object.GetState(npc))AND NOT(Object.GetState(animal))AND NOT(Object.GetStateImpact(no_idle))AND(Object.CanBeInterrupted(StartDialog)))","Destination", -1)
		
		if (TalkPartners == 0) then
			return
		end
		
		CopyAlias("Destination"..Rand(TalkPartners), "Destination")
	end
	
	-- The time in hours until the measure can be repeated
	local MeasureID = GetCurrentMeasureID("")
	local TimeOut = mdata_GetTimeOut(MeasureID)
	
	local DestGender = SimGetGender("Destination")
	local Age = SimGetAge("Destination")
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
	local time1, time2 = 0, 0
	
	-- The distance between both sims to interact with each other
	local InteractionDistance = 128

	if not ai_StartInteraction("", "Destination", 500, InteractionDistance) then
		return
	end
	
	-- for tutorial
	if not IsMultiplayerGame() then
		-- only a player should be able to start a quests
		if GetLocalPlayerDynasty("LocalPlayer") then
			if GetID("LocalPlayer") == GetID("dynasty") then
				if (QuestTalk("", "Destination")) then
					return
				end		
			elseif GetState("Destination", STATE_NPC) then
				return
			end
		end
	end

	SetProperty("", "InTalk", 1)
	SetProperty("Destination", "InTalk", 1)
	SetAvoidanceGroup("", "Destination")
	MoveSetActivity("", "converse")
	MoveSetActivity("Destination", "converse")
	
	-- dialog related
	local ReplaceAge = ""
	local ReplaceGender = ""
	
	if DestGender == GL_GENDER_MALE then
		ReplaceGender = "MALE"
	else
		ReplaceGender = "FEMALE"
	end
	
	if Age < 16 then
		ReplaceAge = "YOUNG"
	else
		ReplaceAge = "ADULT"
	end
	
	-- hello, I need to talk to you
	MsgSay("", "@L_STARTDIALOG_START_"..ReplaceAge.."_"..ReplaceGender)
	
	feedback_OverheadActionName("Owner")
	feedback_OverheadActionName("Destination")
	AlignTo("Owner", "Destination")
	AlignTo("Destination", "Owner")
	Sleep(1)
	Talk("", "Destination", true)
	
	local Friendly = false
	if FavorWon >= 10 then
		Friendly = true
	end
	
	if SimGetGender("") == GL_GENDER_MALE then
		if Friendly then
			PlaySound3DVariation("", "CharacterFX/male_friendly", 0.5)
		else
			PlaySound3DVariation("", "CharacterFX/male_neutral", 0.5)
		end
	else
		if Friendly then
			PlaySound3DVariation("", "CharacterFX/female_friendly", 0.5)
		else
			PlaySound3DVariation("", "CharacterFX/female_neutral", 0.5)
		end
	end
	
	time1 = PlayAnimationNoWait("Owner", "talk")
	Sleep(0.7)
	
	if DestGender == GL_GENDER_MALE then
  		if Friendly then
			PlaySound3DVariation("Destination", "CharacterFX/male_friendly", 0.5)
		else
			PlaySound3DVariation("Destination", "CharacterFX/male_neutral", 0.5)
		end
	else
  		if Friendly then
			PlaySound3DVariation("Destination", "CharacterFX/female_friendly",0.5)
		else
			PlaySound3DVariation("Destination", "CharacterFX/female_neutral", 0.5)
		end
	end

	time2 = PlayAnimation("Destination", "talk")
	local WasCourtLover = false
	-------------------------
	------ Court Lover ------
	-------------------------

	if SimGetCourtLover("", "CourtLover") then
		if GetID("CourtLover") == GetID("Destination") then
			
			WasCourtLover = true
			SetMeasureRepeat(TimeOut)
			
			if CourtingProgress < FavorWon then
				FavorWon = CourtingProgress
			end
			
			MoveSetActivity("", "converse")
			MoveSetActivity("Destination", "converse")

	--		camera_CutscenePlayerLock("cutscene", "Destination")

			if VariationFactor <= 0.5 then
				FavorWon = -1
				CourtingProgress = -5
				MsgSay("Destination", talk_AnswerMissingVariation(SimGetGender("Destination"), GetSkillValue("Destination", RHETORIC)));
			else
				MsgSay("Destination", talk_AnswerCourtingMeasure("TALK", GetSkillValue("Destination", RHETORIC), SimGetGender("Destination"), CourtingProgress));
			end

			Sleep(0.4)
			
			-- Add the achieved progress
			if AliasExists("cutscene") then
				DestroyCutscene("cutscene")
			end
			
			chr_ModifyFavor("Destination", "", FavorWon)
			Sleep(0.3)
			feedback_OverheadCourtProgress("Destination", CourtingProgress)
			AddImpact("Destination", "ReceivedTalk", 1, 3)
			gameplayformulas_CourtingProgress("", CourtingProgress) 
		end
		return
	end

	----------------------------
	------ No Court Lover ------
	----------------------------
	if not WasCourtLover then
	
		SetMeasureRepeat(TimeOut*2)
		
		-- Postiv
		if FavorWon > 0 then
			
			chr_ModifyFavor("Destination", "", FavorWon)
			
			if Age < 16 then
				MsgSay("Destination", "@L_STARTDIALOG_FAVOR_POS_YOUNG")
			else
				MsgSay("Destination", "@L_STARTDIALOG_FAVOR_POS_ADULT")
			end
			
			if SimGetSpouse("Destination", "Spouse") then
				if (GetID("Spouse") == GetID("")) then
					AddImpact("", "LoveLevel", 1, 24) -- add some love for the next 24 hours
					AddImpact("Destination","LoveLevel", 1, 24)
					if GetImpactValue("Destination", "LoveLevel") >= 10 then
						MsgNewsNoWait("", "Destination", "", "schedule", -1,
								"@L_FAMILY_2_COHIBITATION_FULLOFLOVE_HEAD_+0",
								"@L_FAMILY_2_COHIBITATION_FULLOFLOVE_BODY_+0", GetID("Destination"))
					end
				end
			end
			
			if FavorWon >= 10 then
				-- Zufällige Person aus der Umgebung auswählen
				if IsDynastySim("") and IsDynastySim("Destination") then
					local NumOfObjects = Find("", "__F((Object.GetObjectsByRadius(Sim) == 2000)AND(Object.IsDynastySim())AND NOT(Object.GetState(child))AND NOT(Object.GetState(npc))AND NOT(Object.GetState(animal)))","Sims",-1)

					if NumOfObjects > 0 then
						local DestAlias = "Sims"..Rand(NumOfObjects)

						--check for favor to create evidence
						if GetDynastyID(DestAlias) ~= GetDynastyID("") and GetDynastyID(DestAlias) ~= GetDynastyID("Destination") then
							if GetFavorToSim("Destination", DestAlias) < 20 or GetFavorToSim("", DestAlias) < 20 then
								MsgSay("Destination", "@L_STARTDIALOG_EVIDENCE")

								local Random = Rand(11)
								if Random == 0 then
									Evidence = 1
								elseif Random == 1 then
									Evidence = 4
								elseif Random == 2 then
									Evidence = 7
								elseif Random == 3 then
									Evidence = 10
								elseif Random == 4 then
									Evidence = 11
								elseif Random == 5 then
									Evidence = 12
								elseif Random == 6 then
									Evidence = 13
								elseif Random == 7 then
									Evidence = 14
								elseif Random == 8 then
									Evidence = 15
								else
									Evidence = 18
								end

								-- create victim
								while true do
									ScenarioGetRandomObject("cl_Sim", "CurrentRandomSim")
									if GetDynasty("CurrentRandomSim", "CDynasty") and GetID("CDynasty") ~= GetDynastyID(DestAlias) then
										CopyAlias("CurrentRandomSim", "EvidenceVictim")
										break
									end
								end

								AddEvidence("", DestAlias, "EvidenceVictim", Evidence, "Destination", DestAlias)
								MsgSay("", "@L_STARTDIALOG_THX")
							end
						end
					end
				end
			end
		else

			-- Negative
			chr_ModifyFavor("Destination", "", FavorWon)

			if Age < 16 then
				MsgSay("Destination", "@L_STARTDIALOG_FAVOR_NEG_YOUNG")
			else
				MsgSay("Destination", "@L_STARTDIALOG_FAVOR_NEG_ADULT")
			end
		end
	end
end

-- -----------------------
-- CleanUp
-- -----------------------
function CleanUp()

	ReleaseAvoidanceGroup("")
	MoveSetActivity("")
	StopAnimation("")
	RemoveProperty("", "InTalk")
	
	if (AliasExists("Destination")) then
		RemoveProperty("Destination", "InTalk")
		MoveSetActivity("Destination")
		if GetDynastyID("") ~= GetDynastyID("Destination") then
			SimLock("Destination", 0.3)
		end
	end
end

function GetOSHData(MeasureID)
	--can be used again in:
	OSHSetMeasureRepeat("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+2", Gametime2Total(mdata_GetTimeOut(MeasureID)))
end
