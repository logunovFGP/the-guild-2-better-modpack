function Run()
end

function OnLevelUp()
	if BuildingGetAISetting("", "Produce_Selection") > 0 then
	--	bld_SetupAI("")
	end
end

function Setup()
	-- create ambient animals
	if Rand(2)==0 then
		worldambient_CreateAnimal("Cat", "", 1)
	else
		worldambient_CreateAnimal("Dog", "", 1)
	end
end

function PingHour()

	-- Check every worker every hour for bonuses from employer's abilities
	chr_CheckWorkerBonuses("")
	
	-- Check every worker (only once) for illness and equipment 
	if not HasProperty("", "CheckDefaultWorkers") then
		bld_ResetWorkers("")
		SetProperty("", "CheckDefaultWorkers", 1)
	end
	
	-- Improve AI management
	if BuildingGetAISetting("", "Produce_Selection") > 0 then
	--	bld_SetupAI("")
	end
	
	-- Only for AI
	
	if BuildingGetOwner("", "MyBoss") then
		if GetHomeBuilding("MyBoss", "MyHome") then
			if DynastyIsShadow("MyHome") then -- shadows shall only have 1 cart
				bld_RemoveCart("")
			end
			
			if DynastyIsAI("MyHome") then
				bld_CheckRivals("")
				bld_ForceLevelUp("")
				bld_CheckRepairs("")
			end
		end
		if SimHasAbility("MyBoss",16) and GetImpactValue("","BestHouse") == 0 then
			AddImpact("","BestHouse",1,-1)
		elseif not (SimHasAbility("MyBoss",16) or (GetImpactValue("","BestHouse") == 0)) then
			RemoveImpact("","BestHouse")
		end
	end
end
