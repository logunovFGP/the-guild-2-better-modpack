-------------------------------------------------------------------------------
----
----	OVERVIEW "ms_232_InviteToDance"
----
----	with this measure the player can invite an other character to a dance
----	in the tavern
----
-------------------------------------------------------------------------------

-- -----------------------
-- Run
-- -----------------------
function Run()
	
	-- The time in hours until the measure can be repeated
	local MeasureID = GetCurrentMeasureID("")
	local TimeUntilRepeat = mdata_GetTimeOut(MeasureID)
	
	-- the minimum favor of the destination sim to success
	local TitleDifference = (GetNobilityTitle("Destination") - GetNobilityTitle(""))*2
	local DexteritySkill = (GetSkillValue("", DEXTERITY))*2
	local MinimumFavor = GL_DANCE_MINFAVOR + TitleDifference - DexteritySkill
	local FavorWon = 6 + (DexteritySkill/2) + Rand(5)
	local FavorLoss = -5
	
	if FavorLoss > -5 then
		FavorLoss = -5
	end
	
	local OverallPrice = 250
	SetData("Price", OverallPrice)
	
	-- Courting related
	local CourtingProgress = gameplayformulas_GetCourtingProgress("", "Destination", MeasureID)
	local VariationFactor = gameplayformulas_GetCourtingMeasureVariation(MeasureID, "Destination") 
	
	local FlirtBonus = GetImpactValue("", "FlirtBonus")		-- 52
	FavorWon = FavorWon + FavorWon * FlirtBonus * 0.01
	CourtingProgress = CourtingProgress * (FlirtBonus * 0.01)
	
	if IsStateDriven() then

		if not AliasExists("Destination") then
			--LogMessage("InviteToDance no Destination Alias")
			if not SimGetCourtLover("", "Destination") then
				return
			end
		end

		if not GetSettlement("", "city") then
			return
		end
		
		if not CityGetNearestBuilding("city", "", -1, GL_BUILDING_TYPE_TAVERN, -1, -1, FILTER_IGNORE, "DestTavern") then
			return
		end

		if not f_MoveTo("", "DestTavern", GL_MOVESPEED_RUN) then
			return
		end
		
		--LogMessage("InviteToDance: Im here ("..GetID("").." "..GetName("")..", where are you my darling? "..GetID("Destination").." "..GetName("Destination").." ")
		
		local DesID = GetID("Destination")
		if GetDistance("Destination", "DestTavern") < 1000 then
			--LogMessage("InviteToDance: My ID: "..GetID("").." . Destination ID: "..DesID.." is in range and moves to Tavern")
			if not f_MoveTo("Destination", "DestTavern", GL_MOVESPEED_RUN) then
				--LogMessage("InviteToDance: Destination ID: "..DesID.." error move")				
				return
			end
			f_MoveTo("Destination", "")
		else
			--LogMessage("InviteToDance: My ID:. "..GetID("").." . Destination ID: "..DesID.." "..GetName("Destination").." is ported")
			GetLocatorByName("DestTavern", "Walledge1", "entry")
			SimBeamMeUp("Destination", "entry", false)
			f_MoveTo("Destination", "DestTavern", GL_MOVESPEED_RUN)
			f_MoveTo("Destination", "")
		end

		local check = true
		local WaitTime = math.mod(GetGametime(), 24) + 2
		--LogMessage("InviteToDance WaitTime for "..GetName("").." begins.")
		while check do
			Sleep(2)

			if not AliasExists("Destination") then
				StopMeasure()
				break
			end

			if math.mod(GetGametime(), 24) > WaitTime then
				--LogMessage(GetName("")..": I waited so long, now I go")
				StopMeasure()
				break
			end
			
			if GetInsideBuilding("", "Building1") and GetInsideBuilding("Destination", "Building2") then
				if (GetID("Building1") == GetID("Building2")) and (GetID("Building1") == GetID("DestTavern")) then
					if LocatorStatus("DestTavern", "Social_Dance") then
						check = false
						--LogMessage("InviteToDance: Lets dance with "..GetID("").." and "..GetID("Destination").." ")
					else
						--LogMessage("InviteToDance Locator Status error!")
					end
				else
					Sleep(5)
				end
			else
				Sleep(5)
			end
			--LogMessage(GetName("")..": InviteToDance still waiting")
			Sleep(3)
		end
	else
		if not GetInsideBuilding("", "DestTavern") then
			StopMeasure()
		end
	end
	
	-- The distance between both sims to interact with each other
	local InteractionDistance=128
	
	if not ai_StartBuildingAction("", "Destination", -1, GL_BUILDING_TYPE_TAVERN) then
		return
	end

	---------------------------------------
	------ Check dancefloor free ------
	---------------------------------------
	if not GetLocatorByName("DestTavern", "Social_Dance", "DancePos") then
		--LogMessage("Dance locator is blocked")
		MsgQuick("", "@L_TAVERN_232_INVITETODANCE_FAILURES_+0", GetID("DestTavern"))
		return
	end
	
	if not GetLocatorByName("DestTavern", "Social_Dance2", "DancePos2") then
		--LogMessage("Dance locator is blocked")
		MsgQuick("", "@L_TAVERN_232_INVITETODANCE_FAILURES_+0", GetID("DestTavern"))
		return
	end
	
	feedback_OverheadActionName("Destination")
	AlignTo("Destination", "")
	Sleep(0.5)
 	
 	MeasureSetNotRestartable()
	local WasCourtLover = 0
	--LogMessage("Dance go")
	-------------------------
	------ Court Lover ------
	-------------------------
	if SimGetCourtLover("", "CourtLover") then
		if GetID("CourtLover") == GetID("Destination") then
	--	LogMessage("Dance with my love")
			
			WasCourtLover = 1
			local ModifyFavor = FavorWon
			SetMeasureRepeat(TimeUntilRepeat)
			
			if VariationFactor <= 0.5 then
			
				local time1 = PlayAnimationNoWait("Destination", "cheer_01")
				Sleep(time1 * 0.4)
				
				feedback_OverheadCourtProgress("Destination", CourtingProgress)
				
				MsgSay("Destination", talk_AnswerMissingVariation(SimGetGender("Destination"), GetSkillValue("Destination", RHETORIC)));
			else
				local OwnerAnimation = ""
				local DestinationAnimation = ""
				
				if (CourtingProgress > 0) then
				
					-- Go to the dancefloor
					if not SendCommandNoWait("Destination", "MoveToPosition") then
						return
					end
					
					f_BeginUseLocator("", "DancePos", GL_STANCE_STAND, true)
					SetData("Dance2LocatorInUse", 1)
					
					while not HasData("DanceLocatorInUse") do
						Sleep(1)
					end
					
				--	LogMessage("Now Pay the dance")
					
					-- Pay if the tavern does not belong to the owners dynasty
					if GetDynastyID("DestTavern") ~= GetDynastyID("") then
						if not chr_SpendMoney("", 250, "CostSocial", false) then
							MsgQuick("", "@L_TAVERN_232_INVITETODANCE_FAILURES_MONEY_+0", GetID(""), 250)
							return
						end
						CreditMoney("DestTavern", 250, "Offering")
				--		local OldBalance = 0
				--		if HasProperty("Tavern", "BalanceDancingFee") then
				--			OldBalance = GetProperty("Tavern", "BalanceDancingFee")
				--		end
				--		SetProperty("Tavern", "BalanceDancingFee", (OldBalance+250))
					end	
					
					SetAvoidanceGroup("", "Destination")		
					ms_232_invitetodance_EnterCutscene()
