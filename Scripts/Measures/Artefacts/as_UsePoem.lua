-------------------------------------------------------------------------------
----
----	OVERVIEW "as_192_UsePoem"
----
----	with this artifact, the player can increase the favour of the destination
----	if the title of the destination is not too high
----	same gender will not raise.
----	
----
-------------------------------------------------------------------------------

function Run()

	if IsStateDriven() then
		local ItemName = "Poem"
		if GetItemCount("", ItemName, INVENTORY_STD) == 0 then
			if not ai_BuyItem("", ItemName, 1, INVENTORY_STD) then
				return
			end
		end
	end

	--how much the favor of the destination to the owner is increased
	local favormodify = GL_FAVOR_MOD_SMALL + GetSkillValue("", RHETORIC)
	--how far the victim can be to start this action
	local MaxDistance = 800
	--how far from the destination, the owner should stand while reading the poem
	local ActionDistance = 80
	
	local MeasureID = GetCurrentMeasureID("")
	local TimeOut = mdata_GetTimeOut(MeasureID)
	
	if (SimGetGender("Owner") == SimGetGender("Destination")) then
		MsgQuick("", "@L_GIVEAPOEM_MESSAGE_FAILURES_+0")
		StopMeasure()
	end

	if GetNobilityTitle("Destination") > (GetNobilityTitle("Owner")+2) then
		MsgQuick("", "@L_GIVEAPOEM_MESSAGE_FAILURES_+1", GetID("Destination"))
		StopMeasure()
	end
	
	-- get target outside of the current building if building is a worker hut or residence
	if not CanBeInterruptetBy("Destination", "", "UsePoem") then
		return
	end
	
	if GetInsideBuilding("Destination", "DestBuilding") then
		if BuildingGetType("DestBuilding") == GL_BUILDING_TYPE_WORKER_HOUSING or BuildingGetType("DestBuilding") == GL_BUILDING_TYPE_RESIDENCE then
			GetOutdoorMovePosition("", "DestBuilding", "MovePos")
			if not f_MoveTo("", "MovePos", GL_MOVESPEED_RUN, 600) then
				StopMeasure()
			end
			BlockChar("Destination")
			f_ExitCurrentBuilding("Destination")
			Sleep(1)
			f_MoveTo("Destination", "Owner", GL_MOVESPEED_RUN, 300)
		end
	end
	
	if not ai_StartInteraction("", "Destination", MaxDistance, ActionDistance, nil) then
		StopMeasure()
	end
	
	--look at each other
	feedback_OverheadActionName("Destination")
	AlignTo("Owner", "Destination")
	AlignTo("Destination", "Owner")
	Sleep(0.5)
	
	local InLove = false
	local DesID = GetID("Destination")
	
	if not SimGetSpouse("", "Spouse") and not SimGetLiaison("", "Liaison") and not SimGetCourtLover("", "CourtLover") then
		InLove = true
	end
	
	if not InLove then
		if AliasExists("Spouse") and GetID("Spouse") == DesID then
			InLove = true
		elseif AliasExists("Liaison") and GetID("Liaison") == DesID then
			InLove = true
		elseif AliasExists("CourtLover") and GetID("CourtLover") == DesID then
			InLove = true
		end
	end

	--read the poem
	if GetItemCount("", "Poem", INVENTORY_STD) > 0 then
		SetMeasureRepeat(TimeOut)
		local Time = PlayAnimationNoWait("", "use_book_standing")
		PlayAnimationNoWait("Destination", "cogitate")
		Sleep(1)
		PlaySound3D("", "Locations/wear_clothes/wear_clothes+1.wav", 1.0)
		CarryObject("", "Handheld_Device/Anim_openscroll.nif", false)
		Sleep(1)
		MsgSayNoWait("", talk_SpeakPoem(SimGetGender("Destination"), InLove))
		Sleep(Time-3)
		PlaySound3D("", "Locations/wear_clothes/wear_clothes+1.wav", 1.0)
		CarryObject("", "", false)

		if RemoveItems("", "Poem", 1) ~= 1 then
			StopMeasure()
		end
		--modify the favor
		chr_ModifyFavor("Destination", "", favormodify)
		-- add progress
		if AliasExists("CourtLover") and GetID("CourtLover") == DesID then
			feedback_OverheadCourtProgress("Destination", favormodify)
			gameplayformulas_CourtingProgress("", favormodify) 
		end
		
		-- lovelevel
		if SimGetSpouse("Destination", "Spouse") then
			if (GetID("Spouse") == GetID("")) then
				AddImpact("", "LoveLevel", 4, 24) -- add some love for the next 24 hours
				AddImpact("Destination", "LoveLevel", 4, 24)
				if GetImpactValue("Destination", "LoveLevel") >= 10 then
					MsgNewsNoWait("", "Destination", "", "schedule", -1,
								"@L_FAMILY_2_COHIBITATION_FULLOFLOVE_HEAD_+0",
								"@L_FAMILY_2_COHIBITATION_FULLOFLOVE_BODY_+0", GetID("Destination"))
				end
			end
		end
		
		local CurrentSimGender = SimGetGender("Destination")
		if CurrentSimGender == GL_GENDER_FEMALE then
			PlayAnimation("Destination", "curtsy")
		else
			PlayAnimation("Destination", "bow")
		end
	
		if (IsDynastySim("Destination") and IsPartyMember("Destination") and GetDynastyID("") ~= GetDynastyID("Destination")) then
			MsgNewsNoWait("Destination", "", "", "intrigue", -1,
						"@L_ARTEFACTS_192_USEPOEM_MSG_VICTIM_HEAD_+0",
						"@L_ARTEFACTS_192_USEPOEM_MSG_VICTIM_BODY_+0", GetID("Destination"), GetID(""))
		end
	
		chr_GainXP("", GetData("BaseXP"))
		chr_GainXP("Destination", GetData("BaseXP"))
		
		Sleep(1)
	end
end

-- -----------------------
-- CleanUp
-- -----------------------
function CleanUp()
	feedback_OverheadActionName("Destination")
end

function GetOSHData(MeasureID)
	--can be used again in:
	OSHSetMeasureRepeat("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+2", Gametime2Total(mdata_GetTimeOut(MeasureID)))
end

