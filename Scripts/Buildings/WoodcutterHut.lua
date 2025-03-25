function Run()
end

function OnLevelUp()
	bld_HandleOnLevelUp("")
end

function Setup()
	bld_HandleSetup("")	-- create ambient animals
	if Rand(2)==0 then
		worldambient_CreateAnimal("Stag", "", 2)
	else
		worldambient_CreateAnimal("Deer", "", 2)
	end
end

function PingHour()
	bld_HandlePingHour("")
		
	-- Improve AI management
	if BuildingGetAISetting("", "Produce_Selection") > 0 then
	--	bld_SetupAI("")
	end
end
