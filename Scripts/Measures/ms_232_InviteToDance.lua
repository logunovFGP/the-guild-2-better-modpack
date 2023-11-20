-------------------------------------------------------------------------------
----
----	OVERVIEW "ms_232_InviteToDance"
----
----	with this measure the player can invite an other character to a dance
----	in the tavern
----
-------------------------------------------------------------------------------

-- -----------------------
-- AI Init
-- -----------------------
function AIInit()

end

-- -----------------------
-- Run
-- -----------------------
LOCATOR_DANCE = "DancePos"

function Run()
	
	-- The time in hours until the measure can be repeated
	local MeasureID = GetCurrentMeasureID("")
	local TimeOut = mdata_GetTimeOut(MeasureID)
	
	-- the minimum favor of the destination sim to success
	local TitleDifference = (GetNobilityTitle("Destination") - GetNobilityTitle(""))*2
	local MinFavor = gameplayformulas_CalcMinFavor("", "Destination", MeasureID)
	local FavorWon = gameplayformulas_CalcFavorWon("", "Destination", MeasureID)
	
	local OverallPrice = GL_DANCING_COST
	
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
	
	if IsStateDriven() then -- AI

		if not AliasExists("Destination") then
			if not SimGetCourtLover("", "Destination") then
				return
			end
		end
		
		if not CanBeInterruptetBy("Destination", "", "InviteToDance") then
			return
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
		
		-- Check if the DanceFloor is free
		if HasProperty("DestTavern", "BlockDancefloor") then
			local BlockerID = GetProperty("DestTavern", "BlockDancefloor")
			if BlockerID ~= GetID("") then
				return
			end
		else
			-- block the DanceFloor
			SetProperty("DestTavern", "BlockDancefloor", GetID(""))
		end
		
		local DesID = GetID("Destination")
		if GetDistance("Destination", "DestTavern") < 1000 then
			if not f_MoveTo("Destination", "DestTavern", GL_MOVESPEED_RUN) then
				return
			end
			f_MoveTo("Destination", "")
		else
			GetLocatorByName("DestTavern", "Walledge1", "entry")
			SimBeamMeUp("Destination", "entry", false)
			f_MoveTo("Destination", "DestTavern", GL_MOVESPEED_RUN)
			f_MoveTo("Destination", "")
		end

		local check = true
		local WaitTime = math.mod(GetGametime(), 24) + 2
		
		while check do
			Sleep(2)

			if not AliasExists("Destination") then
				check = false
				StopMeasure()
				break
			end

			if math.mod(GetGametime(), 24) > WaitTime then
				check = false
				StopMeasure()
				break
			end
			
			if GetInsideBuilding("", "Building1") and GetInsideBuilding("Destination", "Building2") then
				if (GetID("Building1") == GetID("Building2")) and (GetID("Building1") == GetID("DestTavern")) then
					if GetProperty("DestTavern", "BlockDancefloor") == GetID("") then
						check = false
					end
				end
			end
		
			Sleep(3)
		end
	else
		if not GetInsideBuilding("", "DestTavern") then
			StopMeasure()
		end
		
		-- Check if the DanceFloor is free
		if HasProperty("DestTavern", "BlockDancefloor") then
			local BlockerID = GetProperty("DestTavern", "BlockDancefloor")
			if BlockerID ~= GetID("") then
				MsgQuick("", "@L_MEASURE_INVITETODANCE_ERROR_BLOCKED_+0")
				StopMeasure()
			end
		else
			-- block the DanceFloor
			SetProperty("DestTavern", "BlockDancefloor", GetID(""))
		end
		
	end
	
	-- The distance between both sims to interact with each other
	local InteractionDistance = 128
	
	if not ai_StartBuildingAction("", "Destination", -1, GL_BUILDING_TYPE_TAVERN) then
		return
	end
		
	---------------------------------------
	------ Check dancefloor free ------
	---------------------------------------
	if not GetLocatorByName("DestTavern", "Social_Dance", LOCATOR_DANCE) or not GetLocatorByName("DestTavern", "Social_Dance2", "DancePos2") then
		MsgQuick("", "@L_TAVERN_232_INVITETODANCE_FAILURES_+0", GetID("DestTavern"))
		return
	end
		
	feedback_OverheadActionName("Destination")
	AlignTo("Destination", "")
	Sleep(0.5)
 	
 	MeasureSetNotRestartable()
	local WasCourtLover = 0
		
	-------------------------
	------ Court Lover ------
	-------------------------
	if SimGetCourtLover("", "CourtLover") then
		if GetID("CourtLover") == GetID("Destination") then
			
			WasCourtLover = 1
			SetMeasureRepeat(TimeOut)
			
			if AliasExists("DestTavern") then
				if HasProperty("DestTavern", "BlockDancefloor") then
					local BlockerID = GetProperty("DestTavern", "BlockDancefloor")
					if GetID("") == BlockerID then
						RemoveProperty("DestTavern", "BlockDancefloor")
					end
				end
			end
			
			if VariationFactor <= 0.5 then
		
				local time1 = PlayAnimationNoWait("Destination", "shake_head")
				Sleep(time1 * 0.3)
				CourtingProgress = -5
				
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
					
					f_BeginUseLocator("", LOCATOR_DANCE, GL_STANCE_STAND, true)
					SetData("Dance2LocatorInUse", 1)
					local MaxWaitTime = GetGametime() + 2
					while not HasData("DanceLocatorInUse") and GetGametime() < MaxWaitTime do
						Sleep(3)
					end
		
					-- Pay if the tavern does not belong to the owners dynasty
					if GetDynastyID("DestTavern") ~= GetDynastyID("") then
						--if not chr_SpendMoney("", OverallPrice, "CostSocial", false) then
						if GetMoney("") > OverallPrice then
							chr_SpendMoney("", OverallPrice, "CostSocial", false)
							CreditMoney("DestTavern", OverallPrice, "Offering")
						else
							MsgQuick("", "@L_TAVERN_232_INVITETODANCE_FAILURES_MONEY_+0", GetID(""), OverallPrice)
							LogMessage(GetName("") .. " cannot afford the dance, abort measure. Current money: " .. GetMoney(""))
							StopMeasure()
						end
					end	
		
					SetAvoidanceGroup("", "Destination")		
					ms_232_invitetodance_EnterCutscene()
