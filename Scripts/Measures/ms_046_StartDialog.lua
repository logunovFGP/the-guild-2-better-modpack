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
	
	local Age = SimGetAge("Destination")
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
	
	local time1, time2 = 0, 0
	
	-- The distance between both sims to interact with each other
	local InteractionDistance = 128

	if not ai_StartInteraction("", "Destination", 800, InteractionDistance) then
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
	
	-- this will remove any question marks etc.
	feedback_OverheadActionName("Owner")
	feedback_OverheadActionName("Destination")
	AlignTo("Owner", "Destination")
	AlignTo("Destination", "Owner")
	SetMeasureRepeat(TimeOut)
	SetState("", STATE_DUEL, true) -- no cancel-cheat allowed
	
	-- hello, I need to talk to you
	MsgSay("", talk_StartDialog(IsLover, Age, DestGender));
	
	-- Does the destination want to talk?
	local Started = false
	if CurrentFavor >= MinFavor or IsLover then
		Started = true
	end
		
	MsgSay("Destination", talk_AnswerDialog(IsLover, Age, DestGender, Started));
	
	if not Started then
		IsLover = false
		ms_046_startdialog_End(Started, IsCourtLover, IsLover, MinFavor, FavorWon, CourtingProgress)
	else
		Sleep(1)
		Talk("", "Destination", true)
	
		-- sfx
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
		Sleep(1)
		
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
		
		local Positive = true
		-- Result
		if IsCourtLover or IsLover then -- need variation
			AddImpact("Destination", "ReceivedTalk", 1, 3)
			if VariationFactor <= 0.5 then
				FavorWon = -1
				CourtingProgress = -5
				
				MsgSay("Destination", talk_AnswerMissingVariation(DestGender, GetSkillValue("Destination", RHETORIC)));
				
				ms_046_startdialog_End(Started, IsCourtLover, IsLover, MinFavor, FavorWon, CourtingProgress)
			else
				Positive = (CourtingProgress > 0)
				MsgSay("Destination", talk_FavorDialog(Age, DestGender, Positive));
				ms_046_startdialog_End(Started, IsCourtLover, IsLover, MinFavor, FavorWon, CourtingProgress)
			end

		else -- social talk is harder, no need of variation
			
			Positive = (FavorWon > 0)
			MsgSay("Destination", talk_FavorDialog(Age, DestGender, Positive));
			
			-- special: get evidence
			if FavorWon >= 12 and Age >= 16 then
				-- choose a random person in the area
				if IsDynastySim("") and IsDynastySim("Destination") then
					local NumOfObjects = Find("", "__F((Object.GetObjectsByRadius(Sim) == 2000)AND(Object.IsDynastySim())AND NOT(Object.GetState(child))AND NOT(Object.GetState(npc))AND NOT(Object.GetState(animal)))","Sims",-1)

					if NumOfObjects > 0 then
						local DestAlias = "Sims"..Rand(NumOfObjects)

						--check for favor to create evidence
						if GetDynastyID(DestAlias) ~= GetDynastyID("") and GetDynastyID(DestAlias) ~= GetDynastyID("Destination") then
							if GetFavorToSim("Destination", DestAlias) < 30 then
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
									if GetDynasty("CurrentRandomSim", "CDynasty") and GetID("CDynasty") ~= GetDynastyID(DestAlias) and GetID("CDynasty") ~= GetDynastyID("") then
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
			
			ms_046_startdialog_End(Started, IsCourtLover, IsLover, MinFavor, FavorWon, CourtingProgress)
		end
	end
end

function End(Started, IsCourtLover, IsLover, MinFavor, FavorWon, CourtingProgress)
	
	if not Started then
		chr_ModifyFavor("Destination", "", FavorWon)
		
		if IsCourtLover then 
			Sleep(0.4)
			feedback_OverheadCourtProgress("Destination", CourtingProgress)
			gameplayformulas_CourtingProgress("", CourtingProgress)
		end
		
		MsgNewsNoWait("", "Destination", "", "default", -1,
					"@L_COURTLOVER_MSG_FAILED_HEAD_+0",
					"@L_SOCIAL_INTERACTION_DIALOG_FAIL_BEFORE_START_BODY_+0", GetID("Destination"), GetID(""), MinFavor)
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
	
	SetState("", STATE_DUEL, false)
	ReleaseAvoidanceGroup("")
	MoveSetActivity("")
	StopAnimation("")
	RemoveProperty("", "InTalk")
	
	if (AliasExists("Destination")) then
		RemoveProperty("Destination", "InTalk")
		MoveSetActivity("Destination")
		if GetDynastyID("") ~= GetDynastyID("Destination") and not HasData("Fail") then
			SimLock("Destination", 0.5)
		end
	end
end

function GetOSHData(MeasureID)
	mdata_ShowTalentOSH(MeasureID)
	--can be used again in:
	OSHSetMeasureRepeat("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+2", Gametime2Total(mdata_GetTimeOut(MeasureID)))
end
