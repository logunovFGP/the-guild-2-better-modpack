function Init()
	-- this is needed for stink bombs
	if IsType("", "Building") then
		SetStateImpact("no_enter")
	end
end

function Run()
	
	if IsType("", "Sim") then
	
	--perfume
		if GetImpactValue("", "perfume") == 1 then
			CommitAction("perfume", "", "")
			-- stay true as long as you have the impact on you
			while GetImpactValue("", "perfume") > 0 do
				Sleep(10)
			end
			
			-- remove everything
			StopAction("perfume", "")
		end

	--Pox
		if GetImpactValue("", "Pox") == 1 then
			-- perfume negates this effect
			if GetImpactValue("", "perfume") == 1 then
				return
			end

			CommitAction("Pox", "", "")
			-- stay true as long as you have the impact on you
			while GetImpactValue("", "Pox") > 0 do
				Sleep(10)
			end

			-- remove everything
			StopAction("Pox", "")
		end

	-- Kamm (Comb)
		if GetImpactValue("", "kamm") == 1 then
			CommitAction("kamm", "", "")
			while GetImpactValue("", "kamm") > 0 do
				Sleep(10)
			end

			-- remove everything
			StopAction("kamm", "")
		end
	
	-- thrown a stinking bomb at the ground?
		if HasProperty("", "IsStinkBomb") then
			RemoveProperty("", "IsStinkBomb")
			GetPosition("", "ParticleSpawnPos")
			PlaySound3D("", "measures/toadexcrements+0.wav", 1.0)
			StartSingleShotParticle("particles/toadexcrements_hit.nif", "ParticleSpawnPos", 6, 5)
			GfxAttachObject("stinkbomb", "Handheld_Device/ANIM_Bomb_02.nif")
			GfxSetPositionTo("stinkbomb", "ParticleSpawnPos")
			GfxMoveToPosition("stinkbomb", 0, 20, 0, 0.1, false)
			GfxStartParticle("Smoke", "particles/toadexcrements.nif", "ParticleSpawnPos", 7)
			
			while true do
				Sleep(10)
			end

			-- remove it
			if AliasExists("stinkbomb") then
				GfxDetachObject("stinkbomb")
			end

			if AliasExists("Smoke") then
				GfxStopParticle("Smoke")
			end
		end
		
		SetState("", STATE_CONTAMINATED, false)
		return
	else
	
	-- check for contaminated buildings and evacuate them

	-- polluted well
		if (BuildingGetType("") == GL_BUILDING_TYPE_WELL) then
			CommitAction("PollutedWell", "", "")
			GetPosition("", "ParticleSpawnPos")
			GfxStartParticle("Smoke", "particles/toadexcrements.nif", "ParticleSpawnPos", 4)
			
			while (GetImpactValue("", "polluted") == 1) do
				Evacuate("")
				Sleep(10)
			end
			
			StopAction("PollutedWell", "")
			SetState("", STATE_CONTAMINATED, false)
			return
		end
	
		-- toadexcrements
		-- count the fire locator
		local FireLocatorCount = 1
		while GetFreeLocatorByName("Owner", "Fire"..FireLocatorCount, -1, -1, "SmokeLocator"..FireLocatorCount) do
			FireLocatorCount = FireLocatorCount + 1
		end
		FireLocatorCount = FireLocatorCount - 1
		-- create the smoke particles, size and position them
		local SmokeCount = FireLocatorCount-1
		while(SmokeCount > 0) do
	
			GfxStartParticle("Smoke"..SmokeCount, "particles/toadexcrements.nif", "SmokeLocator"..SmokeCount, 7)
			SmokeCount = SmokeCount -1	
		end
	
		while (GetImpactValue("", "toadexcrements") == 1)  do
			Evacuate("Owner")
			Sleep(8)
		end
		
		SetState("", STATE_CONTAMINATED, false)
		return
	end
end

function CleanUp()
	
	SetState("Owner", STATE_CONTAMINATED, false)
	if HasProperty("Owner", "perfume") then
		RemoveProperty("Owner", "perfume")
	end
end