--					camera_CutsceneBothLock("", "Destination")
					chr_MultiAnim("", "dance_social_male", "Destination", "dance_social_female", InteractionDistance)
					
				elseif (CourtingProgress < -5) then
					ms_232_invitetodance_EnterCutscene()
--					camera_CutsceneBothLock("", "Destination")
					chr_MultiAnim("", "got_a_slap", "Destination", "give_a_slap", InteractionDistance, 0.4)
				else
					ms_232_invitetodance_EnterCutscene()
--					camera_CutscenePlayerLock("", "Destination")
					chr_MultiAnim("", "talk", "Destination", "cheer_01", InteractionDistance, 0.4)
				end
				
				feedback_OverheadCourtProgress("Destination", CourtingProgress)				
				MsgSay("Destination", talk_AnswerCourtingMeasure("DANCE", GetSkillValue("Destination", RHETORIC), SimGetGender("Destination"), CourtingProgress));
				
			end
			
			-- Add the achieved progress
			if AliasExists("cutscene") then
				DestroyCutscene("cutscene")
			end
			f_EndUseLocatorNoWait("", LOCATOR_DANCE)
			f_EndUseLocatorNoWait("Destination", "DancePos2")
			
			Sleep(0.3)
			chr_ModifyFavor("Destination", "", FavorWon)
			AddImpact("Destination", "ReceivedDance", 1, 6)
			gameplayformulas_CourtingProgress("", CourtingProgress) 
			StopMeasure()
		end
	end
	
	----------------------------
	------ No Court Lover ------
	----------------------------
	if (WasCourtLover == 0) then
	
		local slap = false
		local outraged = false
		SetMeasureRepeat(TimeOut)
		
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
		elseif GetFavorToSim("Destination", "") < MinFavor then
			if Rand(20) > 10 then
				slap = true
			end
		elseif Rand(10) == 5 then
			outraged = true
		end
		
		if AliasExists("DestTavern") then
				if HasProperty("DestTavern", "BlockDancefloor") then
					local BlockerID = GetProperty("DestTavern", "BlockDancefloor")
					if GetID("") == BlockerID then
						RemoveProperty("DestTavern", "BlockDancefloor")
					end
				end
			end
		
		if slap then
			
			-- Set the favor here so that the player will not be able to cancel the measure if he recognizes the defeat (cheat)
			chr_ModifyFavor("Destination", "", FavorWon)
			ms_232_invitetodance_EnterCutscene()
--			camera_CutsceneBothLock("", "Destination")
			chr_MultiAnim("", "got_a_slap", "Destination", "give_a_slap", InteractionDistance, 1.0, true)
			MsgSay("Destination", talk_SocialMeasureFailedBeforeStart(SimGetGender("Destination"), GetSkillValue("Destination", RHETORIC), "Slap"));
			
		elseif outraged then
			
			-- Set the favor here so that the player will not be able to cancel the measure if he recognizes the defeat (cheat)
			chr_ModifyFavor("Destination", "", FavorWon)
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
			
			f_BeginUseLocator("", LOCATOR_DANCE, GL_STANCE_STAND, true)
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
			f_EndUseLocatorNoWait("", LOCATOR_DANCE)
			f_EndUseLocatorNoWait("Destination", "DancePos2")
			
			-- Set the favor here so that the player will not be able to cancel the measure if he recognizes the success in order to save time (cheat)
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
	
	if AliasExists("DestTavern") then
		if HasProperty("DestTavern", "BlockDancefloor") then
			local BlockerID = GetProperty("DestTavern", "BlockDancefloor")
			if GetID("") == BlockerID then
				RemoveProperty("DestTavern", "BlockDancefloor")
			end
		end
	end
	
	ReleaseAvoidanceGroup("")
	StopAnimation("")
	ReleaseLocator("")
	
	if (AliasExists("Destination")) then
		MoveSetActivity("Destination")
		ReleaseLocator("Destination")
		if GetDynastyID("") ~= GetDynastyID("Destination") then
			SimLock("Destination", 0.5)
		end
	end

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
	--while true do
		Sleep(10)
	--end
end

function GetOSHData(MeasureID)
	--can be used again in:
	OSHSetMeasureRepeat("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+2", Gametime2Total(mdata_GetTimeOut(MeasureID)))
	OSHSetMeasureCost("@L_INTERFACE_HEADER_+6", GL_DANCING_COST)
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