--					camera_CutsceneBothLock("", "Destination")
					chr_MultiAnim("", "dance_social_male", "Destination", "dance_social_female", InteractionDistance)
					
				elseif (CourtingProgress < -5) then
					ms_232_invitetodance_EnterCutscene()
--					camera_CutsceneBothLock("", "Destination")
					chr_MultiAnim("", "got_a_slap", "Destination", "give_a_slap", InteractionDistance, 0.4)
					ModifyFavor = FavorLoss
				else
					ms_232_invitetodance_EnterCutscene()
--					camera_CutscenePlayerLock("", "Destination")
					chr_MultiAnim("", "talk", "Destination", "cheer_01", InteractionDistance, 0.4)
					ModifyFavor = FavorLoss
				end
				
				feedback_OverheadCourtProgress("Destination", CourtingProgress)				
				MsgSay("Destination", talk_AnswerCourtingMeasure("DANCE", GetSkillValue("Destination", RHETORIC), SimGetGender("Destination"), CourtingProgress));
				
			end
			
			-- Add the achieved progress
			f_EndUseLocatorNoWait("", "DancePos")
			f_EndUseLocatorNoWait("Destination", "DancePos2")
			chr_ModifyFavor("Destination", "", ModifyFavor)
			AddImpact("Destination", "ReceivedDance", 1, 12)
			gameplayformulas_CourtingProgress("", CourtingProgress) 
			f_ExitCurrentBuilding("Destination")
		end
	end
	
	----------------------------
	------ No Court Lover ------
	----------------------------
	if (WasCourtLover==0) then
		--LogMessage("Dance with friends")
	
		local slap = false
		local outraged = false
		SetMeasureRepeat(TimeUntilRepeat)
		
		-- React negativ if the destination married or if the favor is not high enough
		if SimGetSpouse("Destination", "Spouse") then
			if (GetID("Spouse") ~= GetID("")) then
				outraged = true
			else
				AddImpact("", "LoveLevel", 6, 24) -- add some love for the next 24 hours
				AddImpact("Destination", "LoveLevel", 6, 24)
				if GetImpactValue("Destination", "LoveLevel") >= 10 then
					MsgNewsNoWait("", "Destination", "", "schedule", -1,
								"@L_FAMILY_2_COHIBITATION_FULLOFLOVE_HEAD_+0",
								"@L_FAMILY_2_COHIBITATION_FULLOFLOVE_BODY_+0", GetID("Destination"))
				end
			end
		elseif GetFavorToSim("Destination", "") < MinimumFavor then
			if Rand(20) > 10 then
				slap = true
			end
		elseif Rand(10) == 5 then
			outraged = true
		end
		
		if slap then
			
			-- Set the favor here so that the player will not be able to cancel the measure if he recognizes the defeat (cheat)
			chr_ModifyFavor("Destination", "", FavorLoss)
			ms_232_invitetodance_EnterCutscene()
