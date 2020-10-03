function Run()
end

function OnLevelUp()
end

function Setup()
	-- create ambient animals
	if Rand(2) == 0 then
		worldambient_CreateAnimal("Cat", "", 1)
	else
		worldambient_CreateAnimal("Dog", "", 1)
	end
end

function PingHour()
	bld_HandlePingHour("", true)
end
