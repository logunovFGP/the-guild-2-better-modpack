function Init()
	SetStateImpact("no_upgrades")
	SetStateImpact("no_enter")
end

function Run()
  	Evacuate("", false) 
	
	local FireProt = GetImpactValue("Owner", "ProtectionFromFire")
	if FireProt > 0.95 then
		FireProt = 0.95
	end
	
	-- how dangerous is the fire in general? 1 = minor; 2 = severe, 3 = dangerous, 4 = hell
	local FireLevel = 1 + Rand(2)
	if GetImpactValue("", "buildingbombedtoday") > 0 then
		FireLevel = FireLevel + 1
	end
	local Season = GetSeason()
	
	-- season may cause more damage or less
	if Season == EN_SEASON_SUMMER then
		FireLevel = FireLevel + 1
	elseif Season == EN_SEASON_WINTER then
		FireLevel = FireLevel - 1
	end
	
	-- check for rain for lesser damage
	local RainValue = Weather_GetValue(0)
	if RainValue > 0.3 then
		FireLevel = FireLevel - 1
	end
	
	if FireLevel < 1 then
		FireLevel = 1
	end
	
	-- calculate the threat
	local MaxBurnTime = FireLevel * FireLevel
	local StartTime = GetGametime()
	local MaxHP = GetMaxHP("")
	local DamagePerTick = math.ceil((MaxHP * 0.025 + 12*FireLevel) - FireProt*(MaxHP * 0.025 + 12*FireLevel))
	
	SetProperty("Owner", "BurningTime", MaxBurnTime) -- save it to property for firefighting-Measures
	CommitAction("fire", "Owner", "Owner")
	
	-- count the fire locator
	local FireLocatorCount = 1
	while GetFreeLocatorByName("Owner", "Fire"..FireLocatorCount, -1, -1, "FlameLocator"..FireLocatorCount) do
		FireLocatorCount = FireLocatorCount + 1
	end

	if FireLocatorCount > 0 then
		FireLocatorCount = FireLocatorCount
	end

	-- create the flame particles, size and position them
	local FlameCount
	for FlameCount=1, FireLocatorCount-1 do
		if AliasExists("FlameLocator"..FlameCount) then
			GfxStartParticle("Flames"..FlameCount, "particles/fire1.nif", "FlameLocator"..FlameCount, 5)
		end
	end

	local SmokeCount
	for SmokeCount=1, FireLocatorCount-1 do
		GfxStartParticle("Smoke"..SmokeCount, "particles/smoke_light.nif", "FlameLocator"..SmokeCount, 5)

	end

	-- create the spark particles, size and position them
	local SparkCount
	for SparkCount=1, FireLocatorCount-1 do
		if AliasExists("FlameLocator"..SparkCount) then
			GfxStartParticle("Spark"..SparkCount, "particles/spark1.nif", "FlameLocator"..SparkCount, 8)
		end
	end
	
	if Rand(2) == 0 then
		Attach3DSound("", "fire/Fire_01.wav", 1.0)
	else
		Attach3DSound("", "fire/Fire_l_02.wav", 1.0)
	end

	while GetGametime() < (StartTime+MaxBurnTime) do
		
		Evacuate("Owner")
		Sleep(5)
		PlaySound3D("", "fire/DartingFlame_s_02.wav", 1.0)
		
		if BuildingGetType("Owner") == GL_BUILDING_TYPE_WORKER_HOUSING then
			if GetHPRelative("Owner") >= 0.1 then
				ModifyHP("Owner", -DamagePerTick, true)
			end
		else
			ModifyHP("Owner", -DamagePerTick, true)
		end
		
		Sleep(10)
		
		-- check property for counter measures
		MaxBurnTime = GetProperty("", "BurningTime")
		
		-- fire may spread
		local BuildingFilter = "__F((Object.GetObjectsByRadius(Building) == 1500)AND NOT(Object.GetState(burning))AND NOT(Object.HasImpact(Extinguished))AND NOT(Object.IsClass(5))AND NOT(Object.IsClass(3))AND NOT(Object.IsClass(6))AND NOT(Object.IsClass(0)))"
		local NumBuildings = Find("", BuildingFilter, "NexBuilding", -1)
		local Chance = 80
		
		if (Weather_GetSeason() == 1) then -- higher chance for fire going to next building in summer
			Chance = Chance + 10
		elseif (Weather_GetSeason() == 3) then -- lower chance for fire going to next building in winter
			Chance = Chance - 5
		end

		if (Weather_GetValue(0) > 0.5) then -- weather value 0 is precipitation
			Chance = Chance - 10 -- lesser chance for fire going to next building when rain or snow
		end
		
		if NumBuildings > 0 then
			if Chance > Rand(100) then
				local DestAlias = "NexBuilding"..Rand(NumBuildings-1)
				local FireProtection = GetImpactValue(DestAlias, "ProtectionFromFire")*100
				if (Rand(100) > FireProtection) then
					if GetPosition("", "ParticleSpawnPos") then
						StartSingleShotParticle("particles/Explosion.nif", "ParticleSpawnPos", 4, 5)
						PlaySound3D(DestAlias, "fire/Explosion_s_01.wav", 1.0)
					end
					SetState(DestAlias, STATE_BURNING, true)
				end
			end
		end
		Sleep(5)
	end
	
	AddImpact("Owner", "Extinguished", 1, 8)
	SetState("Owner", STATE_BURNING, false)
end

function CleanUp()
	Detach3DSound("")
	StopAction("fire", "Owner")
	if HasProperty("Owner", "BurningTime") then
		RemoveProperty("Owner", "BurningTime")
	end
end
