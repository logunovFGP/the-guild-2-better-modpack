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
	
	local MaxHP = GetMaxHP("")
	local RandomFire = 25 + Rand(7)*10
	local Season = GetSeason()
	
	-- season may cause more damage or less
	if Season == EN_SEASON_SUMMER then
		RandomFire = RandomFire + 20
	elseif Season == EN_SEASON_WINTER then
		RandomFire = RandomFire - 10
	end
	
	-- check for rain for lesser damage
	local RainValue = Weather_GetValue(0)
	if RainValue > 0 then
		if RainValue <= 0.5 then
			RandomFire = RandomFire - 5
		else
			RandomFire = RandomFire - RainValue*10
		end
	end
	
	-- protection may protect 100% against weak fires
	if RandomFire < (FireProt*100) then
		return
	end
	
	-- calculate the actual damage
	local BaseFireDmg = RandomFire * MaxHP
	local ActualFireDmg = math.ceil(BaseFireDmg * (1 - FireProt)) -- each % of FireProt reduces the dmg
	
	SetProperty("Owner", "BurningDmg", ActualFireDmg) -- save it to property for firefighting-Measures
	CommitAction("fire", "Owner", "Owner")
	
	-- prevents worker's dwellings from being destroyed
	
	if BuildingGetType("") == GL_BUILDING_TYPE_WORKER_HOUSING then
		if BurnToHP < (GetMaxHP("") * 0.1) then	
			BurnToHP = (GetMaxHP("") * 0.1)
		end
	end 

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
	
	local DPS = math.ceil(ActualFireDmg / 15)
	if DPS < 20 then
		DPS = 20
	end
	local DmgDealt = 0

	while DmgDealt < ActualFireDmg do
		
		if DmgDealt >= GetProperty("Owner", "BurningDmg") then
			break
		end
		
		Evacuate("Owner")
		Sleep(5)
		PlaySound3D("", "fire/DartingFlame_s_02.wav", 1.0)
		
		if BuildingGetType("Owner") == GL_BUILDING_TYPE_WORKER_HOUSING then
			if GetHPRelative("Owner") >= 0.1 then
				ModifyHP("Owner", -DPS, false)
			end
		else
			ModifyHP("Owner", -DPS, false)
		end
		
		DmgDealt = DmgDealt + DPS
		
		Sleep(5)
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
						Sleep(2)
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
	if HasProperty("Owner", "BurningDmg") then
		RemoveProperty("Owner", "BurningDmg")
	end
end
