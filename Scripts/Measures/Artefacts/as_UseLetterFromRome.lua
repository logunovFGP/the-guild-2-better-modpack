-------------------------------------------------------------------------------
----
----	OVERVIEW "as_UseLetterFromRome"
----
----	with this artifact, the player can decrease the favour of all persons in
----	range which have the same religion as the destination
----	
----
-------------------------------------------------------------------------------

function Run()
	
	if IsStateDriven() then
		local ItemName = "LetterFromRome"
		if GetItemCount("", ItemName, INVENTORY_STD) == 0 then
			if not ai_BuyItem("", ItemName, 1, INVENTORY_STD) then
				return
			end
		end
	end
	
	--how much the favor of the listeners to the destination is decreased
	local favormodify = GL_FAVOR_MOD_NORMAL
	--how much the favor from the victim to the owner is decreased
	local favorloss = GL_FAVOR_MOD_GREATER
	--how far the destination can be to start this action
	local MaxDistance = 1000
	--how far from the destination, the owner should stand while reading the letter from rome
	local ActionDistance = 350
	--the listening range. 
	local ListeningRange = 1500
	--time before artefact can be used again, in hours

	local MeasureID = GetCurrentMeasureID("")
	local TimeOut = mdata_GetTimeOut(MeasureID)
	
	if not ai_StartInteraction("", "Destination", MaxDistance, ActionDistance, nil) then
		StopMeasure()
	end
	
	Sleep(0.5)
	
	-- check inside building
	if GetInsideBuilding("Destination", "Inside") then
 		MsgBoxNoWait("", "Destination", "@L_GENERAL_ERROR_HEAD", "@L_MEASURE_USE_LETTER_FROM_ROME_ERROR_INSIDE", GetID("Destination"), GetID("Inside"))
		StopMeasure()
	end
	--look at each other
	feedback_OverheadActionName("Destination")
	AlignTo("Owner", "Destination")
	AlignTo("Destination", "Owner")
	Sleep(0.5)
	
	--Read the letter
	local Time = PlayAnimationNoWait("", "use_book_standing")
	
	Sleep(1)
	PlaySound3D("", "Locations/wear_clothes/wear_clothes+1.wav", 1.0)
	CarryObject("", "Handheld_Device/Anim_openscroll.nif", false)
	Sleep(2)
	local OwnReligion = SimGetReligion("")
	if OwnReligion == 0 then
		MsgSayNoWait("", "@L_PROCLAIM_LETTERFROMROME_CATHOLIC", GetID("Destination"))
	else
		MsgSayNoWait("", "@L_PROCLAIM_LETTERFROMROME_PROTESTANT", GetID("Destination"))
	end
	Sleep(Time+4)
	PlaySound3D("", "Locations/wear_clothes/wear_clothes+1.wav", 1.0)
	CarryObject("", "", false)
	if RemoveItems("", "LetterFromRome", 1) > 0 then
		
		if GetImpactValue("Destination", "boozybreathbeer") == 1 then	
			GetPosition("Destination", "ParticleSpawnPos")
			StartSingleShotParticle("particles/BoozyBreathBeer.nif", "ParticleSpawnPos",2.7,3)
			PlaySound3DVariation("Destination", "measures/boozybreathbeer", 1)
			feedback_OverheadComment("", "@L_INTRIGUE_055_INSULTCHARACTER_BOOZYBREATHBEER_+0", false, true)
			SetMeasureRepeat(TimeOut)
			GetFleePosition("", "Destination", 1000, "Away")
			f_MoveTo("", "Away", GL_MOVESPEED_RUN)
			
			MsgNewsNoWait("","Destination", "", "intrigue", -1,
				"@L_INTRIGUE_LETTERFROMROME_FAILED_ACTOR_HEAD_+0",
				"@L_INTRIGUE_LETTERFROMROME_FAILED_ACTOR_BODY_+0", GetID("Destination"))
			
			MsgNewsNoWait("Destination", "", "", "intrigue",-1,
				"@L_INTRIGUE_LETTERFROMROME_FAILED_VICTIM_HEAD_+0",
				"@L_INTRIGUE_LETTERFROMROME_FAILED_VICTIM_BODY_+0", GetID("Owner"),GetID("Destination"),ItemGetLabel("BoozyBreathBeer", true))			
			StopMeasure()
		end

		PlayAnimationNoWait("Destination", "appal")
		
		GetPosition("", "MyPosition")
		
		--get the religion of the destination
		local count = Find("Destination", "__F((Object.GetObjectsByRadius(Sim) == "..ListeningRange..") AND (Object.HasSameReligion(Destination)))", "Listener", -1)
		for i = 0, count-1 do 
			if (IsDynastySim("Listener"..i)) then
				feedback_MessageCharacter("Listener"..i,
					"@L_ARTEFACTS_175_USELETTERFROMROME_MSG_LISTENER_HEAD_+0",
					"@L_ARTEFACTS_175_USELETTERFROMROME_MSG_LISTENER_BODY_+0", GetID("Destination"), GetID(""), GetID("Listener"..i))
			end
			chr_ModifyFavor("Listener"..i, "Destination", -favormodify)
			Sleep(0.5)
			SendCommandNoWait("Listener"..i, "Listen")	
		end
			
		Sleep(Time-7)
	
		-- decrease favor to owner
		
		SetMeasureRepeat(TimeOut)
		
		chr_ModifyFavor("Destination", "", -favorloss)
		Sleep(1)
		chr_GainXP("", GetData("BaseXP"))

		if GetSkillValue("", SHADOW_ARTS) >= GetSkillValue("Destination", EMPATHY) then
			MsgNewsNoWait("Destination", "", "", "intrigue", -1,
			"@L_ARTEFACTS_175_USELETTERFROMROME_MSG_VICTIM_HEAD_+0",
			"@L_ARTEFACTS_175_USELETTERFROMROME_MSG_VICTIM_BODY_+0", GetID(""), GetID("Destination"))
		else 
		
			MsgNewsNoWait("Destination", "", "", "intrigue", -1,
			"@L_ARTEFACTS_175_USELETTERFROMROME_MSG_VICTIM_HEAD_+0",
			"@L_ARTEFACTS_175_USELETTERFROMROME_MSG_VICTIM_BODY_+1", GetID(""), GetID("Destination"))
			AddEvidence("Destination", "", "Destination", 10)
		end
		Sleep(5)
	end
end

-- -----------------------
-- Listen
-- -----------------------
function Listen()
	Sleep(0.5)
	AlignTo("", "Destination")
	Sleep(Rand(3) + 1)
	MsgSayNoWait("", "@L_PROCLAMATION_NEGATIVE")
	PlayAnimation("", "threat")
end


-- -----------------------
-- CleanUp
-- -----------------------
function CleanUp()
	Sleep(1)
	feedback_OverheadActionName("")
	feedback_OverheadActionName("Destination")
end

function GetOSHData(MeasureID)
	--can be used again in:
	OSHSetMeasureRepeat("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+2", Gametime2Total(mdata_GetTimeOut(MeasureID)))
	--active time: immediately
	OSHSetMeasureRuntime("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+1")
end

