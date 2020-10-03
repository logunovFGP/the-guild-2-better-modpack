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
		worldambient_CreateAnimal("Wolf", "", 1)
	end
end

function PingHour()
	bld_HandlePingHour("", true)
end
