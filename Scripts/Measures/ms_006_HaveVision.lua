-------------------------------------------------------------------------------
----
----	OVERVIEW "ms_006_HaveVision"
----
----	with this measure the player can invent new artefacts
----
-------------------------------------------------------------------------------

function Run()

	if not GetInsideBuilding("", "Building") then
		StopMeasure()
	end

	local MeasureID = GetCurrentMeasureID("")
	local TimeOut = mdata_GetTimeOut(MeasureID)
	
	--check if buildmaterial is available
	if GetItemCount("", "BuildMaterial") == 0 then 	
		MsgQuick("", "@L_ALCHEMIST_006_HAVEVISION_FAILURES_+0")
		StopMeasure()
	end
	
	--check if tool is available
	if GetItemCount("", "Tool") == 0 then 	
		MsgQuick("","@L_ALCHEMIST_006_HAVEVISION_FAILURES_+1")
		StopMeasure()
	end
	
	--do the initial stuff
	if RemoveItems("", "BuildMaterial", 1) > 0 and RemoveItems("", "Tool", 1) > 0 then
		if GetRemainingInventorySpace("", "CartBooster", INVENTORY_STD) <= 0 then
			MsgQuick("", "@L_ALCHEMIST_006_HAVEVISION_FAILURES_+2")
			AddItems("", "BuildMaterial", 1)
			AddItems("", "Tool", 1)
			StopMeasure()
		end
		
		MeasureSetNotRestartable()
		SetMeasureRepeat(TimeOut)
		MeasureSetStopMode(STOP_NOMOVE)
	
		-- do the visual stuff here
		GetLocatorByName("Building", "Telescope", "MovePos")
		f_MoveTo("", "MovePos")
		PlayAnimation("", "manipulate_middle_twohand")
		PlayAnimation("", "cogitate")
		
		for i=1, 3 do
			GetLocatorByName("Building", "ThinkPos"..i, "MovePos")
			f_MoveTo("", "MovePos")
			Sleep(1)
			if Rand(100)> 60 then
				PlayAnimation("", "cogitate")
			else
				PlayAnimation("", "shake_head")
			end
			Sleep(1)
		end
	
		GetPosition("", "ParticleSpawnPos")
		StartSingleShotParticle("particles/pray_glow.nif", "ParticleSpawnPos", 2, 15)
		PlayAnimation("", "nod")
	
		--do the vision stuff
		local EvocationSkill = GetSkillValue("", SECRET_KNOWLEDGE) * 10
		local CurrentTime = math.mod(GetGametime(),24)
		local EvocationChance = Rand(150)
		
		if (CurrentTime >= 22) and (CurrentTime <= 5) then
			EvocationSkill = EvocationSkill * 2
		end
		
		if Weather_GetValue(1) < 0.5 then
			EvocationChance = EvocationChance - 25
		end
	
		--vision successful
		if EvocationSkill > EvocationChance then
			local ItemChoice = Rand(7)
			local ItemToGet
		
			if ItemChoice == 0 then
				ItemToGet = "Blissstone"
			elseif ItemChoice == 1 then
				ItemToGet = "CartBooster"
			elseif ItemChoice == 2 then
				ItemToGet = "BoobyTrap"
			elseif ItemChoice == 3 then
				ItemToGet = "CrossOfProtection"
			elseif ItemChoice == 4 then
				ItemToGet = "Mace"
			elseif ItemChoice == 5 then
				ItemToGet = "StaffOfAesculap"
			elseif ItemChoice == 6 then
				ItemToGet = "Kamm"
			end
		
			AddItems("", ItemToGet, 1, INVENTORY_STD)
			chr_GainXP("", GetData("BaseXP"))
			achievements_Unlock("", "MISC_HAVE_VISION")
			feedback_MessageWorkshop("","@L_ALCHEMIST_006_HAVEVISION_START_HEAD_+0",
								"@L_ALCHEMIST_006_HAVEVISION_START_BODY_+0", ItemGetLabel(ItemToGet, 1))
		--vision failed
		else
			StartSingleShotParticle("particles/toadexcrements_hit.nif", "ParticleSpawnPos", 3, 5)
			feedback_MessageWorkshop("", "@L_ALCHEMIST_006_HAVEVISION_END_HEAD_+0",
								"@L_ALCHEMIST_006_HAVEVISION_END_BODY_+0")
		end
	end
end

function AIDecide()

	local NumItems = GetData("NumItems")
	return "A"..NumItems
end

function CleanUp()
	MsgMeasure("","")
end

function GetOSHData(MeasureID)
	--can be used again in:
	OSHSetMeasureRepeat("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+2", Gametime2Total(mdata_GetTimeOut(MeasureID)))
end

