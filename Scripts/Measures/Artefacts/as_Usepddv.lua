-------------------------------------------------------------------------------
----
----	OVERVIEW "as_Usepddv"
----
----	with this artifact, the player can decrease the lifespan of an opponent
----
-------------------------------------------------------------------------------

function Run()

	-- AI Script behavior
	if IsStateDriven() then
		local ItemName = "Pddv"
		if GetItemCount("", ItemName, INVENTORY_STD) == 0 then
			if not ai_BuyItem("", ItemName, 1, INVENTORY_STD) then
				return
			end
		end
	end

	-- Measure parameter
	local favormodify = GL_FAVOR_MOD_EPIC
	local MaxDistance = 1500
	local ActionDistance = 130
	local YearsToLive = (-3)
	local MeasureID = GetCurrentMeasureID("")
	local TimeOut = mdata_GetTimeOut(MeasureID)

	if not ai_StartInteraction("", "Destination", MaxDistance, ActionDistance, nil) then
		MsgQuick("", "_HPFZ_ARTEFAKT_ALLGEMEIN_FEHLER_+0")
		StopMeasure()
	end
	
	if GetInsideBuilding("Destination","Inside") then -- don't use indoors
		MsgQuick("", "_HPFZ_ARTEFAKT_ALLGEMEIN_FEHLER_+0")
		StopMeasure()
	end

	if RemoveItems("", "Pddv", 1) == 1 then
	
		-- initialize measure
		MeasureSetNotRestartable()
		SetMeasureRepeat(TimeOut)	
		AlignTo("", "Destination")
		AlignTo("Destination", "")
		Sleep(0.5)
		
		-- ani stuff
		GetPosition("Destination", "ParticleSpawnPos")
		PlayAnimationNoWait("Destination", "cogitate")
		CommitAction("poison", "", "Destination", "Destination")
		PlayAnimationNoWait("", "use_object_standing")
		Sleep(1)
		PlaySound3D("", "Locations/wear_clothes/wear_clothes+1.wav", 1.0)
		CarryObject("", "Handheld_Device/ANIM_Smallsack.nif", false)
		Sleep(5)
		StartSingleShotParticle("particles/smoke_medium.nif", "ParticleSpawnPos", 2.7, 5)
		PlaySound3D("", "Locations/destillery/destillery+1.wav", 1.0)		
		PlayFE("", "smile", 1, 2, 0)
		Sleep(1)
		PlayAnimationNoWait("Destination", "cough")
		if SimGetGender("Destination") == 1 then
			PlaySound3D("Destination", "CharacterFX/cough/Husten+1.wav", 1.0)
			Sleep(3)
		else
			PlaySound3D("Destination", "CharacterFX/cough/Husten+0.wav", 1.0)
			Sleep(3)
		end
		CarryObject("","",false)
		StopAction("poison","")
		PlayFE("", "anger", 1, 2, 0)
		MsgSay("Destination","_HPFZ_ARTEFAKT_PDDV_SPRUCH_+0")
		
		-- skillcheck
		if (GetSkillValue("", SHADOW_ARTS) > GetSkillValue("Destination", EMPATHY)) then	
			AddImpact("Destination", "LifeExpanding", YearsToLive, -1)
			
			MsgNewsNoWait("","Destination","","intrigue",-1,
					"@L_HPFZ_ARTEFAKT_PDDV_NUTZER_KOPF_+0",
					"@L_HPFZ_ARTEFAKT_PDDV_NUTZER_RUMPF_+0",GetID("Destination"))
			MsgNewsNoWait("Destination","","","intrigue",-1,
					"@L_HPFZ_ARTEFAKT_PDDV_OPFER_KOPF_+0",
					"@L_HPFZ_ARTEFAKT_PDDV_OPFER_RUMPF_+0",GetID(""))
					
			Sleep(1)	
		end
		chr_ModifyFavor("Destination", "", -favormodify)
	end

	StopMeasure()
end

function CleanUp()
	StopAction("poison","")
	CarryObject("","",false)
end

function GetOSHData(MeasureID)
	OSHSetMeasureRepeat("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+2",Gametime2Total(mdata_GetTimeOut(MeasureID)))
end
