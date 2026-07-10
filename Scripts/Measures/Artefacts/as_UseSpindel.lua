 -------------------------------------------------------------------------------
----
----	OVERVIEW "as_UseSpindel"
----
----	with this artifact, the player can make an opponent fall asleep
----
-------------------------------------------------------------------------------

function Run()

	-- AI Script behavior
	if IsStateDriven() then
		local ItemName = "Spindel"
		if GetItemCount("", ItemName, INVENTORY_STD) == 0 then
			if not ai_BuyItem("", ItemName, 1, INVENTORY_STD) then
				return
			end
		end
	end

	-- Measure parameter
	local MaxDistance = 1000
	local ActionDistance = 30
	local MeasureID = GetCurrentMeasureID("")
	local duration = mdata_GetDuration(MeasureID)
	local TimeOut = mdata_GetTimeOut(MeasureID)

	if not ai_StartInteraction("", "Destination", MaxDistance, ActionDistance, nil) then
		MsgQuick("", "_HPFZ_ARTEFAKT_ALLGEMEIN_FEHLER_+0")
		StopMeasure()
	end

	if GetItemCount("", "Spindel", INVENTORY_STD) >= 1 then
	
		-- initialize measure
		SetMeasureRepeat(TimeOut)
		MeasureSetNotRestartable()
		AlignTo("", "Destination")
		Sleep(0.5)
		
		-- ani stuff
		PlayAnimationNoWait("", "attack_middle")
		PlaySound3D("", "combat/sword/SwordDraw_s_02.wav", 1.0)
		if SimGetGender("Destination") == 1 then
			PlaySound3D("Destination", "CharacterFX/male_pain_short/male_pain_short+1.ogg", 1.0)
		else
			PlaySound3D("Destination", "CharacterFX/female_pain_short/female_pain_short+1.ogg", 1.0)
		end
		PlayAnimation("Destination", "fistfight_got_hit_04")
		Sleep(1)
		
		-- skillcheck
		if (GetSkillValue("Destination", EMPATHY) > GetSkillValue("", SHADOW_ARTS)) then
			if RemoveItems("", "Spindel", 1) ~= 1 then
				StopMeasure()
			end
			AlignTo("Destination", "")
			PlayFE("", "anger", 1, 3, 0)
			PlayAnimationNoWait("Destination", "propel")
			MsgSayNoWait("Destination", "_HPFZ_ARTEFAKT_SPINDEL_SPRUCH_+0")
			if SimGetGender("Destination") == 1 then
				PlaySound3D("Destination", "CharacterFX/male_anger/male_anger+3.ogg", 1.0)
				Sleep(3)
			else
				PlaySound3D("Destination", "CharacterFX/female_anger/female_anger+3.ogg", 1.0)
				Sleep(3)
			end
			PlayAnimationNoWait("", "devotion")
			
			-- effect
			local Rhetoric = GetSkillValue("", RHETORIC)
			local favorlost = 0
			PlayFE("", "nervous", 1, 3, 0)
			if (Rhetoric < 20) then
				MsgSay("", "_HPFZ_ARTEFAKT_SPINDEL_SPRUCH_+1")
				favorlost = GL_FAVOR_MOD_MAX
				AddEvidence("Destination", "", "Destination", 11)
			elseif (Rhetoric < 40) then
				MsgSay("", "_HPFZ_ARTEFAKT_SPINDEL_SPRUCH_+2")
				favorlost = GL_FAVOR_MOD_EPIC
				AddEvidence("Destination", "", "Destination", 11)
			elseif (Rhetoric < 60) then
				MsgSay("Owner", "_HPFZ_ARTEFAKT_SPINDEL_SPRUCH_+3")
				favorlost = GL_FAVOR_MOD_NORMAL
			elseif (Rhetoric < 80) then
				MsgSay("", "_HPFZ_ARTEFAKT_SPINDEL_SPRUCH_+4")
				favorlost = GL_FAVOR_MOD_SMALL
			else
				MsgSay("", "_HPFZ_ARTEFAKT_SPINDEL_SPRUCH_+5")
				favorlost = 0
			end
			
			Sleep(1)
			chr_ModifyFavor("Destination", "", -favorlost)
		else
			if RemoveItems("", "Spindel", 1) ~= 1 then
				StopMeasure()
			end
			SetState("Destination", STATE_HPFZ_TRAUMLAND, true)

			MsgNewsNoWait("", "Destination", "", "intrigue", -1,
						"@L_HPFZ_ARTEFAKT_SPINDEL_NUTZER_KOPF_+0",
						"@L_HPFZ_ARTEFAKT_SPINDEL_NUTZER_RUMPF_+0", GetID("Destination"))
			MsgNewsNoWait("Destination", "", "", "intrigue", -1,
						"@L_HPFZ_ARTEFAKT_SPINDEL_OPFER_KOPF_+0",
						"@L_HPFZ_ARTEFAKT_SPINDEL_OPFER_RUMPF_+0", GetID(""))

			if SimGetGender("Owner") == 1 then
				PlaySound3D("", "CharacterFX/male_joy_loop/male_joy_loop+2.ogg", 1.0)
			else
				PlaySound3D("", "CharacterFX/female_joy_loop/female_joy_loop+3.ogg", 1.0)
			end
			
			PlayAnimation("", "cheer_01")
		end

	end	
	StopMeasure()
end

function CleanUp()
    feedback_OverheadActionName("Destination")
end

function GetOSHData(MeasureID)
	OSHSetMeasureRepeat("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+2", Gametime2Total(mdata_GetTimeOut(MeasureID)))

	--active time:
	OSHSetMeasureRuntime("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+0",Gametime2Total(mdata_GetDuration(MeasureID)))
end