--			camera_CutsceneBothLock("", "Destination")
			chr_MultiAnim("", "got_a_slap", "Destination", "give_a_slap", InteractionDistance, 1.0, true)
			MsgSay("Destination", talk_SocialMeasureFailedBeforeStart(SimGetGender("Destination"), GetSkillValue("Destination", RHETORIC), "Slap"));
			
		elseif outraged then
			
			-- Set the favor here so that the player will not be able to cancel the measure if he recognizes the defeat (cheat)
			chr_ModifyFavor("Destination", "", FavorLoss)
			ms_232_invitetodance_EnterCutscene()
			camera_CutscenePlayerLock("", "Destination")
			chr_MultiAnim("", "devotion", "Destination", "propel", InteractionDistance, 1.0, true)
			MsgSay("Destination", talk_SocialMeasureFailedBeforeStart(SimGetGender("Destination"), GetSkillValue("Destination", RHETORIC), "Outraged"));
			
		else
			if AliasExists("cutscene") then
				DestroyCutscene("cutscene")			
			end
			
			if not SendCommandNoWait("Destination","MoveToPosition") then
				StopMeasure()
			end
			
			f_BeginUseLocator("", "DancePos", GL_STANCE_STAND, true)
			SetData("Dance2LocatorInUse", 1)
			
			while not HasData("DanceLocatorInUse") do
				Sleep(1)
			end
			
			--LogMessage("Now pay the dance")
			-- Pay if the tavern does not belong to the owners dynasty
			if GetDynastyID("DestTavern") ~= GetDynastyID("") then
				if not SpendMoney("", 250, "CostSocial") then
					MsgQuick("", "@L_TAVERN_232_INVITETODANCE_FAILURES_MONEY_+0", GetID(""), 250)
					return
				end
				CreditMoney("DestTavern", 250, "Offering")
		--		local OldBalance = 0
		--		if HasProperty("Tavern", "BalanceDancingFee") then
		--			OldBalance = GetProperty("Tavern", "BalanceDancingFee")
		--		end
		--		SetProperty("Tavern", "BalanceDancingFee", (OldBalance+250))
			end
			
			SetAvoidanceGroup("", "Destination")
			chr_MultiAnim("", "dance_social_male", "Destination", "dance_social_female", InteractionDistance)
			MsgSay("Destination", talk_AnswerCourtingMeasure("DANCE", GetSkillValue("Destination", RHETORIC), SimGetGender("Destination"), 6));
			
			-- Set the favor here so that the player will not be able to cancel the measure if he recognizes the success in order to save time (cheat)
			f_EndUseLocatorNoWait("", "DancePos")
			f_EndUseLocatorNoWait("Destination", "DancePos2")
			chr_ModifyFavor("Destination", "", FavorWon)
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
	StopAnimation("")
	ReleaseLocator("")
	ReleaseLocator("Destination")

	if IsStateDriven() then
		f_ExitCurrentBuilding("")
		MeasureRun("", nil, "DynastyIdle")
		return
	end
end

function MoveToPosition()
	
	if not f_BeginUseLocator("", "DancePos2", GL_STANCE_STAND, true) then
		StopMeasure()
	end
	
	SetData("DanceLocatorInUse", 1)
	while true do
		Sleep(4)
	end
end

function GetOSHData(MeasureID)
	--can be used again in:
	OSHSetMeasureRepeat("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+2",Gametime2Total(mdata_GetTimeOut(MeasureID)))
	OSHSetMeasureCost("@L_INTERFACE_HEADER_+6", 250)
end

function EnterCutscene()
	if not AliasExists("cutscene") then
		CreateCutscene("default", "cutscene")
		CutsceneAddSim("cutscene", "")
		CutsceneAddSim("cutscene", "Destination")
		CutsceneCameraCreate("cutscene", "")			
		camera_CutsceneBothLock("cutscene", "Destination")
	end
end
