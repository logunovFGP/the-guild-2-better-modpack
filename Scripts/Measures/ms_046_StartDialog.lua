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
	
	-- The minimum favor for this action to success
	local TitleDifference = (GetNobilityTitle("Destination") - GetNobilityTitle(""))*2
	local RhetoricSkill = GetSkillValue("", RHETORIC)
	local MinimumFavor = GL_STARTDIALOG_MINFAVOR + TitleDifference - RhetoricSkill
	local Favor = 0
	if SimGetSpouse("", "Spouse") and GetID("Destination") == GetID("Spouse") then
		Favor = 100
	else
		Favor = GetFavorToSim("Destination", "")
	end
	local FavorWon = 5 + (RhetoricSkill * 0.5)
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
	
	local time1, time2 = 0, 0
	
	local FlirtBonus = GetImpactValue("", "FlirtBonus") -- ability
	FavorWon = FavorWon * (1 + FlirtBonus)
	CourtingProgress = CourtingProgress * (1 + FlirtBonus)
	
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

	-- Destination doesn't want to talk
	if Favor < MinimumFavor then
		TimeOut = TimeOut * 2
		SetMeasureRepeat(TimeOut)
		MsgSay("Destination", "@L_STARTDIALOG_NO")
		chr_ModifyFavor("Destination","", FavorLoss)
		Sleep(0.3)
		MsgSay("", "@L_STARTDIALOG_SORRY")
		return
	end
	
	feedback_OverheadActionName("Owner")
	feedback_OverheadActionName("Destination")
	AlignTo("Owner", "Destination")
	AlignTo("Destination", "Owner")
	SetMeasureRepeat(TimeOut)
	Sleep(1)
	Talk("", "Destination", true)

	if SimGetGender("") == GL_GENDER_MALE then
		if (Favor >= MinimumFavor) then
			PlaySound3DVariation("", "CharacterFX/male_friendly", 0.5)
		else
			PlaySound3DVariation("", "CharacterFX/male_neutral", 0.5)
		end
	else
		if (Favor >= MinimumFavor) then
			PlaySound3DVariation("", "CharacterFX/female_friendly", 0.5)
		else
			PlaySound3DVariation("", "CharacterFX/female_neutral", 0.5)
		end
	end
	
	time1 = PlayAnimationNoWait("Owner", "talk")
	Sleep(0.7)
	
	if DestGender == GL_GENDER_MALE then
  		if (Favor >= MinimumFavor) then
			PlaySound3DVariation("Destination", "CharacterFX/male_friendly", 0.5)
		else
			PlaySound3DVariation("Destination", "CharacterFX/male_neutral", 0.5)
		end
	else
  		if (Favor >= MinimumFavor) then
			PlaySound3DVariation("Destination", "CharacterFX/female_friendly",0.5)
		else
			PlaySound3DVariation("Destination", "CharacterFX/female_neutral", 0.5)
		end
	end

	time2 = PlayAnimation("Destination", "talk")

	-------------------------
	------ Court Lover ------
	-------------------------

	if SimGetCourtLover("", "CourtLover") then
		if GetID("CourtLover") == GetID("Destination") then

			MoveSetActivity("", "converse")
			MoveSetActivity("Destination", "converse")

	--		camera_CutscenePlayerLock("cutscene", "Destination")

			if VariationFactor <= 0.5 then
				ModifyFavor = FavorLoss
				CourtingProgress = -5
				MsgSay("Destination", talk_AnswerMissingVariation(SimGetGender("Destination"), GetSkillValue("Destination", RHETORIC)));
			else
				ModifyFavor = FavorWon
				MsgSay("Destination", talk_AnswerCourtingMeasure("TALK", GetSkillValue("Destination", RHETORIC), SimGetGender("Destination"), CourtingProgress));
			end

			Sleep(3.0)
			
			-- Add the achieved progress
			if AliasExists("cutscene") then
				DestroyCutscene("cutscene")
			end
			chr_ModifyFavor("Destination", "", ModifyFavor)
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
	
	-- Postiv
	if VariationFactor > 0.5 and (Favor >= MinimumFavor or chr_SkillCheck("", RHETORIC, 2, "Destination", RHETORIC)) then
		
		if Favor < 100 then 
			chr_ModifyFavor("Destination", "", ModifyFavor)
		end
		
        	if Age < 16 then
			MsgSay("Destination", "@L_STARTDIALOG_FAVOR_POS_YOUNG")
		else
			MsgSay("Destination", "@L_STARTDIALOG_FAVOR_POS_ADULT")
		end

		AddImpact("Destination", "ReceivedTalk", 1, 4)
		
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
		
		if Favor < 100 then
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
		ModifyFavor = FavorLoss
		chr_ModifyFavor("Destination", "", ModifyFavor)

		if Age < 16 then
			MsgSay("Destination", "@L_STARTDIALOG_FAVOR_NEG_YOUNG")
		else
 			MsgSay("Destination", "@L_STARTDIALOG_FAVOR_NEG_ADULT")
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
