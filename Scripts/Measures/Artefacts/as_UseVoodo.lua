 -------------------------------------------------------------------------------
----
----	OVERVIEW "as_UseVoodo"
----
----	with this artifact, the player can manipulate the behavior of an opponent
----
-------------------------------------------------------------------------------

function Run()

	-- AI Script behavior
	if IsStateDriven() then
		local ItemName = "Voodo"
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
	local TimeOut = mdata_GetTimeOut(MeasureID)
	local duration = mdata_GetDuration(MeasureID)
	
	if not ai_StartInteraction("", "Destination", MaxDistance, ActionDistance, nil) then
		MsgQuick("", "_HPFZ_ARTEFAKT_ALLGEMEIN_FEHLER_+0")
		return
	end

	if RemoveItems("", "Voodo", 1) == 1 then
	
		-- initialize measure
		MeasureSetNotRestartable()
		SetMeasureRepeat(TimeOut)	
		AlignTo("", "Destination")
		AlignTo("Destination", "")
		Sleep(0.5)
		
		-- ani stuff
		PlayAnimationNoWait("", "use_object_standing")
		PlayAnimationNoWait("Destination", "cogitate")
		Sleep(1)
		PlaySound3D("","Locations/wear_clothes/wear_clothes+1.wav", 1.0)
		CarryObject("", "Handheld_Device/Doll_med_01.nif", false)	
		Sleep(1)
		CarryObject("", "", false)
		CarryObject("Destination", "Handheld_Device/Doll_med_01.nif", false)
		PlayAnimationNoWait("Destination", "fetch_store_obj_R")
		Sleep(1)
		PlaySound3D("Destination", "Locations/wear_clothes/wear_clothes+1.wav", 1.0)
		CarryObject("Destination", "", false)
		PlayFE("Destination", "smile", 0.5, 2, 0)
		Sleep(1)
		MsgSay("Destination", "_HPFZ_ARTEFAKT_VODOO_SPRUCH_+0")
		
		-- skillcheck
		if (GetSkillValue("", SHADOW_ARTS) > GetSkillValue("Destination", EMPATHY)) then -- success
			local DerFluch = Rand(10)
			GetPosition("Destination", "ParticleSpawnPos")
			PlayAnimationNoWait("Destination", "watch_for_guard")
			StartSingleShotParticle("particles/light_smoke.nif", "ParticleSpawnPos", 2.7, 5)
			Sleep(1)
			PlaySound3D("", "Locations/destillery/destillery+1.wav", 1.0)
			MsgSay("Destination", "_HPFZ_ARTEFAKT_VODOO_SPRUCH_+1")
			Sleep(1)
			chr_GainXP("", GetData("BaseXP"))
			if DerFluch < 4 then
				-- make drunk
				AddImpact("Destination", "totallydrunk", 1, duration)
				AddImpact("Destination", "MoveSpeed", 0.7, duration)
				SetState("Destination", STATE_TOTALLYDRUNK, true)
				return
			elseif DerFluch < 7 then
				-- make sick
				local SickChoice = Rand(8)+1
				if SickChoice == 1 then
					diseases_giveSickness("Sprain","Destination", true, false)
				elseif SickChoice == 2 then
					diseases_giveSickness("Cold","Destination", true, false)
				elseif SickChoice == 3 then
					diseases_giveSickness("Influenza","Destination", true, false)
				elseif SickChoice == 5 then
					diseases_giveSickness("Pox","Destination", true, false)
				elseif SickChoice == 7 then
					diseases_giveSickness("Fracture","Destination", true, false)
				elseif SickChoice == 8 then
					diseases_giveSickness("Caries","Destination", true, false)
				end
				SetState("Destination", STATE_SICK, true)
			else
				-- force a fight with random npc
				local FightPartners = Find("Destination", "__F((Object.GetObjectsByRadius(Sim)==2000)AND NOT(Object.HasDynasty())AND NOT(Object.GetState(unconscious))AND NOT(Object.GetState(dead))AND(Object.CompareHP()>30))","FightPartner", -1)
				if FightPartners > 0 then
					if not BattleIsFighting(FightPartner) then
						MsgDebugMeasure("Force a Fight")
						SimStopMeasure("FightPartner0")
						StopAnimation("FightPartner0") 
						MoveStop("FightPartner0")
						AlignTo("Destination", "FightPartner0")
						AlignTo(FightPartner, "Destination")
						Sleep(1)
						PlayAnimationNoWait("Destination", "threat")
						PlayAnimation("FightPartner0", "insult_character")
						SetProperty("FightPartner0", "Berserker", 1)
						SetProperty("Destination", "Berserker", 1)
						BattleJoin("Destination", "FightPartner0", false, false)
					end
				else -- no random person found, attack user
					BattleJoin("Destination", "", false, false)
				end
			end
			
			MsgNewsNoWait("","Destination", "", "intrigue", -1,
					"@L_HPFZ_ARTEFAKT_VODOO_NUTZER_KOPF_+0",
					"@L_HPFZ_ARTEFAKT_VODOO_NUTZER_RUMPF_+0", GetID("Destination"))
			MsgNewsNoWait("Destination", "", "", "intrigue", -1,
					"@L_HPFZ_ARTEFAKT_VODOO_OPFER_KOPF_+0",
					"@L_HPFZ_ARTEFAKT_VODOO_OPFER_RUMPF_+0", GetID(""))
					
		else
			PlayAnimation("Destination", "shake_head")
			PlayAnimationNoWait("Destination", "threat")
			MsgSay("Destination", "_HPFZ_ARTEFAKT_FAIL_SPRUCH")
			
			MsgBoxNoWait("","Destination",
						"@L_HPFZ_ARTEFAKT_VODOO_FAILED_NUTZER_KOPF_+0",
						"@L_HPFZ_ARTEFAKT_VODOO_FAILED_NUTZER_RUMPF_+0", GetID("Destination"))
			MsgNewsNoWait("Destination", "", "", "intrigue", -1,
						"@L_HPFZ_ARTEFAKT_VODOO_FAILED_OPFER_KOPF_+0",
						"@L_HPFZ_ARTEFAKT_VODOO_FAILED_OPFER_RUMPF_+0", GetID(""))
			chr_ModifyFavor("Destination", "", -GL_FAVOR_MOD_NORMAL)
			AddEvidence("Destination", "Owner", "Destination", 11) -- poison
		end
	end
end

function CleanUp()

	CarryObject("", "", false)
	CarryObject("Destination", "", false)
end

function GetOSHData(MeasureID)

	OSHSetMeasureRepeat("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+2", Gametime2Total(mdata_GetTimeOut(MeasureID)))
end
