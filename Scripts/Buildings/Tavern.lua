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
	bld_HandlePingHour("", true)
	
	if SimHasAbility("MyBoss", 16) and GetImpactValue("", "BestHouse") == 0 then
		AddImpact("", "BestHouse", 1, -1)
	elseif not (SimHasAbility("MyBoss", 16) or (GetImpactValue("", "BestHouse") == 0)) then
		RemoveImpact("","BestHouse")
	end
end
